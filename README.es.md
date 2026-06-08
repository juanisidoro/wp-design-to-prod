# wp-design-to-prod

> 🌐 Léelo en: [English](README.md) · **Español**

**Toolkit para llevar cambios de diseño de WordPress de *staging* a *producción* de forma
segura, sin tocar los datos vivos** — al estilo Git, con copia de seguridad, verificación y
vuelta atrás automática. Pensado sobre todo para sitios con **Elementor** y otros *builders*
visuales.

> El comando del CLI es **`wpkit`** (el repositorio/proyecto se llama `wp-design-to-prod`).

> No es magia ni un *merge* de bases de datos. La tranquilidad no viene de mezclar bien los
> datos, sino de **no tocarlos nunca**: solo viaja el **diseño**; lo vivo (pedidos, usuarios,
> emails, stock) se queda en producción.

---

## Por qué existe

Si estás aquí, conoces WordPress. En su forma **clásica** (sin builders), WordPress separaba
las cosas de forma limpia:

- **Diseño** → en archivos (temas, plantillas, CSS).
- **Datos** → en la base de datos (posts, páginas, usuarios…).

Esa separación era clara y cómoda. **El problema llegó con los builders.** Su intención era
buena: *democratizar* la creación web, que cualquiera pueda montar un sitio arrastrando y
soltando, sin tocar código. Pero para conseguirlo **metieron el diseño dentro de la base de
datos** (bloques, blobs), mezclándolo con los datos. La separación limpia se rompió.

Y cada día va a más, sobre todo con la **IA**, que hace el código más accesible que nunca:
más sitios, más cambios, más rápido… y más mezcla.

El resultado: hoy hay muchísimos sitios con **inversiones grandes**, o usuarios normales con
**buenas ganancias**, en los que **no compensa meter mano** a lo que ya funciona. En términos
de tiempo y dinero, el riesgo de romper algo vivo (un pedido, un email, un formulario) no
merece la pena. Así que nadie toca, y el sitio se queda anticuado.

Tras encontrarme con varios casos así, **comparto esto por si os ayuda.** Es un marco de
trabajo simple para que, cuando tengas un sitio en producción con **emails, base de datos,
tiempo real, pedidos, etc.**, no sea un dolor: **haces una copia, trabajas en ella con calma,
y publicas los cambios al estilo Git** — pero un poco más documentado.

No es nada complejo. Se basa en **documentar pasos con una metodología simple** y **generar un
changelog**. Poco más. Pero útil.

---

## Para quién es

- **Devs** (o gente que programa con ayuda de IA) que **ya tienen un sitio en producción**.
- Montan un entorno de **desarrollo** (que suele ser lo fácil)… pero **pasar a producción se
  complica**, sobre todo con **Elementor y builders visuales**.
- Sitios con **datos vivos**: pedidos, clientes, emails, tiempo real, stock.

Sé que ya existe alguna herramienta parecida. Esta espero que **se adapte más a vosotros**: es
deliberadamente pequeña y mejorable entre todos.

---

## Qué hace (en breve)

1. Defines un **cambio** (una carpeta con su "receta": qué aplicar y cómo deshacerlo).
2. Lo **pruebas en staging** (tu copia de desarrollo) las veces que haga falta.
3. Lo **publicas en producción** con un comando. Antes de tocar nada, hace **copia de
   seguridad**. Si algo falla, **vuelve atrás solo**.
4. Queda **registrado en un changelog** (independiente del propio framework).

Solo viaja el diseño. Los datos vivos **nunca** entran en un cambio.

---

## Comandos

```bash
wpkit new <cambio>                 # crea la carpeta de un cambio nuevo (desde plantilla)
wpkit dev <cambio> <sitio>         # bucle rápido en staging: aplica + flush, SIN backup (itera CSS)
wpkit apply <cambio> <sitio>       # copia de seguridad + aplica + verifica + auto-rollback
       --dry-run                   # muestra el plan, no ejecuta nada
wpkit rollback <cambio> <sitio>    # deshace el cambio en ese sitio
wpkit list                         # lista los cambios y su estado
wpkit help                         # ayuda
```

**Promover a producción** = `apply` al sitio de producción. No hay un verbo aparte: pide
confirmación y te avisa si no lo probaste antes en staging.

```bash
wpkit new footer
wpkit dev footer staging.example.com     # bucle rápido: editar -> dev -> ver, las veces que haga falta
wpkit apply footer example.com           # publicar en producción (pide confirmación)
```

