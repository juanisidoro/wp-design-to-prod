<?php
/**
 * wpkit/lib/lib.php — Caja de herramientas reutilizable para los apply.php/rollback.php
 * de cada cambio. Se incluye con:  require_once dirname(__DIR__, 2) . '/lib/lib.php';
 * (estas funciones son las que se reescribian a mano; ahora se comparten)
 */

if (!function_exists('kh_fail')) {
  // Aborta con codigo != 0 y motivo (para que apply.sh detecte el fallo y haga rollback).
  function kh_fail($m) {
    if (class_exists('WP_CLI')) { WP_CLI::error($m); }
    else { fwrite(STDERR, "FAIL: $m\n"); exit(1); }
  }
}

if (!function_exists('el_find')) {
  // Busca un elemento Elementor por id (recursivo). Devuelve copia o null.
  function el_find($els, $id) {
    foreach ($els as $e) {
      if (($e['id'] ?? '') === $id) return $e;
      if (!empty($e['elements'])) { $r = el_find($e['elements'], $id); if ($r !== null) return $r; }
    }
    return null;
  }
}

if (!function_exists('el_walk')) {
  // Recorre todos los elementos aplicando un callback por referencia.
  function el_walk(&$els, $cb) {
    foreach ($els as &$e) { $cb($e); if (!empty($e['elements'])) el_walk($e['elements'], $cb); }
    unset($e);
  }
}

if (!function_exists('css_block_set')) {
  // Escribe (o reemplaza) un bloque marcado en Additional CSS.
  function css_block_set($marker, $body) {
    $css = wp_get_custom_css();
    $p = strpos($css, $marker);
    if ($p !== false) $css = rtrim(substr($css, 0, $p));
    wp_update_custom_css_post(rtrim($css) . "\n\n" . $marker . "\n" . $body . "\n");
  }
}

if (!function_exists('css_block_remove')) {
  // Elimina un bloque marcado de Additional CSS.
  function css_block_remove($marker) {
    $css = wp_get_custom_css();
    $p = strpos($css, $marker);
    if ($p !== false) wp_update_custom_css_post(rtrim(substr($css, 0, $p)) . "\n");
  }
}

if (!function_exists('image_register_from')) {
  // Copia un archivo a uploads/<año>/<mes>/ y lo registra como attachment (idempotente por titulo).
  function image_register_from($file, $title) {
    if (!file_exists($file)) kh_fail("asset no encontrado: $file");
    $up = wp_upload_dir();
    $dest = trailingslashit($up['path']) . basename($file);
    if (!@copy($file, $dest)) kh_fail("no pude copiar a uploads: $dest");
    require_once ABSPATH . 'wp-admin/includes/image.php';
    $ex = get_posts(['post_type' => 'attachment', 'title' => $title, 'posts_per_page' => 1, 'fields' => 'ids']);
    if ($ex) { $att = $ex[0]; }
    else {
      $mime = wp_check_filetype($dest)['type'] ?: 'image/png';
      $att = wp_insert_attachment([
        'guid' => trailingslashit($up['url']) . basename($file),
        'post_mime_type' => $mime, 'post_title' => $title, 'post_status' => 'inherit',
      ], $dest);
    }
    wp_update_attachment_metadata($att, wp_generate_attachment_metadata($att, $dest));
    return $att;
  }
}
