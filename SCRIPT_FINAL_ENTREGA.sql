-- =====================================================
-- SISTEMA DE GESTIÓN DE TICKETS (BASE DE DATOS ÚNICA)
-- Arquitectura de Microservicios:
-- 1. auth-service
-- 2. tecnico-service
-- 3. ticket-service
-- NOTA: La carga de archivos/adjuntos queda fuera del alcance de la versión 1.0
-- y se contempla para una versión 2.0.
-- =====================================================

DROP DATABASE IF EXISTS db_tickets;

CREATE DATABASE IF NOT EXISTS db_tickets
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE db_tickets;

-- =====================================================
-- 1. MÓDULO: AUTENTICACIÓN (Microservicio: auth-service)
-- =====================================================

-- TABLA 1: roles
CREATE TABLE IF NOT EXISTS roles (
    id_rol INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- TABLA 2: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    telefono VARCHAR(9),
    id_rol INT UNSIGNED NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
) ENGINE=InnoDB;


-- =====================================================
-- 2. MÓDULO: SOPORTE TÉCNICO (Microservicio: tecnico-service)
-- =====================================================

-- TABLA 3: especialidades
CREATE TABLE IF NOT EXISTS especialidades (
    id_especialidad INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- TABLA 4: tecnicos
CREATE TABLE IF NOT EXISTS tecnicos (
    id_tecnico INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- Referencia lógica al usuario de auth-service (vía FeignClient)
    id_usuario INT UNSIGNED NOT NULL UNIQUE,

    id_especialidad INT UNSIGNED NOT NULL,
    disponibilidad VARCHAR(30) NOT NULL DEFAULT 'DISPONIBLE',
    estado BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_tecnicos_especialidades
        FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad)
) ENGINE=InnoDB;


-- =====================================================
-- 3. MÓDULO: GESTIÓN DE TICKETS (Microservicio: ticket-service)
-- =====================================================

