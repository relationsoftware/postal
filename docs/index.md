# Postal

This is a customized fork of [Postal](https://postalserver.io) — an open-source, self-hosted mail delivery platform with a modern Admin API, Docker-based deployment, and comprehensive mail handling capabilities.

## Key Features

| Feature | Description |
|---------|-------------|
| Multi-tenancy | Organizations and servers with granular permissions |
| HTTP & SMTP APIs | Send via REST API or SMTP |
| Admin API v2 | Full REST API for headless management |
| Click & Open Tracking | Track user engagement |
| Webhook Support | Real-time event notifications |
| IP Pool Management | Control sending IPs |
| DKIM & SPF | Built-in email authentication |
| Web Interface | Full-featured management UI |
| Spam Checking | SpamAssassin integration |

## Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Ruby on Rails 7.1 |
| Database | MariaDB 10.6+ |
| Application Server | Puma |
| Containerization | Docker / Docker Compose |
| Reverse Proxy | Caddy |
| Monitoring | Prometheus metrics |

## Quick Links

- [Quick Start](QUICKSTART.md) — Get running in 5 minutes
- [Installation Checklist](INSTALL-CHECKLIST.md) — Production deployment checklist
- [Development Setup](development.md) — Local development environment
- [Admin API Reference](admin-api.md) — REST API documentation
- [Docker Compose Guide](docker-compose.md) — Container deployment options
