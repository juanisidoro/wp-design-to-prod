#!/usr/bin/env bash
# lib/dev.sh <cambio> <sitio> — BUCLE RAPIDO de desarrollo (solo staging).
# Aplica el cambio (apply.php) + flush, SIN copias de seguridad ni verificacion.
# Pensado para iterar: edita el style.css del cambio y vuelve a correrlo.
# Rechaza el sitio de PRODUCCION (para prod usa 'wpkit apply', que hace backups).
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:-}"; SITE="${2:-}"
[ -n "$CHANGE" ] && [ -n "$SITE" ] || { echo "Uso: wpkit dev <cambio> <sitio>"; exit 1; }
CDIR="$(change_dir "$CHANGE")"
[ -f "$CDIR/apply.php" ] || { echo "✗ No existe $CDIR/apply.php"; exit 1; }
HTDOCS="/var/www/$SITE/htdocs"
[ -d "$HTDOCS" ] || { echo "✗ No existe el sitio $SITE ($HTDOCS)"; exit 1; }
WP="sudo -u www-data wp --path=$HTDOCS"

PROD_SITE="$(meta "$CHANGE" '.environments.prod')"
if [ "$SITE" = "$PROD_SITE" ]; then
  echo "✗ 'dev' es solo para staging/desarrollo (sin backups)."
  echo "  Para produccion:  wpkit apply $CHANGE $SITE"
  exit 1
fi

echo "==> dev: $CHANGE en $SITE (rapido, sin backup) ..."
set +e
OUT="$($WP eval-file "$CDIR/apply.php" 2>&1)"; RC=$?
set -e
echo "$OUT" | grep -viE "$FILTER" || true
[ $RC -eq 0 ] || { echo "✗ apply.php fallo (codigo $RC)."; exit 1; }
flush_site "$SITE"
echo "✓ dev OK. Cuando te guste, publica:  wpkit apply $CHANGE ${PROD_SITE:-<sitio-prod>}"
