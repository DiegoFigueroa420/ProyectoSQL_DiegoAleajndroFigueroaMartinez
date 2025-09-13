-- ============================================
-- 100 CONSULTAS SQL OPTIMIZADAS
-- ============================================

-- 1. Todos los usuarios
SELECT usuario_id, nombre, apellido, email FROM usuarios;

-- 2. Usuarios con membresía activa
SELECT u.* FROM usuarios u 
JOIN membresias m ON u.usuario_id = m.usuario_id 
WHERE m.estado = 'Activa' AND CURDATE() BETWEEN m.fecha_inicio AND m.fecha_fin;


-- 3. Membresías por tipo
SELECT tm.nombre, COUNT(*) FROM membresias m 
JOIN tipos_membresia tm ON m.tipo_membresia_id = tm.tipo_membresia_id 
GROUP BY tm.nombre;

-- 4. Usuarios por empresa
SELECT e.nombre, COUNT(u.usuario_id) FROM empresas e 
LEFT JOIN usuarios u ON e.empresa_id = u.empresa_id 
GROUP BY e.nombre;

-- 5. Reservas de hoy
SELECT r.*, u.nombre, u.apellido FROM reservas r 
JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE DATE(r.inicio) = CURDATE() AND r.estado = 'Confirmada';

-- 6. Espacios más reservados
SELECT e.nombre, COUNT(r.reserva_id) FROM espacios e 
JOIN reservas r ON e.espacio_id = r.espacio_id 
GROUP BY e.espacio_id ORDER BY COUNT(r.reserva_id) DESC;

-- 7. Ingresos por mes
SELECT YEAR(pagado_en) as año, MONTH(pagado_en) as mes, 
SUM(monto) as ingresos FROM pagos WHERE estado = 'Pagado' 
GROUP BY YEAR(pagado_en), MONTH(pagado_en);

-- 8. Métodos de pago
SELECT metodo, COUNT(*) as cantidad, SUM(monto) as total 
FROM pagos WHERE estado = 'Pagado' GROUP BY metodo;

-- 9. Usuarios con mayor gasto
SELECT u.usuario_id, u.nombre, u.apellido, SUM(p.monto) as total_gastado 
FROM pagos p JOIN usuarios u ON p.usuario_id = u.usuario_id 
WHERE p.estado = 'Pagado' GROUP BY u.usuario_id ORDER BY total_gastado DESC LIMIT 10;

-- 10. Facturas pendientes
SELECT f.*, u.nombre, u.apellido FROM facturas f 
JOIN usuarios u ON f.usuario_id = u.usuario_id 
WHERE f.estado = 'Pendiente';

-- 11. Asistencias por día
SELECT DATE(fecha_acceso) as fecha, COUNT(*) as asistencias 
FROM registros_acceso WHERE evento = 'ENTRADA' GROUP BY DATE(fecha_acceso);

-- 12. Usuarios más frecuentes
SELECT u.usuario_id, u.nombre, u.apellido, COUNT(*) as visitas 
FROM registros_acceso ra JOIN usuarios u ON ra.usuario_id = u.usuario_id 
WHERE ra.evento = 'ENTRADA' GROUP BY u.usuario_id ORDER BY visitas DESC LIMIT 10;

-- 13. Horario pico
SELECT HOUR(fecha_acceso) as hora, COUNT(*) as accesos 
FROM registros_acceso WHERE evento = 'ENTRADA' 
GROUP BY HOUR(fecha_acceso) ORDER BY accesos DESC;

-- 14. Servicios más utilizados
SELECT s.nombre, COUNT(sr.id) as veces_utilizado 
FROM servicios s JOIN servicios_reserva sr ON s.servicio_id = sr.servicio_id 
GROUP BY s.servicio_id ORDER BY veces_utilizado DESC;

-- 15. Reservas con servicios
SELECT r.reserva_id, u.nombre, u.apellido, GROUP_CONCAT(s.nombre) as servicios 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
JOIN servicios_reserva sr ON r.reserva_id = sr.reserva_id 
JOIN servicios s ON sr.servicio_id = s.servicio_id 
GROUP BY r.reserva_id LIMIT 10;

