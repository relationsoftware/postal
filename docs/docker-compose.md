# Docker Compose Environments

## Overview

The project uses two Docker Compose configurations following internal development standards.

---

## Production: `docker-compose.yml`

**Standard stack for production deployments**

```bash
docker compose up -d
```

**Features:**
- Caddy reverse proxy with automatic SSL/TLS certificates
- Production-ready ports: HTTP/HTTPS (80/443), SMTP (25)
- MariaDB on standard port 3306
- Image: `ghcr.io/relationsoftware/postal:latest` (automatically pulled)
- No local builds required

**Services:**

| Service | Description |
|---------|-------------|
| `mariadb` | Database |
| `web` | Postal web interface (port 5000, behind Caddy) |
| `smtp` | SMTP server (port 25) |
| `worker` | Background worker |
| `caddy` | Reverse proxy (ports 80, 443) |
| `runner` | Utility container (profile: tools) |

---

## Development: `docker-compose.dev.yml`

**Local development environment**

```bash
docker compose -f docker-compose.dev.yml up -d
```

**Features:**
- Uses `ghcr.io/relationsoftware/postal:latest-dev` from GitHub Container Registry
- Development ports avoid conflicts: MariaDB (3307), Web (5001), SMTP (2525)
- No Caddy - direct service access
- Separate development volumes
- Automatic image updates on commits

**Services:**

| Service | Description |
|---------|-------------|
| `mariadb` | Database (port 3307) |
| `web` | Postal web interface (port 5001) |
| `smtp` | SMTP server (port 2525) |
| `worker` | Background worker |
| `runner` | Utility container (profile: tools) |

---

## Quick Start

### Production

```bash
# 1. Prepare configuration
cp config/postal.yml.example config/postal.yml
# Edit: Domain, DNS, SMTP settings, etc.

# 2. Pull latest version (optional - automatic)
docker compose pull

# 3. Initialize database
./scripts/initialize.sh

# 4. Create admin user
./scripts/make-user.sh

# 5. Start services
docker compose up -d

# 6. View logs
docker compose logs -f
```

### Development

```bash
# 1. Pull images (automatically from latest main)
docker compose -f docker-compose.dev.yml pull

# 2. Start services
docker compose -f docker-compose.dev.yml up -d

# 3. Run tests
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec

# 4. Rails console
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console
```

---

## Port Reference

| Service | Production | Development |
|---------|------------|-------------|
| MariaDB | 3306 | 3307 |
| Web | 5000 (behind Caddy) | 5001 |
| SMTP | 25 | 2525 |
| HTTP | 80 (Caddy) | - |
| HTTPS | 443 (Caddy) | - |

---

## Utility Commands

### Production

```bash
# Restart services
docker compose restart web worker

# View logs
docker compose logs -f web

# Shell access
docker compose exec web bash

# Run Postal CLI
docker compose run --rm runner postal [command]

# Stop services
docker compose down
```

### Development

```bash
# Pull latest images
docker compose -f docker-compose.dev.yml pull

# Start services
docker compose -f docker-compose.dev.yml up -d

# Run tests
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec

# Rails console
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console

# Database migrations
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rake db:migrate
```

---

## Best Practices

### Production

- Use `docker compose up -d` for daemon mode
- Set secure passwords in `.env` file
- Configure `config/postal.yml` with production values
- Use `config/Caddyfile` for SSL/TLS and domain routing
- Regular backups: `docker compose exec mariadb mysqldump ...`

### Development

- Always use `-f docker-compose.dev.yml` flag
- Run tests before each commit
- Clean up volumes regularly: `docker compose -f docker-compose.dev.yml down -v`

---

## Building Local Images

Only needed if testing local changes outside of Git:

```bash
# Build development image locally (optional)
docker compose -f docker-compose.dev.yml build

# Or use the build script for specific architecture
./scripts/build.sh arm64    # ARM64 (Apple Silicon)
./scripts/build.sh amd64    # AMD64 (Intel/Linux)
./scripts/build.sh all      # Both (requires buildx)
```

Production uses pre-built images automatically - no build required.

---

## Related Documentation

- [Development Setup](development.md) - Full development guide
- [Quick Start](QUICKSTART.md) - 5-minute setup
- [Configuration](config/configuration.md) - All configuration options
