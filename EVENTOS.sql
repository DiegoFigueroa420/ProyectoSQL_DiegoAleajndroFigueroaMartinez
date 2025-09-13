-- ============================================
-- EVENTOS 
-- ============================================

-- Membresías
CREATE EVENT ev_actualizar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
DO
  UPDATE membresias SET estado = 'Vencida' WHERE fecha_fin < CURDATE() AND estado != 'Vencida';

CREATE EVENT ev_enviar_recordatorio_renovacion
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  -- Enviar recordatorio de renovación 5 días antes de vencer la membresía
  INSERT INTO notificaciones (usuario_id, mensaje, creado_en)
  SELECT usuario_id, CONCAT('Su membresía vence en 5 días (', fecha_fin, '). Por favor, renueve para evitar interrupciones.'), NOW()
  FROM membresias 
  WHERE estado = 'Activa' 
    AND DATEDIFF(fecha_fin, CURDATE()) = 5;
END;

CREATE EVENT ev_suspender_membresias_inactivas
ON SCHEDULE EVERY 1 DAY
DO
  -- Suspender membresías inactivas después de 30 días sin pago
  UPDATE membresias m
  JOIN (
    SELECT usuario_id, MAX(pagado_en) as ultimo_pago
    FROM pagos p
    JOIN facturas f ON p.factura_id = f.factura_id
    WHERE f.tipo = 'Membresia'
    GROUP BY usuario_id
  ) p ON m.usuario_id = p.usuario_id
  SET m.estado = 'Suspendida'
  WHERE m.estado = 'Activa' 
    AND DATEDIFF(CURDATE(), p.ultimo_pago) > 30;

CREATE EVENT ev_reporte_semanal_nuevas_membresias
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
  -- Generar reporte semanal de nuevas membresías al administrador
  INSERT INTO reportes_administrador (tipo_reporte, contenido, generado_en)
  SELECT 'Nuevas Membresías', 
         CONCAT('Se registraron ', COUNT(*), ' nuevas membresías esta semana.'),
         NOW()
  FROM membresias 
  WHERE creado_en >= DATE_SUB(NOW(), INTERVAL 7 DAY);
END;

CREATE EVENT ev_notificaciones_membresias_suspendidas
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  -- Notificar membresías suspendidas cada día a recepción
  INSERT INTO alertas_recepcion (mensaje, creado_en)
  SELECT CONCAT('Membresía suspendida: Usuario ', u.nombre, ' ', u.apellido), NOW()
  FROM membresias m
  JOIN usuarios u ON m.usuario_id = u.usuario_id
  WHERE m.estado = 'Suspendida'
    AND m.fecha_inicio >= DATE_SUB(NOW(), INTERVAL 60 DAY);
END;

-- Reservas
CREATE EVENT ev_cancelar_reservas_pendientes
ON SCHEDULE EVERY 10 MINUTE
DO
  UPDATE reservas SET estado = 'Cancelada' WHERE estado = 'Pendiente' AND creado_en < DATE_SUB(NOW(), INTERVAL 2 HOUR);

CREATE EVENT ev_enviar_recordatorio_reserva
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
  -- Enviar recordatorio 1 hora antes de la reserva a cada usuario
  INSERT INTO notificaciones (usuario_id, mensaje, creado_en)
  SELECT usuario_id, CONCAT('Recordatorio: Tiene una reserva a las ', DATE_FORMAT(inicio, '%H:%i'), ' en ', e.nombre), NOW()
  FROM reservas r
  JOIN espacios e ON r.espacio_id = e.espacio_id
  WHERE r.estado = 'Confirmada'
    AND inicio BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 1 HOUR)
    AND NOT EXISTS (
      SELECT 1 FROM notificaciones n 
      WHERE n.usuario_id = r.usuario_id 
        AND n.mensaje LIKE CONCAT('%reserva a las ', DATE_FORMAT(r.inicio, '%H:%i'), '%')
    );
END;

CREATE EVENT ev_limpiar_reservas_no_asistidas
ON SCHEDULE EVERY 1 DAY
DO
  -- Eliminar reservas pasadas no asistidas después de 7 días
  DELETE FROM reservas 
  WHERE estado = 'NoAsistio' 
    AND fin < DATE_SUB(NOW(), INTERVAL 7 DAY);

