<?php
/**
 * Cambio de ejemplo — apply.php. Idempotente.
 * Aplica el style.css de este cambio como bloque de Additional CSS marcado.
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';

css_block_set_from_file('/* === wpkit:example-css-tweak === */', __DIR__ . '/style.css');

echo "OK\n";
