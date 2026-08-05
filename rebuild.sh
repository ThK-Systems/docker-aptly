#!/bin/bash
docker compose build --pull aptly
docker compose up -d --no-deps --force-recreate aptly
