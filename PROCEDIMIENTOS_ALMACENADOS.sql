-- ============================================
-- PROCEDIMIENTOS ALMACENADOS (20)
-- ============================================

-- 1. Membresías (4 procedimientos)
CREATE PROCEDURE sp_registrar_membresia(
  IN p_usuario_id INT,
  IN p_tipo_membresia_id INT,
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE,
  IN p_estado VARCHAR(20),
  OUT p_membresia_id INT
)
BEGIN
  INSERT INTO membresias(usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, estado, creado_en)
  VALUES (p_usuario_id, p_tipo_membresia_id, p_fecha_inicio, p_fecha_fin, COALESCE(p_estado,'Activa'), NOW());
  SET p_membresia_id = LAST_INSERT_ID();
END;

CREATE PROCEDURE sp_renovar_membresia(
  IN p_membresia_id INT,
  IN p_extender_dias INT
)
BEGIN
  UPDATE membresias
  SET fecha_fin = DATE_ADD(fecha_fin, INTERVAL p_extender_dias DAY), estado = 'Activa'
  WHERE membresia_id = p_membresia_id;
  INSERT INTO renovaciones_membresia(membresia_id, renovado_en) VALUES (p_membresia_id, NOW());
END;

CREATE PROCEDURE sp_actualizar_membresias_vencidas(OUT p_actualizadas INT)
BEGIN
  UPDATE membresias SET estado = 'Vencida' WHERE fecha_fin < CURDATE() AND estado != 'Vencida';
  SELECT ROW_COUNT() INTO p_actualizadas;
END;

CREATE PROCEDURE sp_suspender_por_deuda(IN p_dias INT, OUT p_cantidad INT)
BEGIN
  UPDATE membresias m
  JOIN (
    SELECT DISTINCT usuario_id FROM facturas WHERE estado != 'Pagada' AND creado_en < DATE_SUB(NOW(), INTERVAL p_dias DAY) AND usuario_id IS NOT NULL
  ) d ON m.usuario_id = d.usuario_id
  SET m.estado = 'Suspendida'
  WHERE m.estado = 'Activa';
  SELECT ROW_COUNT() INTO p_cantidad;
END;

-- 2. Reservas y Espacios (5 procedimientos)
CREATE PROCEDURE sp_verificar_disponibilidad(
  IN p_espacio_id INT,
  IN p_inicio DATETIME,
  IN p_fin DATETIME,
  OUT p_disponible TINYINT
)
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt FROM reservas r
  WHERE r.espacio_id = p_espacio_id AND r.estado IN ('Pendiente','Confirmada') AND (p_inicio < r.fin AND p_fin > r.inicio);
  SET p_disponible = IF(v_cnt=0,1,0);
END;

CREATE PROCEDURE sp_crear_reserva(
  IN p_usuario_id INT,
  IN p_empresa_id INT,
  IN p_espacio_id INT,
  IN p_inicio DATETIME,
  IN p_fin DATETIME,
  OUT p_reserva_id INT
)
BEGIN
  DECLARE v_ok TINYINT;
  CALL sp_verificar_disponibilidad(p_espacio_id, p_inicio, p_fin, v_ok);
  IF v_ok = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Espacio no disponible en ese horario';
  END IF;
  INSERT INTO reservas(usuario_id, empresa_id, espacio_id, inicio, fin, estado, creado_en)
  VALUES (p_usuario_id, p_empresa_id, p_espacio_id, p_inicio, p_fin, 'Pendiente', NOW());
  SET p_reserva_id = LAST_INSERT_ID();
END;