### Bucle rápido para CSS

Para retoques **solo-CSS** no hace falta tocar PHP: pon tu CSS en el `style.css` del cambio e
itera en staging con `wpkit dev` (aplica + flush, sin backup). `dev` funciona **solo en
staging**; a producción siempre se va con `wpkit apply` (backups + verificación).

---

## Arquitectura de archivos (y para qué sirve cada uno)

```
wp-design-to-prod/
├── bin/wpkit              # el comando que ejecutas (despachador; el comando es: wpkit)
├── lib/                   # la maquinaria genérica — se escribe una vez, la usan todos los cambios
│   ├── common.sh          # funciones compartidas (confirmaciones, changelog, auto-rollback)
│   ├── apply.sh           # aplicar: backup → apply.php → flush → verificar → auto-rollback
│   ├── rollback.sh        # deshacer un cambio
│   ├── pre-backup.sh      # copia de seguridad catastrófica (db + wp-content + wp-config)
│   ├── verify.sh          # comprueba que la web responde 200 y contiene tus "marcadores"
│   ├── new.sh             # crea un cambio nuevo desde la plantilla
│   ├── list.sh            # lista cambios y estado
│   └── lib.php            # caja de herramientas PHP reutilizable (Elementor, CSS, imágenes)
├── templates/change/      # plantilla que copia "wpkit new"
└── changes/               # TUS cambios (uno por carpeta) — lo único que escribes por cambio
    └── <cambio>/
        ├── meta.json      # ficha: descripción, entornos (staging/prod), post objetivo, marcadores
        ├── style.css      # cambios solo-CSS (se aplica como bloque marcado; ideal con `wpkit dev`)
        ├── apply.php      # la receta (idempotente; usa los helpers de lib/lib.php)
        ├── rollback.php   # cómo deshacerlo (el inverso exacto)
        └── assets/        # imágenes del cambio, si las hay
```

**La idea de fondo:** `lib/` es la **fábrica** (igual para todo) y `changes/<cambio>/` es la
**receta** (lo único específico que escribes). Por eso el segundo cambio se hace en minutos.

---

## Modelo de seguridad

- **Copia catastrófica** (db + wp-content + wp-config + instrucciones de restauración) **antes**
  de tocar nada.
- **Copia quirúrgica** de solo las filas que el cambio toca.
- `apply.php` y `rollback.php` **idempotentes**; si fallan → **rollback automático**.
- **Verificación del render** tras aplicar (HTTP 200 + tus marcadores); si falla → rollback automático.
- En **producción**: pide confirmación y avisa si no se probó en staging.
- **Changelog independiente** en `/var/www/<sitio>/updates/`: permanece aunque desinstales
  wpkit, y tiene una sección de **notas** libre para ti.

---

## Instalación

```bash
git clone https://github.com/juanisidoro/wp-design-to-prod.git
sudo ln -sf "$PWD/wp-design-to-prod/bin/wpkit" /usr/local/bin/wpkit
wpkit help
```

Necesita: `bash`, [`wp-cli`](https://wp-cli.org/), `jq`, `curl`, `sudo`, y un WordPress
accesible en `/var/www/<sitio>/htdocs`. Los helpers de Elementor asumen Elementor instalado.

---

## Credenciales

Si tu **staging** necesita basic-auth (HTTP) para la verificación del render, **deja
`staging_basic_auth` (y `staging_curl_resolve`) vacíos en `meta.json`** y pásalos en tiempo de
ejecución por variables de entorno — tienen prioridad sobre `meta.json` y nunca se commitean:

```bash
export WPKIT_STAGING_AUTH="usuario:contraseña"
export WPKIT_STAGING_RESOLVE="staging.example.com:443:203.0.113.10"   # opcional
```

El `.gitignore` ya bloquea los archivos de secretos habituales (`.env`, `wp-config.php`,
`*.key`, `*.pem`, dumps…). Nunca commitees credenciales dentro de un cambio versionado.

---

## Estado y contribución

`v0.1` — temprano y pragmático. Lo comparto **por si ayuda**: mejoremos entre todos los casos
de uso y la metodología. *Issues* y *PRs* bienvenidos. **Prueba siempre en staging primero.**
Sin garantías: úsalo bajo tu responsabilidad. Nunca subas credenciales (deja
`staging_basic_auth` vacío o fuera del control de versiones).

## Licencia

MIT
