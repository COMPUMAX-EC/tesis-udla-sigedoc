#!/usr/bin/env bash
# Publica la documentación (docs/) en el tailnet, solo privado (sin Funnel).
#   https://<host>.<tailnet>.ts.net:8443/
# No abre puertos locales: tailscale sirve los archivos directamente.
# No toca la configuración existente en :443.
#
# Uso:  infra/serve-docs.sh          # publicar
#       infra/serve-docs.sh off      # retirar solo :8443
set -euo pipefail

PORT=8443
REPO="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${1:-}" == "off" ]]; then
  tailscale serve --https="$PORT" off
  exit 0
fi

tailscale serve --bg --https="$PORT" --set-path=/ "$REPO/infra/docs-site"
tailscale serve --bg --https="$PORT" --set-path=/docs "$REPO/docs"
tailscale serve status
