#!/bin/bash
set -e

echo "👤 Creating Postal Admin User"
echo "=============================="
echo

# Auto-detect compose file
COMPOSE_FILE="docker-compose.prod.yml"
if [ -f "docker-compose.dev.yml" ] && [ -z "$POSTAL_ENV" ]; then
  echo "📝 Auto-detected development environment"
  COMPOSE_FILE="docker-compose.dev.yml"
fi
if [ ! -z "$POSTAL_ENV" ] && [ "$POSTAL_ENV" = "dev" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
fi

# Check if database is initialized
if ! docker compose -f "$COMPOSE_FILE" run --rm runner postal version &>/dev/null; then
  echo "❌ Database not initialized. Run ./scripts/initialize.sh first."
  exit 1
fi

# Create admin user
echo "Creating admin user..."
echo "You will be prompted for user details."
echo

docker compose -f "$COMPOSE_FILE" run --rm runner postal make-user

echo
echo "✅ User created successfully!"
echo
echo "You can now start Postal:"
echo "  docker compose -f docker-compose.prod.yml up -d"
echo
echo "Access the web interface at: https://your-domain.com"
echo
