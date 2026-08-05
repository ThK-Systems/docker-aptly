#!/bin/sh
set -e

CONTAINER="aptly"
REPO="stable"
DIST="stable"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <file1.deb> [file2.deb] [file3.deb] ..."
  exit 1
fi

TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

for URL in "$@"; do
  DEB_FILE="$(basename "$URL")"
  LOCAL_DEB="$TMPDIR/$DEB_FILE"

  echo "→ downloading package: $DEB_FILE"
  curl -fsSL "$URL" -o "$LOCAL_DEB"

  echo "→ copying package into container"
  docker cp "$LOCAL_DEB" "$CONTAINER:/tmp/$DEB_FILE"

  echo "→ adding package to repo"
  docker exec "$CONTAINER" aptly repo add "$REPO" "/tmp/$DEB_FILE"

  echo "→ cleaning up container temp file"
  docker exec "$CONTAINER" rm -f "/tmp/$DEB_FILE"
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
