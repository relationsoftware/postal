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

echo "🌐 Generating OpenAPI spec ($ENV_CONTEXT)"
echo "Using compose file: $COMPOSE_FILE"

# Mount project workspace and ensure working directory is /app
COMMAND="bundle install && bundle exec rake db:drop db:create db:migrate && SKIP_PENDING_MIGRATIONS=1 SKIP_FACTORY_LINT=1 bundle exec rspec spec/apis/admin_api --format progress"

docker compose -f "$COMPOSE_FILE" run --rm \
  -e RAILS_ENV=test \
  -e OPENAPI=1 \
  -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
  -v "$PWD":/opt/postal/app \
  -w /opt/postal/app \
  runner bash -lc "$COMMAND" || true

# Post-process spec to add missing security requirements
echo "📝 Post-processing OpenAPI spec..."
docker compose -f "$COMPOSE_FILE" run --rm \
  -v "$PWD":/opt/postal/app \
  -w /opt/postal/app \
  runner ruby scripts/post-process-openapi.rb "public/openapi/postal-admin-api.yaml" "AdminAPIKey" "X-Admin-API-Key" "Admin API Key for authenticating with the Postal Admin API"

echo "✅ OpenAPI spec generated and processed at $OUTPUT_DIR/postal-admin-api.yaml"
