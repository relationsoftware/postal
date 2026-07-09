# Agent Description: Postal

## 🤖 Repository Overview

This repository is a customized fork of [Postal](https://postalserver.io), an open-source mail delivery platform. This repository provides a complete, self-hosted email infrastructure solution with a modern Admin API, Docker-based deployment, and comprehensive mail handling capabilities.

---

## 📦 Project Identity

| Property | Value |
|----------|-------|
| **Name** | Postal (Fork) |
| **Type** | Ruby on Rails Application |
| **Ruby Version** | 3.2+ |
| **Rails Version** | 7.1.5.2 |
| **Primary Language** | Ruby |
| **Secondary Languages** | JavaScript, HAML, SCSS |
| **Package Manager** | Bundler |
| **Database** | MariaDB/MySQL |
| **Container Registry** | `ghcr.io/relationsoftware/postal` |

---

## 🎯 Core Purpose

This application serves as a **complete mail transfer agent (MTA)** with:

1. **Outbound Email Delivery** - Send transactional and marketing emails via SMTP or HTTP API
2. **Inbound Email Processing** - Receive, route, and forward incoming emails
3. **Multi-Tenant Architecture** - Organizations, servers, users with granular permissions
4. **Comprehensive Admin API** - Full REST API for headless/programmatic management
5. **Webhook Integration** - Real-time notifications for email events
6. **Tracking & Analytics** - Open/click tracking, delivery status, suppressions

---

## 🏗️ Architecture

### Application Structure

```
postal/
├── app/
│   ├── controllers/
│   │   ├── admin_api/          # REST API v2 (17 controllers)
│   │   ├── legacy_api/         # Legacy API v1
│   │   └── *.rb                # Web UI controllers
│   ├── models/                 # ActiveRecord models
│   ├── views/                  # HAML templates
│   ├── services/               # Business logic services
│   ├── senders/                # Email sending logic
│   └── scheduled_tasks/        # Background jobs
├── config/
│   ├── routes.rb               # API & web routes
│   ├── postal.yml              # Main configuration
│   └── database.yml            # Database config
├── lib/
│   └── postal/                 # Core postal library
├── spec/                       # RSpec test suite
├── docker-compose.yml          # Production deployment
└── docker-compose.dev.yml      # Development environment
```

### Key Components

| Component | Description |
|-----------|-------------|
| **Web UI** | Rails-based admin interface on port 5000/5001 |
| **Admin API v2** | REST JSON API at `/api/v2/admin/*` |
| **SMTP Server** | Inbound/outbound SMTP on port 25/2525 |
| **Worker** | Background job processor for email delivery |
| **MariaDB** | Primary database for configuration & metadata |
| **Message DB** | Per-server databases for message storage |

---

## 🔌 Admin API v2

The primary interface for programmatic control. All endpoints require `X-Admin-API-Key` header.

### Implemented Endpoints

| Resource | Base Path | Operations |
|----------|-----------|------------|
| Organizations | `/api/v2/admin/organizations` | CRUD |
| Servers | `/api/v2/admin/organizations/:org/servers` | CRUD + suspend/unsuspend |
| Domains | `/api/v2/admin/organizations/:org/servers/:srv/domains` | CRUD + verify/check |
| Routes | `/api/v2/admin/organizations/:org/servers/:srv/routes` | CRUD |
| Credentials | `/api/v2/admin/organizations/:org/servers/:srv/credentials` | CRUD |
| Webhooks | `/api/v2/admin/organizations/:org/servers/:srv/webhooks` | CRUD + enable/disable |
| HTTP Endpoints | `/api/v2/admin/organizations/:org/servers/:srv/http_endpoints` | CRUD |
| SMTP Endpoints | `/api/v2/admin/organizations/:org/servers/:srv/smtp_endpoints` | CRUD |
| Address Endpoints | `/api/v2/admin/organizations/:org/servers/:srv/address_endpoints` | CRUD |
| Messages | `/api/v2/admin/organizations/:org/servers/:srv/messages` | List, Show, Retry, Cancel |
| Track Domains | `/api/v2/admin/organizations/:org/servers/:srv/track_domains` | CRUD + check |
| Suppressions | `/api/v2/admin/organizations/:org/servers/:srv/suppressions` | List, Create, Delete |
| Users | `/api/v2/admin/users` | CRUD |
| Organization Users | `/api/v2/admin/organizations/:org/users` | List, Add, Update, Remove |
| IP Pools | `/api/v2/admin/ip_pools` | CRUD |
| IP Addresses | `/api/v2/admin/ip_pools/:pool/ip_addresses` | CRUD |

### Response Format

```json
{
  "status": "success",
  "time": 0.042,
  "data": {
    "resource": { ... }
  }
}
```

---

## 🐳 Deployment

### Docker Images

| Tag | Purpose |
|-----|---------|
| `ghcr.io/relationsoftware/postal:latest` | Latest build from `main` |
| `ghcr.io/relationsoftware/postal:sha-XXXXXXX` | Immutable per-commit tag (rollback) |

Images are built with `scripts/build.sh` (see `--registry` to override the target registry).

### Quick Start

```bash
# Development
docker compose -f docker-compose.dev.yml up -d
# Access: http://localhost:5001

# Production
docker compose up -d
# Access: https://your-domain.com (via Caddy)
```

---

## 🧪 Testing

```bash
# Run all specs
bundle exec rspec

# Run Admin API specs
bundle exec rspec spec/apis/admin_api/

# Run specific test
bundle exec rspec spec/apis/admin_api/domains_spec.rb
```

### Test Coverage

| Area | Specs | Status |
|------|-------|--------|
| Admin API Controllers | 9 spec files | ✅ Partial |
| Models | Multiple | ✅ Yes |
| Services | Multiple | ✅ Yes |

---

## 📁 Key Files for Agents

When working with this codebase, these are the most important files:

### Configuration
- [config/routes.rb](config/routes.rb) - All API and web routes
- [config/postal.yml](config/postal.yml) - Main application config
- [config/database.yml](config/database.yml) - Database configuration

### API Controllers
- [app/controllers/admin_api/base_controller.rb](app/controllers/admin_api/base_controller.rb) - Base API controller with auth
- [app/controllers/admin_api/*.rb](app/controllers/admin_api/) - All 17 API controllers

### Models
- [app/models/](app/models/) - ActiveRecord models for all entities
- [db/schema.rb](db/schema.rb) - Database schema

### Tests
- [spec/apis/admin_api/](spec/apis/admin_api/) - API request specs
- [spec/apis/admin_api/shared_context.rb](spec/apis/admin_api/shared_context.rb) - Shared test helpers

### Documentation
- [docs/README.md](docs/README.md) - Documentation index
- [docs/api-inventory.md](docs/api-inventory.md) - API implementation status
- [docs/admin-api.md](docs/admin-api.md) - Admin API reference
- [docs/development.md](docs/development.md) - Development setup

---

## 🔧 Development Commands

```bash
# Start development environment
docker compose -f docker-compose.dev.yml up -d

# Rails console
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rails console

# Run migrations
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rake db:migrate

# Generate OpenAPI docs
bundle exec rake openapi:generate

# Lint code
bundle exec rubocop

# Create admin user
./scripts/make-user.sh
```

---

## 🎓 Agent Instructions

When working on this repository:

1. **API Changes**: Follow the pattern in existing `admin_api/` controllers
2. **New Endpoints**: Add routes in `config/routes.rb` under the `admin_api` namespace
3. **Testing**: Create request specs in `spec/apis/admin_api/` using the shared context
4. **Response Format**: Use `render_success`, `render_created`, `render_error` helpers
5. **Authentication**: All admin API requires `X-Admin-API-Key` header
6. **Pagination**: Use the `paginate` helper for list endpoints
7. **Error Handling**: Return 422 for validation errors, 404 for not found

### Conventions

- Controllers use `find_by!` with rescue for 404 handling
- UUIDs are preferred over IDs for external references
- JSON serialization is done via `*_json` private methods
- Polymorphic associations (endpoints, owners) are common

---

## 📊 Current Status

- **Controllers**: 17/17 implemented ✅
- **Test Coverage**: ~60% (some controllers need specs)
- **Documentation**: OpenAPI generation available
- **Docker**: Multi-arch images (arm64/amd64)

See [docs/api-inventory.md](docs/api-inventory.md) for implementation details.