-- a
CREATE PROCEDURE sp_confirmar_reserva_con_pago(
  IN p_reserva_id INT,
  IN p_monto DECIMAL(12,2),
  IN p_metodo ENUM('Efectivo','Tarjeta','Transferencia','PayPal'),
  OUT p_ok TINYINT
)
proc_block: BEGIN
  DECLARE v_usuario INT;
  DECLARE v_empresa INT;
  
  SELECT usuario_id, empresa_id INTO v_usuario, v_empresa 
  FROM reservas WHERE reserva_id = p_reserva_id;
  
  IF v_usuario IS NULL THEN
    SET p_ok = 0;
    LEAVE proc_block;
  END IF;
  
  INSERT INTO facturas(usuario_id, empresa_id, monto, tipo, creado_en, estado)
  VALUES (v_usuario, v_empresa, p_monto, 'Reserva', NOW(), 'Pagada');
  
  SET @v_factura_id = LAST_INSERT_ID();
  
  INSERT INTO pagos(factura_id, usuario_id, monto, metodo, estado, pagado_en)
  VALUES (@v_factura_id, v_usuario, p_monto, p_metodo, 'Pagado', NOW());
  
  UPDATE reservas SET estado = 'Confirmada' WHERE reserva_id = p_reserva_id;
  
  SET p_ok = 1;
END;

DELIMITER $$

CREATE PROCEDURE sp_cancelar_reserva_reembolso(
  IN p_reserva_id INT,
  IN p_monto_reembolso DECIMAL(12,2),
  IN p_razon VARCHAR(255)
)
BEGIN
  DECLARE v_usuario INT; 
  DECLARE v_empresa INT;
  
  SELECT usuario_id, empresa_id INTO v_usuario, v_empresa 
  FROM reservas WHERE reserva_id = p_reserva_id;
  
  IF v_usuario IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva no encontrada';
  END IF;
  
  UPDATE reservas SET estado = 'Cancelada' WHERE reserva_id = p_reserva_id;
  
  IF p_monto_reembolso > 0 THEN
    INSERT INTO facturas(usuario_id, empresa_id, monto, tipo, creado_en, estado, descripcion)
    VALUES (v_usuario, v_empresa, -ABS(p_monto_reembolso), 'Reserva', NOW(), 'Anulada', CONCAT('Reembolso: ', p_razon));
  END IF;
END$$

CREATE PROCEDURE sp_liberar_reservas_no_confirmadas(IN p_horas INT, OUT p_cantidad INT)
BEGIN
  UPDATE reservas SET estado = 'Cancelada' 
  WHERE estado = 'Pendiente' 
  AND creado_en < DATE_SUB(NOW(), INTERVAL p_horas HOUR);
  
  SELECT ROW_COUNT() INTO p_cantidad;
END$$

DELIMITER ;

-- 3. Pagos y Facturación (4 procedimientos)
CREATE PROCEDURE sp_generar_factura_membresia(
  IN p_usuario_id INT,
  IN p_empresa_id INT,
  IN p_monto DECIMAL(12,2),
  OUT p_factura_id INT
)
BEGIN
  INSERT INTO facturas(usuario_id, empresa_id, monto, tipo, creado_en, estado)
  VALUES (p_usuario_id, p_empresa_id, p_monto, 'Membresia', NOW(), 'Pendiente');
  SET p_factura_id = LAST_INSERT_ID();
END;

DELIMITER $$

CREATE PROCEDURE sp_generar_factura_consolidada_empresa(IN p_empresa_id INT, OUT p_factura_id INT)
BEGIN
  DECLARE v_total DECIMAL(14,2);
  
  -- Calcular el total de facturas pendientes
  SELECT COALESCE(SUM(monto),0) INTO v_total 
  FROM facturas 
  WHERE empresa_id = p_empresa_id AND estado = 'Pendiente';
  
  -- Si no hay facturas pendientes, retornar NULL
  IF v_total = 0 THEN
    SET p_factura_id = NULL;
    RETURN;
  END IF;
  
  -- Crear la factura consolidada
  INSERT INTO facturas(usuario_id, empresa_id, monto, tipo, creado_en, estado)
  VALUES (NULL, p_empresa_id, v_total, 'Membresia', NOW(), 'Pendiente');
  
  -- Retornar el ID de la factura creada
  SET p_factura_id = LAST_INSERT_ID();
END$$

DELIMITER ;

