<?php
/**
 * Cambio de ejemplo — rollback.php. El inverso exacto de apply.php.
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';

css_block_remove('/* === EXAMPLE CSS TWEAK === */');

echo "OK\n";
