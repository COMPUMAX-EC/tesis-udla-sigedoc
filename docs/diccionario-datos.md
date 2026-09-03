# Diccionario de datos (modelo físico)

Fuente: Tesis VHQP V1.8, Tablas 33–46. Motor: PostgreSQL 17.

> **Nota de implementación:** en la tesis, la Tabla 41 ("Archivo_digital") repite casi
> literalmente los campos de la tabla `documento` (incluyendo `id_categoria` renombrado
> a `id_tipo_documental`), lo cual es inconsistente con su propósito declarado
> (archivo digital adjunto a un documento). Se interpreta aquí como el adjunto/escaneo
> digital de un `documento` — ver sección al final. Ajustar si el director de tesis
> aclara lo contrario.

## rol
| Campo | Tipo | Restricción |
|---|---|---|
| id_rol | BIGSERIAL | PK |
| nombre | VARCHAR(50) | único, not null |
| descripcion | VARCHAR(200) | opcional |
| estado | BOOLEAN | not null |

## usuario
| Campo | Tipo | Restricción |
|---|---|---|
| id_usuario | BIGSERIAL | PK |
| id_rol | BIGINT | FK → rol |
| id_departamento | BIGINT | FK → departamento |
| nombres | VARCHAR(100) | not null |
| apellidos | VARCHAR(100) | not null |
| correo | VARCHAR(150) | único |
| nombre_usuario | VARCHAR(50) | único |
| clave_hash | VARCHAR(255) | not null |
| estado | BOOLEAN | not null |
| fecha_creacion | TIMESTAMP | not null |
| ultimo_acceso | TIMESTAMP | opcional |

## departamento
| Campo | Tipo | Restricción |
|---|---|---|
| id_departamento | BIGSERIAL | PK |
| nombre | VARCHAR(100) | único |
| descripcion | VARCHAR(200) | opcional |
| estado | BOOLEAN | not null |

## tipo_documental
| Campo | Tipo | Restricción |
|---|---|---|
| id_tipo_documental | BIGSERIAL | PK |
| id_departamento | BIGINT | FK → departamento |
| nombre | VARCHAR(100) | not null |
| descripcion | VARCHAR(200) | opcional |
| estado | BOOLEAN | not null |

## categoria
| Campo | Tipo | Restricción |
|---|---|---|
| id_categoria | BIGSERIAL | PK |
| nombre | VARCHAR(100) | único |
| descripcion | VARCHAR(250) | opcional |
| estado | BOOLEAN | not null |

## ubicacion
| Campo | Tipo | Restricción |
|---|---|---|
| id_ubicacion | BIGSERIAL | PK |
| area | VARCHAR(100) | not null |
| archivador | VARCHAR(50) | opcional |
| estante | VARCHAR(50) | opcional |
| seccion | VARCHAR(50) | opcional |
| caja | VARCHAR(50) | opcional |
| descripcion | VARCHAR(250) | opcional |
| estado | BOOLEAN | not null |

## documento
| Campo | Tipo | Restricción |
|---|---|---|
| id_documento | BIGSERIAL | PK |
| id_categoria | BIGINT | FK → categoria |
| id_tipo_documental | BIGINT | FK → tipo_documental |
| id_ubicacion | BIGINT | FK → ubicacion |
| creado_por | BIGINT | FK → usuario |
| codigo_documental | VARCHAR(50) | único |
| titulo | VARCHAR(200) | not null |
| descripcion | TEXT | opcional |
| fecha_documento | DATE | opcional |
| nivel_acceso | VARCHAR(30) | not null |
| estado | VARCHAR(30) | not null — p.ej. `disponible`, `prestado`, `de_baja` |
| fecha_registro | TIMESTAMP | not null |
| fecha_actualizacion | TIMESTAMP | not null |

## codigo_qr
| Campo | Tipo | Restricción |
|---|---|---|
| id_qr | BIGSERIAL | PK |
| id_documento | BIGINT | FK → documento |
| identificador | UUID | único, no predecible |
| contenido | VARCHAR(500) | not null |
| ruta_imagen | VARCHAR(500) | opcional |
| fecha_generacion | TIMESTAMP | not null |
| estado | BOOLEAN | not null |

## archivo_digital (adjunto digital de un documento)
| Campo | Tipo | Restricción |
|---|---|---|
| id_archivo | BIGSERIAL | PK |
| id_documento | BIGINT | FK → documento |
| nombre_archivo | VARCHAR(200) | not null |
| ruta_archivo | VARCHAR(500) | not null |
| tipo_mime | VARCHAR(100) | opcional |
| tamano_bytes | BIGINT | opcional |
| subido_por | BIGINT | FK → usuario |
| fecha_carga | TIMESTAMP | not null |

## solicitud_prestamo
| Campo | Tipo | Restricción |
|---|---|---|
| id_solicitud | BIGSERIAL | PK |
| id_documento | BIGINT | FK → documento |
| id_solicitante | BIGINT | FK → usuario |
| fecha_solicitud | TIMESTAMP | not null |
| motivo | VARCHAR(250) | opcional |
| estado | VARCHAR(20) | not null — `pendiente`, `aprobada`, `rechazada` |
| observacion | VARCHAR(250) | opcional |

## prestamo
| Campo | Tipo | Restricción |
|---|---|---|
| id_prestamo | BIGSERIAL | PK |
| id_documento | BIGINT | FK → documento |
| id_solicitud | BIGINT | FK → solicitud_prestamo |
| entregado_por | BIGINT | FK → usuario |
| recibido_por | BIGINT | FK → usuario |
| fecha_entrega | TIMESTAMP | not null |
| fecha_devolucion_prevista | TIMESTAMP | not null |
| fecha_devolucion_real | TIMESTAMP | opcional |
| observacion | VARCHAR(250) | opcional |
| estado | VARCHAR(20) | not null — `activo`, `devuelto`, `vencido` |

## movimiento
| Campo | Tipo | Restricción |
|---|---|---|
| id_movimiento | BIGSERIAL | PK |
| id_documento | BIGINT | FK → documento |
| id_usuario | BIGINT | FK → usuario |
| id_prestamo | BIGINT | FK → prestamo (opcional) |
| tipo_movimiento | VARCHAR(50) | not null |
| descripcion | VARCHAR(250) | opcional |
| estado_anterior | VARCHAR(20) | opcional |
| estado_nuevo | VARCHAR(20) | opcional |
| fecha_movimiento | TIMESTAMP | not null |
| direccion_ip | VARCHAR(45) | opcional |
