-- ============================================
-- TRIGGERS 
-- ============================================

-- Módulo Membresías
CREATE TRIGGER trg_antes_insertar_membresia
BEFORE INSERT ON membresias
FOR EACH ROW
BEGIN
  -- Insertar fecha de vencimiento automáticamente al crear una nueva membresía
  IF NEW.fecha_fin IS NULL THEN
    SET NEW.fecha_fin = DATE_ADD(NEW.fecha_inicio, INTERVAL 
      CASE NEW.tipo_membresia_id
        WHEN 1 THEN 1 -- Diaria
        WHEN 2 THEN 30 -- Mensual
        WHEN 3 THEN 30 -- Corporativa
        WHEN 4 THEN 30 -- Premium
        ELSE 30
      END DAY);
  END IF;
END;

CREATE TRIGGER trg_despues_actualizar_pagos_membresia
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
  -- Actualizar estado de membresía a "Activa" cuando se realiza un pago exitoso
  IF NEW.estado = 'Pagado' THEN
    UPDATE membresias m
    JOIN facturas f ON f.usuario_id = m.usuario_id
    SET m.estado = 'Activa'
    WHERE f.factura_id = NEW.factura_id 
      AND f.tipo = 'Membresia'
      AND m.estado != 'Activa';
  END IF;
END;

CREATE TRIGGER trg_verificar_membresia_vencida
BEFORE UPDATE ON membresias
FOR EACH ROW
BEGIN
  -- Actualizar estado de membresía a "Suspendida" cuando no se paga antes de la fecha límite
  IF NEW.fecha_fin < CURDATE() AND NEW.estado = 'Activa' THEN
    SET NEW.estado = 'Vencida';
  END IF;
END;

CREATE TRIGGER trg_log_cambio_membresia
AFTER UPDATE ON membresias
FOR EACH ROW
BEGIN
  -- Registrar en un log cada vez que se actualice el tipo de membresía de un usuario
  IF OLD.tipo_membresia_id <> NEW.tipo_membresia_id THEN
    INSERT INTO log_auditoria_membresia(membresia_id, tipo_anterior, tipo_nuevo, cambiado_en, cambiado_por)
    VALUES (NEW.membresia_id, OLD.tipo_membresia_id, NEW.tipo_membresia_id, NOW(), USER());
  END IF;
END;

CREATE TRIGGER trg_prevenir_eliminacion_membresia
BEFORE DELETE ON membresias
FOR EACH ROW
BEGIN
  -- Bloquear eliminación de membresía si el usuario tiene reservas activas
  IF EXISTS (SELECT 1 FROM reservas WHERE usuario_id = OLD.usuario_id AND estado IN ('Pendiente','Confirmada') AND inicio > NOW()) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar membresía con reservas futuras activas';
  END IF;
END;

