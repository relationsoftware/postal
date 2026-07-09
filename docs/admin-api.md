# Postal Admin API v2

The Admin API provides full administrative control over Postal, allowing external applications to manage organizations, servers, domains, credentials, routes, and all other resources.

## Authentication

All requests must include the `X-Admin-API-Key` header with a valid API key.

```bash
curl -H "X-Admin-API-Key: your-api-key" https://postal.example.com/api/v2/admin/organizations
```

### Configuration

Set the admin API key in your Postal configuration:

```yaml
postal:
  admin_api_key: "your-secure-api-key"
```

## Response Format

All responses are JSON with the following structure:

### Success Response
```json
{
  "status": "success",
  "time": 0.123,
  "data": { ... }
}
```

### Error Response
```json
{
  "status": "error",
  "time": 0.123,
  "error": {
    "code": "ErrorCode",
    "message": "Error description",
    "errors": ["Validation error 1", "Validation error 2"]
  }
}
```

## Pagination

List endpoints support pagination with the following query parameters:
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

Paginated responses include:
```json
{
  "pagination": {
    "page": 1,
    "per_page": 25,
    "total": 100,
    "total_pages": 4
  }
}
```

---

## Organizations

### List Organizations
```
GET /api/v2/admin/organizations
```

### Get Organization
```
GET /api/v2/admin/organizations/:permalink
```

### Create Organization
```
POST /api/v2/admin/organizations
```
Parameters:
- `name` (required) - Organization name
- `permalink` - URL-friendly identifier (auto-generated if not provided)
- `time_zone` - Time zone (default: UTC)
- `owner_email` - Email of the user to set as owner

### Update Organization
```
PATCH /api/v2/admin/organizations/:permalink
```

### Delete Organization
```
DELETE /api/v2/admin/organizations/:permalink
```

---

## Organization Users

### List Organization Users
```
GET /api/v2/admin/organizations/:organization_id/users
```

### Add User to Organization
```
POST /api/v2/admin/organizations/:organization_id/users/add
```
Parameters:
- `email` (required) - User's email address
- `admin` - Is organization admin (default: false)
- `all_servers` - Has access to all servers (default: false)

### Update Organization User
```
PATCH /api/v2/admin/organizations/:organization_id/users/:user_uuid
```
Parameters:
- `admin` - Is organization admin
- `all_servers` - Has access to all servers

### Remove User from Organization
```
DELETE /api/v2/admin/organizations/:organization_id/users/:user_uuid
```

---

## Servers

### List Servers
```
GET /api/v2/admin/organizations/:organization_id/servers
```

### Get Server
```
GET /api/v2/admin/organizations/:organization_id/servers/:permalink
```

### Create Server
```
POST /api/v2/admin/organizations/:organization_id/servers
```
Parameters:
- `name` (required) - Server name
- `permalink` - URL-friendly identifier
- `mode` - Server mode: `Live` or `Development`
- `send_limit` - Maximum emails per hour
- `allow_sender` - Allowed sender pattern
- `log_smtp_data` - Log SMTP data
- `outbound_spam_threshold` - Spam threshold for outbound
- `message_retention_days` - Days to retain messages
- `raw_message_retention_days` - Days to retain raw messages
- `priority` - Queue priority (higher = processed first)

### Update Server
```
PATCH /api/v2/admin/organizations/:organization_id/servers/:permalink
```

### Delete Server
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:permalink
```

### Suspend Server
```
POST /api/v2/admin/organizations/:organization_id/servers/:permalink/suspend
```
Parameters:
- `reason` - Suspension reason

### Unsuspend Server
```
POST /api/v2/admin/organizations/:organization_id/servers/:permalink/unsuspend
```

---

## Domains

### List Domains
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
```

### Get Domain
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
```

### Create Domain
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
```
Parameters:
- `name` (required) - Domain name

### Delete Domain
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
```

### Verify Domain DNS
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id/verify
```

---

## Credentials

### List Credentials
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials
```

### Get Credential
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:uuid
```

### Create Credential
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials
```
Parameters:
- `name` (required) - Credential name
- `type` (required) - Type: `SMTP`, `API`, or `SMTP-IP`
- `key` - For SMTP-IP: the IP address
- `hold` - Hold messages sent with this credential

### Update Credential
```
PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:uuid
```
Parameters:
- `name` - Credential name
- `hold` - Hold messages

### Delete Credential
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:uuid
```

---

## Routes

### List Routes
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/routes
```

### Get Route
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:uuid
```

### Create Route
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/routes
```
Parameters:
- `name` (required) - Route name (e.g., `*@example.com`)
- `mode` - Mode: `Endpoint`, `Bounce`, `Reject`, `Hold`
- `spam_mode` - Spam handling: `Mark`, `Quarantine`, `Fail`
- `endpoint_uuid` - UUID of the endpoint
- `endpoint_type` - Type: `HTTPEndpoint`, `SMTPEndpoint`, `AddressEndpoint`

### Update Route
```
PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:uuid
```

### Delete Route
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:uuid
```

---

## HTTP Endpoints

### List HTTP Endpoints
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/http_endpoints
```

### Create HTTP Endpoint
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/http_endpoints
```
Parameters:
- `name` (required) - Endpoint name
- `url` (required) - Webhook URL
- `encoding` - Encoding: `BodyAsJSON`, `FormData`
- `format` - Format: `Hash`, `RawMessage`
- `strip_replies` - Strip reply content
- `include_attachments` - Include attachments
- `timeout` - Request timeout in seconds

