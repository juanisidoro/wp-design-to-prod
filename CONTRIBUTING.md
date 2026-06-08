# Contributing to wp-design-to-prod

Thanks for your interest! This is a small, pragmatic toolkit — contributions that keep it
**simple and safe** are very welcome. Issues and PRs in **English or Español** are both fine.

## Ground rules (the philosophy)

- **Design only, never live data.** Nothing here should ever touch orders, users, comments,
  stock, etc. A change moves *design* (Elementor, options, CSS, media) from staging to production.
- **Reversible and idempotent.** Every `apply.php` must be safe to run twice and have a matching
  `rollback.php` that undoes it exactly.
- **Small over clever.** A few clear lines beat a premature abstraction.

## Ways to contribute

- **Report a bug / propose an idea** → open an [Issue](../../issues) (include steps and your
  WordPress / Elementor / wp-cli versions).
- **Improve the framework** (`lib/`, `bin/`, docs) → open a Pull Request.
- **Share a reusable change pattern** → a well-documented example under `changes/`
  (sanitized: no real domains, IPs, logos or credentials).

## Dev setup & testing

The framework is plain `bash` + `php` (via `wp-cli`), no build step.

- Requirements: `bash`, [`wp-cli`](https://wp-cli.org/), `jq`, `curl`, `sudo`, and a WordPress
  site at `/var/www/<site>/htdocs`.
- Always test on **staging** first: `wpkit dev <change> staging.example.com`.
- Lint before a PR: `bash -n bin/wpkit lib/*.sh` and `php -l <file>.php`.
- Keep shell scripts **LF** (enforced by `.gitattributes`).

## Security

- **Never commit credentials.** Keep `staging_basic_auth` empty in `meta.json`; pass secrets via
  the `WPKIT_STAGING_AUTH` environment variable (see the README "Credentials" section).
  `.gitignore` already blocks common secret files (`.env`, `wp-config.php`, `*.key`, dumps…).
- Use `example.com` placeholders in examples — never real domains, IPs, logos or DB data.

## Pull requests

- One focused change per PR; describe **what** and **why**.
- Update the README / USAGE if you add or change a command.
- No co-author or AI attribution required.

## Code of conduct

Be kind and constructive. That's it.

## License

By contributing, you agree that your contributions are licensed under the project's **MIT** license.
