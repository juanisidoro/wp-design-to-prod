<?php
/**
 * rollback.php — PLANTILLA. Debe deshacer EXACTAMENTE lo que hace apply.php.
 * Idempotente y tolerante (si ya no esta, no pasa nada).
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';

/* === Ejemplos (espejo de apply.php) ===

// css_block_remove('/* === MI CAMBIO === *\/');

// Borrar attachment creado:
// $ex = get_posts(['post_type'=>'attachment','title'=>'Mi Imagen','fields'=>'ids']);
// if ($ex) { $f = get_attached_file($ex[0]); wp_delete_attachment($ex[0], true); if ($f && file_exists($f)) @unlink($f); }

*/

echo "OK\n";
