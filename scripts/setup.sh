#!/bin/bash
set -e

# Determine which docker-compose file to use
if [ -f "docker-compose.dev.yml" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  ENV_CONTEXT="development"
  POSTAL_DOMAIN="postal.example.com"
  SMTP_DOMAIN="postal.example.com"
elif [ "$POSTAL_ENV" == "development" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  ENV_CONTEXT="development"
  POSTAL_DOMAIN="postal.example.com"
  SMTP_DOMAIN="postal.example.com"
else
  COMPOSE_FILE="docker-compose.prod.yml"
  ENV_CONTEXT="production"
  POSTAL_DOMAIN="mail.example.com"  # Default for production
  SMTP_DOMAIN="mail.example.com"    # Default for production
fi

echo "🚀 Postal Setup Script"
echo "======================"
echo "📍 Environment: $ENV_CONTEXT"
echo "🏗️  Compose file: $COMPOSE_FILE"
echo

# Check if running as root (optional, but recommended for production)
if [ "$EUID" -eq 0 ] && [ "$ALLOW_ROOT" != "true" ]; then
  echo "⚠️  Running as root. Set ALLOW_ROOT=true if intentional."
  echo
fi

# Check if config files exist
if [ -f "config/postal.yml" ]; then
  echo "✅ config/postal.yml already exists"
else
  echo "📝 Creating config/postal.yml from example..."
  cp config/postal.yml.example config/postal.yml
  
  # Generate secret key
  echo "🔑 Generating Rails secret key..."
  SECRET_KEY=$(openssl rand -hex 128)
  sed -i.bak "s/REPLACE_WITH_SECRET_KEY/$SECRET_KEY/" config/postal.yml
  rm config/postal.yml.bak
  
  # Pre-populate default domains for dev
  if [ "$ENV_CONTEXT" == "development" ]; then
    sed -i.bak "s/mail\.example\.com/$POSTAL_DOMAIN/g" config/postal.yml
    rm config/postal.yml.bak
    echo "✅ Pre-configured for development domain: $POSTAL_DOMAIN"
  fi
  
  echo "⚠️  Please edit config/postal.yml and update:"
  echo "   - postal.web_hostname (your domain) [current: $POSTAL_DOMAIN]"
  echo "   - postal.smtp_hostname (your domain) [current: $SMTP_DOMAIN]"
  echo "   - dns.* (all DNS records)"
  echo "   - main_db.password (database password)"
  echo "   - message_db.password (database password)"
fi

# Check if Caddyfile exists (dev only)
if [ "$ENV_CONTEXT" == "development" ]; then
  if [ -f "config/Caddyfile" ]; then
    echo "✅ config/Caddyfile already exists"
  else
    echo "📝 Creating config/Caddyfile from example..."
    cp config/Caddyfile.example config/Caddyfile
    sed -i.bak "s/mail\.example\.com/$POSTAL_DOMAIN/g" config/Caddyfile
    rm config/Caddyfile.bak
    echo "✅ Pre-configured Caddyfile for domain: $POSTAL_DOMAIN"
  fi
fi

# Check if signing key exists
if [ -f "config/signing.key" ]; then
  echo "✅ config/signing.key already exists"
else
  echo "🔐 Generating signing key..."
  openssl genrsa -out config/signing.key 1024 2>/dev/null
  chmod 644 config/signing.key
  echo "✅ Signing key generated"
fi

# Check if .env exists
if [ -f ".env" ]; then
  echo "✅ .env already exists"
else
  echo "📝 Creating .env from .env.example..."
  if [ -f ".env.$ENV_CONTEXT" ]; then
    cp ".env.$ENV_CONTEXT" .env
    echo "✅ Copied .env.$ENV_CONTEXT"
  elif [ -f ".env.example" ]; then
    cp .env.example .env
    echo "⚠️  Please edit .env and update your configuration"
  fi
fi

echo
echo "✅ Setup complete!"
echo
echo "Next steps:"
if [ "$ENV_CONTEXT" == "development" ]; then
  echo "1. (Optional) Edit config/postal.yml with your domain settings"
  echo "2. Run: ./scripts/initialize.sh to set up the database"
  echo "3. Run: docker compose -f $COMPOSE_FILE up -d"
  echo "4. Access: https://postal.example.com"
else
  echo "1. Edit config/postal.yml with your domain and database settings"
  echo "2. Edit config/Caddyfile with your domain"
  echo "3. Edit .env with your settings"
  echo "4. Run: ./scripts/initialize.sh to set up the database"
  echo "5. Run: docker compose -f $COMPOSE_FILE up -d"
fi
echo
