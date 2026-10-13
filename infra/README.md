# Infraestructura

Servidor: Ubuntu 24.04 con PHP 8.3, Composer, PostgreSQL 17, Flutter y Nginx.

| Script | Uso |
|---|---|
| `provision-vm-sudo.sh` | Instala PHP 8.3 y Nginx, activa PostgreSQL 17 y crea la base `sigedoc` con su usuario. Requiere `sudo`; imprime las credenciales para el `.env` del backend. |
| `serve-app.sh` | Compila Flutter web y sirve la aplicación completa (interfaz + `/api`) en `127.0.0.1:8091`. |
| `dev-router.php` | Enrutador usado por `serve-app.sh`: `/api/*` → Laravel, resto → build de Flutter. |
| `serve-docs.sh` | Publica la documentación de `docs/` en la red privada (Tailscale). |

Despliegue de la aplicación:

```bash
bash infra/provision-vm-sudo.sh          # una vez, con sudo
cd backend && composer install && cp .env.example .env && php artisan key:generate
php artisan migrate --seed
cd .. && infra/serve-app.sh
```
