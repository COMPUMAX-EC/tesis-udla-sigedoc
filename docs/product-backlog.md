# Product Backlog (Scrum)

Backlog priorizado por sprint, derivado de los requisitos funcionales (RF) del
Capítulo 3 de la tesis. Cada sprint entrega un incremento funcional evaluable.

## Sprint 0 — Fundacional (infraestructura + esqueleto)
- Provisionar VM (PHP, Composer, PostgreSQL, Flutter, Nginx).
- Crear proyecto Laravel (`backend/`) con Sanctum, conexión a PostgreSQL.
- Crear proyecto Flutter (`frontend/`) con soporte web + Android habilitado.
- Migraciones de las 12 tablas del diccionario de datos + seeders de catálogo
  (roles, departamentos, tipos documentales).
- CI básico (lint + test) en GitHub Actions.

## Sprint 1 — M01 Gestión de usuarios (RF-01.x)
- Auth (login/logout) con Sanctum, tokens por dispositivo.
- Middleware de autorización por rol (Administrador / Responsable del archivo /
  Funcionario).
- CRUD de usuarios, roles y departamentos (solo Administrador).
- Pantallas Flutter: login, panel principal (según wireframes Figuras 34–35).

## Sprint 2 — M02 Gestión documental (RF-02.x)
- CRUD de `documento` (registrar, clasificar, ubicar, actualizar).
- Búsqueda/consulta con filtros (categoría, departamento, estado, ubicación).
- Pantalla Flutter: listado documental (wireframe Figura 36).

## Sprint 3 — M03 Gestión QR (RF-03.x)
- Generación de `identificador` UUID + `codigo_qr` al registrar un documento.
- Generación de imagen QR (endpoint que devuelve PNG/SVG imprimible).
- Endpoint de resolución: QR → datos del documento.
- Pantalla Flutter móvil: escaneo QR (wireframe Figura 37) usando cámara.

## Sprint 4 — M04 Préstamos (RF-04.x)
- Solicitud de préstamo (funcionario).
- Autorización/rechazo (responsable del archivo).
- Registro de entrega y devolución, con observaciones.
- Regla de negocio: bloquear solicitud si el documento no está `disponible`.
- Actualización automática de `estado` del documento (RF-04.6).

## Sprint 5 — M05 Trazabilidad (RF-05.x)
- Registro automático de `movimiento` en cada transición de estado.
- Consulta de historial de préstamos/devoluciones por documento.
- Consulta de ubicación física actual.

## Sprint 6 — M06 Reportes + cierre
- Reportes: documentos, préstamos/devoluciones, movimientos consolidados
  (filtrables por rango de fechas / departamento).
- Backups automatizados de PostgreSQL (RNF-06).
- Pruebas funcionales, de rendimiento (RNF-02: consultas ≤3s) y de usabilidad.
- Despliegue final en la VM (Nginx + TLS).

## Fuera de alcance (explícito)
- Integraciones externas (firma electrónica, gestores documentales de terceros).
- Notificaciones push/email (no está en los RF actuales — evaluar como mejora futura,
  según sección "Recomendaciones" de la tesis).
