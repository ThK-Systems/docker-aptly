#!/bin/sh
set -e

CONTAINER="aptly"

echo "→ running aptly db cleanup"
docker exec "$CONTAINER" aptly db cleanup

echo "✓ cleanup done"

