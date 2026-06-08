<?php
/**
 * Cambio de ejemplo — apply.php. Idempotente.
 * Anade un bloque de Additional CSS marcado. Se ejecuta con: wp eval-file apply.php
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';

css_block_set('/* === EXAMPLE CSS TWEAK === */', "footer a { color: #c9a227 !important; }");

echo "OK\n";
