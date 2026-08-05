#!/bin/sh
set -e

CONTAINER="aptly"
REPO="stable"
DIST="stable"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 package=version"
  echo "Example: $0 mypkg=1.2.3"
  exit 1
fi

PKG="$1"

echo "→ removing $PKG from repo $REPO"
docker exec "$CONTAINER" aptly repo remove "$REPO" "$PKG"

echo "→ publishing update"
docker exec "$CONTAINER" aptly publish update "$DIST"

echo "✓ removed and published"

