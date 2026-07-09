#!/bin/bash
set -e

# Determine which docker-compose file to use
if [ -f "docker-compose.dev.yml" ]; then
  ENV_CONTEXT="development"
  DEFAULT_REGISTRY="postal:dev-local"
elif [ "$POSTAL_ENV" == "development" ]; then
  ENV_CONTEXT="development"
  DEFAULT_REGISTRY="postal:dev-local"
else
  ENV_CONTEXT="production"
  DEFAULT_REGISTRY="ghcr.io/relationsoftware/postal"
fi

# Build Postal image for different architectures
# Usage: ./scripts/build.sh [ARCHITECTURE] [VERSION] [--registry REGISTRY]
# Examples:
#   ./scripts/build.sh arm64 3.3.4                              # Build ARM64 image
#   ./scripts/build.sh amd64 3.3.4                              # Build AMD64 image
#   ./scripts/build.sh all 3.3.4                                # Build both ARM64 and AMD64 (requires buildx)
#   ./scripts/build.sh all 3.3.4 --registry ghcr.io/relationsoftware/postal # Push to registry

ARCH="${1:-arm64}"
VERSION="${2:-3.3.4}"
REGISTRY="${3:-$DEFAULT_REGISTRY}"

# Parse optional registry flag
if [ "$3" == "--registry" ] && [ ! -z "$4" ]; then
  REGISTRY="$4"
fi

echo "🐳 Building Postal image for $ARCH (v$VERSION)..."
echo "📍 Environment: $ENV_CONTEXT"
echo "🏷️  Registry: $REGISTRY"
echo

if [ "$ARCH" = "all" ]; then
  echo "📦 Building multi-arch image (requires buildx)..."
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "$REGISTRY:$VERSION" \
    -t "$REGISTRY:latest" \
    --target full \
    --build-arg VERSION="$VERSION" \
    .
  echo "✓ Multi-arch image built successfully"
else
  echo "🔨 Building $ARCH image..."
  docker build \
    --platform "linux/$ARCH" \
    -t "$REGISTRY:$VERSION-$ARCH" \
    -t "$REGISTRY:latest-$ARCH" \
    --target full \
    --build-arg VERSION="$VERSION" \
    .
  echo "✓ Image built: $REGISTRY:$VERSION-$ARCH"
fi

echo ""
if [ "$ENV_CONTEXT" = "development" ]; then
  echo "To use the local image in dev:"
  echo "  export POSTAL_IMAGE=postal:dev-local"
  echo "  docker compose -f docker-compose.dev.yml up -d web smtp worker"
else
  echo "To push to registry (production):"
  echo "  docker push $REGISTRY:$VERSION"
  echo "  docker push $REGISTRY:latest"
fi
echo ""
