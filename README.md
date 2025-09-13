Sistema de Gestión de Coworking - Base de Datos
Descripción del Proyecto

Este proyecto consiste en una base de datos completa para gestionar un espacio de coworking. El sistema permite administrar usuarios, empresas, membresías, reservas de espacios, servicios adicionales, facturación y control de accesos.

La base de datos está diseñada para automatizar procesos como la renovación de membresías, verificación de disponibilidad de espacios, gestión de pagos y control de acceso mediante triggers, procedimientos almacenados y eventos programados.

Funcionalidades principales:

    Gestión de usuarios y empresas

    Control de membresías y sus renovaciones

    Sistema de reservas de espacios con verificación de disponibilidad

    Facturación y sistema de pagos

    Control de accesos y asistencias

    Servicios adicionales

    Reportes y analytics

Requisitos del Sistema

    MySQL Server 8.0 o superior

    MySQL Workbench o cliente similar

    Mínimo 2GB de RAM recomendado

    500MB de espacio en disco

Instalación y Configuración
1. Configuración inicial
bash

# Conectarse a MySQL
mysql -u root -p

# Crear la base de datos
CREATE DATABASE gestion_coworking;
USE gestion_coworking;

2. Ejecutar el script DDL
bash

# Ejecutar el script completo
mysql -u root -p gestion_coworking < script_completo.sql

3. Cargar datos iniciales

El script incluye todos los datos de ejemplo necesarios para probar el sistema:

    8 empresas

    60 usuarios

    4 tipos de membresía

    60 membresías con diferentes estados

    60 espacios de trabajo

    50 servicios adicionales

    100 reservas

    150 servicios asociados a reservas

    100 facturas y pagos

    150 registros de acceso

4. Ejecutar consultas y procedimientos
sql

-- Ejemplo de consulta
SELECT * FROM usuarios WHERE empresa_id = 1;

-- Ejemplo de procedimiento almacenado
CALL sp_verificar_disponibilidad(1, '2024-01-15 09:00:00', '2024-01-15 17:00:00', @disponible);
SELECT @disponible;

Estructura de la Base de Datos
Tablas Principales

    empresas: Almacena información de las empresas que utilizan el coworking

    usuarios: Datos de los usuarios individuales del sistema

    membresias: Control de membresías de los usuarios

    tipos_membresia: Catálogo de tipos de membresía disponibles

    espacios: Espacios físicos disponibles para reservar

    tipos_espacio: Categorización de los espacios (escritorio, oficina, sala reuniones, etc.)

    reservas: Registro de reservas de espacios

    servicios: Catálogo de servicios adicionales

    servicios_reserva: Relación entre reservas y servicios contratados

    facturas: Sistema de facturación

    pagos: Registro de pagos realizados

    registros_acceso: Control de entradas y salidas del coworking

Tablas de Soporte

    bloqueos_servicio: Usuarios bloqueados por impagos

    log_auditoria_membresia: Histórico de cambios en membresías

    notificaciones: Sistema de notificaciones a usuarios

    reportes_administrador: Reportes generados automáticamente

    alertas_recepcion: Alertas para el personal de recepción

    resumenes_facturacion: Resúmenes financieros

    reportes_contabilidad: Reportes para el departamento contable

    alertas_administrador: Alertas para administradores

    accesos_denegados: Registro de intentos de acceso denegados

Ejemplos de Consultas
Consultas Básicas
sql

-- Usuarios con membresía activa
SELECT u.nombre, u.apellido, m.fecha_fin 
FROM usuarios u 
JOIN membresias m ON u.usuario_id = m.usuario_id 
WHERE m.estado = 'Activa';

-- Reservas para hoy
SELECT u.nombre, e.nombre as espacio, r.inicio, r.fin 
FROM reservas r 
JOIN usuarios u ON r.usuario_id = u.usuario_id 
JOIN espacios e ON r.espacio_id = e.espacio_id 
WHERE DATE(r.inicio) = CURDATE();

Consultas Avanzadas
sql

