#!/bin/bash
set -e

# Determine which docker-compose file to use
if [ -f "docker-compose.dev.yml" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  ENV_CONTEXT="development"
elif [ "$POSTAL_ENV" == "development" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  ENV_CONTEXT="development"
else
  COMPOSE_FILE="docker-compose.prod.yml"
  ENV_CONTEXT="production"
fi

echo "🔄 Upgrading Postal ($ENV_CONTEXT)"
echo "==================="
echo

if [ "$1" == "" ]; then
  echo "Usage: ./scripts/upgrade.sh [version]"
  echo "Example: ./scripts/upgrade.sh 3.3.4"
  exit 1
fi

NEW_VERSION=$1

echo "Upgrading to version: $NEW_VERSION"
echo "Using compose file: $COMPOSE_FILE"
echo

# Update .env file
if [ -f ".env" ]; then
  sed -i.bak "s/POSTAL_VERSION=.*/POSTAL_VERSION=$NEW_VERSION/" .env
  rm .env.bak
  echo "✅ Updated .env with version $NEW_VERSION"
fi

# Update VERSION file
echo "$NEW_VERSION" > VERSION
echo "✅ Updated VERSION file with $NEW_VERSION"

# Pull new images
echo "📦 Pulling Postal $NEW_VERSION..."
docker compose -f "$COMPOSE_FILE" pull

# Run database migrations
echo "🔧 Running database migrations..."
docker compose -f "$COMPOSE_FILE" run --rm runner postal upgrade

# Restart services
echo "🔄 Restarting services..."
docker compose -f "$COMPOSE_FILE" up -d

echo
echo "✅ Upgrade complete!"
echo
docker compose -f "$COMPOSE_FILE" ps
echo
