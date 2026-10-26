#!/usr/bin/env bash
# Levanta SIGEDOC en esta PC con las herramientas de .entorno/:
#   PostgreSQL (127.0.0.1:5434) + API Laravel y la web de Flutter en http://127.0.0.1:8091
#
#   infra/local/iniciar.sh            # arranca (compila la web si aún no existe)
#   infra/local/iniciar.sh --build    # fuerza recompilar la web de Flutter
set -euo pipefail
source "$(dirname "$0")/entorno.sh"
PUERTO="${PORT:-8091}"

if ! pg_isready -q -h 127.0.0.1 -p 5434; then
  echo "Iniciando PostgreSQL…"
  pg_ctl -D "$SIGEDOC_ENTORNO/pgdata" -o "-p 5434 -c listen_addresses=127.0.0.1" -l "$SIGEDOC_ENTORNO/pgdata/servidor.log" -w start >/dev/null
fi

if [[ "${1:-}" == "--build" || ! -f "$SIGEDOC_REPO/frontend/build/web/index.html" ]]; then
  echo "Compilando la web de Flutter (tarda varios minutos y usa ~2 GB de RAM; cierre otros programas)…"
  (cd "$SIGEDOC_REPO/frontend" && flutter build web --release)
fi

(cd "$SIGEDOC_REPO/backend" && php artisan config:clear >/dev/null)
echo "SIGEDOC listo en http://127.0.0.1:$PUERTO  (Ctrl+C para detener la web; infra/local/detener.sh apaga también PostgreSQL)"
exec php -S "127.0.0.1:$PUERTO" -t "$SIGEDOC_REPO/frontend/build/web" "$SIGEDOC_REPO/infra/dev-router.php"
