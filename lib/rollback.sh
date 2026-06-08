#!/usr/bin/env bash
# lib/rollback.sh <cambio> <sitio> — Revierte un cambio (ejecuta su rollback.php) + flush.
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:-}"; SITE="${2:-}"
[ -n "$CHANGE" ] && [ -n "$SITE" ] || { echo "Uso: wpkit rollback <cambio> <sitio>"; exit 1; }
CDIR="$(change_dir "$CHANGE")"
[ -f "$CDIR/rollback.php" ] || { echo "✗ No existe $CDIR/rollback.php"; exit 1; }
HTDOCS="/var/www/$SITE/htdocs"
[ -d "$HTDOCS" ] || { echo "✗ No existe el sitio $SITE"; exit 1; }
WP="sudo -u www-data wp --path=$HTDOCS"

echo "==> wpkit rollback: $CHANGE en $SITE"
$WP eval-file "$CDIR/rollback.php" 2>&1 | grep -viE "$FILTER" || true
flush_site "$SITE"
echo "==> Rollback completado. (Para restaurar TODO, usa el RESTORE.md del pre-backup.)"