CREATE PROCEDURE sp_aplicar_recargos(IN p_dias INT, IN p_porcentaje DECIMAL(5,2), OUT p_cantidad INT)
BEGIN
  UPDATE facturas SET monto = ROUND(monto * (1 + p_porcentaje/100.0),2)
  WHERE estado != 'Pagada' AND estado != 'Anulada' AND creado_en < DATE_SUB(NOW(), INTERVAL p_dias DAY);
  SELECT ROW_COUNT() INTO p_cantidad;
END;

CREATE PROCEDURE sp_bloquear_servicios_por_impago(IN p_dias INT, OUT p_cantidad INT)
BEGIN
  INSERT INTO bloqueos_servicio(usuario_id, bloqueado_desde, razon)
  SELECT DISTINCT usuario_id, NOW(), CONCAT('Facturas pendientes > ', p_dias, ' dias')
  FROM facturas
  WHERE estado != 'Pagada' AND creado_en < DATE_SUB(NOW(), INTERVAL p_dias DAY) AND usuario_id IS NOT NULL
  ON DUPLICATE KEY UPDATE bloqueado_desde = VALUES(bloqueado_desde), razon = VALUES(razon);
  SELECT ROW_COUNT() INTO p_cantidad;
END;

-- 4. Accesos y Asistencias (4 procedimientos)
CREATE PROCEDURE sp_registrar_acceso_entrada(IN p_usuario_id INT, IN p_info_validacion VARCHAR(255), OUT p_resultado VARCHAR(10))
BEGIN
  DECLARE v_tiene_membresia TINYINT DEFAULT 0;
  DECLARE v_tiene_reserva TINYINT DEFAULT 0;
  SET v_tiene_membresia = fn_membresia_activa(p_usuario_id);
  SELECT EXISTS (SELECT 1 FROM reservas r WHERE r.usuario_id = p_usuario_id AND r.estado = 'Confirmada' AND NOW() BETWEEN r.inicio AND r.fin) INTO v_tiene_reserva;
  IF v_tiene_membresia = 1 OR v_tiene_reserva = 1 THEN
    INSERT INTO registros_acceso(usuario_id, fecha_acceso, evento, razon) VALUES (p_usuario_id, NOW(), 'ENTRADA', p_info_validacion);
    SET p_resultado = 'ENTRADA';
  ELSE
    INSERT INTO registros_acceso(usuario_id, fecha_acceso, evento, razon) VALUES (p_usuario_id, NOW(), 'DENEGADO', 'Sin membresia ni reserva');
    SET p_resultado = 'DENEGADO';
  END IF;
END;

CREATE PROCEDURE sp_registrar_acceso_salida(IN p_usuario_id INT)
BEGIN
  INSERT INTO registros_acceso(usuario_id, fecha_acceso, evento, razon) VALUES (p_usuario_id, NOW(), 'SALIDA', NULL);
END;

CREATE PROCEDURE sp_reporte_diario_asistencias(IN p_fecha DATE)
BEGIN
  SELECT
    (SELECT COUNT(*) FROM registros_acceso WHERE DATE(fecha_acceso) = p_fecha AND evento = 'ENTRADA') AS total_accesos,
    (SELECT COUNT(DISTINCT usuario_id) FROM registros_acceso WHERE DATE(fecha_acceso) = p_fecha AND evento = 'ENTRADA') AS usuarios_unicos,
    (SELECT HOUR(fecha_acceso) FROM registros_acceso WHERE DATE(fecha_acceso) = p_fecha AND evento = 'ENTRADA' GROUP BY HOUR(fecha_acceso) ORDER BY COUNT(*) DESC LIMIT 1) AS hora_pico;
END;

