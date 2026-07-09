# Testing Guide

Guide for running and writing tests for Postal.

---

## Running Tests

### With Docker (Recommended)

```bash
# Set up test database
docker compose -f docker-compose.dev.yml run --rm runner \
  sh -c 'RAILS_ENV=test bundle exec rake db:create db:schema:load'

# Run all tests
docker compose -f docker-compose.dev.yml run --rm runner bundle exec rspec

# Run specific test file
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/lib/query_string_spec.rb

# Run specific test by line number
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/models/credential_spec.rb:10
```

### Test Categories

```bash
# Run lib tests only (minimal dependencies)
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/lib/

# Run model tests (requires DB setup)
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/models/

# Run API tests
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/apis/
```

---

## Test Database Setup

Before running tests that require the database:

```bash
# Create and migrate test database
docker compose -f docker-compose.dev.yml run --rm runner \
  sh -c 'RAILS_ENV=test bundle exec rake db:create db:migrate'

# Or load schema directly (faster)
docker compose -f docker-compose.dev.yml run --rm runner \
  sh -c 'RAILS_ENV=test bundle exec rake db:schema:load'

# Load test data (if needed)
docker compose -f docker-compose.dev.yml run --rm runner \
  sh -c 'RAILS_ENV=test bundle exec rake db:seed'
```

---

## Known Issues

### Zeitwerk Autoloading

The Postal codebase has a Zeitwerk/Rails autoloading issue in some AdminAPI controllers. File naming doesn't match expected constant names:

- `app/controllers/admin_api/http_endpoints_controller.rb` defines `HTTPEndpointsController`
- Zeitwerk expects `HttpEndpointsController`

### Workarounds

```bash
# Skip admin_api specs if autoload issues occur
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec --exclude-pattern "**/admin_api/**"

# Run tests that don't require Rails
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/ --skip-pattern "**/rails/**"
```

---

## Using Postal CLI for Testing

Alternative to RSpec - test functionality through CLI:

```bash
# Check Postal version
docker compose -f docker-compose.dev.yml run --rm runner postal --version

# Get system information
docker compose -f docker-compose.dev.yml run --rm runner postal status

# View available commands
docker compose -f docker-compose.dev.yml run --rm runner postal help
```

---

## Writing Tests

### Test Structure

```
spec/
├── apis/              # API request specs
│   └── admin_api/     # Admin API specs
├── factories/         # FactoryBot factories
├── helpers/           # Helper specs
├── lib/               # Library specs
├── models/            # Model specs
├── services/          # Service specs
└── spec_helper.rb     # RSpec configuration
```

### Guidelines

1. **Use factories** - Create test data with FactoryBot
2. **Keep tests isolated** - Use `use_transactional_fixtures = true`
3. **Test one thing** - Each test should verify one behavior
4. **Use descriptive names** - Test names should describe expected behavior

### Example Test

```ruby
RSpec.describe Credential, type: :model do
  describe "validations" do
    it "requires a name" do
      credential = build(:credential, name: nil)
      expect(credential).not_to be_valid
    end
  end

  describe "#authenticate" do
    let(:credential) { create(:credential) }

    it "returns true for valid key" do
      expect(credential.authenticate(credential.key)).to be true
    end
  end
end
```

---

## Continuous Integration

GitHub Actions CI runs tests automatically. See `.github/workflows/ci.yml` for details.

### CI Jobs

| Job | Description |
|-----|-------------|
| `lint` | RuboCop code style checking |
| `test` | RSpec test suite with MariaDB |
| `security` | Vulnerability scanning |

---

## Contributing Tests

When adding new tests:

1. Avoid Rails environment dependencies if possible
2. Use factories for test data
3. Keep tests isolated with transactional fixtures
4. Run locally before pushing

```bash
# Verify tests pass
docker compose -f docker-compose.dev.yml run --rm runner \
  bundle exec rspec spec/path/to/new_spec.rb
```

---

## Related Documentation

- [Development Setup](development.md) - Full development guide
- [Contributing](contributing.md) - How to contribute
- [API Inventory](api-inventory.md) - API implementation status
