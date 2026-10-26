# Requisitos del sistema

Especificación de requisitos de SIGEDOC según la Tesis VHQP V1.8, Capítulo 3 (Tablas 10–13).

## Avance

Los requisitos funcionales se miden así: modelo de datos 15 % · API 35 % · interfaz 25 % ·
verificación con pruebas 25 %. Los no funcionales y las reglas de negocio, según la parte
ya aplicada en base de datos, API e interfaz. Un requisito está completo al llegar a 100 %.

**Estado al 2026-10-20:** los módulos M01–M06 están programados (API, interfaz y pruebas automáticas escritas),
pero **todavía no se han ejecutado** las migraciones ni las pruebas contra PostgreSQL, por eso ningún
requisito supera el 75 %. Pasa a 100 % solo cuando su prueba automática o manual se ejecuta y aprueba
(ver [plan-de-pruebas.md](plan-de-pruebas.md)).

| Grupo | Avance promedio |
|---|---|
| Requisitos funcionales (26) | 75 % |
| Requisitos no funcionales (7) | 54 % |
| Reglas de negocio (6) | 75 % |

## Requisitos funcionales

### M01 · Gestión de usuarios
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-01.1 | Iniciar sesión | Todos | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar con pruebas |
| RF-01.2 | Gestionar usuarios (crear, consultar, modificar, desactivar) | Administrador | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar con pruebas |
| RF-01.3 | Gestionar roles y permisos | Administrador | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar con pruebas |
| RF-01.4 | Gestionar departamentos | Administrador | Should | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar con pruebas |
| RF-01.5 | Gestionar tipos documentales | Administrador | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar con pruebas |

### M02 · Gestión documental
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-02.1 | Registrar documento | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-02.2 | Clasificar documento (departamento + tipo documental) | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-02.3 | Asignar ubicación física | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-02.4 | Actualizar documento | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-02.5 | Consultar documento (búsqueda por criterios) | Responsable / Funcionario | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |

### M03 · Gestión QR
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-03.1 | Generar identificador único (UUID) | Aplicación | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-03.2 | Generar código QR asociado al documento | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-03.3 | Imprimir etiqueta QR | Responsable del archivo | Must | 75 % | Ejecutar pruebas y verificar la impresión de la etiqueta |
| RF-03.4 | Leer código QR (app móvil) | Funcionario departamental | Must | 75 % | Ejecutar pruebas y verificar el escaneo con cámara (Android y navegador) |

### M04 · Gestión de préstamos
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-04.1 | Solicitar préstamo | Funcionario departamental | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-04.2 | Autorizar o rechazar solicitud | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-04.3 | Registrar préstamo (entrega) | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-04.4 | Registrar devolución | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-04.5 | Registrar observación de devolución | Responsable del archivo | Should | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-04.6 | Actualizar estado del documento | Aplicación | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |

### M05 · Trazabilidad
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-05.1 | Registrar movimiento | Aplicación | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-05.2 | Consultar historial de préstamos y devoluciones | Responsable del archivo | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-05.3 | Consultar ubicación física actual | Responsable / Funcionario | Must | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |

### M06 · Reportes
| ID | Funcionalidad | Actor | Prioridad | Avance | Falta |
|---|---|---|---|---|---|
| RF-06.1 | Reportar documentos registrados | Administrador / Responsable | Should | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-06.2 | Reportar préstamos y devoluciones | Administrador / Responsable | Should | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |
| RF-06.3 | Reportar movimientos consolidados | Administrador / Responsable | Should | 75 % | Ejecutar migraciones y pruebas en PostgreSQL y verificar la pantalla en el navegador |

## Requisitos no funcionales

| ID | Descripción | Atributo (ISO 9126) | Verificación | Avance | Falta |
|---|---|---|---|---|---|
| RNF-01 | Autenticación por credenciales y control de permisos según rol | Seguridad | Pruebas de acceso por rol | 75 % | Ejecutar las pruebas de acceso por rol (AutenticacionTest) |
| RNF-02 | Consulta de documentos en ≤ 3 s en condiciones normales | Eficiencia | Prueba de rendimiento (Cap. 5.3) | 40 % | Índices creados y prueba con 5 000 documentos escrita; falta ejecutarla y medir |
| RNF-03 | Web en navegadores actuales; móvil en Android con cámara | Portabilidad | Pruebas en navegadores y dispositivo | 30 % | Web compila; falta probar en navegadores y en Android con cámara |
| RNF-04 | Integridad de datos: validaciones en la app + restricciones en BD | Fiabilidad | Migraciones con FK/unique/check + tests | 70 % | Restricciones CHECK/UNIQUE/triggers y validaciones de M01–M06 hechas; falta ejecutar pruebas |
| RNF-05 | Interfaz intuitiva, sin capacitación especializada | Usabilidad | Pruebas de usabilidad (Cap. 5.4) | 30 % | Interfaz de todos los módulos lista; faltan las pruebas de usabilidad con usuarios reales |
| RNF-06 | Copias de respaldo de la base de datos | Fiabilidad | Script de backup + restauración probada | 60 % | Scripts backup-db.sh y restore-db.sh escritos; falta programarlos y probar una restauración |
| RNF-07 | Web y móvil se comunican con el servidor solo por API REST | Interoperabilidad | Revisión de arquitectura / tests de API | 75 % | Todo el flujo web usa solo la API REST; falta verificar la app móvil y ejecutar pruebas de API |

## Reglas de negocio

| ID | Regla | Avance | Falta |
|---|---|---|---|
| RN-01 | Cada documento tiene un identificador único dentro del archivo institucional | 75 % | Código único (UNIQUE + generador) implementado; falta ejecutar la prueba |
| RN-02 | Cada documento tiene un único código QR | 75 % | UNIQUE en codigo_qr.id_documento; falta ejecutar la prueba |
| RN-03 | Solo se presta un documento cuyo estado sea Disponible | 75 % | Validación al solicitar y entregar; falta ejecutar la prueba |
| RN-04 | Un documento no puede tener más de un préstamo activo a la vez | 75 % | Índice parcial único + validación en API; falta ejecutar la prueba |
| RN-05 | El estado se actualiza automáticamente al registrar préstamo o devolución | 75 % | Cambio automático de estado en el servicio de préstamos; falta ejecutar la prueba |
| RN-06 | El historial de préstamos y devoluciones se conserva y los usuarios no pueden eliminarlo | 75 % | Trigger de PostgreSQL y sin rutas de borrado; falta ejecutar la prueba |

## Actores y roles

- **Administrador** — configuración, usuarios, roles, departamentos, tipos documentales.
- **Responsable del archivo (Secretaría)** — registro, clasificación, ubicación, QR,
  préstamos, devoluciones, trazabilidad, reportes.
- **Funcionario departamental** — consulta, escaneo QR, solicitud de préstamos.

## Estados de documento

`Disponible` ⇄ `Prestado` (el préstamo cambia a Prestado; la devolución vuelve a Disponible).
