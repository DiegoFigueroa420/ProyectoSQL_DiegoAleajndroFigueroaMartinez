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