-- Módulo Reservas
CREATE TRIGGER trg_antes_insertar_reservas
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
  -- Validar que no existan reservas duplicadas en el mismo espacio, fecha y hora
  IF EXISTS (
    SELECT 1 FROM reservas r
    WHERE r.espacio_id = NEW.espacio_id
      AND r.estado IN ('Pendiente','Confirmada')
      AND (NEW.inicio < r.fin AND NEW.fin > r.inicio)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflicto de reserva: horario no disponible';
  END IF;
END;

CREATE TRIGGER trg_despues_insertar_reservas
AFTER INSERT ON reservas
FOR EACH ROW
BEGIN
  -- Registrar automáticamente el estado "Pendiente de Confirmación" al crear una reserva
  UPDATE reservas SET estado = 'Pendiente' WHERE reserva_id = NEW.reserva_id;
END;

CREATE TRIGGER trg_despues_actualizar_pagos_reserva
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
  -- Cambiar estado a "Confirmada" al registrar el pago de la reserva
  IF NEW.estado = 'Pagado' THEN
    UPDATE reservas r
    JOIN facturas f ON f.usuario_id = r.usuario_id
    SET r.estado = 'Confirmada'
    WHERE f.factura_id = NEW.factura_id 
      AND f.tipo = 'Reserva'
      AND r.estado = 'Pendiente';
  END IF;
END;

CREATE TRIGGER trg_cancelar_reserva_eliminar_membresia
AFTER UPDATE ON membresias
FOR EACH ROW
BEGIN
  -- Cancelar reserva automáticamente si el usuario elimina su membresía
  IF NEW.estado = 'Vencida' OR NEW.estado = 'Suspendida' THEN
    UPDATE reservas 
    SET estado = 'Cancelada' 
    WHERE usuario_id = NEW.usuario_id 
      AND estado IN ('Pendiente','Confirmada')
      AND inicio > NOW();
  END IF;
END;

CREATE TRIGGER trg_log_cancelacion_reserva
AFTER UPDATE ON reservas
FOR EACH ROW
BEGIN
  -- Registrar en un log cada vez que una reserva es cancelada
  IF OLD.estado != 'Cancelada' AND NEW.estado = 'Cancelada' THEN
    INSERT INTO registros_acceso(usuario_id, fecha_acceso, evento, razon) 
    VALUES (NEW.usuario_id, NOW(), 'SALIDA', CONCAT('Reserva cancelada id=', NEW.reserva_id));
  END IF;
END;

-- Módulo Pagos y Facturación
CREATE TRIGGER trg_despues_insertar_pagos
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  -- Declarar todas las variables al inicio
  DECLARE v_suma DECIMAL(14,2);
  DECLARE v_factura_total DECIMAL(14,2);
  
  -- Calcular la suma de pagos para esta factura
  SELECT COALESCE(SUM(monto),0) INTO v_suma 
  FROM pagos 
  WHERE factura_id = NEW.factura_id AND estado = 'Pagado';
  
  -- Obtener el monto total de la factura
  SELECT monto INTO v_factura_total 
  FROM facturas 
  WHERE factura_id = NEW.factura_id;
  
  -- Actualizar el estado de la factura según el pago
  IF v_suma >= v_factura_total THEN
    UPDATE facturas SET estado = 'Pagada' WHERE factura_id = NEW.factura_id;
  ELSE
    UPDATE facturas SET estado = 'Parcial' WHERE factura_id = NEW.factura_id;
  END IF;
END;

CREATE TRIGGER trg_despues_actualizar_facturas
AFTER UPDATE ON facturas
FOR EACH ROW
BEGIN
  -- Actualizar factura a "Pagada" cuando se confirma el pago
  IF NEW.estado = 'Pagada' AND OLD.estado != 'Pagada' THEN
    UPDATE pagos SET estado = 'Pagado' WHERE factura_id = NEW.factura_id;
  END IF;
END;

CREATE TRIGGER trg_prevenir_eliminacion_pago
BEFORE DELETE ON pagos
FOR EACH ROW
BEGIN
  -- Bloquear eliminación de un pago si ya existe factura asociada
  IF EXISTS (SELECT 1 FROM facturas WHERE factura_id = OLD.factura_id AND estado = 'Pagada') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar pago de una factura ya pagada';
  END IF;
END;

CREATE TRIGGER trg_actualizar_saldo_factura
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  -- Actualizar saldo pendiente en facturas con pagos parciales
  DECLARE v_pagado DECIMAL(14,2);
  DECLARE v_total DECIMAL(14,2);
  
  SELECT COALESCE(SUM(monto), 0) INTO v_pagado 
  FROM pagos 
  WHERE factura_id = NEW.factura_id AND estado = 'Pagado';
  
  SELECT monto INTO v_total FROM facturas WHERE factura_id = NEW.factura_id;
  
  IF v_pagado >= v_total THEN
    UPDATE facturas SET estado = 'Pagada' WHERE factura_id = NEW.factura_id;
  ELSEIF v_pagado > 0 THEN
    UPDATE facturas SET estado = 'Parcial' WHERE factura_id = NEW.factura_id;
  END IF;
END;

CREATE TRIGGER trg_log_pagos_anulados
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
  -- Registrar en un log todos los pagos anulados
  IF OLD.estado != 'Cancelado' AND NEW.estado = 'Cancelado' THEN
    INSERT INTO registros_acceso(usuario_id, fecha_acceso, evento, razon) 
    VALUES (NEW.usuario_id, NOW(), 'SALIDA', CONCAT('Pago cancelado id=', NEW.pago_id));
  END IF;
END;

-- Módulo Accesos
CREATE TRIGGER trg_despues_insertar_registros_acceso
AFTER INSERT ON registros_acceso
FOR EACH ROW
BEGIN
  -- Registrar asistencia automáticamente al validar acceso con QR o tarjeta
  IF NEW.evento = 'ENTRADA' THEN
    UPDATE usuarios SET ultimo_acceso = NOW() WHERE usuario_id = NEW.usuario_id;
  END IF;
END;

CREATE TRIGGER trg_antes_insertar_registros_acceso
BEFORE INSERT ON registros_acceso
FOR EACH ROW
BEGIN
  -- Bloquear acceso si el usuario no tiene membresía activa
  DECLARE v_membresia_activa TINYINT;
  SET v_membresia_activa = fn_membresia_activa(NEW.usuario_id);
  
  IF NEW.evento = 'ENTRADA' AND v_membresia_activa = 0 THEN
    -- Verificar si tiene reserva confirmada para el momento actual
    IF NOT EXISTS (
      SELECT 1 FROM reservas 
      WHERE usuario_id = NEW.usuario_id 
        AND estado = 'Confirmada' 
        AND NOW() BETWEEN inicio AND fin
    ) THEN
      SET NEW.evento = 'DENEGADO';
      SET NEW.razon = 'Sin membresía activa ni reserva confirmada';
    END IF;
  END IF;
END;

CREATE TRIGGER trg_actualizar_ultimo_acceso
AFTER INSERT ON registros_acceso
FOR EACH ROW
BEGIN
  -- Actualizar última fecha de acceso del usuario al ingresar
  IF NEW.evento = 'ENTRADA' THEN
    UPDATE usuarios SET ultimo_acceso = NOW() WHERE usuario_id = NEW.usuario_id;
  END IF;
END;

CREATE TRIGGER trg_registrar_salida_automatica
BEFORE INSERT ON registros_acceso
FOR EACH ROW
BEGIN
  -- Registrar salida automáticamente si el usuario vuelve a entrar sin salida previa
  DECLARE v_ultimo_evento ENUM('ENTRADA','SALIDA','DENEGADO');
  
  IF NEW.evento = 'ENTRADA' THEN
    SELECT evento INTO v_ultimo_evento 
    FROM registros_acceso 
    WHERE usuario_id = NEW.usuario_id 
    ORDER BY fecha_acceso DESC 
    LIMIT 1;
    
    IF v_ultimo_evento = 'ENTRADA' THEN
      -- Registrar salida automática antes del nuevo acceso
      INSERT INTO registros_acceso (usuario_id, fecha_acceso, evento, razon)
      VALUES (NEW.usuario_id, NOW(), 'SALIDA', 'Salida automática por nuevo acceso');
    END IF;
  END IF;
END;

CREATE TRIGGER trg_log_intentos_rechazados
AFTER INSERT ON registros_acceso
FOR EACH ROW
BEGIN
  -- Registrar en un log cada intento de acceso rechazado
  IF NEW.evento = 'DENEGADO' THEN
    INSERT INTO accesos_denegados (usuario_id, fecha_intento, razon, metodo)
    VALUES (NEW.usuario_id, NEW.fecha_acceso, NEW.razon, 'QR/Tarjeta');
  END IF;
END;