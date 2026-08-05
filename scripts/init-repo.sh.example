#!/bin/sh
set -e

CONTAINER="aptly"
REPO="stable"
DIST="stable"
COMP="main"

docker exec "$CONTAINER" aptly repo show "$REPO" >/dev/null 2>&1 || \
docker exec "$CONTAINER" aptly repo create \
  -distribution="$DIST" \
  -component="$COMP" \
  "$REPO"

echo "✓ repo ensured"
