#!/usr/bin/env bash
# Borra TODO lo instalado localmente: .entorno/ (PHP, PostgreSQL con sus datos, Flutter, Composer),
# backend/vendor, backend/.env y frontend/build. No toca el código ni Git.
set -euo pipefail
source "$(dirname "$0")/entorno.sh"
read -r -p "Se borrará .entorno/ (incluida la base de datos local), vendor, .env y build. ¿Continuar? [s/N] " r
[[ "$r" == "s" || "$r" == "S" ]] || { echo "Cancelado."; exit 0; }
pg_ctl -D "$SIGEDOC_ENTORNO/pgdata" -m immediate stop 2>/dev/null || true
cd "$SIGEDOC_REPO"
rm -rf .entorno backend/vendor backend/.env frontend/build frontend/.dart_tool backups
echo "Entorno local eliminado."