CREATE EVENT ev_reporte_semanal_ocupacion
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
  -- Generar reporte semanal de ocupación de espacios
  INSERT INTO reportes_administrador (tipo_reporte, contenido, generado_en)
  SELECT 'Ocupación Semanal', 
         CONCAT('Ocupación promedio: ', ROUND(AVG(tasa_ocupacion), 2), '%'),
         NOW()
  FROM (
    SELECT espacio_id, 
           (COUNT(*) * 100.0 / (7 * 12)) as tasa_ocupacion -- 7 días * 12 horas laborales
    FROM reservas 
    WHERE estado = 'Confirmada'
      AND inicio >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY espacio_id
  ) t;
END;

CREATE EVENT ev_liberar_reservas_no_reclamadas
ON SCHEDULE EVERY 15 MINUTE
DO
BEGIN
  -- Liberar reservas bloqueadas si no se inicia en los primeros 15 minutos
  UPDATE reservas r
  LEFT JOIN registros_acceso a ON r.usuario_id = a.usuario_id 
    AND a.fecha_acceso BETWEEN r.inicio AND DATE_ADD(r.inicio, INTERVAL 15 MINUTE)
    AND a.evento = 'ENTRADA'
  SET r.estado = 'Cancelada'
  WHERE r.estado = 'Confirmada'
    AND a.acceso_id IS NULL
    AND r.inicio < DATE_SUB(NOW(), INTERVAL 15 MINUTE)
    AND r.inicio > DATE_SUB(NOW(), INTERVAL 1 HOUR);
END;

-- Pagos y Facturación
CREATE EVENT ev_enviar_recordatorio_pago
ON SCHEDULE EVERY 3 DAY
DO
BEGIN
  -- Enviar recordatorio de pago pendiente cada 3 días
  INSERT INTO notificaciones (usuario_id, mensaje, creado_en)
  SELECT DISTINCT usuario_id, 
         CONCAT('Tiene facturas pendientes por un total de $', ROUND(SUM(monto), 2), '. Por favor, regularice su situación.'),
         NOW()
  FROM facturas 
  WHERE estado = 'Pendiente'
    AND creado_en < DATE_SUB(NOW(), INTERVAL 5 DAY)
  GROUP BY usuario_id
  HAVING SUM(monto) > 0;
END;

CREATE EVENT ev_bloquear_servicios_facturas_vencidas
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  -- Bloquear servicios adicionales si existen facturas vencidas mayores a 10 días
  INSERT INTO bloqueos_servicio (usuario_id, bloqueado_desde, razon)
  SELECT DISTINCT usuario_id, NOW(), 'Facturas vencidas por más de 10 días'
  FROM facturas 
  WHERE estado = 'Pendiente'
    AND creado_en < DATE_SUB(NOW(), INTERVAL 10 DAY)
    AND usuario_id IS NOT NULL
  ON DUPLICATE KEY UPDATE bloqueado_desde = NOW(), razon = 'Facturas vencidas por más de 10 días';
END;

CREATE EVENT ev_generar_resumen_facturacion_mensual
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
  -- Generar resumen de facturación mensual automáticamente
  INSERT INTO resumenes_facturacion (mes_anio, ingreso_total, ingreso_membresias, ingreso_reservas, creado_en)
  SELECT 
    DATE_FORMAT(NOW(), '%Y-%m') as mes_anio,
    COALESCE(SUM(p.monto), 0) as ingreso_total,
    COALESCE(SUM(CASE WHEN f.tipo = 'Membresia' THEN p.monto ELSE 0 END), 0) as ingreso_membresias,
    COALESCE(SUM(CASE WHEN f.tipo = 'Reserva' THEN p.monto ELSE 0 END), 0) as ingreso_reservas,
    NOW()
  FROM pagos p
  JOIN facturas f ON p.factura_id = f.factura_id
  WHERE p.estado = 'Pagado'
    AND MONTH(p.pagado_en) = MONTH(NOW())
    AND YEAR(p.pagado_en) = YEAR(NOW());
END;

