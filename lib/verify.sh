#!/usr/bin/env bash
# lib/verify.sh <cambio> <sitio> — Smoke test del render:
#   home responde 200 + el HTML contiene todos los 'verify_markers' del cambio.
# En staging, si necesita basic-auth/resolve, los toma de variables de entorno
# (WPKIT_STAGING_AUTH / WPKIT_STAGING_RESOLVE) y, como fallback, de meta.json.
# Recomendado: deja meta.json vacio y pasa las credenciales por entorno (no se commitean).
set -uo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:?}"; SITE="${2:?}"
TMP="/tmp/wpkit-verify-$SITE.html"

AUTH=(); RESOLVE=()
STAGING="$(meta "$CHANGE" '.environments.staging')"
if [ "$SITE" = "$STAGING" ]; then
  # Prioridad: variable de entorno > meta.json (fallback)
  BA="${WPKIT_STAGING_AUTH:-$(meta "$CHANGE" '.staging_basic_auth')}"
  RS="${WPKIT_STAGING_RESOLVE:-$(meta "$CHANGE" '.staging_curl_resolve')}"
  [ -n "$BA" ] && AUTH=(-k -u "$BA")
  [ -n "$RS" ] && RESOLVE=(--resolve "$RS")
fi

CODE="$(curl -s "${AUTH[@]}" "${RESOLVE[@]}" -A 'Mozilla/5.0 (Windows NT 10.0)' -o "$TMP" -w '%{http_code}' "https://$SITE/")"
echo "    HTTP $CODE"
[ "$CODE" = "200" ] || { echo "    ✗ la home no devuelve 200"; exit 1; }

mapfile -t MARKERS < <(jq -r '.verify_markers[]?' "$(change_dir "$CHANGE")/meta.json" 2>/dev/null)
for m in "${MARKERS[@]}"; do
  [ -z "$m" ] && continue
  grep -q "$m" "$TMP" || { echo "    ✗ falta en el HTML: $m"; exit 1; }
done
echo "    ✓ render OK (home 200 + markers presentes)"
exit 0
