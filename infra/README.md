# Aprovisionamiento de la VM

El aprovisionamiento se divide en dos partes porque el asistente no puede escribir
contraseñas de `sudo` en ninguna terminal, ni siquiera si el usuario la proporciona:

1. **`provision-vm-sudo.sh`** — la única parte que requiere `sudo` (instala PHP 8.3,
   deja activo solo el clúster PostgreSQL 17, crea la base `sigedoc`, instala Nginx).
   **Debe ejecutarla el usuario, interactivamente:**
   ```bash
   cd ~/tesis-udla-sigedoc
   bash infra/provision-vm-sudo.sh
   ```
   Al final imprime las credenciales de la base de datos — pégalas en el chat (o el
   `.env` resultante) para continuar.

2. Todo lo demás (Flutter SDK en `~/flutter`, Composer, `git clone`, scaffolding de
   Laravel/Flutter, migraciones) no requiere `sudo` y se ejecuta directamente por SSH.

Estado en la VM de desarrollo (`ciit@100.64.139.1`, Ubuntu 24.04, acceso vía
Tailscale):
- [x] Flutter 3.47.2 (stable) instalado en `~/flutter`, `enable-web` activado.
- [ ] PHP 8.3 + extensiones (pendiente — requiere `provision-vm-sudo.sh`).
- [ ] PostgreSQL 17 activo + base `sigedoc` (pendiente — requiere `provision-vm-sudo.sh`).
- [ ] Composer.
- [ ] Nginx configurado como reverse proxy (se hace en el sprint de despliegue).
