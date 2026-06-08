#!/usr/bin/env bash
# lib/new.sh <change> — Create a new change folder from the template.
set -euo pipefail
. "$WPKIT_HOME/lib/common.sh"

CHANGE="${1:-}"
[ -n "$CHANGE" ] || { echo "Usage: wpkit new <change>"; exit 1; }
CDIR="$(change_dir "$CHANGE")"
[ -e "$CDIR" ] && { echo "✗ Change '$CHANGE' already exists in $CHANGES_DIR"; exit 1; }

cp -r "$WPKIT_HOME/templates/change" "$CDIR"
sed -i "s/__CHANGE__/$CHANGE/g" "$CDIR/meta.json"

echo "✓ Change created: $CDIR"
echo "  Edit these files:"
echo "    - meta.json     (description, target_post, verify_markers, environments)"
echo "    - apply.php      (the recipe; use the helpers in lib/lib.php)"
echo "    - rollback.php   (how to undo it)"
echo "    - assets/        (change images, if any)"
echo
echo "  Then:  wpkit apply $CHANGE staging.example.com   (test on staging)"
