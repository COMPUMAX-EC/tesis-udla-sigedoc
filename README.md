# SIGEDOC · Sistema de Gestión Documental (VIALZACHIN E.P.)

Sistema híbrido (web + móvil) para la gestión, ubicación física y trazabilidad de
documentos institucionales mediante códigos QR. Desarrollado como parte del
Trabajo de Integración Curricular (Tesis UDLA).

## Stack

| Capa | Tecnología |
|---|---|
| Backend / API REST | Laravel 11 (PHP 8.3), patrón MVC |
| Frontend web + móvil | Flutter (codebase único) |
| Base de datos | PostgreSQL 17 |
| Autenticación | Laravel Sanctum, roles: Administrador / Responsable del archivo / Funcionario departamental |
| Comunicación | HTTPS + REST (JSON) |

Arquitectura cliente-servidor documentada con el Modelo C4 (contexto → contenedores →
componentes). Detalle completo en [`docs/arquitectura.md`](docs/arquitectura.md).

## Estructura del repositorio

```
backend/     API REST en Laravel (lógica de negocio, migraciones, seeders)
frontend/    Aplicación Flutter (web + Android)
docs/        Requisitos, diccionario de datos, arquitectura, backlog
infra/       Scripts de aprovisionamiento y despliegue (VM)
```

## Módulos funcionales

| Código | Módulo | Resumen |
|---|---|---|
| M01 | Gestión de usuarios | Login, usuarios, roles, departamentos |
| M02 | Gestión documental | Registro, clasificación, ubicación, consulta de documentos |
| M03 | Gestión QR | Generación, impresión y lectura de códigos QR |
| M04 | Préstamos | Solicitud, autorización, entrega, devolución |
| M05 | Trazabilidad | Historial de movimientos y ubicación |
| M06 | Reportes | Documentos, préstamos, movimientos |

Especificación completa de requisitos funcionales/no funcionales:
[`docs/requisitos.md`](docs/requisitos.md). Backlog priorizado por sprint:
[`docs/product-backlog.md`](docs/product-backlog.md).

## Entorno de desarrollo (VM vía SSH)

El desarrollo se realiza sobre una VM Ubuntu accesible por Tailscale/SSH.
Aprovisionamiento inicial: [`infra/provision-vm.sh`](infra/provision-vm.sh).

```bash
ssh ciit@100.64.139.1
cd ~/tesis-udla-sigedoc
```

Backend:
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Frontend:
```bash
cd frontend
flutter pub get
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=5000
```

## Licencia

Uso académico — Trabajo de Integración Curricular, UDLA.
