FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      aptly \
      gnupg \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

CMD ["aptly", "serve", "-listen=:8080"]