-- Ingresos por mes y tipo
SELECT YEAR(pagado_en) as año, MONTH(pagado_en) as mes, 
f.tipo, SUM(p.monto) as ingresos 
FROM pagos p 
JOIN facturas f ON p.factura_id = f.factura_id 
WHERE p.estado = 'Pagado' 
GROUP BY YEAR(pagado_en), MONTH(pagado_en), f.tipo;

-- Ocupación de espacios por hora
SELECT e.nombre, HOUR(r.inicio) as hora, COUNT(r.reserva_id) as reservas 
FROM reservas r 
JOIN espacios e ON r.espacio_id = e.espacio_id 
WHERE r.estado = 'Confirmada' 
GROUP BY e.espacio_id, HOUR(r.inicio);

Procedimientos, Funciones, Triggers y Eventos
Funciones (15)

    fn_membresia_activa(p_usuario_id): Verifica si un usuario tiene membresía activa

    fn_dias_restantes_membresia(p_usuario_id): Calcula días restantes de membresía

    fn_total_reservas(p_usuario_id): Cuenta reservas de un usuario

    fn_total_pagado(p_usuario_id): Calcula total pagado por un usuario

    fn_total_asistencias(p_usuario_id): Cuenta asistencias de un usuario

Procedimientos Almacenados (20)

    sp_registrar_membresia: Crea una nueva membresía

    sp_verificar_disponibilidad: Verifica disponibilidad de espacios

    sp_crear_reserva: Crea una nueva reserva con validación

    sp_generar_factura_membresia: Genera factura por membresía

    sp_registrar_acceso_entrada: Registra entrada de usuarios

Triggers (20)

    trg_antes_insertar_membresia: Establece fecha fin automáticamente

    trg_antes_insertar_reservas: Valida que no haya conflictos de reserva

    trg_despues_insertar_pagos: Actualiza estado de facturas al pagar

    trg_antes_insertar_registros_acceso: Valida acceso según membresía/reserva

Eventos (20)

    ev_actualizar_membresias_vencidas: Actualiza membresías vencidas diariamente

    ev_enviar_recordatorio_renovacion: Envía recordatorios de renovación

    ev_cancelar_reservas_pendientes: Cancela reservas pendientes cada 10 minutos

    ev_enviar_recordatorio_pago: Envía recordatorios de pago cada 3 días

    ev_generar_resumen_facturacion_mensual: Genera resumen financiero mensual

Roles de Usuario y Permisos
1. rol_administrador

Acceso completo a toda la base de datos. Puede realizar cualquier operación.
2. rol_recepcionista

    SELECT, INSERT, UPDATE en: usuarios, membresias, reservas

    SELECT en: espacios, registros_acceso

    Gestiona registros de usuarios, asignación de membresías y reservas

3. rol_usuario

    SELECT en: espacios, tipos_espacio, reservas, facturas, pagos

    INSERT en: reservas

    Puede reservar espacios y consultar su información

4. rol_gerente_corporativo

    SELECT, INSERT, UPDATE en: usuarios

    SELECT en: membresias, reservas, facturas, pagos

    Gestiona empleados de su empresa y consulta información corporativa

5. rol_contador

    SELECT en: facturas, pagos, resumenes_facturacion

    SELECT, INSERT, UPDATE en: reportes_contabilidad

    Acceso a información financiera y reportes

Cómo crear usuarios y asignar roles
sql

-- Crear usuario
CREATE USER 'nuevo_usuario'@'localhost' IDENTIFIED BY 'password';

-- Asignar rol
GRANT rol_recepcionista TO 'nuevo_usuario'@'localhost';

-- Activar roles
SET DEFAULT ROLE rol_recepcionista TO 'nuevo_usuario'@'localhost';

Contribuciones

Este proyecto fue desarrollado como parte de un ejercicio académico. Las contribuciones incluyen:

    Diseño de la base de datos y modelado de tablas

    Implementación de scripts DDL y DML

    Desarrollo de funciones, procedimientos almacenados y triggers

    Creación de eventos programados

    Definición de roles y permisos

    Documentación completa del sistema

