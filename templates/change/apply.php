<?php
/**
 * apply.php — PLANTILLA de cambio wpkit. Debe ser IDEMPOTENTE (correrse 2 veces sin romper).
 * Se ejecuta con:  wp --path=/var/www/<site>/htdocs eval-file apply.php
 * Ante cualquier fallo, llama a kh_fail("motivo") -> el harness hara rollback automatico.
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';   // helpers: kh_fail, el_find, css_block_set, image_register_from...

/* === Ejemplos (borra lo que no uses) ===

// 1) Bloque CSS marcado:
// css_block_set('/* === MI CAMBIO === *\/', '.algo{color:#CFB171!important}');

// 2) Registrar una imagen del cambio:
// $att = image_register_from(__DIR__ . '/assets/mi-imagen.png', 'Mi Imagen');

// 3) Editar Elementor del post objetivo:
// $pid = 0; // <- pon el target_post de meta.json
// $data = json_decode(get_post_meta($pid, '_elementor_data', true), true);
// if (!is_array($data)) kh_fail("post $pid sin _elementor_data");
// ... modifica $data ...
// update_post_meta($pid, '_elementor_data', wp_slash(wp_json_encode($data)));

*/

echo "OK\n";
