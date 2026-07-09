#!/bin/bash

echo "📊 Postal Status"
echo "================"
echo

# Auto-detect compose file
COMPOSE_FILE="docker-compose.prod.yml"
if [ -f "docker-compose.dev.yml" ] && [ -z "$POSTAL_ENV" ]; then
  echo "📝 Using development environment"
  COMPOSE_FILE="docker-compose.dev.yml"
fi
if [ ! -z "$POSTAL_ENV" ] && [ "$POSTAL_ENV" = "dev" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
fi

docker compose -f "$COMPOSE_FILE" ps

echo
echo "Logs: docker compose -f $COMPOSE_FILE logs -f [service]"
echo "Services: web, smtp, worker, mariadb, caddy"
echo
