# Requisitos del sistema

Fuente: Tesis VHQP V1.8, Capítulo 3 (Análisis y Diseño). Resumen técnico para guiar
el desarrollo — la especificación narrativa completa está en el documento de tesis.

## Requisitos funcionales

### M01 · Gestión de usuarios
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-01.1 | Iniciar sesión | Todos |
| RF-01.2 | Gestionar usuarios (CRUD + activar/desactivar) | Administrador |
| RF-01.3 | Gestionar roles y permisos | Administrador |
| RF-01.4 | Gestionar departamentos | Administrador |

### M02 · Gestión documental
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-02.1 | Registrar documento | Responsable del archivo |
| RF-02.2 | Clasificar documento (departamento + tipo documental) | Responsable del archivo |
| RF-02.3 | Asignar ubicación física | Responsable del archivo |
| RF-02.4 | Actualizar documento | Responsable del archivo |
| RF-02.5 | Consultar documento (búsqueda por criterios) | Responsable del archivo / Funcionario |

### M03 · Gestión QR
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-03.1 | Generar identificador único (UUID) | Aplicación |
| RF-03.2 | Generar código QR asociado | Responsable del archivo |
| RF-03.3 | Imprimir etiqueta QR | Responsable del archivo |
| RF-03.4 | Leer código QR (app móvil) | Funcionario departamental |

### M04 · Gestión de préstamos
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-04.1 | Solicitar préstamo | Funcionario departamental |
| RF-04.2 | Autorizar/rechazar solicitud | Responsable del archivo |
| RF-04.3 | Registrar entrega del documento | Responsable del archivo |
| RF-04.4 | Registrar devolución | Responsable del archivo |
| RF-04.5 | Registrar observación de devolución | Responsable del archivo |
| RF-04.6 | Actualizar estado del documento | Aplicación |

### M05 · Trazabilidad
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-05.1 | Registrar movimiento | Aplicación |
| RF-05.2 | Consultar historial de préstamos/devoluciones | Responsable del archivo |
| RF-05.3 | Consultar ubicación física actual | Responsable del archivo / Funcionario |

### M06 · Reportes
| ID | Funcionalidad | Actor principal |
|---|---|---|
| RF-06.1 | Reportar documentos registrados | Administrador / Responsable del archivo |
| RF-06.2 | Reportar préstamos y devoluciones | Administrador / Responsable del archivo |
| RF-06.3 | Reportar movimientos consolidados | Administrador / Responsable del archivo |

## Requisitos no funcionales

| ID | Descripción | Atributo (ISO 9126) |
|---|---|---|
| RNF-01 | Autenticación por credenciales + control de acceso por rol | Seguridad |
| RNF-02 | Consulta de documentos ≤ 3s en condiciones normales | Eficiencia |
| RNF-03 | Web compatible con navegadores actuales; móvil compatible con Android + cámara | Portabilidad |
| RNF-04 | Integridad de datos vía validaciones de app + restricciones de BD | Fiabilidad |
| RNF-05 | Interfaz intuitiva, sin capacitación especializada | Usabilidad |
| RNF-06 | Backups periódicos de la base de datos | Fiabilidad (recuperabilidad) |
| RNF-07 | Comunicación web/móvil ↔ servidor exclusivamente vía API REST | Interoperabilidad |

## Actores y roles del sistema

- **Administrador** — configuración general, usuarios, roles, departamentos.
- **Responsable del archivo (Secretaría)** — registro, clasificación, ubicación,
  préstamos, devoluciones, trazabilidad, reportes.
- **Funcionario departamental** — consulta documentos, escanea QR, solicita préstamos.

## Reglas de negocio clave

- Un documento no puede prestarse si su estado no es "disponible".
- Cada documento tiene un identificador único (UUID) no predecible para el QR —
  evita enumeración/adivinación de documentos por URL.
- Toda transición de estado de un documento debe generar un registro en `movimiento`.
- El préstamo y la devolución son operaciones distintas: la devolución no reutiliza
  el registro de préstamo, lo actualiza (`fecha_devolucion_real`, `estado`).
