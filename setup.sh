#!/bin/bash
# new-api installation recap (actual steps executed on 2026-07-21)
# Environment: macOS + colima (Docker already running); Docker Hub unreachable, mirror required

# 1. Pull the three images via the DaoCloud registry mirror
docker pull docker.m.daocloud.io/calciumion/new-api:latest
docker pull docker.m.daocloud.io/library/redis:latest

# 2. Retag them to the image names referenced by docker-compose.yml
docker tag docker.m.daocloud.io/calciumion/new-api:latest calciumion/new-api:latest
docker tag docker.m.daocloud.io/library/redis:latest redis:latest

if ! docker image inspect postgres:15 >/dev/null 2>&1; then
    docker pull docker.m.daocloud.io/library/postgres:15
    docker tag docker.m.daocloud.io/library/postgres:15 postgres:15
fi

# 3. Start the stack (new-api + PostgreSQL + Redis)
docker compose up -d

# 4. Wait for the database and schema migrations to be ready
sleep 15

# 5. Switch to the new frontend (rc.21 defaults to the classic frontend, which shows
#    a deprecation banner), then restart to apply
docker compose exec -T postgres psql -U root -d new-api -c \
    "INSERT INTO options (key, value) VALUES ('theme.frontend', 'default') ON CONFLICT (key) DO UPDATE SET value = 'default';"
docker compose restart new-api

# Done. Open http://localhost:3000 — the setup wizard will run on first visit to create the admin account
