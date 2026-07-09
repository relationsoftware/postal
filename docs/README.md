# Postal Documentation

Complete documentation for this customized fork of Postal — an open-source mail delivery platform.

---

## Quick Navigation

| Guide | Description |
|-------|-------------|
| [Quick Start](QUICKSTART.md) | Get running in 5 minutes |
| [Development Setup](development.md) | Local development environment |
| [Docker Compose](docker-compose.md) | Container deployment options |
| [Admin API](admin-api.md) | REST API reference |
| [Installation Checklist](INSTALL-CHECKLIST.md) | Production deployment checklist |

---

## Documentation Structure

### Setup & Deployment

Essential guides for getting started:

- [Quick Start](QUICKSTART.md) - Fast setup with Docker Compose
- [Installation Checklist](INSTALL-CHECKLIST.md) - Complete deployment checklist
- [Development Setup](development.md) - Local development environment
- [Docker Compose Guide](docker-compose.md) - Container configurations
- [Contributing](contributing.md) - How to contribute to the project
- [Testing Guide](TESTING.md) - Running and writing tests

### Configuration

Configuration options and settings:

- [Configuration Overview](config/configuration.md) - Configuration methods
- [Environment Variables](config/environment-variables.md) - All environment variables

### Getting Started (Original Postal Docs)

Installation and setup guides from upstream:

- [Getting Started](getting-started/index.md) - Overview and installation process
- [Prerequisites](getting-started/prerequisites.md) - System requirements
- [Installation](getting-started/installation.md) - Step-by-step installation
- [DNS Configuration](getting-started/dns-configuration.md) - Required DNS records
- [Configuration](getting-started/configuration.md) - Configuration options
- [Upgrading](getting-started/upgrading.md) - How to upgrade Postal
- [Upgrade to v3](getting-started/upgrade-to-v3.md) - Upgrading from v2 to v3
- [Upgrade to v2](getting-started/upgrade-to-v2.md) - Upgrading from v1 to v2

### Features

Detailed feature documentation:

- [Click & Open Tracking](features/click-and-open-tracking.md) - Track email engagement
- [Health & Metrics](features/health-metrics.md) - Monitoring and performance
- [IP Pools](features/ip-pools.md) - Manage sending IP addresses
- [Logging](features/logging.md) - Log configuration
- [OpenID Connect](features/oidc.md) - OIDC authentication
- [SMTP Authentication](features/smtp-authentication.md) - Authentication methods
- [SMTP TLS](features/smtp-tls.md) - TLS configuration
- [Spam & Virus Checking](features/spam-and-virus-checking.md) - SpamAssassin/ClamAV

### Developer & API

Integration and API documentation:

- [Admin API v2](admin-api.md) - Full administrative REST API
- [API Inventory](api-inventory.md) - API implementation status
- [Using the API](developer/api.md) - Legacy HTTP API documentation
- [Client Libraries](developer/client-libraries.md) - Available SDKs
- [HTTP Payloads](developer/http-payloads.md) - Receiving email via HTTP
- [Webhooks](developer/webhooks.md) - Webhook events and payloads

### Operations

Operational topics:

- [Auto-Responders & Bounces](other/auto-responders-and-bounces.md) - Bounce handling
- [Container Image](other/containers.md) - Docker container details
- [Debugging](other/debugging.md) - Troubleshooting guide
- [Wildcards & Address Tags](other/wildcards-and-address-tags.md) - Advanced routing

### Project

Project management and history:

- [Changelog](changelog.md) - Version history and changes
- [Security](security.md) - Security policy

---

## Welcome

Introduction to Postal:

- [Feature List](welcome/feature-list.md) - Complete list of capabilities
- [FAQs](welcome/faqs.md) - Frequently asked questions

---

## About this fork

This is a customized fork of [Postal](https://postalserver.io), providing:

- **Modern Admin API** - Complete REST API for headless management
- **Docker Deployment** - Simplified Docker Compose setup
- **Multi-Architecture** - ARM64 and AMD64 images
- **Automated CI/CD** - GitHub Actions for testing and releases

### Key Features

| Feature | Description |
|---------|-------------|
| Multi-tenancy | Organizations and servers with granular permissions |
| HTTP & SMTP APIs | Send via API or SMTP |
| Click & Open Tracking | Track user engagement |
| Webhook Support | Real-time event notifications |
| IP Pool Management | Control sending IPs |
| DKIM & SPF | Built-in email authentication |
| Web Interface | Full-featured management UI |
| Message Retention | Configurable message storage |
| Spam Checking | SpamAssassin integration |

### Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Ruby on Rails 7.1.5.2 |
| Database | MariaDB (10.6+) |
| Application Server | Puma |
| Containerization | Docker |
| Monitoring | Prometheus metrics |

---

## External Links

- [Original Postal](https://github.com/postalserver/postal)
- [Postal Documentation](https://docs.postalserver.io)
- [Postal Discord](https://discord.postalserver.io)
