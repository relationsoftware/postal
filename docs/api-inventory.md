# API Inventory & Implementation Status

Overview of all APIs in Postal and their implementation status.

---

## Admin API v2 (Primary)

**Purpose:** Complete management API for headless operation  
**Route:** `/api/v2/admin/*`  
**Format:** JSON Request/Response  
**Auth:** `X-Admin-API-Key` header

### Status Summary

| Metric | Value |
|--------|-------|
| Implemented Controllers | 14 |
| With Tests | 5 |
| Test Examples | 74+ |

### Implemented Controllers (with tests)

| Controller | Endpoint | Tests |
|-----------|----------|-------|
| `credentials_controller` | `/organizations/:org/servers/:srv/credentials` | 12 |
| `endpoints_controller` | `/organizations/:org/servers/:srv/{http,smtp,address}_endpoints` | 12 |
| `organizations_controller` | `/organizations` | 13 |
| `servers_controller` | `/organizations/:org/servers` | 14 |
| `webhooks_controller` | `/organizations/:org/servers/:srv/webhooks` | 11 |

### Implemented Controllers (need tests)

| Controller | Endpoint |
|-----------|----------|
| `domains_controller` | `/organizations/:org/servers/:srv/domains` |
| `routes_controller` | `/organizations/:org/servers/:srv/routes` |
| `users_controller` | `/users` |
| `ip_pools_controller` | `/ip_pools` |
| `ip_addresses_controller` | `/ip_pools/:pool/ip_addresses` |
| `messages_controller` | `/organizations/:org/servers/:srv/messages` |
| `organization_users_controller` | `/organizations/:org/users` |
| `suppressions_controller` | `/organizations/:org/servers/:srv/suppressions` |
| `track_domains_controller` | `/organizations/:org/servers/:srv/track_domains` |

---

## Legacy API v1

**Purpose:** Email sending and message tracking  
**Route:** `/api/v1/*`  
**Format:** HTTP POST with JSON body  
**Auth:** `X-Server-API-Key` header

### Controllers

Located in `app/controllers/legacy_api/`:

- `base_controller`
- `messages_controller`
- `send_controller`

### Endpoints

```
POST /api/v1/send/message
POST /api/v1/send/raw
POST /api/v1/messages/message
POST /api/v1/messages/deliveries
```

---

## Web UI Controllers

**Purpose:** Admin web interface  
**Routes:** `/org/*`, `/organizations`, `/servers`, etc.  
**Format:** HTML responses with HAML templates

These controllers provide the web interface and are not needed for headless/API operation.

---

## Implementation Priorities

### High Priority

Add test coverage for implemented controllers:

1. `domains_controller`
2. `routes_controller`
3. `users_controller`
4. `ip_pools_controller`
5. `ip_addresses_controller`
6. `messages_controller`
7. `organization_users_controller`
8. `suppressions_controller`
9. `track_domains_controller`

### Medium Priority

- Review Legacy API v1 status
- Document any missing functionality

### Low Priority

- Generate complete OpenAPI spec

---

## API Configuration

### Base URL

```
https://your-postal-domain/api/v2/admin
```

### Authentication

```http
X-Admin-API-Key: your-api-key
```

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

## OpenAPI Generation

Generate OpenAPI specification:

```bash
OPENAPI=1 ./scripts/generate-openapi.sh
```

Output: `public/openapi/postal-admin-api.yaml`

---

## Related Documentation

- [Admin API Reference](admin-api.md) - Complete API documentation
- [Developer API Guide](developer/api.md) - Legacy API documentation
- [Webhooks](developer/webhooks.md) - Webhook events