-- 16. Duración promedio de reservas
SELECT te.nombre, AVG(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as duracion_promedio 
FROM reservas r JOIN espacios e ON r.espacio_id = e.espacio_id 
JOIN tipos_espacio te ON e.tipo_espacio_id = te.tipo_espacio_id 
WHERE r.estado = 'Confirmada' GROUP BY te.tipo_espacio_id;

-- 17. Espacios nunca reservados
SELECT e.* FROM espacios e 
LEFT JOIN reservas r ON e.espacio_id = r.espacio_id 
WHERE r.reserva_id IS NULL;

-- 18. Renovaciones de membresía
SELECT u.nombre, u.apellido, COUNT(rm.renovacion_id) as renovaciones 
FROM usuarios u JOIN membresias m ON u.usuario_id = m.usuario_id 
JOIN renovaciones_membresia rm ON m.membresia_id = rm.membresia_id 
GROUP BY u.usuario_id;

-- 19. Membresías próximas a vencer
SELECT u.nombre, u.apellido, m.fecha_fin 
FROM usuarios u JOIN membresias m ON u.usuario_id = m.usuario_id 
WHERE m.estado = 'Activa' AND m.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);

-- 20. Usuarios nuevos este mes
SELECT * FROM usuarios 
WHERE MONTH(creado_en) = MONTH(CURDATE()) AND YEAR(creado_en) = YEAR(CURDATE());

-- 21. Pagos por empresa
SELECT e.nombre, SUM(p.monto) as total_pagado 
FROM empresas e JOIN usuarios u ON e.empresa_id = u.empresa_id 
JOIN pagos p ON u.usuario_id = p.usuario_id 
WHERE p.estado = 'Pagado' GROUP BY e.empresa_id;

-- 22. Reservas canceladas
SELECT r.*, u.nombre, u.apellido FROM reservas r 
JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Cancelada';

-- 23. Accesos denegados
SELECT u.nombre, u.apellido, ra.razon, ra.fecha_acceso 
FROM registros_acceso ra JOIN usuarios u ON ra.usuario_id = u.usuario_id 
WHERE ra.evento = 'DENEGADO';

-- 24. Uso de espacios por capacidad
SELECT e.nombre, e.capacidad, COUNT(r.reserva_id) as reservas 
FROM espacios e LEFT JOIN reservas r ON e.espacio_id = r.espacio_id 
AND r.estado = 'Confirmada' GROUP BY e.espacio_id;

-- 25. Facturas por tipo
SELECT tipo, COUNT(*) as cantidad, SUM(monto) as total 
FROM facturas GROUP BY tipo;

-- 26. Usuarios sin reservas
SELECT u.* FROM usuarios u 
LEFT JOIN reservas r ON u.usuario_id = r.usuario_id 
WHERE r.reserva_id IS NULL;

-- 27. Servicios por reserva
SELECT r.reserva_id, COUNT(sr.servicio_id) as cantidad_servicios 
FROM reservas r JOIN servicios_reserva sr ON r.reserva_id = sr.reserva_id 
GROUP BY r.reserva_id;

-- 28. Facturas con pagos parciales
SELECT f.*, SUM(p.monto) as pagado, (f.monto - SUM(p.monto)) as pendiente 
FROM facturas f JOIN pagos p ON f.factura_id = p.factura_id 
WHERE f.estado = 'Parcial' GROUP BY f.factura_id;

-- 29. Membresías por estado
SELECT estado, COUNT(*) as cantidad FROM membresias GROUP BY estado;

-- 30. Reservas por estado
SELECT estado, COUNT(*) as cantidad FROM reservas GROUP BY estado;

-- 31. Usuarios por grupo etario
SELECT CASE 
    WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE()) < 25 THEN 'Menos de 25'
    WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE()) BETWEEN 25 AND 35 THEN '25-35'
    WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
    ELSE 'Más de 45'
END as grupo_edad, COUNT(*) as cantidad
FROM usuarios WHERE fecha_nacimiento IS NOT NULL GROUP BY grupo_edad;

-- 32. Frecuencia de uso por usuario
SELECT u.usuario_id, u.nombre, u.apellido, 
COUNT(ra.acceso_id) as dias_con_acceso 
FROM usuarios u JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id 
WHERE ra.evento = 'ENTRADA' GROUP BY u.usuario_id;

-- 33. Espacios por tipo y capacidad
SELECT te.nombre, AVG(e.capacidad) as capacidad_promedio 
FROM espacios e JOIN tipos_espacio te ON e.tipo_espacio_id = te.tipo_espacio_id 
GROUP BY te.tipo_espacio_id;