CREATE PROCEDURE sp_marcar_no_show_y_penalizar(IN p_horas_despues INT, IN p_monto_penalizacion DECIMAL(12,2), OUT p_cantidad INT)
BEGIN
  DECLARE hecho INT DEFAULT 0;
  DECLARE r_id INT; DECLARE r_usuario INT; DECLARE r_empresa INT;
  DECLARE cur1 CURSOR FOR
    SELECT reserva_id, usuario_id, empresa_id
    FROM reservas r
    WHERE r.estado = 'Confirmada'
      AND r.fin < DATE_SUB(NOW(), INTERVAL p_horas_despues HOUR)
      AND NOT EXISTS (SELECT 1 FROM registros_acceso a WHERE a.usuario_id = r.usuario_id AND a.evento = 'ENTRADA' AND a.fecha_acceso BETWEEN r.inicio AND r.fin);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET hecho = 1;
  SET p_cantidad = 0;
  OPEN cur1;
  bucle_lectura: LOOP
    FETCH cur1 INTO r_id, r_usuario, r_empresa;
    IF hecho THEN LEAVE bucle_lectura; END IF;
    UPDATE reservas SET estado = 'NoAsistio' WHERE reserva_id = r_id;
    INSERT INTO facturas(usuario_id, empresa_id, monto, tipo, creado_en, estado, descripcion) VALUES (r_usuario, r_empresa, p_monto_penalizacion, 'Penalizacion', NOW(), 'Pendiente', 'No show');
    SET p_cantidad = p_cantidad + 1;
  END LOOP;
  CLOSE cur1;
END;

-- 5. Corporativos y Administración (3 procedimientos)
CREATE PROCEDURE sp_registrar_lote_empleados(IN p_empresa_id INT, IN p_usuarios_json TEXT, IN p_tipo_membresia_id INT, IN p_fecha_inicio DATE, IN p_fecha_fin DATE, OUT p_cantidad INT)
BEGIN
  DECLARE v_i INT DEFAULT 0;
  DECLARE v_longitud INT DEFAULT 0;
  DECLARE v_nombre VARCHAR(100); DECLARE v_apellido VARCHAR(100); DECLARE v_email VARCHAR(200); DECLARE v_nacimiento DATE;
  SET p_cantidad = 0;
  SET v_longitud = JSON_LENGTH(p_usuarios_json);
  WHILE v_i < v_longitud DO
    SET v_nombre = JSON_UNQUOTE(JSON_EXTRACT(p_usuarios_json, CONCAT('$[', v_i, '].nombre')));
    SET v_apellido = JSON_UNQUOTE(JSON_EXTRACT(p_usuarios_json, CONCAT('$[', v_i, '].apellido')));
    SET v_email = JSON_UNQUOTE(JSON_EXTRACT(p_usuarios_json, CONCAT('$[', v_i, '].email')));
    SET v_nacimiento = JSON_UNQUOTE(JSON_EXTRACT(p_usuarios_json, CONCAT('$[', v_i, '].fecha_nacimiento')));
    INSERT INTO usuarios(nombre,apellido,email,fecha_nacimiento,empresa_id) VALUES (v_nombre, v_apellido, v_email, v_nacimiento, p_empresa_id);
    SET @nuevo_usuario = LAST_INSERT_ID();
    INSERT INTO membresias(usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, estado, creado_en) VALUES (@nuevo_usuario, p_tipo_membresia_id, p_fecha_inicio, p_fecha_fin, 'Activa', NOW());
    SET p_cantidad = p_cantidad + 1;
    SET v_i = v_i + 1;
  END WHILE;
END;

CREATE PROCEDURE sp_cancelar_reservas_al_eliminar_membresia(IN p_usuario_id INT, OUT p_canceladas INT)
BEGIN
  UPDATE membresias SET estado = 'Vencida' WHERE usuario_id = p_usuario_id;
  UPDATE reservas SET estado = 'Cancelada' WHERE usuario_id = p_usuario_id AND inicio > NOW() AND estado IN ('Pendiente','Confirmada');
  SELECT ROW_COUNT() INTO p_canceladas;
END;

CREATE PROCEDURE sp_reporte_ingresos_mensuales(IN p_anio INT)
BEGIN
  SELECT m.mes, ROUND(m.total,2) AS total, ROUND(SUM(m.total) OVER (ORDER BY m.mes),2) AS acumulado
  FROM (
    SELECT MONTH(creado_en) AS mes, SUM(monto) AS total
    FROM facturas
    WHERE YEAR(creado_en) = p_anio AND estado = 'Pagada'
    GROUP BY MONTH(creado_en)
  ) m ORDER BY m.mes;
END;