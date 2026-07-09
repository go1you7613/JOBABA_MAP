#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-${PROJECT_ROOT}/docker-compose.yml}"
DB_SERVICE="${DB_SERVICE:-jobaba-map-db}"
JOBABA_SYNC_SQL="${JOBABA_SYNC_SQL:-/docker-entrypoint-initdb.d/002-build-job-posting-table.sql}"

DOCKER_BIN="${DOCKER_BIN:-docker}"
DOCKER_CMD=("${DOCKER_BIN}")
if [ "${JOBABA_DOCKER_SUDO:-}" = "1" ]; then
  DOCKER_CMD=(sudo "${DOCKER_BIN}")
fi

if ! "${DOCKER_CMD[@]}" compose -f "${COMPOSE_FILE}" ps "${DB_SERVICE}" >/dev/null 2>&1; then
  echo "Docker compose DB service not found: ${DB_SERVICE}" >&2
  exit 1
fi

echo "[sync] v_job_posting docker sync started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[sync] compose=${COMPOSE_FILE} service=${DB_SERVICE}"
echo "[sync] sql=${JOBABA_SYNC_SQL}"

"${DOCKER_CMD[@]}" compose -f "${COMPOSE_FILE}" exec -T "${DB_SERVICE}" sh -c \
  'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" < "$1"' \
  sh "${JOBABA_SYNC_SQL}"

"${DOCKER_CMD[@]}" compose -f "${COMPOSE_FILE}" exec -T "${DB_SERVICE}" sh -c \
  'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" --table --execute="
SELECT TABLE_NAME, TABLE_TYPE, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE '\''v_job_posting%'\''
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS job_count
FROM v_job_posting;
"'

echo "[sync] v_job_posting docker sync completed: $(date '+%Y-%m-%d %H:%M:%S')"