-- 34. Crecimiento de usuarios por mes
SELECT YEAR(creado_en) as año, MONTH(creado_en) as mes, COUNT(*) as nuevos_usuarios 
FROM usuarios GROUP BY YEAR(creado_en), MONTH(creado_en);

-- 35. Reservas de más de 4 horas
SELECT r.*, u.nombre, u.apellido, TIMESTAMPDIFF(HOUR, r.inicio, r.fin) as horas 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE TIMESTAMPDIFF(HOUR, r.inicio, r.fin) > 4 AND r.estado = 'Confirmada';

-- 36. Pagos atrasados
SELECT f.*, u.nombre, u.apellido, DATEDIFF(CURDATE(), f.creado_en) as dias_atraso 
FROM facturas f JOIN usuarios u ON f.usuario_id = u.usuario_id 
WHERE f.estado = 'Pendiente' AND DATEDIFF(CURDATE(), f.creado_en) > 15;

-- 37. Horas ocupadas por espacio
SELECT e.nombre, SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as horas_ocupadas 
FROM espacios e JOIN reservas r ON e.espacio_id = r.espacio_id 
WHERE r.estado = 'Confirmada' GROUP BY e.espacio_id;

-- 38. Facturación mensual por tipo
SELECT YEAR(creado_en) as año, MONTH(creado_en) as mes, tipo, SUM(monto) as total 
FROM facturas WHERE estado = 'Pagada' GROUP BY YEAR(creado_en), MONTH(creado_en), tipo;

-- 39. Ratio de ocupación
SELECT e.nombre, 
(SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) / (30 * 10)) * 100 as porcentaje_ocupacion 
FROM espacios e JOIN reservas r ON e.espacio_id = r.espacio_id 
WHERE r.estado = 'Confirmada' AND r.inicio >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
GROUP BY e.espacio_id;

-- 40. Usuarios con membresía corporativa
SELECT u.*, e.nombre as empresa 
FROM usuarios u JOIN membresias m ON u.usuario_id = m.usuario_id 
JOIN tipos_membresia tm ON m.tipo_membresia_id = tm.tipo_membresia_id 
JOIN empresas e ON u.empresa_id = e.empresa_id 
WHERE tm.nombre = 'Corporativa' AND m.estado = 'Activa';

-- 41. Reservas recurrentes
SELECT u.usuario_id, u.nombre, u.apellido, COUNT(r.reserva_id) as reservas 
FROM usuarios u JOIN reservas r ON u.usuario_id = r.usuario_id 
GROUP BY u.usuario_id HAVING COUNT(r.reserva_id) > 5;

-- 42. Ingresos por servicios adicionales
SELECT s.nombre, SUM(s.precio) as ingresos 
FROM servicios s JOIN servicios_reserva sr ON s.servicio_id = sr.servicio_id 
JOIN reservas r ON sr.reserva_id = r.reserva_id 
WHERE r.estado = 'Confirmada' GROUP BY s.servicio_id;

-- 43. Tendencia de uso mensual
SELECT YEAR(r.inicio) as año, MONTH(r.inicio) as mes, COUNT(r.reserva_id) as reservas 
FROM reservas r WHERE r.estado = 'Confirmada' 
GROUP BY YEAR(r.inicio), MONTH(r.inicio) ORDER BY año, mes;

-- 44. Usuarios con acceso hoy
SELECT u.* FROM usuarios u 
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id 
WHERE DATE(ra.fecha_acceso) = CURDATE() AND ra.evento = 'ENTRADA';

-- 45. Reservas para mañana
SELECT r.*, u.nombre, u.apellido, e.nombre as espacio 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
JOIN espacios e ON r.espacio_id = e.espacio_id 
WHERE DATE(r.inicio) = DATE_ADD(CURDATE(), INTERVAL 1 DAY) AND r.estado = 'Confirmada';

-- 46. Facturas vencidas
SELECT f.*, u.nombre, u.apellido 
FROM facturas f JOIN usuarios u ON f.usuario_id = u.usuario_id 
WHERE f.estado = 'Pendiente' AND f.creado_en < DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- 47. Espacios favoritos por usuario
SELECT u.usuario_id, u.nombre, u.apellido, e.nombre as espacio_favorito, COUNT(r.reserva_id) as veces 
FROM usuarios u JOIN reservas r ON u.usuario_id = r.usuario_id 
JOIN espacios e ON r.espacio_id = e.espacio_id 
WHERE r.estado = 'Confirmada' 
GROUP BY u.usuario_id, e.espacio_id ORDER BY u.usuario_id, veces DESC;

