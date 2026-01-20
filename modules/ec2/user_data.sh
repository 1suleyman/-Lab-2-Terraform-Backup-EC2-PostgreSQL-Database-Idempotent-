#!/bin/bash
set -euxo pipefail
# Enables:

# -e → exit immediately on errors

# -u → error on unset variables

# -x → print commands as they run (great for cloud-init debugging)

# -o pipefail → fail if any part of a pipeline fails

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $1"
}

# ----------------------------
# 1) Install Docker
# ----------------------------
log "Installing Docker..."
dnf update -y
dnf install -y docker

systemctl enable --now docker
usermod -aG docker ec2-user

# ----------------------------
# 2) Install Docker Compose v2 plugin
# ----------------------------
log "Installing Docker Compose plugin..."
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v5.0.1/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ----------------------------
# 3) Create docker-compose.yml (Postgres bound to localhost only)
# ----------------------------
cat > /home/ec2-user/docker-compose.yml <<'YAML'
services:
  postgres_db:
    image: postgres:13
    container_name: postgres_db
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: appdb
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
YAML

chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

# ----------------------------
# 4) Create seed SQL file
# ----------------------------
cat > /home/ec2-user/seed.sql <<'SQL'
-- Create table + sample data
CREATE TABLE IF NOT EXISTS customers (
  id serial PRIMARY KEY,
  name text,
  created_at timestamptz DEFAULT now()
);

INSERT INTO customers(name)
SELECT v.name
FROM (VALUES ('Aisha'), ('Omar'), ('Suleyman')) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM customers c WHERE c.name = v.name
);

-- Create “enterprise-ish” users/roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readonly') THEN
    CREATE ROLE app_readonly LOGIN PASSWORD 'readonlypass';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_writer') THEN
    CREATE ROLE app_writer LOGIN PASSWORD 'writerpass';
  END IF;
END$$;

-- DB connect permissions (safe to re-run)
GRANT CONNECT ON DATABASE appdb TO app_readonly;
GRANT CONNECT ON DATABASE appdb TO app_writer;

-- Basic schema permissions (optional but realistic)

GRANT USAGE ON SCHEMA public TO app_readonly, app_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_writer;

-- Ensure future tables also inherit permissions
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_writer;
SQL

chown ec2-user:ec2-user /home/ec2-user/seed.sql

# ----------------------------
# 5) Start Postgres container
# ----------------------------
log "Starting Postgres..."
su - ec2-user -c "docker compose -f /home/ec2-user/docker-compose.yml up -d"
# ----------------------------
# 6) Wait for Postgres to be ready, then seed automatically
# ----------------------------
# Wait up to ~60 seconds (30 x 2s)
# I’ll knock 30 times. If it never opens, I stop the whole operation and raise an alarm.
READY=0
for i in {1..30}; do
  if su - ec2-user -c "docker exec postgres_db pg_isready -U admin -d appdb" >/dev/null 2>&1; then
    READY=1
    log "Postgres is ready."
    break
  fi

  log "Waiting for Postgres... ($i/30)"
  sleep 2
done

if [ "$READY" -ne 1 ]; then
  log "Postgres never became ready"
  docker logs postgres_db || true
  exit 1
fi

# Run the seed SQL inside the container
log "Seeding database..."
su - ec2-user -c "docker exec -i postgres_db psql -U admin -d appdb" < /home/ec2-user/seed.sql
log "Seeding complete."

# ----------------------------
# 7) Create a backup on first boot (after seeding)
# ----------------------------
su - ec2-user -c "mkdir -p /home/ec2-user/db_backups"

# Timestamped filename so you don't overwrite old backups
BACKUP_FILE="/home/ec2-user/db_backups/appdb-$(date +%F-%H%M%S).dump"

# Dump in custom format (-Fc) to the EC2 host filesystem
log "Creating backup..."
su - ec2-user -c "docker exec -i postgres_db pg_dump -U admin -d appdb -Fc" > "$BACKUP_FILE"

# Verify it exists and has size
chown ec2-user:ec2-user "$BACKUP_FILE"
su - ec2-user -c "ls -lh '$BACKUP_FILE'"
log "Backup created at: $BACKUP_FILE"

