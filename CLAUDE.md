# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This is a customized fork of [Postal](https://postalserver.io) — a self-hosted mail delivery platform (MTA). It is a **Ruby on Rails 7.1** app (Ruby **3.4.6**, see `.ruby-version`) backed by MariaDB. The fork's main addition over upstream Postal is the **Admin API v2** (`app/controllers/admin_api/`), a full REST/JSON management API.

There is a more detailed orientation doc in `Agents.md`; user-facing docs live in `docs/`.

## Development workflow (Docker-first)

Development is done through Docker Compose, not a native Ruby install. The `runner` service is a one-off container for running Rails/rake/rspec.

```bash
make dev                  # start dev env (web on :5001, SMTP on :2525, DB on :3307)
make dev-logs
make dev-stop

# one-off commands go through the `runner` service:
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rake db:migrate
```

Production / ops use the `Makefile` (defaults to `docker-compose.prod.yml`): `make setup`, `make init` (db), `make user` (admin), `make start/stop/status`, `make upgrade VERSION=x.y.z`, `make console`, `make db`, `make dkim`. Run `make help` for the full list.

## Testing

RSpec. CI (`.github/workflows/ci.yml`) runs natively against a MariaDB service; locally use the `runner` container.

```bash
# all specs
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec
# admin API specs only
bundle exec rspec spec/apis/admin_api/
# a single file
bundle exec rspec spec/apis/admin_api/domains_spec.rb
```

Tests require a Postal config file — set `POSTAL_CONFIG_FILE_PATH=config/postal/postal.test.yml` and `RAILS_ENV=test` (see how CI sets these). Admin API specs share setup via `spec/apis/admin_api/shared_context.rb`.

## Lint

`bundle exec rubocop` (config in `.rubocop.yml`). CI runs it `continue-on-error`, so it is non-blocking.

## Architecture — the non-obvious parts

**Two-tier database layout.** The main Rails/ActiveRecord database holds configuration and metadata (orgs, servers, users, domains, routes). Actual email message storage is **per-server**: each Postal "server" gets its own MariaDB database, accessed *not* through ActiveRecord but through a hand-rolled layer in `lib/postal/message_db/` (`database.rb`, `message.rb`, `connection_pool.rb`, plus its own `migrations/`). When touching message data, work through `Postal::MessageDB`, not ActiveRecord models.

**The `postal` CLI dispatches the processes.** `bin/postal` is the entrypoint that selects which process to run: `web-server` (Puma), `smtp-server` (`script/smtp_server.rb`), `worker`, `console`, etc. The same image runs different roles depending on this argument — that's how the compose services differ.

**Configuration goes through `Postal::Config`.** Config is loaded from `config/postal/*.yml` (path overridable via `POSTAL_CONFIG_FILE_PATH`) and validated against the schema in `lib/postal/config_schema.rb`. Don't read raw YAML — use `Postal::Config`.

**Admin API conventions** (`app/controllers/admin_api/`):
- All controllers inherit `BaseController`, which handles auth, timing, and error rendering.
- Auth is the `X-Admin-API-Key` header. Two valid sources: an `AdminAPIKey` DB record, or the global `Postal::Config.postal.admin_api_key` (backward-compat fallback).
- Responses use the `render_success` / `render_created` / `render_deleted` / `render_error` helpers — every response is `{ status, time, data | error }`. Don't hand-roll `render json:`.
- `BaseController` rescues `RecordNotFound` → 404, `RecordInvalid` → 422, `ParameterMissing` → 400. Lean on these rather than rescuing in each action.
- List endpoints use the `paginate` helper (`page` / `per_page`, capped at 100).
- Add routes under the `admin_api` namespace in `config/routes.rb`; serialize via private `*_json` methods.

There is also a `legacy_api/` (v1) — leave it alone unless specifically working on legacy compatibility.

## OpenAPI generation

The OpenAPI spec is produced as a side effect of running the admin API specs with `OPENAPI=1`. Use `scripts/generate-openapi.sh` (auto-detects compose file, drops/recreates the test DB, runs `spec/apis/admin_api`, writes to `public/openapi/`). Post-processing is in `scripts/post-process-openapi.rb`.

## CI

- **`ci.yml`**: lint (RuboCop, non-blocking) + tests (RSpec against a MariaDB service, **blocking**) on push/PR.

## Secrets

Do not commit `.env*` files with real values (`.env.example` is the template).
