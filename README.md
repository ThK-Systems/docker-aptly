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

### 2. Create the Aptly configuration

Copy the example configuration:

```bash
cp aptly.conf.example aptly.conf
```

`aptly.conf.example` is only a template. The local `aptly.conf` can be adjusted to match the installation.

Keep the following setting unless the Docker volume mount is changed as well:

```json
"rootDir": "/aptly"
```

Leave the GPG fingerprint placeholder unchanged for now. It will be replaced after the signing key has been created.

### 3. Create the repository initialization script

Copy the example script:

```bash
cp scripts/init-repo.sh.example scripts/init-repo.sh
chmod +x scripts/init-repo.sh
```

`scripts/init-repo.sh.example` is only a template. The local script can be adjusted to define the repository name, distribution, and component:

```sh
REPO="stable"
DIST="stable"
COMP="main"
```

The local `aptly.conf` and `scripts/init-repo.sh` files are excluded through `.gitignore`.

### 4. Configure Docker Compose

Host-specific settings can be placed in:

```text
docker-compose.override.yml
```

Docker Compose automatically combines this file with `docker-compose.yml`.

Example:

```yaml
services:
  aptly:
    mem_limit: 512m
    memswap_limit: 1g
    cpus: "1.0"
```

The override file is optional and excluded through `.gitignore`.

### 5. Create the GPG directory

The directory must exist before starting a container because it is bind-mounted to `/gpg`:

```bash
mkdir -p gpg
chmod 700 gpg
```

It contains the private signing key and must not be committed.

### 6. Validate and build the configuration

Validate the combined Docker Compose configuration:

```bash
docker compose config >/dev/null
```

Build the image:

```bash
docker compose build --pull
```

### 7. Start a temporary setup container

The regular container starts the Aptly HTTP server. A fresh installation does not yet contain a published repository, so first start a temporary setup container:

```bash
docker compose run -d \
  --name aptly \
  --entrypoint sleep \
  aptly infinity
```

Verify that it is running:

```bash
docker ps --filter name=aptly
```

### 8. Create the GPG signing key

Generate a dedicated signing key inside the setup container:

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

The empty passphrase permits unattended repository publishing. Protect and back up the `gpg` directory.

### 9. Configure the GPG fingerprint

Display the fingerprint:

```bash
docker exec aptly gpg --fingerprint
```

Example output:

```text
84B4 E216 7E61 36DF 4BAA  1ACE 22B1 E4DD DD57 F553
```

Enter the fingerprint in `aptly.conf` without spaces:

```json
"gpgKey": "84B4E2167E6136DF4BAA1ACE22B1E4DDDD57F553"
```

The updated configuration is immediately available inside the container through the bind mount.

### 10. Initialize the repository

Create the local repository:

```bash
./scripts/init-repo.sh
```

With the default settings, this creates:

* Repository: `stable`
* Distribution: `stable`
* Component: `main`

### 11. Publish the repository

Publish the repository so that the Aptly HTTP server can serve it:

```bash
docker exec aptly aptly publish repo stable
```

Replace `stable` with the `REPO` value configured in `scripts/init-repo.sh` when necessary.

The architectures required for publishing an empty repository are defined in `aptly.conf`.

### 12. Start the regular container

Remove the temporary setup container:

```bash
docker rm -f aptly
```

Start the regular Aptly service:

```bash
docker compose up -d
```

Verify the container:

```bash
docker compose ps
docker compose logs aptly
```

Test the published repository:

```bash
curl -fsSL http://127.0.0.1:8090/dists/stable/Release
```

Replace `stable` with the configured distribution when necessary.

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

Use an HTTPS reverse proxy when the repository must be accessible from other systems. (see `nginx-reverse-proxy.conf.example`.)

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

## 🔧 Maintainance

### `rebuild.sh`

Rebuilds the image and recreates the Aptly container (minimal downtime)

```bash
./rebuild.sh
```

### `update.sh`

Stops, rebuilds, and restarts the Docker Compose stack (like a hard reset)

```bash
./update.sh
```

### `git pull`

May update the delivered files and scripts.\
Use with caution!!

```bash
git pull
```

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

## 🧱 Custom Dockerfile

Docker does not provide an automatic override mechanism for `Dockerfile` files.

To use a custom Dockerfile, create a separate file, for example:

```text
Dockerfile.local
```

Then select it through `docker-compose.override.yml`:

```yaml
services:
  aptly:
    build:
      context: .
      dockerfile: Dockerfile.local
```

The custom Dockerfile can either replace the default build instructions or extend an existing image.

Example:

```dockerfile
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      aptly \
      gnupg \
      ca-certificates \
      curl \
 && rm -rf /var/lib/apt/lists/*

CMD ["aptly", "serve", "-listen=:8080"]
```

This keeps local Dockerfile customizations separate from the tracked `Dockerfile`.