-- 48. Horas pico por espacio
SELECT e.nombre, HOUR(r.inicio) as hora, COUNT(r.reserva_id) as reservas 
FROM reservas r JOIN espacios e ON r.espacio_id = e.espacio_id 
WHERE r.estado = 'Confirmada' 
GROUP BY e.espacio_id, HOUR(r.inicio) ORDER BY e.nombre, reservas DESC;

-- 49. Membresías por duración
SELECT tm.nombre, AVG(DATEDIFF(m.fecha_fin, m.fecha_inicio)) as duracion_promedio 
FROM membresias m JOIN tipos_membresia tm ON m.tipo_membresia_id = tm.tipo_membresia_id 
GROUP BY tm.tipo_membresia_id;

-- 50. Usuarios inactivos
SELECT u.* FROM usuarios u 
WHERE u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id FROM registros_acceso 
    WHERE fecha_acceso > DATE_SUB(CURDATE(), INTERVAL 30 DAY)
);

-- 51. Reservas con check-in
SELECT r.*, u.nombre, u.apellido 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Confirmada' AND EXISTS (
    SELECT 1 FROM registros_acceso ra 
    WHERE ra.usuario_id = r.usuario_id 
    AND ra.fecha_acceso BETWEEN r.inicio AND r.fin 
    AND ra.evento = 'ENTRADA'
);

-- 52. Reservas sin check-in (no-show)
SELECT r.*, u.nombre, u.apellido 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Confirmada' AND NOT EXISTS (
    SELECT 1 FROM registros_acceso ra 
    WHERE ra.usuario_id = r.usuario_id 
    AND ra.fecha_acceso BETWEEN r.inicio AND r.fin 
    AND ra.evento = 'ENTRADA'
);

-- 53. Uso de espacios los fines de semana
SELECT e.nombre, COUNT(r.reserva_id) as reservas_finde 
FROM espacios e JOIN reservas r ON e.espacio_id = r.espacio_id 
WHERE r.estado = 'Confirmada' AND DAYOFWEEK(r.inicio) IN (1,7) 
GROUP BY e.espacio_id;

-- 54. Cambios de membresía
SELECT u.nombre, u.apellido, COUNT(lam.id) as cambios 
FROM usuarios u JOIN membresias m ON u.usuario_id = m.usuario_id 
JOIN log_auditoria_membresia lam ON m.membresia_id = lam.membresia_id 
GROUP BY u.usuario_id;

-- 55. Reservas de última hora
SELECT r.*, u.nombre, u.apellido 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Confirmada' AND TIMESTAMPDIFF(HOUR, r.creado_en, r.inicio) < 2;

-- 56. Patrones de uso por día de semana
SELECT DAYNAME(r.inicio) as dia_semana, COUNT(r.reserva_id) as reservas 
FROM reservas r WHERE r.estado = 'Confirmada' 
GROUP BY DAYNAME(r.inicio) ORDER BY reservas DESC;

-- 57. Usuarios con múltiples reservas mismo día
SELECT u.usuario_id, u.nombre, u.apellido, DATE(r.inicio) as fecha, COUNT(r.reserva_id) as reservas 
FROM usuarios u JOIN reservas r ON u.usuario_id = r.usuario_id 
WHERE r.estado = 'Confirmada' 
GROUP BY u.usuario_id, DATE(r.inicio) HAVING COUNT(r.reserva_id) > 1;

-- 58. Facturas con descuento
SELECT f.*, u.nombre, u.apellido 
FROM facturas f JOIN usuarios u ON f.usuario_id = u.usuario_id 
WHERE f.monto < 0;

-- 59. Espacios por precio promedio
SELECT e.nombre, AVG(f.monto) as precio_promedio 
FROM espacios e JOIN reservas r ON e.espacio_id = r.espacio_id 
JOIN facturas f ON r.usuario_id = f.usuario_id AND f.tipo = 'Reserva' 
WHERE f.estado = 'Pagada' GROUP BY e.espacio_id;

-- 60. Reservas con máxima duración
SELECT r.*, u.nombre, u.apellido, TIMESTAMPDIFF(HOUR, r.inicio, r.fin) as horas 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Confirmada' 
ORDER BY TIMESTAMPDIFF(HOUR, r.inicio, r.fin) DESC LIMIT 10;

