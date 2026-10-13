# Requisitos del sistema

Especificación de requisitos de SIGEDOC según la Tesis VHQP V1.8, Capítulo 3 (Tablas 10–13).

## Avance

Los requisitos funcionales se miden así: modelo de datos 15 % · API 35 % · interfaz 25 % ·
verificación con pruebas 25 %. Los no funcionales y las reglas de negocio, según la parte
ya aplicada en base de datos, API e interfaz. Un requisito está completo al llegar a 100 %.

| Grupo | Avance promedio |
|---|---|
| Requisitos funcionales (26) | 24 % |
| Requisitos no funcionales (7) | 29 % |
| Reglas de negocio (6) | 22 % |

## Requisitos funcionales

### M01 · Gestión de usuarios
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-01.1 | Iniciar sesión | Todos | Must | 75 % | Ejecutar migraciones en PostgreSQL y verificar con pruebas |
| RF-01.2 | Gestionar usuarios (crear, consultar, modificar, desactivar) | Administrador | Must | 75 % | Ejecutar migraciones en PostgreSQL y verificar con pruebas |
| RF-01.3 | Gestionar roles y permisos | Administrador | Must | 75 % | Ejecutar migraciones en PostgreSQL y verificar con pruebas |
| RF-01.4 | Gestionar departamentos | Administrador | Should | 75 % | Ejecutar migraciones en PostgreSQL y verificar con pruebas |
| RF-01.5 | Gestionar tipos documentales | Administrador | Must | 75 % | Ejecutar migraciones en PostgreSQL y verificar con pruebas |

### M02 · Gestión documental
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-02.1 | Registrar documento | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-02.2 | Clasificar documento (departamento + tipo documental) | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-02.3 | Asignar ubicación física | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-02.4 | Actualizar documento | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-02.5 | Consultar documento (búsqueda por criterios) | Responsable / Funcionario | Must | 15 % | API de búsqueda con filtros, pantalla y pruebas |

### M03 · Gestión QR
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-03.1 | Generar identificador único (UUID) | Aplicación | Must | 15 % | Generar el UUID al registrar el documento; pruebas |
| RF-03.2 | Generar código QR asociado al documento | Responsable del archivo | Must | 15 % | Endpoint que genera la imagen QR; pruebas |
| RF-03.3 | Imprimir etiqueta QR | Responsable del archivo | Must | 0 % | Vista de etiqueta imprimible |
| RF-03.4 | Leer código QR (app móvil) | Funcionario departamental | Must | 0 % | Pantalla móvil de escaneo con cámara |

### M04 · Gestión de préstamos
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-04.1 | Solicitar préstamo | Funcionario departamental | Must | 15 % | API, pantalla y pruebas |
| RF-04.2 | Autorizar o rechazar solicitud | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-04.3 | Registrar préstamo (entrega) | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-04.4 | Registrar devolución | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-04.5 | Registrar observación de devolución | Responsable del archivo | Should | 15 % | API, pantalla y pruebas |
| RF-04.6 | Actualizar estado del documento | Aplicación | Must | 15 % | Cambio automático de estado al prestar/devolver; pruebas |

### M05 · Trazabilidad
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-05.1 | Registrar movimiento | Aplicación | Must | 15 % | Registro automático en cada cambio de estado; pruebas |
| RF-05.2 | Consultar historial de préstamos y devoluciones | Responsable del archivo | Must | 15 % | API, pantalla y pruebas |
| RF-05.3 | Consultar ubicación física actual | Responsable / Funcionario | Must | 15 % | API, pantalla y pruebas |

### M06 · Reportes
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-06.1 | Reportar documentos registrados | Administrador / Responsable | Should | 0 % | Consulta, pantalla con filtros y pruebas |
| RF-06.2 | Reportar préstamos y devoluciones | Administrador / Responsable | Should | 0 % | Consulta, pantalla con filtros y pruebas |
| RF-06.3 | Reportar movimientos consolidados | Administrador / Responsable | Should | 0 % | Consulta, pantalla con filtros y pruebas |

## Requisitos no funcionales

| ID | Descripción | Atributo (ISO 9126) | Verificación | Avance | Falta |
|---|---|---|---|---|---|
| RNF-01 | Autenticación por credenciales y control de permisos según rol | Seguridad | Pruebas de acceso por rol | 60 % | Ejecutar las pruebas de acceso por rol |
| RNF-02 | Consulta de documentos en ≤ 3 s en condiciones normales | Eficiencia | Prueba de rendimiento (Cap. 5.3) | 0 % | Prueba de rendimiento sobre consulta de documentos |
| RNF-03 | Web en navegadores actuales; móvil en Android con cámara | Portabilidad | Pruebas en navegadores y dispositivo | 30 % | Web compila; falta probar en navegadores y en Android con cámara |
| RNF-04 | Integridad de datos: validaciones en la app + restricciones en BD | Fiabilidad | Migraciones con FK/unique/check + tests | 40 % | Restricciones en BD y validaciones de M01 hechas; faltan las de M02–M04 y pruebas |
| RNF-05 | Interfaz intuitiva, sin capacitación especializada | Usabilidad | Pruebas de usabilidad (Cap. 5.4) | 10 % | Interfaz de M01 lista; falta resto de módulos y pruebas de usabilidad |
| RNF-06 | Copias de respaldo de la base de datos | Fiabilidad | Script de backup + restauración probada | 0 % | Script de respaldo y prueba de restauración |
| RNF-07 | Web y móvil se comunican con el servidor solo por API REST | Interoperabilidad | Revisión de arquitectura / tests de API | 60 % | Arquitectura aplicada en web; falta verificar app móvil y pruebas de API |

## Reglas de negocio

| ID | Regla | Avance | Falta |
|---|---|---|---|
| RN-01 | Cada documento tiene un identificador único dentro del archivo institucional | 40 % | Restricción única en BD; falta lógica de registro y prueba |
| RN-02 | Cada documento tiene un único código QR | 40 % | Restricción única en BD; falta generación del QR y prueba |
| RN-03 | Solo se presta un documento cuyo estado sea Disponible | 10 % | Validación al solicitar préstamo; prueba |
| RN-04 | Un documento no puede tener más de un préstamo activo a la vez | 40 % | Índice único de préstamo activo en BD; falta validación en API y prueba |
| RN-05 | El estado se actualiza automáticamente al registrar préstamo o devolución | 0 % | Actualización automática de estado; prueba |
| RN-06 | El historial de préstamos y devoluciones se conserva y los usuarios no pueden eliminarlo | 0 % | Bloquear edición/eliminación del historial; prueba |

## Actores y roles

- **Administrador** — configuración, usuarios, roles, departamentos, tipos documentales.
- **Responsable del archivo (Secretaría)** — registro, clasificación, ubicación, QR,
  préstamos, devoluciones, trazabilidad, reportes.
- **Funcionario departamental** — consulta, escaneo QR, solicitud de préstamos.

## Estados de documento

`Disponible` ⇄ `Prestado` (el préstamo cambia a Prestado; la devolución vuelve a Disponible).
