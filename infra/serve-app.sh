#!/usr/bin/env bash
# Sirve SIGEDOC (Flutter web + API Laravel) en 127.0.0.1:${PORT:-8091} para desarrollo/demos.
# Exponer con:  ngrok http 8091
#   infra/serve-app.sh          # compila Flutter web y arranca
#   infra/serve-app.sh --no-build
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8091}"

if [[ "${1:-}" != "--no-build" ]]; then
  (cd "$REPO/frontend" && "${FLUTTER:-$HOME/flutter/bin/flutter}" build web --release)
fi
(cd "$REPO/backend" && php artisan config:cache >/dev/null)

exec env PHP_CLI_SERVER_WORKERS=4 php -S "127.0.0.1:$PORT" -t "$REPO/frontend/build/web" "$REPO/infra/dev-router.php"
