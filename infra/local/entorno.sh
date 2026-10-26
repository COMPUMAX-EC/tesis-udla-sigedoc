# Carga las herramientas portables de .entorno/ en la sesión actual (no toca el sistema):
#   source infra/local/entorno.sh
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SIGEDOC_REPO="$REPO"
export SIGEDOC_ENTORNO="$REPO/.entorno"
export PATH="$SIGEDOC_ENTORNO/php:$SIGEDOC_ENTORNO/flutter/bin:$SIGEDOC_ENTORNO/pgsql/bin:$PATH"
export PHPRC="$SIGEDOC_ENTORNO/php"
composer() { php "$SIGEDOC_ENTORNO/composer/composer.phar" "$@"; }
export -f composer 2>/dev/null || true