CREATE EVENT ev_aplicar_recargos_morosidad
ON SCHEDULE EVERY 1 DAY
DO
  -- Aplicar recargos automáticos a facturas vencidas después de 15 días
  UPDATE facturas 
  SET monto = ROUND(monto * 1.02, 2) -- 2% de recargo
  WHERE estado = 'Pendiente'
    AND creado_en < DATE_SUB(NOW(), INTERVAL 15 DAY);

CREATE EVENT ev_enviar_reporte_ingresos_mensual
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
  -- Enviar al contador un reporte de ingresos acumulados cada fin de mes
  INSERT INTO reportes_contabilidad (tipo_reporte, contenido, generado_en)
  SELECT 'Ingresos Mensuales',
         CONCAT('Ingresos totales del mes: $', ROUND(COALESCE(SUM(p.monto), 0), 2)),
         NOW()
  FROM pagos p
  WHERE p.estado = 'Pagado'
    AND MONTH(p.pagado_en) = MONTH(NOW())
    AND YEAR(p.pagado_en) = YEAR(NOW());
END;

-- Accesos y Asistencias
CREATE EVENT ev_limpiar_registros_acceso_antiguos
ON SCHEDULE EVERY 1 WEEK
DO
  -- Eliminar accesos antiguos (más de 1 año) automáticamente
  DELETE FROM registros_acceso WHERE fecha_acceso < DATE_SUB(NOW(), INTERVAL 1 YEAR);

CREATE EVENT ev_reporte_diario_asistencias
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  -- Enviar reporte diario de asistencias al administrador
  INSERT INTO reportes_administrador (tipo_reporte, contenido, generado_en)
  SELECT 'Asistencias Diarias',
         CONCAT('Total de asistencias hoy: ', COUNT(*), '. Usuarios únicos: ', COUNT(DISTINCT usuario_id)),
         NOW()
  FROM registros_acceso 
  WHERE evento = 'ENTRADA'
    AND DATE(fecha_acceso) = CURDATE();
END;

CREATE EVENT ev_reporte_semanal_usuarios_inactivos
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
  -- Generar reporte semanal de usuarios inactivos (sin accesos)
  INSERT INTO reportes_administrador (tipo_reporte, contenido, generado_en)
  SELECT 'Usuarios Inactivos',
         CONCAT('Usuarios sin acceso en la última semana: ', COUNT(*)),
         NOW()
  FROM usuarios u
  WHERE NOT EXISTS (
    SELECT 1 FROM registros_acceso a 
    WHERE a.usuario_id = u.usuario_id 
      AND a.evento = 'ENTRADA'
      AND a.fecha_acceso >= DATE_SUB(NOW(), INTERVAL 7 DAY)
  );
END;

CREATE EVENT ev_alerta_accesos_fuera_horario
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  -- Alertar accesos fuera de horario laboral cada día
  INSERT INTO alertas_administrador (mensaje, severidad, creado_en)
  SELECT CONCAT('Acceso fuera de horario: ', u.nombre, ' ', u.apellido, ' a las ', DATE_FORMAT(a.fecha_acceso, '%H:%i')),
         'MEDIA',
         NOW()
  FROM registros_acceso a
  JOIN usuarios u ON a.usuario_id = u.usuario_id
  WHERE a.evento = 'ENTRADA'
    AND (HOUR(a.fecha_acceso) < 7 OR HOUR(a.fecha_acceso) > 21)
    AND DATE(a.fecha_acceso) = CURDATE();
END;

CREATE EVENT ev_reporte_mensual_top_usuarios
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
  -- Enviar reporte de top 10 usuarios más frecuentes cada mes
  INSERT INTO reportes_administrador (tipo_reporte, contenido, generado_en)
  SELECT 'Top 10 Usuarios Más Frecuentes',
         GROUP_CONCAT(CONCAT(u.nombre, ' ', u.apellido, ' (', cnt, ' accesos)') SEPARATOR ', '),
         NOW()
  FROM (
    SELECT usuario_id, COUNT(*) as cnt
    FROM registros_acceso 
    WHERE evento = 'ENTRADA'
      AND MONTH(fecha_acceso) = MONTH(NOW())
      AND YEAR(fecha_acceso) = YEAR(NOW())
    GROUP BY usuario_id
    ORDER BY cnt DESC
    LIMIT 10
  ) t
  JOIN usuarios u ON t.usuario_id = u.usuario_id;
END;