---

## SMTP Endpoints

### List SMTP Endpoints
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints
```

### Create SMTP Endpoint
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints
```
Parameters:
- `name` (required) - Endpoint name
- `hostname` (required) - SMTP server hostname
- `port` - SMTP port (default: 25)
- `ssl_mode` - SSL mode: `None`, `Auto`, `STARTTLS`, `TLS`

---

## Address Endpoints

### List Address Endpoints
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints
```

### Create Address Endpoint
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints
```
Parameters:
- `address` (required) - Email address to forward to

---

## Webhooks

### List Webhooks
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks
```

### Create Webhook
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks
```
Parameters:
- `name` (required) - Webhook name
- `url` (required) - Webhook URL
- `enabled` - Is enabled (default: true)
- `sign` - Sign webhook payloads
- `all_events` - Subscribe to all events
- `events` - Array of event types

### Enable Webhook
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:uuid/enable
```

### Disable Webhook
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:uuid/disable
```

---

## Track Domains

### List Track Domains
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains
```

### Create Track Domain
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains
```
Parameters:
- `name` (required) - Domain name
- `ssl_enabled` - Enable SSL
- `track_clicks` - Track link clicks
- `track_loads` - Track email opens

### Check Track Domain DNS
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains/:uuid/check
```

---

## Messages

### List Messages
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/messages
```
Query Parameters:
- `scope` - Filter: `incoming`, `outgoing`, `held`, or `all`
- `status` - Filter by status

### Get Message
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id
```

### Retry Message
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/retry
```

### Cancel Hold
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/cancel_hold
```

### Remove from Queue
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/queue
```

---

## Suppressions

### List Suppressions
```
GET /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions
```

### Add Suppression
```
POST /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions
```
Parameters:
- `address` (required) - Email address to suppress
- `type` - Type: `recipient` (default)
- `reason` - Reason for suppression
- `days` - Days until automatic removal

### Remove Suppression
```
DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions/:address
```
Query Parameters:
- `type` - Type: `recipient` (default)

---

## Users (Global)

### List Users
```
GET /api/v2/admin/users
```

### Get User
```
GET /api/v2/admin/users/:uuid_or_email
```

### Create User
```
POST /api/v2/admin/users
```
Parameters:
- `email_address` (required) - Email address
- `first_name` (required) - First name
- `last_name` (required) - Last name
- `password` - Password (optional for OIDC users)
- `time_zone` - Time zone
- `admin` - Is global admin

### Update User
```
PATCH /api/v2/admin/users/:uuid_or_email
```

### Delete User
```
DELETE /api/v2/admin/users/:uuid_or_email
```

---

## IP Pools (Global)

### List IP Pools
```
GET /api/v2/admin/ip_pools
```

### Get IP Pool
```
GET /api/v2/admin/ip_pools/:uuid
```

### Create IP Pool
```
POST /api/v2/admin/ip_pools
```
Parameters:
- `name` (required) - Pool name
- `default` - Is default pool

### Update IP Pool
```
PATCH /api/v2/admin/ip_pools/:uuid
```

### Delete IP Pool
```
DELETE /api/v2/admin/ip_pools/:uuid
```

---

## IP Addresses

### List IP Addresses
```
GET /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses
```

### Create IP Address
```
POST /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses
```
Parameters:
- `ipv4` - IPv4 address
- `ipv6` - IPv6 address
- `hostname` - Hostname for HELO
- `priority` - Priority (higher = preferred)

### Update IP Address
```
PATCH /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id
```

### Delete IP Address
```
DELETE /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id
```

---

## Example: Complete Setup

Here's an example of setting up a complete mail server via the API:

```bash
API_KEY="your-admin-api-key"
BASE_URL="https://postal.example.com/api/v2/admin"

# 1. Create a user
curl -X POST "$BASE_URL/users" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email_address": "admin@example.com",
    "first_name": "Admin",
    "last_name": "User",
    "password": "secure-password",
    "admin": false
  }'

# 2. Create an organization
curl -X POST "$BASE_URL/organizations" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Company",
    "owner_email": "admin@example.com"
  }'

# 3. Create a server
curl -X POST "$BASE_URL/organizations/my-company/servers" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Mail",
    "mode": "Live"
  }'

# 4. Add a domain
curl -X POST "$BASE_URL/organizations/my-company/servers/production-mail/domains" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "example.com"
  }'

# 5. Create SMTP credentials
curl -X POST "$BASE_URL/organizations/my-company/servers/production-mail/credentials" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Application SMTP",
    "type": "SMTP"
  }'

# 6. Create API credentials
curl -X POST "$BASE_URL/organizations/my-company/servers/production-mail/credentials" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Application API",
    "type": "API"
  }'

# 7. Create a webhook for delivery notifications
curl -X POST "$BASE_URL/organizations/my-company/servers/production-mail/webhooks" \
  -H "X-Admin-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Delivery Notifications",
    "url": "https://app.example.com/webhooks/postal",
    "all_events": true
  }'

# 8. Verify domain DNS
curl -X POST "$BASE_URL/organizations/my-company/servers/production-mail/domains/example.com/verify" \
  -H "X-Admin-API-Key: $API_KEY"
```
