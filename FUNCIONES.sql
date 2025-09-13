-- ============================================
-- FUNCIONES 
-- ============================================

-- 1. Membresías
CREATE FUNCTION fn_membresia_activa(p_usuario_id INT)
RETURNS TINYINT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT DEFAULT 0;
  SELECT COUNT(*) INTO v_cnt FROM membresias
    WHERE usuario_id = p_usuario_id
      AND estado = 'Activa'
      AND CURDATE() BETWEEN fecha_inicio AND fecha_fin;
  RETURN IF(v_cnt>0,1,0);
END;

CREATE FUNCTION fn_dias_restantes_membresia(p_usuario_id INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_fecha_fin DATE;
  DECLARE v_dias INT;
  SELECT fecha_fin INTO v_fecha_fin FROM membresias
    WHERE usuario_id = p_usuario_id
      AND estado = 'Activa'
      AND CURDATE() <= fecha_fin
    ORDER BY fecha_fin DESC LIMIT 1;
  IF v_fecha_fin IS NULL THEN
    RETURN 0;
  END IF;
  SET v_dias = DATEDIFF(v_fecha_fin, CURDATE());
  RETURN IF(v_dias<0,0,v_dias);
END;

CREATE FUNCTION fn_tipo_membresia(p_usuario_id INT)
RETURNS VARCHAR(100) DETERMINISTIC
BEGIN
  DECLARE v_nombre VARCHAR(100);
  SELECT tm.nombre INTO v_nombre
  FROM membresias m
  JOIN tipos_membresia tm ON m.tipo_membresia_id = tm.tipo_membresia_id
  WHERE m.usuario_id = p_usuario_id
    AND m.estado = 'Activa'
    AND CURDATE() BETWEEN m.fecha_inicio AND m.fecha_fin
  ORDER BY m.fecha_fin DESC LIMIT 1;
  RETURN v_nombre;
END;

CREATE FUNCTION fn_renovaciones_membresia(p_usuario_id INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(rm.renovacion_id) INTO v_cnt
  FROM renovaciones_membresia rm
  JOIN membresias m ON rm.membresia_id = m.membresia_id
  WHERE m.usuario_id = p_usuario_id;
  RETURN COALESCE(v_cnt,0);
END;

CREATE FUNCTION fn_estado_membresia(p_usuario_id INT)
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
  DECLARE v_estado VARCHAR(20);
  SELECT estado INTO v_estado
  FROM membresias
  WHERE usuario_id = p_usuario_id
  ORDER BY fecha_fin DESC, creado_en DESC
  LIMIT 1;
  RETURN v_estado;
END;

-- 2. Reservas
CREATE FUNCTION fn_total_reservas(p_usuario_id INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_total INT;
  SELECT COUNT(*) INTO v_total FROM reservas WHERE usuario_id = p_usuario_id;
  RETURN COALESCE(v_total,0);
END;

CREATE FUNCTION fn_horas_reservadas(p_usuario_id INT, p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  DECLARE v_horas DECIMAL(10,2);
  SELECT COALESCE(SUM(TIMESTAMPDIFF(SECOND, inicio, fin))/3600,0) INTO v_horas
  FROM reservas
  WHERE usuario_id = p_usuario_id
    AND MONTH(inicio) = p_mes
    AND YEAR(inicio) = p_anio
    AND estado = 'Confirmada';
  RETURN ROUND(v_horas,2);
END;

CREATE FUNCTION fn_espacio_mas_reservado()
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_espacio INT;
  SELECT espacio_id INTO v_espacio
  FROM (
    SELECT espacio_id, COUNT(*) AS cnt
    FROM reservas
    WHERE estado = 'Confirmada'
    GROUP BY espacio_id
    ORDER BY cnt DESC LIMIT 1
  ) AS t;
  RETURN v_espacio;
END;

CREATE FUNCTION fn_reservas_activas(p_usuario_id INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt FROM reservas
  WHERE usuario_id = p_usuario_id
    AND estado = 'Confirmada'
    AND NOW() BETWEEN inicio AND fin;
  RETURN COALESCE(v_cnt,0);
END;

CREATE FUNCTION fn_duracion_promedio_reservas(p_espacio_id INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  DECLARE v_promedio DECIMAL(10,2);
  SELECT AVG(TIMESTAMPDIFF(SECOND,inicio,fin)/3600) INTO v_promedio
  FROM reservas
  WHERE espacio_id = p_espacio_id
    AND estado = 'Confirmada';
  RETURN COALESCE(ROUND(v_promedio,2),0);
END;

-- 3. Pagos y Facturación
CREATE FUNCTION fn_total_pagado(p_usuario_id INT)
RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
  DECLARE v_suma DECIMAL(12,2);
  SELECT COALESCE(SUM(monto),0) INTO v_suma FROM pagos WHERE usuario_id = p_usuario_id AND estado = 'Pagado';
  RETURN ROUND(v_suma,2);
END;

CREATE FUNCTION fn_ingresos_por_mes(p_mes INT, p_anio INT)
RETURNS DECIMAL(14,2) DETERMINISTIC
BEGIN
  DECLARE v_suma DECIMAL(14,2);
  SELECT COALESCE(SUM(p.monto),0) INTO v_suma
  FROM pagos p
  WHERE p.estado = 'Pagado'
    AND MONTH(p.pagado_en) = p_mes
    AND YEAR(p.pagado_en) = p_anio;
  RETURN ROUND(v_suma,2);
END;

CREATE FUNCTION fn_ingresos_por_membresias()
RETURNS DECIMAL(14,2) DETERMINISTIC
BEGIN
  DECLARE v_suma DECIMAL(14,2);
  SELECT COALESCE(SUM(p.monto),0) INTO v_suma
  FROM pagos p
  JOIN facturas f ON p.factura_id = f.factura_id
  WHERE p.estado = 'Pagado' AND f.tipo = 'Membresia';
  RETURN ROUND(v_suma,2);
END;

CREATE FUNCTION fn_ingresos_por_reservas()
RETURNS DECIMAL(14,2) DETERMINISTIC
BEGIN
  DECLARE v_suma DECIMAL(14,2);
  SELECT COALESCE(SUM(p.monto),0) INTO v_suma
  FROM pagos p
  JOIN facturas f ON p.factura_id = f.factura_id
  WHERE p.estado = 'Pagado' AND f.tipo = 'Reserva';
  RETURN ROUND(v_suma,2);
END;

CREATE FUNCTION fn_ingresos_por_empresa(p_empresa_id INT)
RETURNS DECIMAL(14,2) DETERMINISTIC
BEGIN
  DECLARE v_suma DECIMAL(14,2);
  SELECT COALESCE(SUM(p.monto),0) INTO v_suma
  FROM pagos p
  JOIN facturas f ON p.factura_id = f.factura_id
  WHERE p.estado = 'Pagado' AND f.empresa_id = p_empresa_id;
  RETURN ROUND(v_suma,2);
END;

-- 4. Accessos y Asistencias
CREATE FUNCTION fn_total_asistencias(p_usuario_id INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt FROM registros_acceso WHERE usuario_id = p_usuario_id AND evento = 'ENTRADA';
  RETURN COALESCE(v_cnt,0);
END;

CREATE FUNCTION fn_asistencias_mes(p_usuario_id INT, p_mes INT, p_anio INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt FROM registros_acceso
  WHERE usuario_id = p_usuario_id AND evento = 'ENTRADA'
    AND MONTH(fecha_acceso) = p_mes AND YEAR(fecha_acceso) = p_anio;
  RETURN COALESCE(v_cnt,0);
END;

CREATE FUNCTION fn_top_usuario_asistencias()
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_usuario INT;
  SELECT usuario_id INTO v_usuario FROM (
    SELECT usuario_id, COUNT(*) AS cnt FROM registros_acceso WHERE evento = 'ENTRADA' GROUP BY usuario_id ORDER BY cnt DESC LIMIT 1
  ) t;
  RETURN v_usuario;
END;

CREATE FUNCTION fn_ultima_asistencia(p_usuario_id INT)
RETURNS DATETIME DETERMINISTIC
BEGIN
  DECLARE v_fecha DATETIME;
  SELECT MAX(fecha_acceso) INTO v_fecha FROM registros_acceso WHERE usuario_id = p_usuario_id AND evento = 'ENTRADA';
  RETURN v_fecha;
END;

CREATE FUNCTION fn_promedio_asistencias()
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  DECLARE v_promedio DECIMAL(10,2);
  SELECT COALESCE(AVG(cnt),0) INTO v_promedio FROM (
    SELECT usuario_id, COUNT(*) AS cnt FROM registros_acceso WHERE evento = 'ENTRADA' GROUP BY usuario_id
  ) t;
  RETURN ROUND(v_promedio,2);
END;