-- TABLA 5: categorias
CREATE TABLE IF NOT EXISTS categorias (
    id_categoria INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- TABLA 6: prioridades
CREATE TABLE IF NOT EXISTS prioridades (
    id_prioridad INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- TABLA 7: estados_ticket
CREATE TABLE IF NOT EXISTS estados_ticket (
    id_estado INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    orden INT NOT NULL
) ENGINE=InnoDB;

-- TABLA 8: tickets
CREATE TABLE IF NOT EXISTS tickets (
    id_ticket INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    codigo_ticket VARCHAR(30) NOT NULL UNIQUE,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,

    id_categoria INT UNSIGNED NOT NULL,
    id_prioridad INT UNSIGNED NOT NULL,
    id_estado INT UNSIGNED NOT NULL,

    -- Referencia lógica a auth-service
    id_usuario_creador INT UNSIGNED NOT NULL,

    -- Referencia lógica a tecnico-service
    id_tecnico_asignado INT UNSIGNED NULL,

    solucion TEXT NULL,

    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_asignacion DATETIME NULL,
    fecha_inicio_atencion DATETIME NULL,
    fecha_resolucion DATETIME NULL,
    fecha_cierre DATETIME NULL,

    fecha_actualizacion DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_tickets_categorias
        FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria),

    CONSTRAINT fk_tickets_prioridades
        FOREIGN KEY (id_prioridad)
        REFERENCES prioridades(id_prioridad),

    CONSTRAINT fk_tickets_estados
        FOREIGN KEY (id_estado)
        REFERENCES estados_ticket(id_estado),

    INDEX idx_tickets_usuario (id_usuario_creador),
    INDEX idx_tickets_tecnico (id_tecnico_asignado),
    INDEX idx_tickets_fecha (fecha_creacion)
) ENGINE=InnoDB;

-- TABLA 9: comentarios_ticket
CREATE TABLE IF NOT EXISTS comentarios_ticket (
    id_comentario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_ticket INT UNSIGNED NOT NULL,

    -- Referencia lógica a auth-service
    id_usuario INT UNSIGNED NOT NULL,

    comentario TEXT NOT NULL,
    fecha_comentario DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comentarios_tickets
        FOREIGN KEY (id_ticket)
        REFERENCES tickets(id_ticket),

    INDEX idx_comentarios_usuario (id_usuario)
) ENGINE=InnoDB;

-- TABLA 10: historial_ticket
CREATE TABLE IF NOT EXISTS historial_ticket (
    id_historial INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_ticket INT UNSIGNED NOT NULL,

    -- Referencia lógica a auth-service
    id_usuario INT UNSIGNED NOT NULL,

    accion VARCHAR(100) NOT NULL,
    estado_anterior INT UNSIGNED NULL,
    estado_nuevo INT UNSIGNED NULL,
    descripcion TEXT,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historial_tickets
        FOREIGN KEY (id_ticket)
        REFERENCES tickets(id_ticket),

    CONSTRAINT fk_historial_estado_anterior
        FOREIGN KEY (estado_anterior)
        REFERENCES estados_ticket(id_estado),

    CONSTRAINT fk_historial_estado_nuevo
        FOREIGN KEY (estado_nuevo)
        REFERENCES estados_ticket(id_estado),

    INDEX idx_historial_usuario (id_usuario)
) ENGINE=InnoDB;

-- =====================================================
-- INSERCIÓN DE DATOS INICIALES (SEED DATA)
-- =====================================================

-- 1. ROLES
INSERT INTO roles (id_rol, nombre, descripcion, estado) VALUES
(1, 'ADMIN', 'Administrador del sistema', 1),
(2, 'TECNICO', 'Personal de soporte técnico', 1),
(3, 'USUARIO', 'Usuario que registra tickets', 1);

-- 2. USUARIOS (Contraseña para todos: "password")
INSERT INTO usuarios (id_usuario, nombres, apellidos, correo, password, telefono, id_rol, estado) VALUES
(1, 'Administrador', 'General', 'admin@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999111111', 1, 1),
(2, 'Carlos', 'Ramirez', 'carlos@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999222222', 2, 1),
(3, 'Maria', 'Fernandez', 'maria@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999333333', 2, 1),
(4, 'Luis', 'Torres', 'luis@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999444444', 2, 1),
(5, 'Ana', 'Gutierrez', 'ana@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999555555', 2, 1),
(6, 'Pedro', 'Lopez', 'pedro@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999666666', 3, 1),
(7, 'Lucia', 'Martinez', 'lucia@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999777777', 3, 1),
(8, 'Jorge', 'Castillo', 'jorge@tickets.local', '$2a$10$ha5Ue0UTEFBTcbd4B6jhcOXSuBOmCQIojDFtC4SanWt810CNsJXzO', '999888888', 3, 1);

-- 3. ESPECIALIDADES
INSERT INTO especialidades (id_especialidad, nombre, descripcion, estado) VALUES
(1, 'Hardware', 'Reparación y mantenimiento de computadoras', 1),
(2, 'Software', 'Instalación y soporte de aplicaciones', 1),
(3, 'Redes', 'Conectividad, redes y comunicaciones', 1),
(4, 'Sistemas', 'Soporte de sistemas empresariales', 1),
(5, 'Impresoras', 'Instalación y mantenimiento de impresoras', 1);

-- 4. TECNICOS
INSERT INTO tecnicos (id_tecnico, id_usuario, id_especialidad, disponibilidad, estado) VALUES
(1, 2, 1, 'DISPONIBLE', 1),
(2, 3, 2, 'DISPONIBLE', 1),
(3, 4, 3, 'OCUPADO', 1),
(4, 5, 4, 'DISPONIBLE', 1);

-- 5. CATEGORIAS
INSERT INTO categorias (id_categoria, nombre, descripcion, estado) VALUES
(1, 'Hardware', 'Problemas con equipos físicos', 1),
(2, 'Software', 'Problemas con programas', 1),
(3, 'Redes', 'Problemas de conectividad', 1),
(4, 'Accesos', 'Problemas de usuarios y contraseñas', 1),
(5, 'Impresoras', 'Problemas de impresión y escaneo', 1),
(6, 'Sistemas', 'Problemas en sistemas internos', 1);

-- 6. PRIORIDADES
INSERT INTO prioridades (id_prioridad, nombre) VALUES
(1, 'BAJA'),
(2, 'MEDIA'),
(3, 'ALTA'),
(4, 'CRITICA');

-- 7. ESTADOS DEL TICKET
INSERT INTO estados_ticket (id_estado, nombre, descripcion, orden) VALUES
(1, 'CREADO', 'Ticket registrado sin asignar', 1),
(2, 'ASIGNADO', 'Ticket asignado a un técnico', 2),
(3, 'EN_PROCESO', 'Ticket en atención', 3),
(4, 'PENDIENTE', 'Ticket esperando información', 4),
(5, 'RESUELTO', 'Problema solucionado', 5),
(6, 'CERRADO', 'Ticket finalizado', 6),
(7, 'CANCELADO', 'Ticket cancelado', 7);

-- 8. TICKETS
INSERT INTO tickets (
    id_ticket, codigo_ticket, titulo, descripcion,
    id_categoria, id_prioridad, id_estado,
    id_usuario_creador, id_tecnico_asignado,
    solucion, fecha_creacion, fecha_asignacion,
    fecha_inicio_atencion, fecha_resolucion, fecha_cierre
) VALUES
(1, 'TK-2026-000001', 'Laptop no enciende', 'La laptop no responde al presionar el botón.', 1, 3, 3, 6, 1, NULL, '2026-10-01 08:30:00', '2026-10-01 09:00:00', '2026-10-01 09:30:00', NULL, NULL),
(2, 'TK-2026-000002', 'Error al abrir Excel', 'Excel muestra un error al iniciar.', 2, 2, 5, 7, 2, 'Se reparó la instalación de Office.', '2026-10-01 10:00:00', '2026-10-01 10:20:00', '2026-10-01 10:40:00', '2026-10-01 12:00:00', NULL),
(3, 'TK-2026-000003', 'Sin acceso a Internet', 'El equipo no tiene conexión a la red.', 3, 4, 3, 8, 3, NULL, '2026-10-02 08:00:00', '2026-10-02 08:10:00', '2026-10-02 08:20:00', NULL, NULL),
(4, 'TK-2026-000004', 'Olvido de contraseña', 'El usuario no recuerda su contraseña.', 4, 2, 6, 6, 4, 'Se restableció la contraseña.', '2026-10-02 09:00:00', '2026-10-02 09:10:00', '2026-10-02 09:20:00', '2026-10-02 09:40:00', '2026-10-02 10:00:00'),
(5, 'TK-2026-000005', 'Impresora no imprime', 'La impresora de contabilidad no responde.', 5, 3, 2, 7, 1, NULL, '2026-10-03 11:00:00', '2026-10-03 11:30:00', NULL, NULL, NULL),
(6, 'TK-2026-000006', 'Error en sistema contable', 'El sistema muestra un error al guardar.', 6, 4, 4, 8, 4, NULL, '2026-10-03 14:00:00', '2026-10-03 14:10:00', '2026-10-03 14:30:00', NULL, NULL),
(7, 'TK-2026-000007', 'Mouse no funciona', 'El mouse USB dejó de responder.', 1, 1, 1, 6, NULL, NULL, '2026-10-04 08:00:00', NULL, NULL, NULL, NULL),
(8, 'TK-2026-000008', 'Instalación de software', 'Solicito instalación de aplicación.', 2, 2, 2, 7, 2, NULL, '2026-10-04 09:00:00', '2026-10-04 09:15:00', NULL, NULL, NULL),
(9, 'TK-2026-000009', 'Problema con VPN', 'No puedo conectarme desde casa.', 3, 3, 5, 8, 3, 'Se actualizó la configuración de VPN.', '2026-10-05 10:00:00', '2026-10-05 10:15:00', '2026-10-05 10:30:00', '2026-10-05 11:00:00', NULL),
(10, 'TK-2026-000010', 'Cuenta bloqueada', 'La cuenta de dominio está bloqueada.', 4, 3, 6, 6, 4, 'Se desbloqueó la cuenta en Active Directory.', '2026-10-05 11:00:00', '2026-10-05 11:10:00', '2026-10-05 11:20:00', '2026-10-05 11:40:00', '2026-10-05 12:00:00');

-- 9. COMENTARIOS DE TICKETS
INSERT INTO comentarios_ticket (id_comentario, id_ticket, id_usuario, comentario, fecha_comentario) VALUES
(1, 1, 6, 'Mi laptop dejó de encender esta mañana.', '2026-10-01 08:35:00'),
(2, 1, 2, 'Revisaré el cargador y la batería.', '2026-10-01 09:35:00'),
(3, 2, 7, 'Excel no abre correctamente.', '2026-10-01 10:05:00'),
(4, 2, 3, 'La instalación ya fue reparada.', '2026-10-01 12:00:00'),
(5, 3, 8, 'No tengo Internet desde las 8.', '2026-10-02 08:05:00'),
(6, 3, 4, 'Estoy revisando la conexión.', '2026-10-02 08:25:00'),
(7, 4, 6, 'Necesito recuperar mi acceso.', '2026-10-02 09:05:00'),
(8, 4, 5, 'Su contraseña fue restablecida.', '2026-10-02 09:40:00'),
(9, 5, 7, 'La impresora sigue sin responder.', '2026-10-03 11:05:00'),
(10, 6, 8, 'El problema ocurre al guardar registros.', '2026-10-03 14:05:00'),
(11, 6, 5, 'Necesito una captura del error.', '2026-10-03 14:35:00'),
(12, 9, 4, 'Se corrigió la configuración VPN.', '2026-10-05 11:00:00');

-- 10. HISTORIAL DE TICKETS
INSERT INTO historial_ticket (id_historial, id_ticket, id_usuario, accion, estado_anterior, estado_nuevo, descripcion, fecha) VALUES
(1, 1, 6, 'CREACION', NULL, 1, 'Ticket registrado por el usuario.', '2026-10-01 08:30:00'),
(2, 1, 1, 'ASIGNACION', 1, 2, 'Ticket asignado a Carlos Ramirez.', '2026-10-01 09:00:00'),
(3, 1, 2, 'CAMBIO_ESTADO', 2, 3, 'Técnico inició la atención.', '2026-10-01 09:30:00'),
(4, 2, 7, 'CREACION', NULL, 1, 'Ticket registrado.', '2026-10-01 10:00:00'),
(5, 2, 3, 'RESOLUCION', 3, 5, 'Se reparó Office.', '2026-10-01 12:00:00'),
(6, 3, 8, 'CREACION', NULL, 1, 'Ticket de conectividad creado.', '2026-10-02 08:00:00'),
(7, 3, 4, 'CAMBIO_ESTADO', 2, 3, 'Se inició el diagnóstico de red.', '2026-10-02 08:20:00'),
(8, 4, 6, 'CREACION', NULL, 1, 'Solicitud de recuperación de contraseña.', '2026-10-02 09:00:00'),
(9, 4, 5, 'RESOLUCION', 3, 5, 'Contraseña restablecida.', '2026-10-02 09:40:00'),
(10, 4, 6, 'CIERRE', 5, 6, 'Usuario confirmó la solución.', '2026-10-02 10:00:00'),
(11, 5, 7, 'CREACION', NULL, 1, 'Problema de impresora registrado.', '2026-10-03 11:00:00'),
(12, 6, 5, 'CAMBIO_ESTADO', 3, 4, 'Esperando captura del error.', '2026-10-03 14:35:00'),
(13, 7, 6, 'CREACION', NULL, 1, 'Problema de mouse registrado.', '2026-10-04 08:00:00'),
(14, 9, 4, 'RESOLUCION', 3, 5, 'Conexión VPN restablecida.', '2026-10-05 11:00:00'),
(15, 10, 6, 'CIERRE', 5, 6, 'Se confirmó el desbloqueo.', '2026-10-05 12:00:00');

-- Verificar las 10 tablas creadas en la base de datos única
SHOW TABLES FROM db_tickets;