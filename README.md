# wp-design-to-prod

> 🌐 Read this in: **English** · [Español](README.es.md)

**A toolkit to take WordPress design changes from *staging* to *production* safely, without
touching live data** — Git-style, with backups, render verification, and automatic rollback.
Built mainly for sites using **Elementor** and other visual *builders*.

> The CLI command is **`wpkit`** (the repository/project is named `wp-design-to-prod`).

> It's not magic, and it's not a database *merge*. Peace of mind doesn't come from merging data
> well — it comes from **never touching it**: only the **design** travels; everything live
> (orders, users, emails, stock) stays in production.

---

## Why it exists

If you're here, you know WordPress. In its **classic** form (no builders), WordPress kept
things cleanly separated:

- **Design** → in files (themes, templates, CSS).
- **Data** → in the database (posts, pages, users…).

That separation was clean and convenient. **Then builders arrived.** Their intent was good: to
*democratize* web creation, so anyone can build a site by dragging and dropping, without
touching code. But to pull it off, they **put the design inside the database** (blocks, blobs),
mixing it with the data. The clean separation broke.

And it keeps getting worse, especially with **AI**, which makes code more accessible than ever:
more sites, more changes, faster… and more mixing.

The result: today there are countless sites with **big investments**, or regular users earning
**good money**, where **it's not worth touching** what already works. In time and money, the
risk of breaking something live (an order, an email, a form) isn't worth it. So nobody touches
it, and the site grows stale.

After running into several cases like this, **I'm sharing this in case it helps.** It's a simple
framework so that, when you have a production site with **emails, a database, real-time, orders,
etc.**, it's not a pain: **you make a copy, work on it calmly, and publish the changes Git-style**
— just a bit more documented.

It's nothing complex. It's based on **documenting steps with a simple methodology** and
**generating a changelog**. Not much more. But useful.

---

## Who it's for

- **Developers** (or people who code with AI assistance) who **already have a site in production**.
- They set up a **development** environment (usually the easy part)… but **going to production
  gets complicated**, especially with **Elementor and visual builders**.
- Sites with **live data**: orders, customers, emails, real-time, stock.

I know similar tools already exist. This one is deliberately small, and meant to be improved
together.

---

## What it does (in short)

1. You define a **change** (a folder with its "recipe": what to apply and how to undo it).
2. You **test it on staging** (your dev copy) as many times as you need.
3. You **publish it to production** with one command. Before touching anything, it takes a
   **backup**. If something fails, it **rolls back on its own**.
4. It's **recorded in a changelog** (independent of the framework itself).

Only the design travels. Live data **never** enters a change.

---

## Commands

```bash
wpkit new <change>                 # create a new change folder (from the template)
wpkit apply <change> <site>        # backup + apply + verify + auto-rollback
       --dry-run                   # print the plan, execute nothing
wpkit rollback <change> <site>     # undo the change on that site
wpkit list                         # list changes and their status
wpkit help                         # help
```

**Promoting to production** = `apply` to the production site. There's no separate verb: it asks
for confirmation and warns you if you didn't test it on staging first.

```bash
wpkit new footer
wpkit apply footer staging.example.com   # test on staging
wpkit apply footer example.com           # publish to production (asks for confirmation)
```

---

## File architecture (and what each part is for)

```
wp-design-to-prod/
├── bin/wpkit              # the command you run (dispatcher; the command is: wpkit)
├── lib/                   # the generic machinery — written once, used by every change
│   ├── common.sh          # shared functions (confirmations, changelog, auto-rollback)
│   ├── apply.sh           # apply: backup → apply.php → flush → verify → auto-rollback
│   ├── rollback.sh        # undo a change
│   ├── pre-backup.sh      # catastrophic backup (db + wp-content + wp-config)
│   ├── verify.sh          # checks the site returns 200 and contains your "markers"
│   ├── new.sh             # create a new change from the template
│   ├── list.sh            # list changes and status
│   └── lib.php            # reusable PHP toolbox (Elementor, CSS, images)
├── templates/change/      # template copied by "wpkit new"
└── changes/               # YOUR changes (one folder each) — the only thing you write per change
    └── <change>/
        ├── meta.json      # spec: description, environments (staging/prod), target post, markers
        ├── apply.php      # the recipe (idempotent; uses the helpers in lib/lib.php)
        ├── rollback.php   # how to undo it (the exact inverse)
        └── assets/        # change images, if any
```

**The core idea:** `lib/` is the **factory** (same for everything) and `changes/<change>/` is the
**recipe** (the only thing specific you write). That's why the second change takes minutes.

---

## Safety model

- **Catastrophic backup** (db + wp-content + wp-config + restore instructions) **before** touching anything.
- **Surgical backup** of only the rows the change touches.
- `apply.php` and `rollback.php` are **idempotent**; if they fail → **automatic rollback**.
- **Render verification** after applying (HTTP 200 + your markers); on failure → automatic rollback.
- On **production**: asks for confirmation and warns if it wasn't tested on staging.
- An **independent changelog** under `/var/www/<site>/updates/`: it stays even if you uninstall
  the tool, and has a free **notes** section for you.

---

## Install

```bash
git clone https://github.com/juanisidoro/wp-design-to-prod.git
sudo ln -sf "$PWD/wp-design-to-prod/bin/wpkit" /usr/local/bin/wpkit
wpkit help
```

Requires: `bash`, [`wp-cli`](https://wp-cli.org/), `jq`, `curl`, `sudo`, and a WordPress site
reachable at `/var/www/<site>/htdocs`. The Elementor helpers assume Elementor is installed.

---

## Status & contributing

`v0.1` — early and pragmatic. I'm sharing it **in case it helps**: let's improve the use cases
and the methodology together. *Issues* and *PRs* welcome. **Always test on staging first.**
No warranty: use it at your own risk. Never commit credentials (keep `staging_basic_auth` empty
or out of version control).

## License

MIT
