#!/usr/bin/env bash
# RNF-06: restaura un respaldo en una base NUEVA para comprobar que es recuperable.
# No toca la base en uso: crea (o recrea) la base indicada.
#
#   infra/restore-db.sh backups/sigedoc-20261020-023000.dump [sigedoc_restaurada]
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVO="${1:?Indique el archivo .dump}"
DESTINO="${2:-sigedoc_restaurada}"
ENV_FILE="$REPO/backend/.env"

valor() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'; }
export PGHOST="$(valor DB_HOST)" PGPORT="$(valor DB_PORT)" PGUSER="$(valor DB_USERNAME)" PGPASSWORD="$(valor DB_PASSWORD)"

[[ "$DESTINO" != "$(valor DB_DATABASE)" ]] || { echo "Por seguridad no se restaura sobre la base en uso." >&2; exit 1; }
dropdb --if-exists "$DESTINO"
createdb "$DESTINO"
pg_restore --no-owner --dbname="$DESTINO" "$ARCHIVO"

for tabla in documento codigo_qr prestamo movimiento usuario; do
  echo "$tabla: $(psql -At -d "$DESTINO" -c "SELECT count(*) FROM $tabla")"
done
echo "Restauración correcta en la base «$DESTINO»."