-- 61. Usuarios con mayor frecuencia
SELECT u.usuario_id, u.nombre, u.apellido, 
COUNT(DISTINCT DATE(ra.fecha_acceso)) as dias_con_acceso 
FROM usuarios u JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id 
WHERE ra.evento = 'ENTRADA' 
GROUP BY u.usuario_id ORDER BY dias_con_acceso DESC LIMIT 10;

-- 62. Servicios combinados
SELECT s1.nombre as servicio1, s2.nombre as servicio2, COUNT(*) as veces_juntos 
FROM servicios_reserva sr1 JOIN servicios_reserva sr2 
ON sr1.reserva_id = sr2.reserva_id AND sr1.servicio_id < sr2.servicio_id 
JOIN servicios s1 ON sr1.servicio_id = s1.servicio_id 
JOIN servicios s2 ON sr2.servicio_id = s2.servicio_id 
GROUP BY s1.servicio_id, s2.servicio_id ORDER BY veces_juntos DESC LIMIT 10;

-- 63. Crecimiento de reservas
SELECT YEAR(inicio) as año, MONTH(inicio) as mes, COUNT(*) as reservas
FROM reservas WHERE estado = 'Confirmada' 
GROUP BY YEAR(inicio), MONTH(inicio);

-- 64. Usuarios por antigüedad
SELECT usuario_id, nombre, apellido, creado_en, 
DATEDIFF(CURDATE(), creado_en) as dias_desde_registro 
FROM usuarios ORDER BY creado_en;

-- 65. Reservas por franja horaria
SELECT CASE 
    WHEN HOUR(inicio) BETWEEN 6 AND 11 THEN 'Mañana'
    WHEN HOUR(inicio) BETWEEN 12 AND 17 THEN 'Tarde'
    ELSE 'Noche'
END as franja_horaria, COUNT(*) as reservas 
FROM reservas WHERE estado = 'Confirmada' GROUP BY franja_horaria;

-- 66. Facturas pagadas en efectivo
SELECT f.*, u.nombre, u.apellido 
FROM facturas f JOIN usuarios u ON f.usuario_id = u.usuario_id 
JOIN pagos p ON f.factura_id = p.factura_id 
WHERE p.metodo = 'Efectivo' AND p.estado = 'Pagado';

-- 67. Usuarios con mayor variedad de servicios
SELECT u.usuario_id, u.nombre, u.apellido, COUNT(DISTINCT sr.servicio_id) as servicios_diferentes 
FROM usuarios u JOIN reservas r ON u.usuario_id = r.usuario_id 
JOIN servicios_reserva sr ON r.reserva_id = sr.reserva_id 
WHERE r.estado = 'Confirmada' GROUP BY u.usuario_id ORDER BY servicios_diferentes DESC LIMIT 10;

-- 68. Reservas con máxima anticipación
SELECT r.*, u.nombre, u.apellido, 
DATEDIFF(r.inicio, r.creado_en) as dias_anticipacion 
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
WHERE r.estado = 'Confirmada' ORDER BY dias_anticipacion DESC LIMIT 10;

-- 69. Facturas por rango de monto
SELECT CASE 
    WHEN monto < 50 THEN 'Menos de 50'
    WHEN monto BETWEEN 50 AND 100 THEN '50-100'
    WHEN monto BETWEEN 101 AND 200 THEN '101-200'
    ELSE 'Más de 200'
END as rango_monto, COUNT(*) as cantidad_facturas 
FROM facturas GROUP BY rango_monto;

-- 70. Uso de aplicaciones móviles (accesos con QR)
SELECT DATE(fecha_acceso) as fecha, COUNT(*) as accesos_qr 
FROM registros_acceso 
WHERE razon LIKE '%QR%' GROUP BY DATE(fecha_acceso);

-- 71. Tendencia de cancelaciones
SELECT YEAR(creado_en) as año, MONTH(creado_en) as mes, 
COUNT(*) as total_reservas,
SUM(CASE WHEN estado = 'Cancelada' THEN 1 ELSE 0 END) as cancelaciones,
(SUM(CASE WHEN estado = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*)) * 100 as tasa_cancelacion
FROM reservas GROUP BY YEAR(creado_en), MONTH(creado_en);

-- 72. Usuarios con reservas en múltiples espacios
SELECT u.usuario_id, u.nombre, u.apellido, COUNT(DISTINCT r.espacio_id) as espacios_diferentes 
FROM usuarios u JOIN reservas r ON u.usuario_id = r.usuario_id 
WHERE r.estado = 'Confirmada' GROUP BY u.usuario_id HAVING COUNT(DISTINCT r.espacio_id) > 1;

