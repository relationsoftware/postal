# Security Policy

## Supported Versions

Only the 3.x versions of Postal are supported with security updates.

| Version | Supported |
|---------|-----------|
| 3.x.x | Yes |
| < 3.0 | No |

## Reporting a Vulnerability

If you discover a security vulnerability:

1. **Do not** create a public GitHub issue
2. Send an email to security@postalserver.io with details
3. We will respond directly to coordinate disclosure

## Security Best Practices

When deploying Postal:

- Use strong, unique passwords for all services
- Keep Docker images updated to latest versions
- Configure TLS for SMTP and web interface
- Restrict network access to management ports
- Regularly backup your database
- Monitor logs for suspicious activity
