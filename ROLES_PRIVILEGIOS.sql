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