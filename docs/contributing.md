# Contributing to Postal

This guide explains how to set up a development environment and contribute to the project.

## Prerequisites

### Using Docker (Recommended)

- Docker & Docker Compose v2.6+
- Git

### Native Development

- MySQL/MariaDB database server
- Ruby 3.2.2 (via rbenv, asdf, or rvm)

## Getting Started

### Option 1: Docker Development (Recommended)

```bash
# Clone repository
git clone https://github.com/relationsoftware/postal.git
cd mail

# Start development environment
docker compose -f docker-compose.dev.yml pull
docker compose -f docker-compose.dev.yml up -d

# Create test user
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec postal user admin@localhost.localdomain password123
```

Access: http://localhost:5001

See [Development Setup](development.md) for complete details.

### Option 2: Native Development

```bash
# Clone repository
git clone https://github.com/relationsoftware/postal.git
cd mail

# Install dependencies
bundle install

# Configure
cp config/examples/development.yml config/postal/postal.yml

# Generate signing key
openssl genrsa -out config/postal/signing.key 2048

# Initialize database
bin/postal initialize
bin/postal make-user

# Run application
bin/dev
```

## Configuration

### Config File

Configuration lives in `config/postal/postal.yml`. Example files:
- `config/examples/development.yml` - Development settings
- `config/examples/test.yml` - Test settings (copy to `config/postal/postal.test.yml`)

### Environment Variables

Alternatively, configure via `.env` or `.env.test` files.

## Running the Application

```bash
# Using Foreman (runs all components)
bin/dev

# Or run individual components
bin/postal web
bin/postal worker
bin/postal smtp
```

## Database

```bash
# Initialize database and create user
bin/postal initialize
bin/postal make-user
```

## Running Tests

### With Docker

```bash
# Set up test database
docker compose -f docker-compose.dev.yml run --rm runner \
  sh -c 'RAILS_ENV=test bundle exec rake db:create db:schema:load'

# Run all tests
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec

# Run specific test file
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/lib/query_string_spec.rb
```

### Native

```bash
# Set up test database
RAILS_ENV=test bundle exec rake db:create db:schema:load

# Run tests
bundle exec rspec
```

## Code Style

We use RuboCop for code style enforcement:

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -A
```

## Making Changes

### API Changes

- Follow patterns in existing `app/controllers/admin_api/` controllers
- Add routes in `config/routes.rb` under the `admin_api` namespace
- Use `render_success`, `render_created`, `render_error` helpers
- All admin API requires `X-Admin-API-Key` header

### Testing

- Create request specs in `spec/apis/admin_api/` using shared context
- Use factories for test data
- Run tests locally before submitting PR

### Documentation

- Update relevant docs in `docs/` directory
- Keep documentation in English
- Follow existing formatting patterns

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run tests (`bundle exec rspec`)
5. Run linter (`bundle exec rubocop`)
6. Commit with descriptive message
7. Push to your fork
8. Open a pull request

## Related Documentation

- [Development Setup](development.md) - Detailed development environment guide
- [Testing Guide](TESTING.md) - Comprehensive testing information
- [API Inventory](api-inventory.md) - API implementation status
