<?php
/**
 * apply.php — PLANTILLA de cambio wpkit. IDEMPOTENTE (correrse 2 veces sin romper).
 * Se ejecuta con:  wp --path=/var/www/<site>/htdocs eval-file apply.php
 * Ante cualquier fallo, llama a kh_fail("motivo") -> el harness hara rollback automatico.
 */
require_once dirname(__DIR__, 2) . '/lib/lib.php';

$CHANGE = basename(__DIR__);
$MARK   = "/* === wpkit:$CHANGE === */";

// Si este cambio tiene un style.css, se aplica como bloque de Additional CSS marcado.
// Bucle rapido:  edita style.css  ->  wpkit dev <cambio> staging.example.com
css_block_set_from_file($MARK, __DIR__ . '/style.css');

/* === Resto de la receta (borra lo que no uses) ===

// Registrar una imagen del cambio:
// $att = image_register_from(__DIR__ . '/assets/mi-imagen.png', 'Mi Imagen');

// Editar Elementor del post objetivo (target_post de meta.json):
// $pid = 0;
// $data = json_decode(get_post_meta($pid, '_elementor_data', true), true);
// if (!is_array($data)) kh_fail("post $pid sin _elementor_data");
// ... modifica $data ...
// update_post_meta($pid, '_elementor_data', wp_slash(wp_json_encode($data)));

*/

echo "OK\n";
