#!/usr/bin/env bash
# Apaga PostgreSQL y cualquier servidor web de SIGEDOC iniciado desde .entorno/.
source "$(dirname "$0")/entorno.sh"
pg_ctl -D "$SIGEDOC_ENTORNO/pgdata" -m fast stop 2>/dev/null && echo "PostgreSQL detenido."
taskkill //F //FI "WINDOWTITLE eq SIGEDOC*" >/dev/null 2>&1 || true
