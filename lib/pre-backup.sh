#!/usr/bin/env bash
# lib/pre-backup.sh <cambio> <sitio> — Backup CATASTROFICO con fecha/hora.
# db completa + wp-content + wp-config + README del cambio + RESTORE.md.
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:?}"; SITE="${2:?}"
HTDOCS="/var/www/$SITE/htdocs"
WP="sudo -u www-data wp --path=$HTDOCS"
DEST="/backup/wpkit-$CHANGE-prebackup-$SITE-$(now)"

echo "==> Pre-backup CATASTROFICO de $SITE"
echo "    Destino: $DEST"
sudo mkdir -p "$DEST"

echo "    - DB completa ..."
$WP db export - 2>/dev/null | sudo tee "$DEST/db-full.sql" >/dev/null

echo "    - wp-content (sin ai1wm-backups ni cache) ..."
sudo tar --warning=no-file-changed --exclude='*/ai1wm-backups' --exclude='*/cache' \
  -czf "$DEST/wp-content.tar.gz" -C "$HTDOCS" wp-content 2>/dev/null || true

echo "    - wp-config ..."
sudo cp "/var/www/$SITE/wp-config.php" "$DEST/wp-config.php" 2>/dev/null \
  || sudo cp "$HTDOCS/wp-config.php" "$DEST/wp-config.php" 2>/dev/null || true

sudo cp "$(change_dir "$CHANGE")/README.md" "$DEST/CAMBIO-README.md" 2>/dev/null || true

sudo tee "$DEST/RESTORE.md" >/dev/null <<EOF
# Backup pre-cambio (wpkit) — $CHANGE
- Sitio: $SITE
- Fecha: $(date '+%Y-%m-%d %H:%M')
- Cambio: $(meta "$CHANGE" '.description')

## Rollback NORMAL (recomendado)
\`\`\`bash
wpkit rollback $CHANGE $SITE
\`\`\`

## Restauracion CATASTROFICA (vuelve TODO a este punto)
\`\`\`bash
sudo -u www-data wp --path=$HTDOCS db import "$DEST/db-full.sql"
sudo tar -xzf "$DEST/wp-content.tar.gz" -C "$HTDOCS"
sudo -u www-data wp --path=$HTDOCS elementor flush-css
sudo -u www-data wp --path=$HTDOCS cache flush
sudo -u www-data wp --path=$HTDOCS nginx-helper purge-all || true
\`\`\`
EOF

SIZE="$(sudo du -sh "$DEST" | cut -f1)"
echo "==> Pre-backup OK ($SIZE): $DEST"
