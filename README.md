# 📦 Docker Aptly

A compact Docker Compose setup for running a signed Debian package repository with Aptly.

Repository data is stored in a Docker volume. Configuration and GPG keys remain on the Docker host.

## ✨ Features

* Debian Trixie based image
* Persistent Aptly data
* Persistent GPG keyring
* Signed Debian repositories
* Local HTTP server on `127.0.0.1:8090`
* Docker Compose overrides
* Helper scripts for repository management

## ✅ Requirements

* Docker Engine
* Docker Compose plugin
* `git`
* `curl` (optional)

## 🚀 Installation

### 1. Clone the repository

```bash
git clone git@github.com:ThK-Systems/docker-aptly.git
cd docker-aptly
```

### 2. Create the local Aptly configuration

```bash
cp aptly.conf.example aptly.conf
```

Keep the following setting unchanged unless the Docker volume mount is changed as well:

```json
"rootDir": "/aptly"
```

### 3. Create the repository initialization script

```bash
cp scripts/init-repo.sh.example scripts/init-repo.sh
chmod +x scripts/init-repo.sh
```

Adjust the repository settings when required:

```sh
REPO="stable"
DIST="stable"
COMP="main"
```

### 4. Create the GPG directory

```bash
mkdir -p gpg
chmod 700 gpg
```

The directory contains the private signing key and must not be committed.

### 5. Configure Docker Compose

Host-specific settings can be placed in:

```text
docker-compose.override.yml
```

Docker Compose automatically combines it with `docker-compose.yml`.

Example:

```yaml
services:
  aptly:
    ports:
      - "8090:8080"

    mem_limit: 512m
    cpus: "1.0"
```

### 6. Build and start the container

```bash
docker compose up -d --build
```

Check the container:

```bash
docker compose ps
docker compose logs aptly
```

### 7. Create the GPG signing key

```bash
docker exec aptly gpg \
  --batch \
  --pinentry-mode loopback \
  --passphrase '' \
  --quick-generate-key \
  "Aptly Repository <aptly@example.com>" \
  rsa4096 sign 0
```

Replace the name and email address with suitable values.

The empty passphrase permits unattended publishing. Protect and back up the `gpg` directory.

### 8. Configure the GPG fingerprint

Get the fingerprint:

```bash
docker exec aptly gpg \
  --list-secret-keys \
  --with-colons |
awk -F: '/^fpr:/ { print $10; exit }'
```

Replace the placeholder in `aptly.conf`:

```json
"gpgKey": "YOUR_GPG_KEY_FINGERPRINT"
```

Example:

```json
"gpgKey": "4A8F3E91D264B7C05F12A6E89C3D714B28E65F90"
```

Restart the container:

```bash
docker compose restart aptly
```

### 9. Initialize the repository

```bash
./scripts/init-repo.sh
```

With the default settings, this creates:

* Repository: `stable`
* Distribution: `stable`
* Component: `main`

## 🔑 Export the public signing key

```bash
docker exec aptly sh -c \
  'mkdir -p /aptly/public && gpg --armor --export "Aptly Repository" > /aptly/public/aptly-repository.asc'
```

The public key is then available at:

```text
http://127.0.0.1:8090/aptly-repository.asc
```

## 🌐 Repository access

The Aptly HTTP server listens on:

```text
http://127.0.0.1:8090/
```

Use an HTTPS reverse proxy when the repository must be accessible from other systems.

Test the repository:

```bash
curl -fsSL http://127.0.0.1:8090/dists/stable/Release
```

## 💻 Debian client configuration

The following example uses:

```text
https://apt.example.com
```

Install the public key:

```bash
install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://apt.example.com/aptly-repository.asc \
  | gpg --dearmor \
  > /etc/apt/keyrings/docker-aptly.gpg

chmod 644 /etc/apt/keyrings/docker-aptly.gpg
```

Add the repository:

```bash
cat > /etc/apt/sources.list.d/docker-aptly.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/docker-aptly.gpg] https://apt.example.com stable main
EOF
```

Update the package lists:

```bash
apt update
```

## 💾 Backup

Back up:

* Docker volume `aptly-data`
* Local `gpg` directory
* Local `aptly.conf`
* Local `scripts/init-repo.sh`
* Optional `docker-compose.override.yml`

Without the private GPG key, new repository metadata cannot be signed with the existing repository identity.

## 🧰 Scripts

### `scripts/add-package.sh`

Adds one or more local `.deb` files and publishes or updates the repository.

```bash
./scripts/add-package.sh package1.deb package2.deb
```

### `scripts/add-package-from-url.sh`

Downloads one or more `.deb` files, adds them, and publishes or updates the repository.

```bash
./scripts/add-package-from-url.sh \
  https://example.com/package1.deb \
  https://example.com/package2.deb
```

### `scripts/remove-package.sh`

Removes a package version and updates the publication.

```bash
./scripts/remove-package.sh package-name=1.2.3
```

### `scripts/show-repo.sh`

Shows all packages in the `stable` repository.

```bash
./scripts/show-repo.sh
```

### `scripts/aptly-db-cleanup.sh`

Removes unused Aptly database objects.

```bash
./scripts/aptly-db-cleanup.sh
```

### `rebuild.sh`

Rebuilds the image and recreates the Aptly container.

```bash
./rebuild.sh
```

### `update.sh`

Stops, rebuilds, and restarts the Docker Compose stack.

```bash
./update.sh
```
