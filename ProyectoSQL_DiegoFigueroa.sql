CREATE DATABASE IF NOT EXISTS gestion_coworking;
USE gestion_coworking;

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================
DROP TABLE IF EXISTS empresas;
CREATE TABLE empresas (
  empresa_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL
);

DROP TABLE IF EXISTS usuarios;
CREATE TABLE usuarios (
  usuario_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100),
  apellido VARCHAR(100),
  fecha_nacimiento DATE,
  email VARCHAR(200),
  empresa_id INT,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ultimo_acceso TIMESTAMP NULL,
  FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id) ON DELETE SET NULL
);

DROP TABLE IF EXISTS tipos_membresia;
CREATE TABLE tipos_membresia (
  tipo_membresia_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

DROP TABLE IF EXISTS membresias;
CREATE TABLE membresias (
  membresia_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  tipo_membresia_id INT NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  estado ENUM('Activa','Suspendida','Vencida') NOT NULL DEFAULT 'Activa',
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  FOREIGN KEY (tipo_membresia_id) REFERENCES tipos_membresia(tipo_membresia_id)
);

DROP TABLE IF EXISTS renovaciones_membresia;
CREATE TABLE renovaciones_membresia (
  renovacion_id INT AUTO_INCREMENT PRIMARY KEY,
  membresia_id INT NOT NULL,
  renovado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (membresia_id) REFERENCES membresias(membresia_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS tipos_espacio;
CREATE TABLE tipos_espacio (
  tipo_espacio_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

DROP TABLE IF EXISTS espacios;
CREATE TABLE espacios (
  espacio_id INT AUTO_INCREMENT PRIMARY KEY,
  tipo_espacio_id INT,
  nombre VARCHAR(200),
  capacidad INT DEFAULT 1,
  FOREIGN KEY (tipo_espacio_id) REFERENCES tipos_espacio(tipo_espacio_id)
);

DROP TABLE IF EXISTS reservas;
CREATE TABLE reservas (
  reserva_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  empresa_id INT NULL,
  espacio_id INT NOT NULL,
  inicio DATETIME NOT NULL,
  fin DATETIME NOT NULL,
  estado ENUM('Pendiente','Confirmada','Cancelada','NoAsistio') NOT NULL DEFAULT 'Pendiente',
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
  FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
  FOREIGN KEY (espacio_id) REFERENCES espacios(espacio_id)
);

DROP TABLE IF EXISTS servicios;
CREATE TABLE servicios (
  servicio_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150),
  precio DECIMAL(12,2) DEFAULT 0
);

DROP TABLE IF EXISTS servicios_reserva;
CREATE TABLE servicios_reserva (
  id INT AUTO_INCREMENT PRIMARY KEY,
  reserva_id INT,
  servicio_id INT,
  FOREIGN KEY (reserva_id) REFERENCES reservas(reserva_id) ON DELETE CASCADE,
  FOREIGN KEY (servicio_id) REFERENCES servicios(servicio_id)
);

DROP TABLE IF EXISTS facturas;
CREATE TABLE facturas (
  factura_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  empresa_id INT,
  monto DECIMAL(12,2) NOT NULL,
  tipo ENUM('Membresia','Reserva','Servicio','Penalizacion') NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Pagada','Pendiente','Anulada','Parcial') NOT NULL DEFAULT 'Pendiente',
  descripcion TEXT,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
  FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id)
);

DROP TABLE IF EXISTS pagos;
CREATE TABLE pagos (
  pago_id INT AUTO_INCREMENT PRIMARY KEY,
  factura_id INT,
  usuario_id INT,
  monto DECIMAL(12,2) NOT NULL,
  metodo ENUM('Efectivo','Tarjeta','Transferencia','PayPal') DEFAULT 'Efectivo',
  estado ENUM('Pagado','Pendiente','Cancelado') DEFAULT 'Pagado',
  pagado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (factura_id) REFERENCES facturas(factura_id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

DROP TABLE IF EXISTS registros_acceso;
CREATE TABLE registros_acceso (
  acceso_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  fecha_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  evento ENUM('ENTRADA','SALIDA','DENEGADO') NOT NULL,
  razon VARCHAR(255),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

DROP TABLE IF EXISTS bloqueos_servicio;
CREATE TABLE bloqueos_servicio (
  usuario_id INT PRIMARY KEY,
  bloqueado_desde TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  razon VARCHAR(255),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS log_auditoria_membresia;
CREATE TABLE log_auditoria_membresia (
  id INT AUTO_INCREMENT PRIMARY KEY,
  membresia_id INT,
  tipo_anterior INT,
  tipo_nuevo INT,
  cambiado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  cambiado_por VARCHAR(100)
);

DROP TABLE IF EXISTS notificaciones;
CREATE TABLE notificaciones (
  notificacion_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  mensaje TEXT,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

DROP TABLE IF EXISTS reportes_administrador;
CREATE TABLE reportes_administrador (
  reporte_id INT AUTO_INCREMENT PRIMARY KEY,
  tipo_reporte VARCHAR(100),
  contenido TEXT,
  generado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS alertas_recepcion;
CREATE TABLE alertas_recepcion (
  alerta_id INT AUTO_INCREMENT PRIMARY KEY,
  mensaje TEXT,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS resumenes_facturacion;
CREATE TABLE resumenes_facturacion (
  resumen_id INT AUTO_INCREMENT PRIMARY KEY,
  mes_anio VARCHAR(7),
  ingreso_total DECIMAL(14,2),
  ingreso_membresias DECIMAL(14,2),
  ingreso_reservas DECIMAL(14,2),
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS reportes_contabilidad;
CREATE TABLE reportes_contabilidad (
  reporte_id INT AUTO_INCREMENT PRIMARY KEY,
  tipo_reporte VARCHAR(100),
  contenido TEXT,
  generado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS alertas_administrador;
CREATE TABLE alertas_administrador (
  alerta_id INT AUTO_INCREMENT PRIMARY KEY,
  mensaje TEXT,
  severidad ENUM('BAJA','MEDIA','ALTA'),
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS accesos_denegados;
CREATE TABLE accesos_denegados (
  acceso_denegado_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  fecha_intento TIMESTAMP,
  razon VARCHAR(255),
  metodo VARCHAR(50),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

-- ============================================
-- INSERTS PARA CADA TABLA
-- ============================================

--- 1. Empresas (5 registros)
INSERT INTO empresas (nombre) VALUES
('Tech Solutions Inc.'),
('Innovate Labs'),
('Digital Creations'),
('Cloud Services Ltd.'),
('Data Analytics Corp'),
('StartUp Ventures'), -- Nueva empresa para más diversidad
('Global Tech Hub'),  -- Nueva empresa
('Future Systems');   -- Nueva empresa

-- 2. Usuarios (60 registros con distribución más equilibrada)
INSERT INTO usuarios (nombre, apellido, fecha_nacimiento, email, empresa_id) VALUES
-- Usuarios para Tech Solutions Inc. (10)
('Carlos', 'Gomez', '1990-05-12', 'carlos.gomez@email.com', 1),
('Maria', 'Lopez', '1985-08-23', 'maria.lopez@email.com', 1),
('Juan', 'Martinez', '1992-11-15', 'juan.martinez@email.com', 1),
('Ana', 'Rodriguez', '1988-03-07', 'ana.rodriguez@email.com', 1),
('Pedro', 'Hernandez', '1991-07-19', 'pedro.hernandez@email.com', 1),
('Laura', 'Garcia', '1987-12-30', 'laura.garcia@email.com', 1),
('Diego', 'Perez', '1993-02-14', 'diego.perez@email.com', 1),
('Sofia', 'Sanchez', '1989-06-25', 'sofia.sanchez@email.com', 1),
('Miguel', 'Ramirez', '1994-09-08', 'miguel.ramirez@email.com', 1),
('Elena', 'Torres', '1986-01-17', 'elena.torres@email.com', 1),

-- Usuarios para Innovate Labs (10)
('Ricardo', 'Diaz', '1995-04-03', 'ricardo.diaz@email.com', 2),
('Carmen', 'Vargas', '1990-10-21', 'carmen.vargas@email.com', 2),
('Jorge', 'Moreno', '1988-08-12', 'jorge.moreno@email.com', 2),
('Isabel', 'Rojas', '1992-12-05', 'isabel.rojas@email.com', 2),
('Fernando', 'Castro', '1987-05-28', 'fernando.castro@email.com', 2),
('Patricia', 'Ortiz', '1993-03-16', 'patricia.ortiz@email.com', 2),
('Roberto', 'Silva', '1989-07-22', 'roberto.silva@email.com', 2),
('Gabriela', 'Mendoza', '1991-11-09', 'gabriela.mendoza@email.com', 2),
('Daniel', 'Guerrero', '1994-02-27', 'daniel.guerrero@email.com', 2),
('Lucia', 'Navarro', '1986-06-14', 'lucia.navarro@email.com', 2),

-- Usuarios para Digital Creations (10)
('Alejandro', 'Ruiz', '1990-09-03', 'alejandro.ruiz@email.com', 3),
('Veronica', 'Peña', '1985-01-25', 'veronica.pena@email.com', 3),
('Oscar', 'Rios', '1992-04-18', 'oscar.rios@email.com', 3),
('Teresa', 'Mendez', '1988-08-07', 'teresa.mendez@email.com', 3),
('Hector', 'Delgado', '1993-12-11', 'hector.delgado@email.com', 3),
('Silvia', 'Cordoba', '1987-03-29', 'silvia.cordoba@email.com', 3),
('Rafael', 'Herrera', '1991-07-02', 'rafael.herrera@email.com', 3),
('Monica', 'Paredes', '1994-10-15', 'monica.paredes@email.com', 3),
('Francisco', 'Campos', '1989-05-20', 'francisco.campos@email.com', 3),
('Rosa', 'Santana', '1986-02-08', 'rosa.santana@email.com', 3),

-- Usuarios para Cloud Services Ltd. (10)
('Alberto', 'Bravo', '1990-06-23', 'alberto.bravo@email.com', 4),
('Beatriz', 'Franco', '1985-11-16', 'beatriz.franco@email.com', 4),
('Manuel', 'Gallego', '1992-03-09', 'manuel.gallego@email.com', 4),
('Eva', 'León', '1988-07-31', 'eva.leon@email.com', 4),
('Sergio', 'Marin', '1993-01-24', 'sergio.marin@email.com', 4),
('Olga', 'Ponce', '1987-04-17', 'olga.ponce@email.com', 4),
('Victor', 'Reyes', '1991-08-10', 'victor.reyes@email.com', 4),
('Alicia', 'Cruz', '1994-12-03', 'alicia.cruz@email.com', 4),
('Jorge', 'Soto', '1989-09-26', 'jorge.soto@email.com', 4),
('Adriana', 'Guzman', '1986-05-19', 'adriana.guzman@email.com', 4),

-- Usuarios para Data Analytics Corp (10)
('Gabriel', 'Rueda', '1990-10-12', 'gabriel.rueda@email.com', 5),
('Claudia', 'Aguilar', '1985-02-05', 'claudia.aguilar@email.com', 5),
('Mario', 'Salazar', '1992-05-28', 'mario.salazar@email.com', 5),
('Daniela', 'Contreras', '1988-09-21', 'daniela.contreras@email.com', 5),
('José', 'Miranda', '1993-01-14', 'jose.miranda@email.com', 5),
('Lorena', 'Vega', '1987-04-07', 'lorena.vega@email.com', 5),
('Arturo', 'Fuentes', '1991-07-30', 'arturo.fuentes@email.com', 5),
('Marina', 'Valdez', '1994-11-23', 'marina.valdez@email.com', 5),
('Alejandro', 'Carrasco', '1989-06-16', 'alejandro.carrasco@email.com', 5),
('Rocio', 'Medina', '1986-03-09', 'rocio.medina@email.com', NULL),

-- Usuarios adicionales sin empresa (10)
('Luis', 'Morales', '1991-09-15', 'luis.morales@email.com', NULL),
('Carmen', 'Reyes', '1989-04-22', 'carmen.reyes@email.com', NULL),
('Javier', 'Ortega', '1993-07-30', 'javier.ortega@email.com', NULL),
('Isabella', 'Flores', '1990-12-08', 'isabella.flores@email.com', NULL),
('Raul', 'Mendoza', '1988-02-14', 'raul.mendoza@email.com', NULL),
('Teresa', 'Vargas', '1992-05-19', 'teresa.vargas@email.com', NULL),
('Andres', 'Castro', '1994-08-25', 'andres.castro@email.com', NULL),
('Camila', 'Rojas', '1987-11-11', 'camila.rojas@email.com', NULL),
('Hector', 'Silva', '1995-01-30', 'hector.silva@email.com', NULL),
('Valeria', 'Torres', '1986-06-17', 'valeria.torres@email.com', NULL);

-- 3. Tipos Membresía (4 registros)
INSERT INTO tipos_membresia (nombre) VALUES
('Diaria'),
('Mensual'),
('Corporativa'),
('Premium');

-- 4. Membresías (60 registros con distribución equilibrada)
INSERT INTO membresias (usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, estado) VALUES
-- Membresías activas (40)
(1, 2, '2024-01-01', '2024-12-31', 'Activa'),
(2, 3, '2024-01-05', '2024-12-31', 'Activa'),
(3, 1, '2024-01-10', '2024-01-11', 'Vencida'),
(4, 4, '2024-01-15', '2024-12-31', 'Activa'),
(5, 2, '2024-01-20', '2024-12-31', 'Activa'),
(6, 3, '2024-01-25', '2024-12-31', 'Activa'),
(7, 1, '2024-01-30', '2024-01-31', 'Vencida'),
(8, 4, '2024-02-01', '2024-12-31', 'Activa'),
(9, 2, '2024-02-05', '2024-12-31', 'Activa'),
(10, 3, '2024-02-10', '2024-12-31', 'Activa'),
(11, 1, '2024-02-15', '2024-02-16', 'Vencida'),
(12, 4, '2024-02-20', '2024-12-31', 'Activa'),
(13, 2, '2024-02-25', '2024-12-31', 'Activa'),
(14, 3, '2024-03-01', '2024-12-31', 'Activa'),
(15, 1, '2024-03-05', '2024-03-06', 'Vencida'),
(16, 4, '2024-03-10', '2024-12-31', 'Activa'),
(17, 2, '2024-03-15', '2024-12-31', 'Activa'),
(18, 3, '2024-03-20', '2024-12-31', 'Activa'),
(19, 1, '2024-03-25', '2024-03-26', 'Vencida'),
(20, 4, '2024-03-30', '2024-12-31', 'Activa'),
(21, 2, '2024-04-01', '2024-12-31', 'Activa'),
(22, 3, '2024-04-05', '2024-12-31', 'Activa'),
(23, 1, '2024-04-10', '2024-04-11', 'Vencida'),
(24, 4, '2024-04-15', '2024-12-31', 'Activa'),
(25, 2, '2024-04-20', '2024-12-31', 'Activa'),
(26, 3, '2024-04-25', '2024-12-31', 'Activa'),
(27, 1, '2024-04-30', '2024-05-01', 'Vencida'),
(28, 4, '2024-05-05', '2024-12-31', 'Activa'),
(29, 2, '2024-05-10', '2024-12-31', 'Activa'),
(30, 3, '2024-05-15', '2024-12-31', 'Activa'),
(31, 1, '2024-05-20', '2024-05-21', 'Vencida'),
(32, 4, '2024-05-25', '2024-12-31', 'Activa'),
(33, 2, '2024-05-30', '2024-12-31', 'Activa'),
(34, 3, '2024-06-01', '2024-12-31', 'Activa'),
(35, 1, '2024-06-05', '2024-06-06', 'Vencida'),
(36, 4, '2024-06-10', '2024-12-31', 'Activa'),
(37, 2, '2024-06-15', '2024-12-31', 'Activa'),
(38, 3, '2024-06-20', '2024-12-31', 'Activa'),
(39, 1, '2024-06-25', '2024-06-26', 'Vencida'),
(40, 4, '2024-06-30', '2024-12-31', 'Activa'),

-- Membresías vencidas (20)
(41, 2, '2024-01-01', '2024-01-31', 'Vencida'),
(42, 3, '2024-01-05', '2024-02-05', 'Vencida'),
(43, 1, '2024-01-10', '2024-01-11', 'Vencida'),
(44, 4, '2024-01-15', '2024-02-15', 'Vencida'),
(45, 2, '2024-01-20', '2024-02-20', 'Vencida'),
(46, 3, '2024-01-25', '2024-02-25', 'Vencida'),
(47, 1, '2024-01-30', '2024-01-31', 'Vencida'),
(48, 4, '2024-02-01', '2024-03-01', 'Vencida'),
(49, 2, '2024-02-05', '2024-03-05', 'Vencida'),
(50, 3, '2024-02-10', '2024-03-10', 'Vencida'),
(51, 1, '2024-02-15', '2024-02-16', 'Vencida'),
(52, 4, '2024-02-20', '2024-03-20', 'Vencida'),
(53, 2, '2024-02-25', '2024-03-25', 'Vencida'),
(54, 3, '2024-03-01', '2024-04-01', 'Vencida'),
(55, 1, '2024-03-05', '2024-03-06', 'Vencida'),
(56, 4, '2024-03-10', '2024-04-10', 'Vencida'),
(57, 2, '2024-03-15', '2024-04-15', 'Vencida'),
(58, 3, '2024-03-20', '2024-04-20', 'Vencida'),
(59, 1, '2024-03-25', '2024-03-26', 'Vencida'),
(60, 4, '2024-03-30', '2024-04-30', 'Vencida');

-- 5. Renovaciones Membresía (60 registros)
INSERT INTO renovaciones_membresia (membresia_id, renovado_en) VALUES
(1, '2024-02-01 10:00:00'),
(2, '2024-02-05 11:30:00'),
(4, '2024-02-15 09:15:00'),
(5, '2024-02-20 14:20:00'),
(6, '2024-02-25 16:45:00'),
(8, '2024-03-01 08:30:00'),
(9, '2024-03-05 10:10:00'),
(10, '2024-03-10 11:45:00'),
(12, '2024-03-20 13:20:00'),
(13, '2024-03-25 15:30:00'),
(14, '2024-04-01 09:00:00'),
(16, '2024-04-10 10:30:00'),
(17, '2024-04-15 12:15:00'),
(18, '2024-04-20 14:45:00'),
(20, '2024-04-30 16:00:00'),
(21, '2024-05-01 08:45:00'),
(22, '2024-05-05 10:20:00'),
(24, '2024-05-15 11:30:00'),
(25, '2024-05-20 13:45:00'),
(26, '2024-05-25 15:15:00'),
(28, '2024-06-05 09:30:00'),
(29, '2024-06-10 11:00:00'),
(30, '2024-06-15 12:30:00'),
(32, '2024-06-25 14:00:00'),
(33, '2024-06-30 15:45:00'),
(34, '2024-07-01 08:15:00'),
(36, '2024-07-10 10:45:00'),
(37, '2024-07-15 12:00:00'),
(38, '2024-07-20 13:30:00'),
(40, '2024-07-30 15:00:00'),
(41, '2024-08-01 09:45:00'),
(42, '2024-08-05 11:15:00'),
(44, '2024-08-15 12:45:00'),
(45, '2024-08-20 14:15:00'),
(46, '2024-08-25 15:30:00'),
(48, '2024-09-01 08:00:00'),
(49, '2024-09-05 10:30:00'),
(50, '2024-09-10 12:00:00'),
(1, '2024-03-01 09:15:00'),
(2, '2024-03-05 10:45:00'),
(4, '2024-03-15 12:30:00'),
(5, '2024-03-20 14:00:00'),
(6, '2024-03-25 15:45:00'),
(8, '2024-04-01 08:30:00'),
(9, '2024-04-05 10:00:00'),
(10, '2024-04-10 11:30:00'),
(12, '2024-04-20 13:00:00'),
(13, '2024-04-25 14:30:00'),
(14, '2024-05-01 09:45:00'),
(15, '2024-05-05 10:15:00'),
(16, '2024-05-10 11:45:00'),
(17, '2024-05-15 13:15:00'),
(18, '2024-05-20 14:45:00'),
(19, '2024-05-25 16:15:00'),
(20, '2024-05-30 17:45:00'),
(21, '2024-06-04 09:15:00'),
(22, '2024-06-09 10:45:00'),
(23, '2024-06-14 12:15:00'),
(24, '2024-06-19 13:45:00'),
(25, '2024-06-24 15:15:00');

-- 6. Tipos Espacio (4 registros)
INSERT INTO tipos_espacio (nombre) VALUES
('Escritorio'),
('Oficina'),
('Sala Reuniones'),
('Sala Eventos');

-- 7. Espacios (60 registros)
INSERT INTO espacios (tipo_espacio_id, nombre, capacidad) VALUES
-- Escritorios (20)
(1, 'Escritorio A1', 1),
(1, 'Escritorio A2', 1),
(1, 'Escritorio A3', 1),
(1, 'Escritorio A4', 1),
(1, 'Escritorio A5', 1),
(1, 'Escritorio B1', 1),
(1, 'Escritorio B2', 1),
(1, 'Escritorio B3', 1),
(1, 'Escritorio B4', 1),
(1, 'Escritorio B5', 1),
(1, 'Escritorio C1', 1),
(1, 'Escritorio C2', 1),
(1, 'Escritorio C3', 1),
(1, 'Escritorio C4', 1),
(1, 'Escritorio C5', 1),
(1, 'Escritorio D1', 1),
(1, 'Escritorio D2', 1),
(1, 'Escritorio D3', 1),
(1, 'Escritorio D4', 1),
(1, 'Escritorio D5', 1),

-- Oficinas (20)
(2, 'Oficina 101', 2),
(2, 'Oficina 102', 2),
(2, 'Oficina 103', 3),
(2, 'Oficina 104', 3),
(2, 'Oficina 105', 4),
(2, 'Oficina 201', 2),
(2, 'Oficina 202', 2),
(2, 'Oficina 203', 3),
(2, 'Oficina 204', 3),
(2, 'Oficina 205', 4),
(2, 'Oficina 301', 2),
(2, 'Oficina 302', 2),
(2, 'Oficina 303', 3),
(2, 'Oficina 304', 3),
(2, 'Oficina 305', 4),
(2, 'Oficina 401', 2),
(2, 'Oficina 402', 2),
(2, 'Oficina 403', 3),
(2, 'Oficina 404', 3),
(2, 'Oficina 405', 4),

-- Salas de Reuniones (10)
(3, 'Sala Reuniones Pequeña', 4),
(3, 'Sala Reuniones Mediana', 6),
(3, 'Sala Reuniones Grande', 8),
(3, 'Sala Conferencias A', 10),
(3, 'Sala Conferencias B', 12),
(3, 'Sala Brainstorming', 5),
(3, 'Sala Creativa', 4),
(3, 'Sala Ejecutiva', 6),
(3, 'Sala VIP', 4),
(3, 'Sala Multimedia', 8),

-- Salas de Eventos (10)
(4, 'Sala Eventos Principal', 50),
(4, 'Sala Eventos Pequeña', 25),
(4, 'Sala Conferencias Principal', 40),
(4, 'Sala Presentaciones', 30),
(4, 'Sala Workshop A', 20),
(4, 'Sala Workshop B', 20),
(4, 'Sala Networking', 35),
(4, 'Sala Exhibición', 45),
(4, 'Sala Auditorio', 60),
(4, 'Sala Convenciones', 70);

-- 8. Servicios (50 registros)
INSERT INTO servicios (nombre, precio) VALUES
('Internet Básico', 5.00),
('Internet Premium', 15.00),
('Impresiones B/N', 0.10),
('Impresiones Color', 0.25),
('Fotocopias', 0.05),
('Escáner', 0.15),
('Fax', 1.00),
('Teléfono', 0.50),
('Videoconferencia', 20.00),
('Proyector', 12.00),
('Pantalla LCD', 8.00),
('Pizarra Digital', 20.00),
('Pizarra Blanca', 3.00),
('Marcadores', 1.50),
('Coffee Break', 25.00),
('Agua Mineral', 2.00),
('Refrescos', 3.00),
('Snacks', 5.00),
('Almuerzo Ejecutivo', 15.00),
('Catering Básico', 50.00),
('Catering Premium', 100.00),
('Secretaría Virtual', 10.00),
('Recepcionista', 15.00),
('Asistente Administrativo', 25.00),
('Traducción', 30.00),
('Interpretación', 40.00),
('Servicio de Mensajería', 8.00),
('Paquetería', 12.00),
('Estacionamiento', 10.00),
('Lockers', 3.00),
('Guardarropa', 2.00),
('Servicio de Limpieza', 20.00),
('Aire Acondicionado', 5.00),
('Calefacción', 5.00),
('WiFi Premium', 8.00),
('Enchufes Adicionales', 2.00),
('Extensiones', 1.50),
('Adaptadores', 2.00),
('Servicio Técnico', 15.00),
('Soporte IT', 25.00),
('Impresión 3D', 15.00),
('Realidad Virtual', 35.00),
('Tablets', 10.00),
('Laptops', 20.00),
('Smartphones', 15.00),
('Audio Conferencia', 8.00),
('Video Grabación', 30.00),
('Fotografía', 40.00),
('Streaming', 25.00),
('Edición Video', 45.00);

-- 9. Reservas (100 registros con diversidad de estados)
INSERT INTO reservas (usuario_id, empresa_id, espacio_id, inicio, fin, estado) VALUES
-- Reservas confirmadas (70)
(1, 1, 1, '2024-01-15 09:00:00', '2024-01-15 17:00:00', 'Confirmada'),
(2, 1, 11, '2024-01-16 08:00:00', '2024-01-16 12:00:00', 'Confirmada'),
(3, NULL, 2, '2024-01-17 10:00:00', '2024-01-17 14:00:00', 'Confirmada'),
(4, NULL, 3, '2024-01-18 13:00:00', '2024-01-18 17:00:00', 'Confirmada'),
(5, 1, 12, '2024-01-19 09:00:00', '2024-01-19 18:00:00', 'Confirmada'),
(6, 1, 21, '2024-01-22 08:30:00', '2024-01-22 10:30:00', 'Confirmada'),
(7, 1, 4, '2024-01-23 11:00:00', '2024-01-23 15:00:00', 'Confirmada'),
(8, NULL, 5, '2024-01-24 14:00:00', '2024-01-24 16:00:00', 'Confirmada'),
(9, 1, 13, '2024-01-25 09:00:00', '2024-01-25 17:00:00', 'Confirmada'),
(10, 1, 14, '2024-01-26 08:00:00', '2024-01-26 12:00:00', 'Confirmada'),
(11, 2, 6, '2024-01-29 10:00:00', '2024-01-29 14:00:00', 'Confirmada'),
(12, 2, 15, '2024-01-30 13:00:00', '2024-01-30 17:00:00', 'Confirmada'),
(13, 2, 7, '2024-01-31 09:00:00', '2024-01-31 18:00:00', 'Confirmada'),
(14, 2, 22, '2024-02-01 08:30:00', '2024-02-01 10:30:00', 'Confirmada'),
(15, 2, 8, '2024-02-02 11:00:00', '2024-02-02 15:00:00', 'Confirmada'),
(16, 2, 16, '2024-02-05 14:00:00', '2024-02-05 16:00:00', 'Confirmada'),
(17, 2, 9, '2024-02-06 09:00:00', '2024-02-06 17:00:00', 'Confirmada'),
(18, 2, 17, '2024-02-07 08:00:00', '2024-02-07 12:00:00', 'Confirmada'),
(19, 2, 10, '2024-02-08 10:00:00', '2024-02-08 14:00:00', 'Confirmada'),
(20, 2, 18, '2024-02-09 13:00:00', '2024-02-09 17:00:00', 'Confirmada'),
(21, 3, 23, '2024-02-12 09:00:00', '2024-02-12 18:00:00', 'Confirmada'),
(22, 3, 19, '2024-02-13 08:30:00', '2024-02-13 10:30:00', 'Confirmada'),
(23, 3, 24, '2024-02-14 11:00:00', '2024-02-14 15:00:00', 'Confirmada'),
(24, 3, 20, '2024-02-15 14:00:00', '2024-02-15 16:00:00', 'Confirmada'),
(25, 3, 25, '2024-02-16 09:00:00', '2024-02-16 17:00:00', 'Confirmada'),
(26, 3, 26, '2024-02-19 08:00:00', '2024-02-19 12:00:00', 'Confirmada'),
(27, 3, 27, '2024-02-20 10:00:00', '2024-02-20 14:00:00', 'Confirmada'),
(28, 3, 28, '2024-02-21 13:00:00', '2024-02-21 17:00:00', 'Confirmada'),
(29, 3, 29, '2024-02-22 09:00:00', '2024-02-22 18:00:00', 'Confirmada'),
(30, 3, 30, '2024-02-23 08:30:00', '2024-02-23 10:30:00', 'Confirmada'),
(31, 4, 31, '2024-02-26 11:00:00', '2024-02-26 15:00:00', 'Confirmada'),
(32, 4, 32, '2024-02-27 14:00:00', '2024-02-27 16:00:00', 'Confirmada'),
(33, 4, 33, '2024-02-28 09:00:00', '2024-02-28 17:00:00', 'Confirmada'),
(34, 4, 34, '2024-02-29 08:00:00', '2024-02-29 12:00:00', 'Confirmada'),
(35, 4, 35, '2024-03-01 10:00:00', '2024-03-01 14:00:00', 'Confirmada'),
(36, 4, 36, '2024-03-04 13:00:00', '2024-03-04 17:00:00', 'Confirmada'),
(37, 4, 37, '2024-03-05 09:00:00', '2024-03-05 18:00:00', 'Confirmada'),
(38, 4, 38, '2024-03-06 08:30:00', '2024-03-06 10:30:00', 'Confirmada'),
(39, 4, 39, '2024-03-07 11:00:00', '2024-03-07 15:00:00', 'Confirmada'),
(40, 4, 40, '2024-03-08 14:00:00', '2024-03-08 16:00:00', 'Confirmada'),
(41, 5, 41, '2024-03-11 09:00:00', '2024-03-11 17:00:00', 'Confirmada'),
(42, 5, 42, '2024-03-12 08:00:00', '2024-03-12 12:00:00', 'Confirmada'),
(43, 5, 43, '2024-03-13 10:00:00', '2024-03-13 14:00:00', 'Confirmada'),
(44, 5, 44, '2024-03-14 13:00:00', '2024-03-14 17:00:00', 'Confirmada'),
(45, 5, 45, '2024-03-15 09:00:00', '2024-03-15 18:00:00', 'Confirmada'),
(46, 5, 46, '2024-03-18 08:30:00', '2024-03-18 10:30:00', 'Confirmada'),
(47, 5, 47, '2024-03-19 11:00:00', '2024-03-19 15:00:00', 'Confirmada'),
(48, 5, 48, '2024-03-20 14:00:00', '2024-03-20 16:00:00', 'Confirmada'),
(49, 5, 49, '2024-03-21 09:00:00', '2024-03-21 17:00:00', 'Confirmada'),
(50, 5, 50, '2024-03-22 08:00:00', '2024-03-22 12:00:00', 'Confirmada'),
(51, NULL, 1, '2024-03-25 09:00:00', '2024-03-25 17:00:00', 'Confirmada'),
(52, NULL, 2, '2024-03-26 10:00:00', '2024-03-26 14:00:00', 'Confirmada'),
(53, NULL, 3, '2024-03-27 11:00:00', '2024-03-27 15:00:00', 'Confirmada'),
(54, NULL, 4, '2024-03-28 12:00:00', '2024-03-28 16:00:00', 'Confirmada'),
(55, NULL, 5, '2024-03-29 13:00:00', '2024-03-29 17:00:00', 'Confirmada'),
(56, NULL, 6, '2024-04-01 09:00:00', '2024-04-01 17:00:00', 'Confirmada'),
(57, NULL, 7, '2024-04-02 10:00:00', '2024-04-02 14:00:00', 'Confirmada'),
(58, NULL, 8, '2024-04-03 11:00:00', '2024-04-03 15:00:00', 'Confirmada'),
(59, NULL, 9, '2024-04-04 12:00:00', '2024-04-04 16:00:00', 'Confirmada'),
(60, NULL, 10, '2024-04-05 13:00:00', '2024-04-05 17:00:00', 'Confirmada'),

-- Reservas canceladas (15)
(1, 1, 11, '2024-01-17 09:00:00', '2024-01-17 17:00:00', 'Cancelada'),
(2, 1, 12, '2024-01-18 08:00:00', '2024-01-18 12:00:00', 'Cancelada'),
(11, 2, 21, '2024-02-01 10:00:00', '2024-02-01 14:00:00', 'Cancelada'),
(12, 2, 22, '2024-02-02 13:00:00', '2024-02-02 17:00:00', 'Cancelada'),
(21, 3, 31, '2024-02-15 09:00:00', '2024-02-15 18:00:00', 'Cancelada'),
(22, 3, 32, '2024-02-16 08:30:00', '2024-02-16 10:30:00', 'Cancelada'),
(31, 4, 41, '2024-03-01 11:00:00', '2024-03-01 15:00:00', 'Cancelada'),
(32, 4, 42, '2024-03-02 14:00:00', '2024-03-02 16:00:00', 'Cancelada'),
(41, 5, 1, '2024-03-15 09:00:00', '2024-03-15 17:00:00', 'Cancelada'),
(42, 5, 2, '2024-03-16 08:00:00', '2024-03-16 12:00:00', 'Cancelada'),
(51, NULL, 11, '2024-04-01 10:00:00', '2024-04-01 14:00:00', 'Cancelada'),
(52, NULL, 12, '2024-04-02 13:00:00', '2024-04-02 17:00:00', 'Cancelada'),
(53, NULL, 13, '2024-04-03 09:00:00', '2024-04-03 18:00:00', 'Cancelada'),
(54, NULL, 14, '2024-04-04 08:30:00', '2024-04-04 10:30:00', 'Cancelada'),
(55, NULL, 15, '2024-04-05 11:00:00', '2024-04-05 15:00:00', 'Cancelada'),

-- Reservas pendientes (15)
(3, NULL, 13, '2024-04-08 09:00:00', '2024-04-08 17:00:00', 'Pendiente'),
(4, NULL, 14, '2024-04-09 08:00:00', '2024-04-09 12:00:00', 'Pendiente'),
(13, 2, 23, '2024-04-10 10:00:00', '2024-04-10 14:00:00', 'Pendiente'),
(14, 2, 24, '2024-04-11 13:00:00', '2024-04-11 17:00:00', 'Pendiente'),
(23, 3, 33, '2024-04-12 09:00:00', '2024-04-12 18:00:00', 'Pendiente'),
(24, 3, 34, '2024-04-13 08:30:00', '2024-04-13 10:30:00', 'Pendiente'),
(33, 4, 43, '2024-04-14 11:00:00', '2024-04-14 15:00:00', 'Pendiente'),
(34, 4, 44, '2024-04-15 14:00:00', '2024-04-15 16:00:00', 'Pendiente'),
(43, 5, 3, '2024-04-16 09:00:00', '2024-04-16 17:00:00', 'Pendiente'),
(44, 5, 4, '2024-04-17 08:00:00', '2024-04-17 12:00:00', 'Pendiente'),
(56, NULL, 16, '2024-04-18 10:00:00', '2024-04-18 14:00:00', 'Pendiente'),
(57, NULL, 17, '2024-04-19 13:00:00', '2024-04-19 17:00:00', 'Pendiente'),
(58, NULL, 18, '2024-04-22 09:00:00', '2024-04-22 18:00:00', 'Pendiente'),
(59, NULL, 19, '2024-04-23 08:30:00', '2024-04-23 10:30:00', 'Pendiente'),
(60, NULL, 20, '2024-04-24 11:00:00', '2024-04-24 15:00:00', 'Pendiente');



-- 10. Servicios Reserva (150 registros)
INSERT INTO servicios_reserva (reserva_id, servicio_id) VALUES
-- Servicios para las primeras 50 reservas (1-50)
(1, 2), (1, 15),
(2, 1), (2, 16),
(3, 2), (3, 17),
(4, 3), (4, 18),
(5, 4), (5, 19),
(6, 5), (6, 20),
(7, 6), (7, 21),
(8, 7), (8, 22),
(9, 8), (9, 23),
(10, 9), (10, 24),
(11, 10), (11, 25),
(12, 11), (12, 26),
(13, 12), (13, 27),
(14, 13), (14, 28),
(15, 14), (15, 29),
(16, 15), (16, 30),
(17, 16), (17, 31),
(18, 17), (18, 32),
(19, 18), (19, 33),
(20, 19), (20, 34),
(21, 20), (21, 35),
(22, 21), (22, 36),
(23, 22), (23, 37),
(24, 23), (24, 38),
(25, 24), (25, 39),
(26, 25), (26, 40),
(27, 26), (27, 41),
(28, 27), (28, 42),
(29, 28), (29, 43),
(30, 29), (30, 44),
(31, 30), (31, 45),
(32, 31), (32, 46),
(33, 32), (33, 47),
(34, 33), (34, 48),
(35, 34), (35, 49),
(36, 35), (36, 50),
(37, 36), (37, 1),
(38, 37), (38, 2),
(39, 38), (39, 3),
(40, 39), (40, 4),
(41, 40), (41, 5),
(42, 41), (42, 6),
(43, 42), (43, 7),
(44, 43), (44, 8),
(45, 44), (45, 9),
(46, 45), (46, 10),
(47, 46), (47, 11),
(48, 47), (48, 12),
(49, 48), (49, 13),
(50, 49), (50, 14),

-- Servicios para reservas adicionales (51-90)
(51, 1), (51, 2), (51, 15),
(52, 3), (52, 4), (52, 16),
(53, 5), (53, 6), (53, 17),
(54, 7), (54, 8), (54, 18),
(55, 9), (55, 10), (55, 19),
(56, 11), (56, 12), (56, 20),
(57, 13), (57, 14), (57, 21),
(58, 15), (58, 16), (58, 22),
(59, 17), (59, 18), (59, 23),
(60, 19), (60, 20), (60, 24),
(61, 21), (61, 22), (61, 25),
(62, 23), (62, 24), (62, 26),
(63, 25), (63, 26), (63, 27),
(64, 27), (64, 28), (64, 28),
(65, 29), (65, 30), (65, 29),
(66, 31), (66, 32), (66, 30),
(67, 33), (67, 34), (67, 31),
(68, 35), (68, 36), (68, 32),
(69, 37), (69, 38), (69, 33),
(70, 39), (70, 40), (70, 34),
(71, 41), (71, 42), (71, 35),
(72, 43), (72, 44), (72, 36),
(73, 45), (73, 46), (73, 37),
(74, 47), (74, 48), (74, 38),
(75, 49), (75, 50), (75, 39),
(76, 1), (76, 2), (76, 40),
(77, 3), (77, 4), (77, 41),
(78, 5), (78, 6), (78, 42),
(79, 7), (79, 8), (79, 43),
(80, 9), (80, 10), (80, 44),
(81, 11), (81, 12), (81, 45),
(82, 13), (82, 14), (82, 46),
(83, 15), (83, 16), (83, 47),
(84, 17), (84, 18), (84, 48),
(85, 19), (85, 20), (85, 49),
(86, 21), (86, 22), (86, 50),
(87, 23), (87, 24), (87, 1),
(88, 25), (88, 26), (88, 2),
(89, 27), (89, 28), (89, 3),
(90, 29), (90, 30), (90, 4);

-- 11. Facturas (100 registros con diferentes estados)
INSERT INTO facturas (usuario_id, empresa_id, monto, tipo, estado, descripcion) VALUES
-- Facturas pagadas (60)
(1, 1, 50.00, 'Reserva', 'Pagada', 'Reserva de escritorio A1'),
(2, 1, 75.00, 'Reserva', 'Pagada', 'Reserva de oficina 101'),
(4, NULL, 40.00, 'Reserva', 'Pagada', 'Reserva de escritorio A3'),
(5, 1, 120.00, 'Reserva', 'Pagada', 'Reserva de oficina 102'),
(7, 1, 45.00, 'Reserva', 'Pagada', 'Reserva de escritorio A4'),
(9, 1, 100.00, 'Reserva', 'Pagada', 'Reserva de oficina 103'),
(10, 1, 80.00, 'Reserva', 'Pagada', 'Reserva de oficina 104'),
(12, 2, 90.00, 'Reserva', 'Pagada', 'Reserva de oficina 105'),
(13, 2, 55.00, 'Reserva', 'Pagada', 'Reserva de escritorio B2'),
(15, 2, 70.00, 'Reserva', 'Pagada', 'Reserva de escritorio B3'),
(16, 2, 95.00, 'Reserva', 'Pagada', 'Reserva de oficina 201'),
(18, 2, 85.00, 'Reserva', 'Pagada', 'Reserva de oficina 202'),
(19, 2, 60.00, 'Reserva', 'Pagada', 'Reserva de escritorio B5'),
(21, 3, 75.00, 'Reserva', 'Pagada', 'Reserva de sala conferencias A'),
(22, 3, 115.00, 'Reserva', 'Pagada', 'Reserva de oficina 203'),
(24, 3, 80.00, 'Reserva', 'Pagada', 'Reserva de oficina 204'),
(25, 3, 100.00, 'Reserva', 'Pagada', 'Reserva de sala brainstorming'),
(27, 3, 90.00, 'Reserva', 'Pagada', 'Reserva de oficina 205'),
(28, 3, 55.00, 'Reserva', 'Pagada', 'Reserva de sala ejecutiva'),
(30, 3, 70.00, 'Reserva', 'Pagada', 'Reserva de sala multimedia'),
(31, 4, 150.00, 'Reserva', 'Pagada', 'Reserva de sala eventos principal'),
(33, 4, 130.00, 'Reserva', 'Pagada', 'Reserva de sala conferencias principal'),
(34, 4, 95.00, 'Reserva', 'Pagada', 'Reserva de sala presentaciones'),
(36, 4, 75.00, 'Reserva', 'Pagada', 'Reserva de sala workshop B'),
(37, 4, 140.00, 'Reserva', 'Pagada', 'Reserva de sala networking'),
(39, 4, 160.00, 'Reserva', 'Pagada', 'Reserva de sala auditorio'),
(40, 4, 90.00, 'Reserva', 'Pagada', 'Reserva de sala convenciones'),
(42, 5, 80.00, 'Reserva', 'Pagada', 'Reserva de oficina 301'),
(43, 5, 60.00, 'Reserva', 'Pagada', 'Reserva de escritorio C2'),
(45, 5, 70.00, 'Reserva', 'Pagada', 'Reserva de escritorio C3'),
(46, 5, 95.00, 'Reserva', 'Pagada', 'Reserva de oficina 303'),
(48, 5, 85.00, 'Reserva', 'Pagada', 'Reserva de oficina 304'),
(49, 5, 110.00, 'Reserva', 'Pagada', 'Reserva de oficina 305'),
(51, NULL, 50.00, 'Reserva', 'Pagada', 'Reserva de escritorio A1'),
(52, NULL, 65.00, 'Reserva', 'Pagada', 'Reserva de escritorio A2'),
(53, NULL, 85.00, 'Reserva', 'Pagada', 'Reserva de escritorio A3'),
(54, NULL, 45.00, 'Reserva', 'Pagada', 'Reserva de escritorio A4'),
(55, NULL, 60.00, 'Reserva', 'Pagada', 'Reserva de escritorio A5'),
(56, NULL, 120.00, 'Reserva', 'Pagada', 'Reserva de oficina 101'),
(57, NULL, 95.00, 'Reserva', 'Pagada', 'Reserva de oficina 102'),
(58, NULL, 110.00, 'Reserva', 'Pagada', 'Reserva de oficina 103'),
(59, NULL, 75.00, 'Reserva', 'Pagada', 'Reserva de oficina 104'),
(60, NULL, 130.00, 'Reserva', 'Pagada', 'Reserva de oficina 105'),
(1, 1, 25.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(2, 1, 35.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(3, NULL, 15.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(4, NULL, 20.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(5, 1, 40.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(6, 1, 30.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(7, 1, 45.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(8, NULL, 10.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(9, 1, 50.00, 'Servicio', 'Pagada', 'Servicios adicionales'),
(10, 1, 35.00, 'Servicio', 'Pagada', 'Servicios adicionales'),

-- Facturas pendientes (25)
(3, NULL, 30.00, 'Reserva', 'Pendiente', 'Reserva de escritorio A2'),
(6, 1, 60.00, 'Reserva', 'Pendiente', 'Reserva de sala reuniones pequeña'),
(8, NULL, 25.00, 'Reserva', 'Pendiente', 'Reserva de escritorio A5'),
(11, 2, 65.00, 'Reserva', 'Pendiente', 'Reserva de escritorio B1'),
(14, 2, 110.00, 'Reserva', 'Pendiente', 'Reserva de sala reuniones mediana'),
(17, 2, 50.00, 'Reserva', 'Pendiente', 'Reserva de escritorio B4'),
(20, 2, 105.00, 'Reserva', 'Pendiente', 'Reserva de sala reuniones grande'),
(23, 3, 65.00, 'Reserva', 'Pendiente', 'Reserva de sala conferencias B'),
(26, 3, 45.00, 'Reserva', 'Pendiente', 'Reserva de sala creativa'),
(29, 3, 120.00, 'Reserva', 'Pendiente', 'Reserva de sala VIP'),
(32, 4, 85.00, 'Reserva', 'Pendiente', 'Reserva de sala eventos pequeña'),
(35, 4, 110.00, 'Reserva', 'Pendiente', 'Reserva de sala workshop A'),
(38, 4, 65.00, 'Reserva', 'Pendiente', 'Reserva de sala exhibición'),
(41, 5, 50.00, 'Reserva', 'Pendiente', 'Reserva de escritorio C1'),
(44, 5, 100.00, 'Reserva', 'Pendiente', 'Reserva de oficina 302'),
(47, 5, 55.00, 'Reserva', 'Pendiente', 'Reserva de escritorio C4'),
(50, 5, 65.00, 'Reserva', 'Pendiente', 'Reserva de escritorio C5'),
(11, 2, 20.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(12, 2, 30.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(13, 2, 25.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(14, 2, 35.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(15, 2, 40.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(16, 2, 45.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(17, 2, 30.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),
(18, 2, 25.00, 'Servicio', 'Pendiente', 'Servicios adicionales'),

-- Facturas con pago parcial (15)
(19, 2, 60.00, 'Reserva', 'Parcial', 'Reserva de escritorio B5'),
(20, 2, 105.00, 'Reserva', 'Parcial', 'Reserva de sala reuniones grande'),
(21, 3, 75.00, 'Reserva', 'Parcial', 'Reserva de sala conferencias A'),
(22, 3, 115.00, 'Reserva', 'Parcial', 'Reserva de oficina 203'),
(23, 3, 65.00, 'Reserva', 'Parcial', 'Reserva de sala conferencias B'),
(24, 3, 80.00, 'Reserva', 'Parcial', 'Reserva de oficina 204'),
(25, 3, 100.00, 'Reserva', 'Parcial', 'Reserva de sala brainstorming'),
(26, 3, 45.00, 'Reserva', 'Parcial', 'Reserva de sala creativa'),
(27, 3, 90.00, 'Reserva', 'Parcial', 'Reserva de oficina 205'),
(28, 3, 55.00, 'Reserva', 'Parcial', 'Reserva de sala ejecutiva'),
(29, 3, 120.00, 'Reserva', 'Parcial', 'Reserva de sala VIP'),
(30, 3, 70.00, 'Reserva', 'Parcial', 'Reserva de sala multimedia'),
(31, 4, 150.00, 'Reserva', 'Parcial', 'Reserva de sala eventos principal'),
(32, 4, 85.00, 'Reserva', 'Parcial', 'Reserva de sala eventos pequeña'),
(33, 4, 130.00, 'Reserva', 'Parcial', 'Reserva de sala conferencias principal');

-- 12. Pagos (100 registros)
INSERT INTO pagos (factura_id, usuario_id, monto, metodo, estado) VALUES
-- Pagos completos (60)
(1, 1, 50.00, 'Tarjeta', 'Pagado'),
(2, 2, 75.00, 'Transferencia', 'Pagado'),
(4, 4, 40.00, 'Efectivo', 'Pagado'),
(5, 5, 120.00, 'Tarjeta', 'Pagado'),
(7, 7, 45.00, 'Transferencia', 'Pagado'),
(9, 9, 100.00, 'Tarjeta', 'Pagado'),
(10, 10, 80.00, 'Efectivo', 'Pagado'),
(12, 12, 90.00, 'Transferencia', 'Pagado'),
(13, 13, 55.00, 'Tarjeta', 'Pagado'),
(15, 15, 70.00, 'Efectivo', 'Pagado'),
(16, 16, 95.00, 'Transferencia', 'Pagado'),
(18, 18, 85.00, 'Tarjeta', 'Pagado'),
(19, 19, 60.00, 'Efectivo', 'Pagado'),
(21, 21, 75.00, 'Transferencia', 'Pagado'),
(22, 22, 115.00, 'Tarjeta', 'Pagado'),
(24, 24, 80.00, 'Efectivo', 'Pagado'),
(25, 25, 100.00, 'Transferencia', 'Pagado'),
(27, 27, 90.00, 'Tarjeta', 'Pagado'),
(28, 28, 55.00, 'Efectivo', 'Pagado'),
(30, 30, 70.00, 'Transferencia', 'Pagado'),
(31, 31, 150.00, 'Tarjeta', 'Pagado'),
(33, 33, 130.00, 'Efectivo', 'Pagado'),
(34, 34, 95.00, 'Transferencia', 'Pagado'),
(36, 36, 75.00, 'Tarjeta', 'Pagado'),
(37, 37, 140.00, 'Efectivo', 'Pagado'),
(39, 39, 160.00, 'Transferencia', 'Pagado'),
(40, 40, 90.00, 'Tarjeta', 'Pagado'),
(42, 42, 80.00, 'Efectivo', 'Pagado'),
(43, 43, 60.00, 'Transferencia', 'Pagado'),
(45, 45, 70.00, 'Tarjeta', 'Pagado'),
(46, 46, 95.00, 'Efectivo', 'Pagado'),
(48, 48, 85.00, 'Transferencia', 'Pagado'),
(49, 49, 110.00, 'Tarjeta', 'Pagado'),
(50, 51, 50.00, 'Efectivo', 'Pagado'),
(51, 52, 65.00, 'Transferencia', 'Pagado'),
(52, 53, 85.00, 'Tarjeta', 'Pagado'),
(53, 54, 45.00, 'Efectivo', 'Pagado'),
(54, 55, 60.00, 'Transferencia', 'Pagado'),
(55, 56, 120.00, 'Tarjeta', 'Pagado'),
(56, 57, 95.00, 'Efectivo', 'Pagado'),
(57, 58, 110.00, 'Transferencia', 'Pagado'),
(58, 59, 75.00, 'Tarjeta', 'Pagado'),
(59, 60, 130.00, 'Efectivo', 'Pagado'),
(60, 1, 25.00, 'Transferencia', 'Pagado'),
(61, 2, 35.00, 'Tarjeta', 'Pagado'),
(62, 3, 15.00, 'Efectivo', 'Pagado'),
(63, 4, 20.00, 'Transferencia', 'Pagado'),
(64, 5, 40.00, 'Tarjeta', 'Pagado'),
(65, 6, 30.00, 'Efectivo', 'Pagado'),
(66, 7, 45.00, 'Transferencia', 'Pagado'),
(67, 8, 10.00, 'Tarjeta', 'Pagado'),
(68, 9, 50.00, 'Efectivo', 'Pagado'),
(69, 10, 35.00, 'Transferencia', 'Pagado'),

-- Pagos pendientes (25)
(3, 3, 30.00, 'Efectivo', 'Pendiente'),
(6, 6, 60.00, 'Transferencia', 'Pendiente'),
(8, 8, 25.00, 'Tarjeta', 'Pendiente'),
(11, 11, 65.00, 'Efectivo', 'Pendiente'),
(14, 14, 110.00, 'Transferencia', 'Pendiente'),
(17, 17, 50.00, 'Tarjeta', 'Pendiente'),
(20, 20, 105.00, 'Efectivo', 'Pendiente'),
(23, 23, 65.00, 'Transferencia', 'Pendiente'),
(26, 26, 45.00, 'Tarjeta', 'Pendiente'),
(29, 29, 120.00, 'Efectivo', 'Pendiente'),
(32, 32, 85.00, 'Transferencia', 'Pendiente'),
(35, 35, 110.00, 'Tarjeta', 'Pendiente'),
(38, 38, 65.00, 'Efectivo', 'Pendiente'),
(41, 41, 50.00, 'Transferencia', 'Pendiente'),
(44, 44, 100.00, 'Tarjeta', 'Pendiente'),
(47, 47, 55.00, 'Efectivo', 'Pendiente'),
(70, 11, 20.00, 'Transferencia', 'Pendiente'),
(71, 12, 30.00, 'Tarjeta', 'Pendiente'),
(72, 13, 25.00, 'Efectivo', 'Pendiente'),
(73, 14, 35.00, 'Transferencia', 'Pendiente'),
(74, 15, 40.00, 'Tarjeta', 'Pendiente'),
(75, 16, 45.00, 'Efectivo', 'Pendiente'),
(76, 17, 30.00, 'Transferencia', 'Pendiente'),
(77, 18, 25.00, 'Tarjeta', 'Pendiente'),
(78, 19, 30.00, 'Efectivo', 'Pendiente'),

-- Pagos parciales (15)
(79, 19, 30.00, 'Transferencia', 'Pagado'),
(80, 20, 50.00, 'Tarjeta', 'Pagado'),
(81, 21, 40.00, 'Efectivo', 'Pagado'),
(82, 22, 60.00, 'Transferencia', 'Pagado'),
(83, 23, 30.00, 'Tarjeta', 'Pagado'),
(84, 24, 40.00, 'Efectivo', 'Pagado'),
(85, 25, 50.00, 'Transferencia', 'Pagado'),
(86, 26, 20.00, 'Tarjeta', 'Pagado'),
(87, 27, 45.00, 'Efectivo', 'Pagado'),
(88, 28, 30.00, 'Transferencia', 'Pagado'),
(89, 29, 60.00, 'Tarjeta', 'Pagado'),
(90, 30, 35.00, 'Efectivo', 'Pagado'),
(91, 31, 75.00, 'Transferencia', 'Pagado'),
(92, 32, 40.00, 'Tarjeta', 'Pagado'),
(93, 33, 65.00, 'Efectivo', 'Pagado');

-- 13. Registros Acceso (150 registros con diversidad de eventos)
INSERT INTO registros_acceso (usuario_id, evento, razon) VALUES
-- Entradas (100)
(1, 'ENTRADA', 'Membresía activa'),
(2, 'ENTRADA', 'Membresía activa'),
(4, 'ENTRADA', 'Membresía activa'),
(5, 'ENTRADA', 'Membresía activa'),
(6, 'ENTRADA', 'Membresía activa'),
(7, 'ENTRADA', 'Membresía activa'),
(9, 'ENTRADA', 'Membresía activa'),
(10, 'ENTRADA', 'Membresía activa'),
(11, 'ENTRADA', 'Membresía activa'),
(12, 'ENTRADA', 'Membresía activa'),
(13, 'ENTRADA', 'Membresía activa'),
(14, 'ENTRADA', 'Membresía activa'),
(16, 'ENTRADA', 'Membresía activa'),
(17, 'ENTRADA', 'Membresía activa'),
(18, 'ENTRADA', 'Membresía activa'),
(19, 'ENTRADA', 'Membresía activa'),
(20, 'ENTRADA', 'Membresía activa'),
(21, 'ENTRADA', 'Membresía activa'),
(22, 'ENTRADA', 'Membresía activa'),
(24, 'ENTRADA', 'Membresía activa'),
(25, 'ENTRADA', 'Membresía activa'),
(26, 'ENTRADA', 'Membresía activa'),
(27, 'ENTRADA', 'Membresía activa'),
(28, 'ENTRADA', 'Membresía activa'),
(30, 'ENTRADA', 'Membresía activa'),
(31, 'ENTRADA', 'Membresía activa'),
(32, 'ENTRADA', 'Membresía activa'),
(33, 'ENTRADA', 'Membresía activa'),
(34, 'ENTRADA', 'Membresía activa'),
(36, 'ENTRADA', 'Membresía activa'),
(37, 'ENTRADA', 'Membresía activa'),
(38, 'ENTRADA', 'Membresía activa'),
(39, 'ENTRADA', 'Membresía activa'),
(40, 'ENTRADA', 'Membresía activa'),
(41, 'ENTRADA', 'Membresía activa'),
(42, 'ENTRADA', 'Membresía activa'),
(44, 'ENTRADA', 'Membresía activa'),
(45, 'ENTRADA', 'Membresía activa'),
(46, 'ENTRADA', 'Membresía activa'),
(47, 'ENTRADA', 'Membresía activa'),
(48, 'ENTRADA', 'Membresía activa'),
(49, 'ENTRADA', 'Membresía activa'),
(50, 'ENTRADA', 'Membresía activa'),
(51, 'ENTRADA', 'Reserva confirmada'),
(52, 'ENTRADA', 'Reserva confirmada'),
(53, 'ENTRADA', 'Reserva confirmada'),
(54, 'ENTRADA', 'Reserva confirmada'),
(55, 'ENTRADA', 'Reserva confirmada'),
(56, 'ENTRADA', 'Reserva confirmada'),
(57, 'ENTRADA', 'Reserva confirmada'),
(58, 'ENTRADA', 'Reserva confirmada'),
(59, 'ENTRADA', 'Reserva confirmada'),
(60, 'ENTRADA', 'Reserva confirmada'),
(1, 'ENTRADA', 'Visita recurrente'),
(2, 'ENTRADA', 'Visita recurrente'),
(3, 'ENTRADA', 'Visita recurrente'),
(4, 'ENTRADA', 'Visita recurrente'),
(5, 'ENTRADA', 'Visita recurrente'),
(6, 'ENTRADA', 'Visita recurrente'),
(7, 'ENTRADA', 'Visita recurrente'),
(8, 'ENTRADA', 'Visita recurrente'),
(9, 'ENTRADA', 'Visita recurrente'),
(10, 'ENTRADA', 'Visita recurrente'),
(11, 'ENTRADA', 'Visita recurrente'),
(12, 'ENTRADA', 'Visita recurrente'),
(13, 'ENTRADA', 'Visita recurrente'),
(14, 'ENTRADA', 'Visita recurrente'),
(15, 'ENTRADA', 'Visita recurrente'),
(16, 'ENTRADA', 'Visita recurrente'),
(17, 'ENTRADA', 'Visita recurrente'),
(18, 'ENTRADA', 'Visita recurrente'),
(19, 'ENTRADA', 'Visita recurrente'),
(20, 'ENTRADA', 'Visita recurrente'),
(21, 'ENTRADA', 'Visita recurrente'),
(22, 'ENTRADA', 'Visita recurrente'),
(23, 'ENTRADA', 'Visita recurrente'),
(24, 'ENTRADA', 'Visita recurrente'),
(25, 'ENTRADA', 'Visita recurrente'),
(26, 'ENTRADA', 'Visita recurrente'),
(27, 'ENTRADA', 'Visita recurrente'),
(28, 'ENTRADA', 'Visita recurrente'),
(29, 'ENTRADA', 'Visita recurrente'),
(30, 'ENTRADA', 'Visita recurrente'),

-- Salidas (30)
(1, 'SALIDA', NULL),
(2, 'SALIDA', NULL),
(4, 'SALIDA', NULL),
(5, 'SALIDA', NULL),
(6, 'SALIDA', NULL),
(7, 'SALIDA', NULL),
(9, 'SALIDA', NULL),
(10, 'SALIDA', NULL),
(11, 'SALIDA', NULL),
(12, 'SALIDA', NULL),
(13, 'SALIDA', NULL),
(14, 'SALIDA', NULL),
(16, 'SALIDA', NULL),
(17, 'SALIDA', NULL),
(18, 'SALIDA', NULL),
(19, 'SALIDA', NULL),
(20, 'SALIDA', NULL),
(21, 'SALIDA', NULL),
(22, 'SALIDA', NULL),
(24, 'SALIDA', NULL),
(25, 'SALIDA', NULL),
(26, 'SALIDA', NULL),
(27, 'SALIDA', NULL),
(28, 'SALIDA', NULL),
(30, 'SALIDA', NULL),
(31, 'SALIDA', NULL),
(32, 'SALIDA', NULL),
(33, 'SALIDA', NULL),
(34, 'SALIDA', NULL),
(36, 'SALIDA', NULL),

-- Accesos denegados (20)
(3, 'DENEGADO', 'Sin membresía activa'),
(8, 'DENEGADO', 'Sin membresía activa'),
(15, 'DENEGADO', 'Sin membresía activa'),
(23, 'DENEGADO', 'Sin membresía activa'),
(29, 'DENEGADO', 'Sin membresía activa'),
(35, 'DENEGADO', 'Sin membresía activa'),
(43, 'DENEGADO', 'Sin membresía activa'),
(49, 'DENEGADO', 'Sin membresía activa'),
(3, 'DENEGADO', 'Facturas pendientes'),
(8, 'DENEGADO', 'Membresía vencida'),
(15, 'DENEGADO', 'Pago rechazado'),
(23, 'DENEGADO', 'Facturas vencidas'),
(29, 'DENEGADO', 'Membresía suspendida'),
(35, 'DENEGADO', 'Pago atrasado'),
(43, 'DENEGADO', 'Facturas sin pagar'),
(49, 'DENEGADO', 'Membresía cancelada'),
(6, 'DENEGADO', 'Pago pendiente'),
(17, 'DENEGADO', 'Problemas de pago'),
(22, 'DENEGADO', 'Reserva no confirmada'),
(27, 'DENEGADO', 'Acceso restringido');

-- 14. Bloqueos Servicio (15 registros)
INSERT INTO bloqueos_servicio (usuario_id, razon) VALUES
(3, 'Facturas pendientes de pago'),
(8, 'Membresía vencida'),
(15, 'Pago rechazado'),
(23, 'Facturas vencidas'),
(29, 'Membresía suspendida'),
(35, 'Pago atrasado'),
(43, 'Facturas sin pagar'),
(49, 'Membresía cancelada'),
(6, 'Pago pendiente'),
(17, 'Problemas de pago'),
(22, 'Incumplimiento de normas'),
(27, 'Pagos en mora'),
(33, 'Tarjeta rechazada'),
(38, 'Suspensión temporal'),
(44, 'Problemas contractuales');

-- 15. Log Auditoría Membresía (60 registros)
INSERT INTO log_auditoria_membresia (membresia_id, tipo_anterior, tipo_nuevo, cambiado_por) VALUES
(1, 2, 3, 'admin'),
(2, 3, 4, 'admin'),
(3, 1, 2, 'admin'),
(4, 4, 3, 'admin'),
(5, 2, 4, 'admin'),
(6, 3, 2, 'admin'),
(7, 1, 3, 'admin'),
(8, 4, 2, 'admin'),
(9, 2, 3, 'admin'),
(10, 3, 4, 'admin'),
(11, 1, 2, 'admin'),
(12, 4, 3, 'admin'),
(13, 2, 4, 'admin'),
(14, 3, 2, 'admin'),
(15, 1, 3, 'admin'),
(16, 4, 2, 'admin'),
(17, 2, 3, 'admin'),
(18, 3, 4, 'admin'),
(19, 1, 2, 'admin'),
(20, 4, 3, 'admin'),
(21, 2, 4, 'admin'),
(22, 3, 2, 'admin'),
(23, 1, 3, 'admin'),
(24, 4, 2, 'admin'),
(25, 2, 3, 'admin'),
(26, 3, 4, 'admin'),
(27, 1, 2, 'admin'),
(28, 4, 3, 'admin'),
(29, 2, 4, 'admin'),
(30, 3, 2, 'admin'),
(31, 1, 3, 'admin'),
(32, 4, 2, 'admin'),
(33, 2, 3, 'admin'),
(34, 3, 4, 'admin'),
(35, 1, 2, 'admin'),
(36, 4, 3, 'admin'),
(37, 2, 4, 'admin'),
(38, 3, 2, 'admin'),
(39, 1, 3, 'admin'),
(40, 4, 2, 'admin'),
(41, 2, 3, 'admin'),
(42, 3, 4, 'admin'),
(43, 1, 2, 'admin'),
(44, 4, 3, 'admin'),
(45, 2, 4, 'admin'),
(46, 3, 2, 'admin'),
(47, 1, 3, 'admin'),
(48, 4, 2, 'admin'),
(49, 2, 3, 'admin'),
(50, 3, 4, 'admin'),
(51, 1, 2, 'admin'),
(52, 4, 3, 'admin'),
(53, 2, 4, 'admin'),
(54, 3, 2, 'admin'),
(55, 1, 3, 'admin'),
(56, 4, 2, 'admin'),
(57, 2, 3, 'admin'),
(58, 3, 4, 'admin'),
(59, 1, 2, 'admin'),
(60, 4, 3, 'admin');
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

-- ============================================
-- ROLES Y PRIVILEGIOS
-- ============================================
CREATE ROLE IF NOT EXISTS rol_administrador;
CREATE ROLE IF NOT EXISTS rol_recepcionista;
CREATE ROLE IF NOT EXISTS rol_usuario;
CREATE ROLE IF NOT EXISTS rol_gerente_corporativo;
CREATE ROLE IF NOT EXISTS rol_contador;

-- Administrador del Coworking → Acceso total
GRANT ALL PRIVILEGES ON gestion_coworking.* TO rol_administrador;

-- Recepcionista → Registro de usuarios, asignación de membresías, gestión de reservas
GRANT SELECT, INSERT, UPDATE ON gestion_coworking.usuarios TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON gestion_coworking.membresias TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON gestion_coworking.reservas TO rol_recepcionista;
GRANT SELECT ON gestion_coworking.espacios TO rol_recepcionista;
GRANT SELECT ON gestion_coworking.registros_acceso TO rol_recepcionista;

-- Usuario → Reservar espacios, consultar historial, descargar facturas
GRANT SELECT ON gestion_coworking.espacios TO rol_usuario;
GRANT SELECT ON gestion_coworking.tipos_espacio TO rol_usuario;
GRANT INSERT ON gestion_coworking.reservas TO rol_usuario;
GRANT SELECT ON gestion_coworking.reservas TO rol_usuario;
GRANT SELECT ON gestion_coworking.facturas TO rol_usuario;
GRANT SELECT ON gestion_coworking.pagos TO rol_usuario;

-- Gerente Corporativo → Administrar empleados de su empresa, ver facturación consolidada
GRANT SELECT, INSERT, UPDATE ON gestion_coworking.usuarios TO rol_gerente_corporativo;
GRANT SELECT ON gestion_coworking.membresias TO rol_gerente_corporativo;
GRANT SELECT ON gestion_coworking.reservas TO rol_gerente_corporativo;
GRANT SELECT ON gestion_coworking.facturas TO rol_gerente_corporativo;
GRANT SELECT ON gestion_coworking.pagos TO rol_gerente_corporativo;

-- Contador → Gestión de ingresos y reportes financieros
GRANT SELECT ON gestion_coworking.facturas TO rol_contador;
GRANT SELECT ON gestion_coworking.pagos TO rol_contador;
GRANT SELECT ON gestion_coworking.resumenes_facturacion TO rol_contador;
GRANT SELECT, INSERT, UPDATE ON gestion_coworking.reportes_contabilidad TO rol_contador;

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




