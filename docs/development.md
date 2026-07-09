# Development Setup Guide

This guide helps you set up Postal locally for development.

## Prerequisites

- Docker & Docker Compose v2.6+
- Git
- ~5GB free disk space

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/relationsoftware/postal.git
cd mail
```

### 2. Verify Configuration Files

Required files are already included:

```
config/postal.yml        # Development configuration template
config/Caddyfile         # Reverse proxy configuration
.env.development         # Environment variables
.env.test                # Test environment variables
```

### 3. Start Development Environment

```bash
# Option A: Using docker compose (recommended)
docker compose -f docker-compose.dev.yml pull
docker compose -f docker-compose.dev.yml up -d

# Option B: With environment file
docker compose -f docker-compose.dev.yml --env-file .env.development up -d
```

### 4. Database Initialization

Database initializes automatically on first start. To manually reset:

```bash
# Enter the runner container
docker compose -f docker-compose.dev.yml run --rm runner sh

# Inside the shell:
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:schema:load
```

### 5. Create Admin User

```bash
docker compose -f docker-compose.dev.yml run --rm runner sh -c \
  'bundle exec postal user admin@localhost.localdomain password123'
```

### 6. Access Services

| Service | URL |
|---------|-----|
| Web UI | http://localhost:5001 |
| SMTP Server | localhost:2525 |
| Database | localhost:3307 |

---

## Configuration Files

### config/postal.yml

Main Postal configuration:

```yaml
postal:
  web_hostname: localhost:5001      # Web interface URL
  smtp_hostname: localhost          # SMTP server

main_db:                            # Primary database
  host: mariadb
  username: root
  password: postal
  database: postal

smtp:                               # Internal SMTP settings
  host: 127.0.0.1
  port: 2525
  username: admin@localhost.localdomain
  password: test123
  from_address: postal@localhost.localdomain
```

**Important development settings:**

- `web_hostname`: Must use http (not https)
- `web_protocol`: `http` for local development
- `smtp.host`: Can be 127.0.0.1 (container internal)
- `rails.secret_key`: Can be any value for development

### .env.development

Environment variables:

```bash
POSTAL_VERSION=latest-dev        # Always latest-dev for development
MARIADB_ROOT_PASSWORD=postal     # Database password
RAILS_ENV=development            # Rails environment
```

---

## Running Tests

### All Tests

```bash
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec
```

### Specific Test File

```bash
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec spec/lib/query_string_spec.rb
```

### Set Up Test Database

```bash
docker compose -f docker-compose.dev.yml run --rm runner sh -c \
  'RAILS_ENV=test bundle exec rake db:create db:schema:load'
```

---

## Rails Console

```bash
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console
```

Example commands:

```ruby
# List users
User.all

# Create organization
Organization.create(name: "Test Org")

# Create user
User.create(email: "test@example.com", password: "test123")
```

---

## Database Management

### MariaDB Shell

```bash
docker compose -f docker-compose.dev.yml exec mariadb mysql -uroot -ppostal
```

### Dump Database

```bash
docker compose -f docker-compose.dev.yml exec mariadb mysqldump -uroot -ppostal postal > backup.sql
```

### Restore Database

```bash
docker compose -f docker-compose.dev.yml exec mariadb mysql -uroot -ppostal postal < backup.sql
```

---

## Viewing Logs

### All Services

```bash
docker compose -f docker-compose.dev.yml logs -f
```

### Specific Service

```bash
docker compose -f docker-compose.dev.yml logs -f web
docker compose -f docker-compose.dev.yml logs -f smtp
docker compose -f docker-compose.dev.yml logs -f worker
```

### Last 50 Lines

```bash
docker compose -f docker-compose.dev.yml logs --tail=50
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check container status
docker compose -f docker-compose.dev.yml ps

# Check logs for errors
docker compose -f docker-compose.dev.yml logs --tail=100
```

### Database Connection Issues

```bash
# Verify MariaDB is running
docker compose -f docker-compose.dev.yml exec mariadb mysql -uroot -ppostal -e "SELECT 1"
```

### Reset Everything

```bash
# Stop and remove all containers and volumes
docker compose -f docker-compose.dev.yml down -v

# Start fresh
docker compose -f docker-compose.dev.yml up -d
```

---

## Related Documentation

- [Docker Compose Guide](docker-compose.md) - Full deployment options
- [Testing Guide](TESTING.md) - Detailed testing information
- [Contributing Guide](contributing.md) - How to contribute
