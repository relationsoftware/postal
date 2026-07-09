# Installation Checklist

Use this checklist to verify a complete Postal deployment.

---

## Prerequisites

- [ ] Server with at least 4GB RAM and 2 CPU cores
- [ ] Docker and Docker Compose installed
- [ ] Git installed
- [ ] Domain name registered
- [ ] DNS access for domain configuration
- [ ] Ports 25, 80, 443 available and not blocked by firewall

---

## Configuration Setup

### 1. Initial Setup

- [ ] Run `./scripts/setup.sh`
- [ ] Verify `config/postal.yml` was created
- [ ] Verify `config/Caddyfile` was created
- [ ] Verify `config/signing.key` was created
- [ ] Verify `.env` was created

### 2. Edit Configuration Files

#### config/postal.yml

- [ ] Update `postal.web_hostname` with your domain
- [ ] Update `postal.smtp_hostname` with your domain
- [ ] Update all DNS records under `dns:` section:
  - [ ] `mx_records`
  - [ ] `spf_include`
  - [ ] `return_path_domain`
  - [ ] `route_domain`
  - [ ] `track_domain`
- [ ] Update database password in `main_db.password`
- [ ] Update database password in `message_db.password`
- [ ] Configure SMTP settings for notifications (optional)

#### config/Caddyfile

- [ ] Replace `postal.yourdomain.com` with your actual domain
- [ ] Add tracking domain configuration if using click/open tracking

#### .env

- [ ] Set `MARIADB_ROOT_PASSWORD` to a secure password
- [ ] Verify `POSTAL_VERSION` is correct

---

## DNS Configuration

Configure these DNS records with your domain provider:

### A Records

- [ ] `postal.yourdomain.com` → Your-Server-IP
- [ ] `mx.postal.yourdomain.com` → Your-Server-IP
- [ ] `rp.postal.yourdomain.com` → Your-Server-IP (return path)
- [ ] `routes.postal.yourdomain.com` → Your-Server-IP (optional)
- [ ] `track.postal.yourdomain.com` → Your-Server-IP (optional)

### MX Records

- [ ] Your domain → `10 mx.postal.yourdomain.com`

### TXT Records

- [ ] SPF: `spf.postal.yourdomain.com` → `v=spf1 ip4:Your-Server-IP ~all`
- [ ] DKIM: Get value from Postal after setup

### PTR Record (Reverse DNS)

- [ ] Your-Server-IP → `postal.yourdomain.com`
  - Contact your hosting provider to set this up

---

## Database Initialization

- [ ] Run `./scripts/initialize.sh`
- [ ] Verify database tables were created successfully
- [ ] No errors in the output

---

## User Creation

- [ ] Run `./scripts/make-user.sh`
- [ ] Enter admin email address
- [ ] Enter first name
- [ ] Enter last name
- [ ] Enter secure password
- [ ] Confirm password
- [ ] Verify user was created successfully

---

## Service Startup

- [ ] Run `docker compose up -d`
- [ ] All services started (web, smtp, worker, mariadb, caddy)
- [ ] Run `./scripts/status.sh` to verify all services are running
- [ ] Check logs: `docker compose logs`

---

## Access Verification

### Web Interface

- [ ] Access https://postal.yourdomain.com
- [ ] SSL certificate was issued automatically by Caddy
- [ ] Login with your admin credentials
- [ ] Dashboard loads successfully

### SMTP Server

- [ ] Test SMTP connection: `telnet postal.yourdomain.com 25`
- [ ] Receive greeting from Postal SMTP server
- [ ] Exit with `QUIT`

### DNS Verification

- [ ] In Postal web interface, go to a server
- [ ] Check DNS status for your domains
- [ ] All DNS checks should be green/passing

---

## Post-Installation

### Create Your First Mail Server

- [ ] Login to Postal web interface
- [ ] Create a new organization (if needed)
- [ ] Create a new mail server
- [ ] Add a sending domain
- [ ] Verify domain DNS records
- [ ] Get DKIM record and add to DNS
- [ ] Create credentials for SMTP/API access

### Test Email Sending

- [ ] Use Postal's test function
- [ ] Send test email to your personal address
- [ ] Verify email was received
- [ ] Check spam score (use mail-tester.com)
- [ ] Verify DKIM signature
- [ ] Verify SPF pass

---

## Security Hardening

- [ ] Change default database password in `.env` and `config/postal.yml`
- [ ] Review and update firewall rules
- [ ] Enable automatic security updates on server
- [ ] Set up regular database backups
- [ ] Configure monitoring (optional)
- [ ] Set up log rotation

---

## Backup Setup

- [ ] Test database backup
- [ ] Test config backup
- [ ] Schedule automatic backups (cron)
- [ ] Store backups off-site
- [ ] Test restore procedure

### Backup Commands

```bash
# Database backup
docker compose exec mariadb mysqldump -u root -ppostal --all-databases > backup.sql

# Configuration backup
tar -czf config-backup.tar.gz config/
```

---

## Monitoring (Optional)

- [ ] Configure Prometheus metrics collection
- [ ] Set up health check monitoring
- [ ] Configure alerting for service failures
- [ ] Monitor disk space usage
- [ ] Monitor database size

---

## Troubleshooting

If something doesn't work:

1. **Check logs**: `docker compose logs -f`
2. **Verify services**: `./scripts/status.sh`
3. **Check DNS**: Use `dig` or online DNS checker
4. **Test connectivity**: `telnet postal.yourdomain.com 25`
5. **Review configuration**: Double-check `config/postal.yml`

---

## Useful Commands

```bash
# View status
docker compose ps

# View logs
docker compose logs -f web

# Restart services
docker compose restart

# Access console
docker compose run --rm runner postal console

# Access database
docker compose exec mariadb mysql -u root -ppostal postal
```

---

## Resources

- [Quick Start Guide](QUICKSTART.md)
- [Full Documentation](README.md)
- [Development Setup](development.md)
- [Admin API Reference](admin-api.md)

---

**Completion Date**: _________________

**Completed By**: _________________

**Notes**:
