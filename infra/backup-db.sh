#!/usr/bin/env bash
# RNF-06: copia de respaldo de la base de datos de SIGEDOC.
#
#   infra/backup-db.sh                 # respalda en backups/ (conserva los últimos 14)
#   BACKUP_DIR=/ruta infra/backup-db.sh
#
# Programación diaria (cron, 02:30):
#   30 2 * * * /ruta/al/repo/infra/backup-db.sh >> /var/log/sigedoc-backup.log 2>&1
#
# Lee la conexión de backend/.env. La restauración se prueba con infra/restore-db.sh.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$REPO/backend/.env"
[[ -f "$ENV_FILE" ]] || { echo "No existe $ENV_FILE" >&2; exit 1; }

valor() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'; }
export PGHOST="$(valor DB_HOST)" PGPORT="$(valor DB_PORT)" PGUSER="$(valor DB_USERNAME)" PGPASSWORD="$(valor DB_PASSWORD)"
BASE="$(valor DB_DATABASE)"

DESTINO="${BACKUP_DIR:-$REPO/backups}"
mkdir -p "$DESTINO"
ARCHIVO="$DESTINO/sigedoc-$(date +%Y%m%d-%H%M%S).dump"

pg_dump --format=custom --no-owner --file="$ARCHIVO" "$BASE"
pg_restore --list "$ARCHIVO" >/dev/null   # verifica que el archivo es legible
echo "Respaldo creado: $ARCHIVO ($(du -h "$ARCHIVO" | cut -f1))"

# Conserva los 14 más recientes.
ls -1t "$DESTINO"/sigedoc-*.dump | tail -n +15 | xargs -r rm --
