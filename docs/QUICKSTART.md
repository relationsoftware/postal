# Quick Start Guide

Get Postal running in 5 minutes with Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- Domain name with DNS access
- At least 4GB RAM and 2 CPU cores
- Ports 25, 80, 443 available

---

## Setup Steps

### 1. Initial Setup

```bash
./scripts/setup.sh
```

Creates:
- `config/postal.yml` - Main configuration
- `config/Caddyfile` - Web proxy configuration  
- `config/signing.key` - Signing key
- `.env` - Environment variables

### 2. Configure Your Domain

Edit `config/postal.yml`:

```yaml
postal:
  web_hostname: postal.yourdomain.com
  smtp_hostname: postal.yourdomain.com

dns:
  mx_records:
    - mx.postal.yourdomain.com
  spf_include: spf.postal.yourdomain.com
  return_path_domain: rp.postal.yourdomain.com
  route_domain: routes.postal.yourdomain.com
  track_domain: track.postal.yourdomain.com
```

Edit `config/Caddyfile` and replace `postal.yourdomain.com` with your actual domain.

### 3. Initialize Database

```bash
./scripts/initialize.sh
```

### 4. Create Admin User

```bash
./scripts/make-user.sh
```

### 5. Start Postal

```bash
docker compose up -d
```

---

## Access Your Installation

| Service | URL |
|---------|-----|
| Web Interface | https://postal.yourdomain.com |
| SMTP Server | smtp://postal.yourdomain.com:25 |

---

## DNS Configuration

Configure these DNS records before sending/receiving email:

| Type | Hostname | Value |
|------|----------|-------|
| A | postal.yourdomain.com | Your-Server-IP |
| A | mx.postal.yourdomain.com | Your-Server-IP |
| MX | yourdomain.com | 10 mx.postal.yourdomain.com |
| TXT | spf.postal.yourdomain.com | v=spf1 ip4:Your-Server-IP ~all |
| TXT | postal._domainkey.rp.yourdomain.com | Get from Postal interface |

See [DNS Configuration](getting-started/dns-configuration.md) for complete details.

---

## Common Commands

### Status & Logs

```bash
# View status
./scripts/status.sh
docker compose ps

# View logs
docker compose logs -f
docker compose logs -f web
```

### Control Services

```bash
# Restart
docker compose restart

# Stop
docker compose down

# Upgrade
./scripts/upgrade.sh 3.3.4
```

### Console & Commands

```bash
# Rails console
docker compose run --rm runner postal console

# Run Postal commands
docker compose run --rm runner postal [command]
```

---

## Services

| Service | Description |
|---------|-------------|
| `web` | Postal web interface (port 5000) |
| `smtp` | SMTP server (port 25) |
| `worker` | Background job processor |
| `mariadb` | Database server (port 3306) |
| `caddy` | Reverse proxy with automatic SSL (ports 80, 443) |
| `runner` | For running one-off commands |

---

## Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production setup |
| `docker-compose.dev.yml` | Development setup |
| `config/postal.yml` | Main Postal configuration |
| `config/Caddyfile` | Reverse proxy configuration |
| `.env` | Environment variables |

---

## Environment Variables

Edit `.env` to customize:

```env
POSTAL_VERSION=3.3.4
MARIADB_ROOT_PASSWORD=your_secure_password
```

---

## Troubleshooting

```bash
# Check services
docker compose ps

# Check logs
docker compose logs

# Test SMTP
telnet postal.yourdomain.com 25

# Verify database
docker compose exec mariadb mysql -u root -ppostal postal
```

---

## Data & Backup

### Data Volumes

- `mariadb-data` - Database data
- `caddy-data` - SSL certificates
- `caddy-config` - Caddy configuration

### Backup

```bash
# Backup database
docker compose exec mariadb \
  mysqldump -u root -ppostal --all-databases > backup.sql

# Backup configuration
tar -czf config-backup.tar.gz config/
```

---

## Next Steps

- [Installation Checklist](INSTALL-CHECKLIST.md) - Verify all steps
- [Configuration Options](getting-started/configuration.md) - All settings
- [DNS Setup](getting-started/dns-configuration.md) - Complete DNS guide
- [Features](features/) - All capabilities
- [Admin API](admin-api.md) - REST API reference