-- 73. Facturas con IVA
SELECT f.*, u.nombre, u.apellido, 
f.monto as subtotal, f.monto * 0.16 as iva, f.monto * 1.16 as total 
FROM facturas f JOIN usuarios u ON f.usuario_id = u.usuario_id;

-- 74. Reservas con preparación anticipada
SELECT r.*, e.nombre as espacio, 
TIMESTAMPDIFF(MINUTE, r.inicio, ra.fecha_acceso) as minutos_anticipacion 
FROM reservas r JOIN espacios e ON r.espacio_id = e.espacio_id 
JOIN registros_acceso ra ON r.usuario_id = ra.usuario_id 
AND ra.evento = 'ENTRADA' AND ra.fecha_acceso BETWEEN DATE_SUB(r.inicio, INTERVAL 1 HOUR) AND r.inicio 
WHERE r.estado = 'Confirmada';

-- 75. Espacios por rentabilidad
SELECT e.nombre, 
SUM(f.monto) as ingresos_totales, 
SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as horas_alquiladas,
SUM(f.monto) / SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as rentabilidad_por_hora
FROM espacios e JOIN reservas r ON e.espacio_id = r.espacio_id 
JOIN facturas f ON r.usuario_id = f.usuario_id AND f.tipo = 'Reserva'
WHERE r.estado = 'Confirmada' AND f.estado = 'Pagada'
GROUP BY e.espacio_id ORDER BY rentabilidad_por_hora DESC;

-- 76. Patrones de uso por temporada
SELECT CASE 
    WHEN MONTH(inicio) IN (12,1,2) THEN 'Invierno'
    WHEN MONTH(inicio) IN (3,4,5) THEN 'Primavera'
    WHEN MONTH(inicio) IN (6,7,8) THEN 'Verano'
    ELSE 'Otoño'
END as temporada, COUNT(*) as reservas 
FROM reservas WHERE estado = 'Confirmada' GROUP BY temporada;

-- 77. Usuarios con membresías consecutivas
SELECT u.usuario_id, u.nombre, u.apellido, 
COUNT(m.membresia_id) as membresias, 
MIN(m.fecha_inicio) as primera_membresia,
MAX(m.fecha_fin) as ultima_membresia
FROM usuarios u JOIN membresias m ON u.usuario_id = m.usuario_id 
GROUP BY u.usuario_id HAVING COUNT(m.membresia_id) > 1;

-- 78. Reservas con overlap
SELECT r1.reserva_id as reserva1, r2.reserva_id as reserva2, 
r1.espacio_id, r1.inicio as inicio1, r1.fin as fin1,
r2.inicio as inicio2, r2.fin as fin2
FROM reservas r1 JOIN reservas r2 
ON r1.espacio_id = r2.espacio_id 
AND r1.reserva_id < r2.reserva_id
AND r1.inicio < r2.fin AND r1.fin > r2.inicio
WHERE r1.estado = 'Confirmada' AND r2.estado = 'Confirmada';

-- 79. Tiempo promedio de uso diario
SELECT u.usuario_id, u.nombre, u.apellido, 
AVG(TIMESTAMPDIFF(HOUR, ra1.fecha_acceso, ra2.fecha_acceso)) as horas_promedio_diarias 
FROM usuarios u JOIN registros_acceso ra1 ON u.usuario_id = ra1.usuario_id 
JOIN registros_acceso ra2 ON u.usuario_id = ra2.usuario_id 
AND DATE(ra1.fecha_acceso) = DATE(ra2.fecha_acceso)
AND ra1.evento = 'ENTRADA' AND ra2.evento = 'SALIDA'
AND ra1.fecha_acceso < ra2.fecha_acceso
GROUP BY u.usuario_id;

-- 80. Facturas con pagos múltiples
SELECT f.factura_id, f.monto, COUNT(p.pago_id) as cantidad_pagos, 
SUM(p.monto) as total_pagado 
FROM facturas f JOIN pagos p ON f.factura_id = p.factura_id 
GROUP BY f.factura_id HAVING COUNT(p.pago_id) > 1;

