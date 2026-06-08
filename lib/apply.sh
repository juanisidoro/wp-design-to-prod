#!/usr/bin/env bash
# lib/apply.sh <cambio> <sitio> [--dry-run] [--yes] [--force]
# Aplica un cambio a un sitio con: pre-backup catastrofico + backup quirurgico +
# apply.php (idempotente, codigo de salida) + flush + verificacion de render.
# Auto-rollback si apply o verificacion fallan. Confirmacion + aviso de staging en prod.
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:-}"; SITE="${2:-}"
[ -n "$CHANGE" ] && [ -n "$SITE" ] || { echo "Uso: wpkit apply <cambio> <sitio> [--dry-run] [--yes] [--force]"; exit 1; }
shift 2 || true
DRYRUN=0; ASSUME_YES=0; FORCE=0
for a in "$@"; do case "$a" in
  --dry-run) DRYRUN=1 ;; --yes|-y) ASSUME_YES=1 ;; --force) FORCE=1 ;;
  *) echo "Opcion desconocida: $a"; exit 1 ;;
esac; done

CDIR="$(change_dir "$CHANGE")"
[ -d "$CDIR" ] && [ -f "$CDIR/meta.json" ] || { echo "✗ No existe el cambio '$CHANGE' (o le falta meta.json) en $CHANGES_DIR"; exit 1; }
HTDOCS="/var/www/$SITE/htdocs"
[ -d "$HTDOCS" ] || { echo "✗ No existe el sitio $SITE ($HTDOCS)"; exit 1; }
WP="sudo -u www-data wp --path=$HTDOCS"

DESC="$(meta "$CHANGE" '.description')"
PROD_SITE="$(meta "$CHANGE" '.environments.prod')"
STAGING_SITE="$(meta "$CHANGE" '.environments.staging')"
TPOST="$(meta "$CHANGE" '.target_post')"
IS_PROD=0; [ "$SITE" = "$PROD_SITE" ] && IS_PROD=1

echo "============================================================"
echo " wpkit apply: $CHANGE  ->  $SITE"
echo " $DESC"
[ $DRYRUN -eq 1 ] && echo " (DRY-RUN: solo muestra el plan, NO ejecuta nada)"
[ $IS_PROD -eq 1 ] && echo " *** Este sitio es PRODUCCION ***"
echo "============================================================"

# --- Confirmaciones (solo prod, solo si NO es dry-run) ---
if [ $IS_PROD -eq 1 ] && [ $DRYRUN -eq 0 ]; then
  if [ $FORCE -eq 0 ] && ! staging_verified "$CHANGE" "$STAGING_SITE"; then
    echo "⚠️  Este cambio NO consta probado/verificado en staging ($STAGING_SITE)."
    echo "    Recomendado primero:  wpkit apply $CHANGE $STAGING_SITE"
    confirm_or_die "forzar" "Para seguir igualmente, escribe 'forzar': "
  fi
  if [ $ASSUME_YES -eq 0 ]; then
    echo "⚠️  Vas a aplicar a PRODUCCION ($SITE)."
    confirm_or_die "aplicar" "Escribe 'aplicar' para continuar: "
  fi
fi

# --- DRY-RUN: imprime el plan y termina ---
if [ $DRYRUN -eq 1 ]; then
  echo "Plan que se ejecutaria:"
  echo "  0. pre-backup CATASTROFICO  -> /backup/wpkit-$CHANGE-prebackup-$SITE-<fecha>/"
  echo "  1. backup QUIRURGICO (post $TPOST + Additional CSS)"
  echo "  2. ejecutar  $CDIR/apply.php   (idempotente)"
  echo "  3. flush elementor/cache/nginx"
  echo "  4. verificar render -> markers: $(meta "$CHANGE" '.verify_markers | join(", ")')"
  echo "  5. anexar entrada al CHANGELOG de $SITE (/var/www/$SITE/updates/CHANGELOG.md)"
  echo "  (si 2 o 4 fallan -> ROLLBACK AUTOMATICO)"
  [ $IS_PROD -eq 1 ] && echo "  (en real: pediria confirmacion 'aplicar'$( staging_verified "$CHANGE" "$STAGING_SITE" || echo " + aviso de staging"))"
  exit 0
fi

# --- 0) pre-backup catastrofico (si falla, set -e aborta) ---
"$WPKIT_HOME/lib/pre-backup.sh" "$CHANGE" "$SITE"

# --- 1) backup quirurgico ---
SBK="/backup/wpkit-$CHANGE-surgical-$SITE-$(now)"
sudo mkdir -p "$SBK"
[ -n "$TPOST" ] && $WP post meta get "$TPOST" _elementor_data 2>/dev/null | sudo tee "$SBK/post-$TPOST.json" >/dev/null
$WP eval 'echo wp_get_custom_css();' 2>/dev/null | sudo tee "$SBK/additional-css.css" >/dev/null
echo "==> Backup quirurgico: $SBK"

# --- 2) apply.php con captura de codigo de salida ---
echo "==> Ejecutando apply.php ..."
set +e
OUT="$($WP eval-file "$CDIR/apply.php" 2>&1)"; RC=$?
set -e
echo "$OUT" | grep -viE "$FILTER" || true
if [ $RC -ne 0 ]; then
  echo "✗ FALLO en apply (codigo $RC) — ver 'Error:' arriba."
  auto_rollback "$CHANGE" "$SITE"
  exit 1
fi

# --- 3) flush ---
echo "==> Limpiando caches ..."
flush_site "$SITE"

# --- 4) verificacion de render ---
echo "==> Verificando render ..."
set +e
"$WPKIT_HOME/lib/verify.sh" "$CHANGE" "$SITE"; VRC=$?
set -e
if [ $VRC -ne 0 ]; then
  echo "✗ La verificacion del render FALLO."
  auto_rollback "$CHANGE" "$SITE"
  exit 1
fi

# --- 5) changelog ---
changelog_append "$CHANGE" "$SITE" "$SBK"

echo "============================================================"
echo " ✓ APLICADO Y VERIFICADO: $CHANGE en $SITE"
echo " Deshacer:  wpkit rollback $CHANGE $SITE"
echo "============================================================"
