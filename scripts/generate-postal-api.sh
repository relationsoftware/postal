#!/bin/bash
set -e

# Auto-detect compose file
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

OUTPUT_DIR="public/openapi"
mkdir -p "$OUTPUT_DIR"
SPEC_FILE="$OUTPUT_DIR/postal-api.yml"

echo "🌐 Generating Server OpenAPI spec ($ENV_CONTEXT)"
echo "Using compose file: $COMPOSE_FILE"

# Mount project workspace and ensure working directory is /app
# We use OPENAPI_FILE env var to tell rspec-openapi where to write
COMMAND="bundle install && SKIP_PENDING_MIGRATIONS=1 SKIP_FACTORY_LINT=1 OPENAPI_FILE=$SPEC_FILE bundle exec rspec spec/apis/server_api --format progress"

docker compose -f "$COMPOSE_FILE" run --rm \
  -e RAILS_ENV=test \
  -e OPENAPI=1 \
  -e OPENAPI_FILE="$SPEC_FILE" \
  -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
  -v "$PWD":/opt/postal/app \
  -w /opt/postal/app \
  runner bash -lc "$COMMAND" || true

# Post-process spec to add missing security requirements
echo "📝 Post-processing OpenAPI spec..."
docker compose -f "$COMPOSE_FILE" run --rm \
  -v "$PWD":/opt/postal/app \
  -w /opt/postal/app \
  runner ruby scripts/post-process-openapi.rb "$SPEC_FILE" "ServerAPIKey" "X-Server-API-Key" "Server API Key for authenticating with the Postal Mail API"

echo "✅ OpenAPI spec generated and processed at $SPEC_FILE"