-- 81. Reservas de mismo usuario consecutivas
SELECT r1.usuario_id, r1.espacio_id, r1.fin as fin_reserva1, 
r2.inicio as inicio_reserva2, TIMESTAMPDIFF(MINUTE, r1.fin, r2.inicio) as minutos_entre_reservas
FROM reservas r1 JOIN reservas r2 
ON r1.usuario_id = r2.usuario_id 
AND r1.reserva_id < r2.reserva_id
AND r2.inicio BETWEEN r1.fin AND DATE_ADD(r1.fin, INTERVAL 1 HOUR)
WHERE r1.estado = 'Confirmada' AND r2.estado = 'Confirmada';

-- 82. Espacios por disponibilidad
SELECT e.nombre, 
COUNT(r.reserva_id) as reservas,
(24*30 - COALESCE(SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)), 0)) as horas_disponibles_mes
FROM espacios e LEFT JOIN reservas r ON e.espacio_id = r.espacio_id 
AND r.estado = 'Confirmada' AND r.inicio >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY e.espacio_id;

-- 83. Usuarios por frecuencia de pago
SELECT u.usuario_id, u.nombre, u.apellido, 
COUNT(p.pago_id) as pagos, 
AVG(DATEDIFF(p.pagado_en, f.creado_en)) as dias_promedio_pago
FROM usuarios u JOIN facturas f ON u.usuario_id = f.usuario_id 
JOIN pagos p ON f.factura_id = p.factura_id 
WHERE p.estado = 'Pagado' GROUP BY u.usuario_id;

-- 84. Reservas con servicios premium
SELECT r.*, u.nombre, u.apellido, 
GROUP_CONCAT(s.nombre) as servicios_premium,
SUM(s.precio) as costo_servicios
FROM reservas r JOIN usuarios u ON r.usuario_id = u.usuario_id 
JOIN servicios_reserva sr ON r.reserva_id = sr.reserva_id 
JOIN servicios s ON sr.servicio_id = s.servicio_id 
WHERE s.precio > 10 AND r.estado = 'Confirmada'
GROUP BY r.reserva_id;

-- 85. Facturación acumulada
SELECT fecha, SUM(ingresos) OVER (ORDER BY fecha) as ingresos_acumulados
FROM (
    SELECT DATE(pagado_en) as fecha, SUM(monto) as ingresos
    FROM pagos WHERE estado = 'Pagado'
    GROUP BY DATE(pagado_en)
) daily_income;

-- 86. Uso de espacios por tamaño empresa
SELECT e.nombre, 
CASE 
    WHEN COUNT(DISTINCT u.usuario_id) = 1 THEN 'Individual'
    WHEN COUNT(DISTINCT u.usuario_id) BETWEEN 2 AND 5 THEN 'Pequeña'
    WHEN COUNT(DISTINCT u.usuario_id) BETWEEN 6 AND 15 THEN 'Mediana'
    ELSE 'Grande'
END as tamaño_empresa,
COUNT(r.reserva_id) as reservas
FROM empresas e 
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado = 'Confirmada'
GROUP BY e.empresa_id;

-- 87. Reservas con mayor valor
SELECT r.*, u.nombre, u.apellido, f.monto as valor_reserva
FROM reservas r 
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN facturas f ON r.usuario_id = f.usuario_id AND f.tipo = 'Reserva'
WHERE r.estado = 'Confirmada' AND f.estado = 'Pagada'
ORDER BY f.monto DESC LIMIT 10;

-- 88. Tiempo entre reserva y uso
SELECT r.reserva_id, u.nombre, u.apellido,
TIMESTAMPDIFF(MINUTE, r.creado_en, r.inicio) as minutos_entre_reserva_y_uso,
TIMESTAMPDIFF(MINUTE, r.inicio, ra.fecha_acceso) as minutos_anticipacion_llegada
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN registros_acceso ra ON r.usuario_id = ra.usuario_id 
AND ra.evento = 'ENTRADA' AND ra.fecha_acceso BETWEEN r.inicio AND r.fin
WHERE r.estado = 'Confirmada';

-- 89. Servicios por temporada
SELECT s.nombre,
CASE 
    WHEN MONTH(r.inicio) IN (12,1,2) THEN 'Invierno'
    WHEN MONTH(r.inicio) IN (3,4,5) THEN 'Primavera'
    WHEN MONTH(r.inicio) IN (6,7,8) THEN 'Verano'
    ELSE 'Otoño'
END as temporada,
COUNT(sr.id) as veces_solicitado
FROM servicios s
JOIN servicios_reserva sr ON s.servicio_id = sr.servicio_id
JOIN reservas r ON sr.reserva_id = r.reserva_id
WHERE r.estado = 'Confirmada'
GROUP BY s.servicio_id, temporada;

