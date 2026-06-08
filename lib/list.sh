#!/usr/bin/env bash
# lib/list.sh — Lista los cambios disponibles y su estado (segun los CHANGELOG de cada sitio).
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

echo "Cambios en $CHANGES_DIR:"
shopt -s nullglob
found=0
for d in "$CHANGES_DIR"/*/; do
  [ -f "$d/meta.json" ] || continue
  found=1
  name="$(basename "$d")"
  desc="$(jq -r '.description // empty' "$d/meta.json")"
  staging="$(jq -r '.environments.staging // empty' "$d/meta.json")"
  prod="$(jq -r '.environments.prod // empty' "$d/meta.json")"
  st="·"; pr="·"
  if [ -n "$staging" ] && staging_verified "$name" "$staging"; then st="✓"; fi
  if [ -n "$prod" ] && [ -f "/var/www/$prod/updates/CHANGELOG.md" ] && grep -q "wpkit:$name verificado" "/var/www/$prod/updates/CHANGELOG.md"; then pr="✓"; fi
  printf "  - %-22s %s\n      staging[%s] prod[%s]\n" "$name" "$desc" "$st" "$pr"
done
if [ $found -eq 0 ]; then
  echo "  (ninguno todavia — crea uno con: wpkit new <cambio>)"
fi
exit 0
