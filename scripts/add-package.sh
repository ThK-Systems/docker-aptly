#!/bin/sh
set -e

CONTAINER="aptly"
REPO="stable"
DIST="stable"
TMP_IN_CONTAINER="/tmp/aptly-import.deb"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 package1.deb [package2.deb ...]"
  exit 1
fi

for DEB in "$@"; do
  if [ ! -f "$DEB" ]; then
    echo "File not found: $DEB"
    exit 1
  fi

  echo "→ adding $DEB"

  echo "  → copying into container"
  docker cp "$DEB" "$CONTAINER:$TMP_IN_CONTAINER"

  echo "  → repo add"
  docker exec "$CONTAINER" aptly repo add "$REPO" "$TMP_IN_CONTAINER"

  echo "  → cleanup"
  docker exec "$CONTAINER" rm -f "$TMP_IN_CONTAINER"
done

echo "→ publishing update"
if docker exec "$CONTAINER" aptly publish list | grep -q " ./${DIST} "; then
    docker exec "$CONTAINER" aptly publish update "$DIST"
else
    docker exec "$CONTAINER" aptly publish repo \
        -distribution="$DIST" \
        -component=main \
        "$REPO"
fi

echo "✓ done"