-- 90. Usuarios por tipo de membresía y empresa
SELECT tm.nombre as tipo_membresia, e.nombre as empresa, COUNT(u.usuario_id) as cantidad_usuarios
FROM usuarios u
JOIN membresias m ON u.usuario_id = m.usuario_id
JOIN tipos_membresia tm ON m.tipo_membresia_id = tm.tipo_membresia_id
LEFT JOIN empresas e ON u.empresa_id = e.empresa_id
WHERE m.estado = 'Activa'
GROUP BY tm.tipo_membresia_id, e.empresa_id;

-- 91. Facturas por estado y tipo
SELECT estado, tipo, COUNT(*) as cantidad, SUM(monto) as total
FROM facturas
GROUP BY estado, tipo;

-- 92. Reservas por hora del día
SELECT HOUR(inicio) as hora, COUNT(*) as reservas
FROM reservas
WHERE estado = 'Confirmada'
GROUP BY HOUR(inicio)
ORDER BY hora;

-- 93. Usuarios con mayor tiempo de uso
SELECT u.usuario_id, u.nombre, u.apellido, 
SUM(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as horas_totales_uso
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado = 'Confirmada'
GROUP BY u.usuario_id
ORDER BY horas_totales_uso DESC LIMIT 10;

-- 94. Espacios con mayor ocupación en horas pico
SELECT e.nombre, HOUR(r.inicio) as hora, COUNT(r.reserva_id) as reservas
FROM espacios e
JOIN reservas r ON e.espacio_id = r.espacio_id
WHERE r.estado = 'Confirmada' AND HOUR(r.inicio) BETWEEN 9 AND 11
GROUP BY e.espacio_id, HOUR(r.inicio)
ORDER BY reservas DESC;

-- 95. Métodos de pago preferidos por usuario
SELECT u.usuario_id, u.nombre, u.apellido, p.metodo, COUNT(p.pago_id) as veces_utilizado
FROM usuarios u
JOIN pagos p ON u.usuario_id = p.usuario_id
WHERE p.estado = 'Pagado'
GROUP BY u.usuario_id, p.metodo
ORDER BY u.usuario_id, veces_utilizado DESC;

-- 96. Facturas por mes de vencimiento
SELECT YEAR(DATE_ADD(creado_en, INTERVAL 30 DAY)) as año_vencimiento,
MONTH(DATE_ADD(creado_en, INTERVAL 30 DAY)) as mes_vencimiento,
COUNT(*) as facturas, SUM(monto) as total
FROM facturas
WHERE estado = 'Pendiente'
GROUP BY año_vencimiento, mes_vencimiento;

-- 97. Reservas con servicios incluidos
SELECT r.reserva_id, u.nombre, u.apellido, e.nombre as espacio,
COUNT(sr.servicio_id) as cantidad_servicios, SUM(s.precio) as costo_servicios
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
JOIN servicios_reserva sr ON r.reserva_id = sr.reserva_id
JOIN servicios s ON sr.servicio_id = s.servicio_id
WHERE r.estado = 'Confirmada'
GROUP BY r.reserva_id;

-- 98. Evolución de precios de servicios
SELECT s.nombre, 
MIN(s.precio) as precio_minimo, 
MAX(s.precio) as precio_maximo,
AVG(s.precio) as precio_promedio
FROM servicios s
GROUP BY s.servicio_id;

-- 99. Usuarios con patrones de uso consistentes
SELECT u.usuario_id, u.nombre, u.apellido,
COUNT(DISTINCT DAYOFWEEK(r.inicio)) as dias_semana_diferentes,
AVG(TIMESTAMPDIFF(HOUR, r.inicio, r.fin)) as duracion_promedio
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado = 'Confirmada'
GROUP BY u.usuario_id
HAVING COUNT(r.reserva_id) > 10;

-- 100. Resumen ejecutivo
SELECT 
(SELECT COUNT(*) FROM usuarios) as total_usuarios,
(SELECT COUNT(*) FROM empresas) as total_empresas,
(SELECT COUNT(*) FROM reservas WHERE estado = 'Confirmada') as reservas_confirmadas,
(SELECT SUM(monto) FROM pagos WHERE estado = 'Pagado') as ingresos_totales,
(SELECT COUNT(*) FROM registros_acceso WHERE evento = 'ENTRADA') as total_accesos;




