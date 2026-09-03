#!/usr/bin/env bash
# Aprovisionamiento inicial de la VM de desarrollo (Ubuntu 24.04).
# Ejecutar UNA vez, interactivamente (pide password de sudo):
#
#   bash infra/provision-vm.sh
#
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
  unzip curl git

echo "==> Instalando Composer"
if ! command -v composer >/dev/null 2>&1; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f composer-setup.php
fi

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

echo "==> Instalando Flutter SDK (canal stable) en \$HOME/flutter"
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi
if ! grep -q 'flutter/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter precache --web
flutter config --enable-web
flutter doctor || true

echo "==> Instalando Nginx (ya presente, se configura al desplegar)"
sudo apt-get install -y nginx

cat <<EOF

============================================================
Aprovisionamiento completo.

Credenciales de base de datos (guárdalas, no se repiten):
  DB_DATABASE=${DB_NAME}
  DB_USERNAME=${DB_USER}
  DB_PASSWORD=${DB_PASS}
  DB_HOST=127.0.0.1
  DB_PORT=5434   # puerto del clúster 17, confirmar con: pg_lsclusters

Siguiente paso: cierra sesión y vuelve a entrar (o \`source ~/.bashrc\`)
para que \`flutter\` quede en el PATH, luego clona el repo:
  git clone https://github.com/COMPUMAX-EC/tesis-udla-sigedoc.git
============================================================
EOF
