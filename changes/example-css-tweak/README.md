# Cambio: example-css-tweak

Un ejemplo minimo y autocontenido de un cambio wpkit basado en `style.css`.

**Que hace:** aplica el `style.css` de este cambio (colorea los enlaces del footer) como un
bloque marcado de Additional CSS.

**Que toca:** solo Additional CSS (bloque `=== wpkit:example-css-tweak ===`).

**Bucle rapido (staging):** `wpkit dev example-css-tweak staging.example.com`
**Publicar:**  `wpkit apply example-css-tweak example.com`
**Revertir:**  `wpkit rollback example-css-tweak <sitio>`

> Edita `style.css` para cambiar el CSS, y `meta.json` con tus dominios reales antes de usarlo.
