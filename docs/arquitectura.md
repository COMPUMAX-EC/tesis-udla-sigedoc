# Arquitectura

Fuente: Tesis VHQP V1.8, sección 3.5 (Modelo C4).

## Nivel 1 — Contexto

Tres actores humanos (Administrador, Responsable del archivo, Funcionario
departamental) interactúan únicamente con el sistema de gestión documental; no hay
integraciones externas contempladas en el alcance actual.

## Nivel 2 — Contenedores

- **Aplicación web (Flutter web)** — administración: usuarios, documentos, préstamos,
  reportes.
- **Aplicación móvil (Flutter/Android)** — lectura de QR y consulta rápida.
- **API REST (Laravel)** — lógica de negocio, autenticación (Sanctum), orquesta acceso
  a datos y archivos. Único punto de acceso a la base de datos.
- **PostgreSQL** — almacenamiento relacional.
- **Repositorio de archivos** — almacenamiento de adjuntos digitales (filesystem local
  en la VM inicialmente; `Storage` de Laravel permite migrar a S3-compatible después).

Regla de diseño: los clientes (web/móvil) **nunca** acceden directamente a PostgreSQL
ni al filesystem — todo pasa por la API REST sobre HTTPS.

## Nivel 3 — Componentes (dentro de la API Laravel)

| Componente | Responsabilidad | Módulo RF |
|---|---|---|
| Gestión de usuarios | Auth, usuarios, roles, departamentos | M01 |
| Gestión documental | CRUD documento, clasificación, ubicación | M02 |
| Gestión de códigos QR | Generar/imprimir/resolver QR | M03 |
| Gestión de préstamos | Solicitudes, autorización, entrega, devolución | M04 |
| Trazabilidad | Registro y consulta de movimientos | M05 |
| Reportes | Consultas consolidadas | M06 |
| Acceso a datos | Eloquent ORM sobre PostgreSQL | — |
| Gestión de archivos | Adjuntos digitales vía `Storage` | — |

Mapeo sugerido a Laravel: cada componente ≈ un `Controller` + `Service` + conjunto de
`Model`s Eloquent bajo `app/Domain/<Componente>` o `app/Http/Controllers/Api/`.

## Infraestructura de despliegue

Cliente-servidor sobre una única VM inicialmente:

```
[Flutter web (build estático)] ─┐
                                 ├─ Nginx (reverse proxy, TLS) ─ PHP-FPM (Laravel API) ─ PostgreSQL
[App móvil Android] ──HTTPS────┘                                        └─ storage/app (archivos)
```

- Nginx sirve el build estático de Flutter web y hace proxy de `/api/*` al backend
  Laravel (PHP-FPM).
- La app móvil consume la misma API REST vía HTTPS.
- PostgreSQL y el filesystem de adjuntos quedan detrás del backend, sin exposición
  directa (cumple RNF-01/RNF-07).

Ver [`infra/`](../infra) para los scripts de aprovisionamiento de la VM.
