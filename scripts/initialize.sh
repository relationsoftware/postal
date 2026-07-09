#!/bin/bash
set -e

echo "🗄️  Initializing Postal Database"
echo "================================"
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

# Check if config exists
if [ ! -f "config/postal.yml" ]; then
  echo "❌ config/postal.yml not found. Run ./scripts/setup.sh first."
  exit 1
fi

# Pull the latest images
echo "📦 Pulling latest Postal images..."
docker compose -f "$COMPOSE_FILE" pull

# Initialize the database
echo "🔧 Initializing database schema..."
docker compose -f "$COMPOSE_FILE" run --rm runner postal initialize

echo
echo "✅ Database initialized!"
echo
echo "Next step: Create your first admin user"
echo "Run: ./scripts/make-user.sh"
echo
