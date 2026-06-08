# common.sh — funciones compartidas. Se hace 'source' desde los demas scripts.
WPKIT_HOME="${WPKIT_HOME:?WPKIT_HOME no definido (ejecuta via bin/wpkit)}"
CHANGES_DIR="$WPKIT_HOME/changes"
FILTER='warning|include|schema-aggregator|deprecated'

change_dir () { echo "$CHANGES_DIR/$1"; }
meta () { jq -r "$2 // empty" "$(change_dir "$1")/meta.json" 2>/dev/null; }
now  () { date +%Y%m%d-%H%M%S; }

# Pide confirmacion escribiendo una palabra exacta. Aborta si no coincide o si no hay terminal.
confirm_or_die () {
  local want="$1" prompt="$2" ans=""
  if [ ! -t 0 ]; then
    echo "✗ Requiere confirmacion interactiva (escribe '$want'). Ejecuta en terminal, o usa --yes/--force."
    exit 1
  fi
  read -r -p "$prompt" ans
  [ "$ans" = "$want" ] || { echo "✗ Cancelado (no escribiste '$want')."; exit 1; }
}

# ¿El cambio consta aplicado y verificado en staging? (lee el CHANGELOG de staging, independiente)
staging_verified () {
  local change="$1" ssite="$2"
  local cl="/var/www/$ssite/updates/CHANGELOG.md"
  [ -f "$cl" ] || return 1
  grep -q "wpkit:$change verificado" "$cl"
}

flush_site () {
  local WP="sudo -u www-data wp --path=/var/www/$1/htdocs"
  $WP elementor flush-css >/dev/null 2>&1 || true
  $WP cache flush         >/dev/null 2>&1 || true
  $WP nginx-helper purge-all >/dev/null 2>&1 || true
}

auto_rollback () {   # auto_rollback <change> <site>
  echo "   -> ROLLBACK AUTOMATICO ..."
  local WP="sudo -u www-data wp --path=/var/www/$2/htdocs"
  $WP eval-file "$(change_dir "$1")/rollback.php" 2>&1 | grep -viE "$FILTER" || true
  flush_site "$2"
  echo "   -> Revertido. El sitio quedo SIN cambios."
}

# Anexa (nunca reescribe) una entrada al CHANGELOG del sitio. Independiente de wpkit.
changelog_append () {   # changelog_append <change> <site> <surgical-backup-dir>
  local change="$1" site="$2" sbk="$3"
  local dir="/var/www/$site/updates" cl="/var/www/$site/updates/CHANGELOG.md"
  local desc touches stamp
  desc="$(meta "$change" '.description')"
  touches="$(meta "$change" '.touches')"
  stamp="$(date '+%Y-%m-%d %H:%M')"
  sudo mkdir -p "$dir"
  sudo chown "$(id -un):$(id -gn)" "$dir" 2>/dev/null || true
  if [ ! -f "$cl" ]; then
    cat > "$cl" <<HDR
# Registro de cambios — $site

Cambios de diseño/estructura aplicados a este sitio.
**Independiente de wpkit**: si desinstalas el framework, este archivo permanece.
Está fuera de \`htdocs\` (no accesible por web). Cada entrada la añade wpkit
automáticamente; la sección **💬 Notas** es tuya para escribir lo que quieras.

---
HDR
  fi
  cat >> "$cl" <<ENTRY

## $stamp — $change  ✅ verificado  <!-- wpkit:$change verificado -->
**Qué:** $desc
**Tocó:** $touches
**Backup:** $sbk
**Revertir:** \`wpkit rollback $change $site\`

**💬 Notas:** _(escribe aquí lo que quieras)_

---
ENTRY
  echo "==> CHANGELOG actualizado: $cl"
}
