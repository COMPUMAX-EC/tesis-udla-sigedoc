#!/usr/bin/env bash
# Parte del aprovisionamiento que REQUIERE sudo (contraseña interactiva).
# Ejecutar UNA vez en la VM:
#
#   cd ~/tesis-udla-sigedoc && bash infra/provision-vm-sudo.sh
#
# Todo lo que NO requiere sudo (Flutter SDK, Composer, git clone) se hace
# aparte, sin intervención manual.
set -euo pipefail

echo "==> Actualizando índices de paquetes"
sudo apt-get update -y

echo "==> Instalando PHP 8.3 + extensiones requeridas por Laravel"
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update -y
sudo apt-get install -y \
  php8.3 php8.3-cli php8.3-fpm php8.3-common \
  php8.3-pgsql php8.3-mbstring php8.3-xml php8.3-curl \
  php8.3-zip php8.3-bcmath php8.3-gd php8.3-intl \
  unzip curl

echo "==> Dejando activo solo el clúster PostgreSQL 17 (libera RAM: la VM tiene 3.9GB)"
sudo pg_ctlcluster 14 main stop || true
sudo pg_ctlcluster 16 main stop || true
sudo systemctl disable --now postgresql@14-main.service 2>/dev/null || true
sudo systemctl disable --now postgresql@16-main.service 2>/dev/null || true
sudo pg_ctlcluster 17 main start || true
sudo systemctl enable postgresql@17-main.service

echo "==> Creando rol y base de datos de la aplicación"
DB_NAME="sigedoc"
DB_USER="sigedoc_app"
DB_PASS="$(openssl rand -base64 24)"

sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$\$;
SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec
SQL

echo "==> Nginx (reverse proxy para el despliegue)"
sudo apt-get install -y nginx

cat <<EOF

============================================================
Listo. Guarda estas credenciales (no se vuelven a mostrar):

  DB_DATABASE=${DB_NAME}
  DB_USERNAME=${DB_USER}
  DB_PASSWORD=${DB_PASS}
  DB_HOST=127.0.0.1
  DB_PORT=5434   # confirmar con: pg_lsclusters

Pégalas en el chat (o pega el .env que te genere) y yo continúo
por SSH con Composer, migraciones y el scaffold de Laravel/Flutter.
============================================================
EOF
