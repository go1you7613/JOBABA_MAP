#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROD_SQL="${PROJECT_ROOT}/db/v_job_posting_prod_template.sql"
MAPPER="${PROJECT_ROOT}/backend/core-domain/src/main/java/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml"

required_files=(
  "db/map_schema.sql"
  "db/work24_public_job_contract.sql"
  "db/v_job_posting_prod_template.sql"
  "scripts/sync_v_job_posting.sh"
  "scripts/verify_v_job_posting_prod_schema.sh"
  "backend/core-domain/src/main/java/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml"
)

for relative_path in "${required_files[@]}"; do
  if [ ! -f "${PROJECT_ROOT}/${relative_path}" ]; then
    echo "required handoff file is missing: ${relative_path}" >&2
    exit 1
  fi
done

forbidden_paths=(
  "docs/ec2-server-deployment.md"
  "scripts/load_work24_source_api.py"
  "scripts/load_work24_public_jobs.py"
  "scripts/load_worknet_csv.py"
  "scripts/load_docs_data.py"
  "scripts/sync_v_job_posting_docker.sh"
  "db/v_job_posting_local.sql"
)

for relative_path in "${forbidden_paths[@]}"; do
  if [ -e "${PROJECT_ROOT}/${relative_path}" ]; then
    echo "source-ingestion or personal deployment artifact remains: ${relative_path}" >&2
    exit 1
  fi
done

if grep -R -E -n \
  '43\.203\.21\.169|quant-eval\.tanauxd\.com|jobaba-map\.tanauxd\.com|95702b4427df8e2707e729267c908b17|fadae118705fddee31ebf7a794a459ea' \
  "${PROJECT_ROOT}/backend" "${PROJECT_ROOT}/README.md" "${PROJECT_ROOT}/docs" >/dev/null; then
  echo "personal host or hard-coded Kakao key remains in the handoff" >&2
  exit 1
fi

if ! grep -Fq "'공공데이터포털' AS SOURCE" "${PROD_SQL}" \
  || ! grep -Fq "'공공' AS SOURCE_TYPE" "${PROD_SQL}" \
  || ! grep -Fq "FROM jwrki.tb_public_job" "${PROD_SQL}"; then
  echo "public-data-portal classification contract is incomplete" >&2
  exit 1
fi

if grep -Fq "'잡코리아(공공)' AS SOURCE" "${PROD_SQL}" \
  || ! grep -Fq "'잡코리아 ETC' AS SOURCE" "${PROD_SQL}"; then
  echo "JobKorea ETC classification contract is incorrect" >&2
  exit 1
fi

for table_name in \
  "jwrki.v_job_posting" \
  "jwrki.tb_empmn_map_coord" \
  "jwrki.tb_jobcls_ncs_map"; do
  if ! grep -Fq "${table_name}" "${MAPPER}"; then
    echo "schema-qualified mapper table is missing: ${table_name}" >&2
    exit 1
  fi
done

echo "source-boundary verification passed."
