
#!/usr/bin/env bash
set -e

NETWORK_NAME="app-net"
VOLUME_NAME="db-data"
DB_CONTAINER="db-server"
APP_CONTAINER="app-container"
DB_NAME="appdb"
DB_USER="appuser"
DB_PASSWORD="apppass"

echo "=== 1. Create network ==="
docker network create "$NETWORK_NAME" 2>/dev/null || true

echo "=== 2. Create named volume ==="
docker volume create "$VOLUME_NAME"

echo "=== 3. Start PostgreSQL ==="
docker rm -f "$DB_CONTAINER" 2>/dev/null || true

docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e POSTGRES_DB="$DB_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -v "$VOLUME_NAME":/var/lib/postgresql/data \
  postgres:15-alpine

echo "=== 4. Wait for PostgreSQL ==="
until docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
  sleep 2
done

echo "=== 5. Build backend image ==="
docker build -t session10-ex4-backend .

echo "=== 6. Start backend ==="
docker rm -f "$APP_CONTAINER" 2>/dev/null || true

docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 3000:3000 \
  -e DB_HOST="$DB_CONTAINER" \
  -e DB_PORT=5432 \
  -e DB_NAME="$DB_NAME" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  session10-ex4-backend

echo "=== 7. Check network and volume ==="
docker network inspect "$NETWORK_NAME"
docker volume inspect "$VOLUME_NAME"

echo "=== 8. Check backend-to-database connection ==="
sleep 3
docker logs "$APP_CONTAINER"
echo "Test API at http://localhost:3000/api/health"

