# Postal Management Scripts

Helper scripts for managing your Postal installation.

---

## Scripts Overview

### setup.sh

Initial setup - creates all necessary configuration files.

```bash
./scripts/setup.sh
```

Creates:
- `config/postal.yml` from example
- `config/Caddyfile` from example
- `config/signing.key` (RSA key)
- `.env` from example

### initialize.sh

Initialize the Postal database schema.

```bash
./scripts/initialize.sh
```

Run once after setup and configuration.

### make-user.sh

Create a new admin user.

```bash
./scripts/make-user.sh
```

Run after database initialization.

### status.sh

Show status of all Postal services.

```bash
./scripts/status.sh
```

### upgrade.sh

Upgrade Postal to a new version.

```bash
./scripts/upgrade.sh [version]
```

Example:
```bash
./scripts/upgrade.sh 3.3.4
```

---

## Workflow

1. **Setup**: `./scripts/setup.sh`
2. **Configure**: Edit `config/postal.yml` and `config/Caddyfile`
3. **Initialize**: `./scripts/initialize.sh`
4. **Create User**: `./scripts/make-user.sh`
5. **Start**: `docker compose up -d`
6. **Status**: `./scripts/status.sh`

---

## Direct Docker Compose Commands

### Production

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart a service
docker compose restart web

# Run a command
docker compose run --rm runner postal [command]

# Access shell
docker compose exec web bash
```

### Development

```bash
# Start services
docker compose -f docker-compose.dev.yml up -d

# Stop services
docker compose -f docker-compose.dev.yml down

# Run tests
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec

# Rails console
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console
```

---

## Runner Commands

The `runner` service executes Postal commands:

```bash
# Console
docker compose run --rm runner postal console

# Show version
docker compose run --rm runner postal version

# Default DKIM record
docker compose run --rm runner postal default-dkim-record

# Test app SMTP
docker compose run --rm runner postal test-app-smtp [email]
```

---

## Troubleshooting

### View Logs

```bash
docker compose logs -f [service]
```

### Restart All Services

```bash
docker compose restart
```

### Reset Everything

```bash
docker compose down -v
```

### Database Access

```bash
docker compose exec mariadb mysql -u root -ppostal postal
```
