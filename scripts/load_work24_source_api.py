#!/usr/bin/env python3
"""Load Work24 source job postings into tb_empmn_worknet_api."""

from __future__ import annotations

import csv
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from xml.etree import ElementTree


MYSQL = os.environ.get("MYSQL_BIN", "mysql")
DB_HOST = os.environ.get("JOBABA_DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("JOBABA_DB_PORT", "3306")
DB_USER = os.environ.get("JOBABA_DB_USER", "jobaba")
DB_PASSWORD = os.environ.get("JOBABA_DB_PASSWORD")
DB_NAME = os.environ.get("JOBABA_DB_NAME", "jobaba_map")
WORK24_AUTH_KEY = os.environ.get("WORK24_AUTH_KEY")

OPENAPI_URL = "https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo210L01.do"
USER_AGENT = "Mozilla/5.0 (compatible; JOBABA-MAP/1.0)"

TABLE = "tb_empmn_worknet_api"
STAGING = "tb_empmn_worknet_api_staging"
PREV = "tb_empmn_worknet_api_prev"


FIELD_MAP = {
    "WANTED_AUTH_NO": "wantedAuthNo",
    "COMPANY": "company",
    "TITLE": "title",
    "JOBS_NM": "indTpNm",
    "JOBS_CD": "jobsCd",
    "SAL_TP_NM": "salTpNm",
    "SAL_TP_CD": "salTpCd",
    "SAL": "sal",
    "SAL_AMT": "sal",
    "REGION": "region",
    "REGION_CD": "regionCd",
    "HOLIDAY_TP_NM": "holidayTpNm",
    "MIN_EDUBG": "minEdubg",
    "MIN_EDUBG_CD": "minEdubgCd",
    "MAX_EDUBG": "maxEdubg",
    "MAX_EDUBG_CD": "maxEdubgCd",
    "CAREER": "career",
    "CAREER_CD": "careerCd",
    "EMP_TP_NM": "empTpNm",
    "EMP_TP_CD": "empTpCd",
    "PSN_CNT": "psnCnt",
    "RCPT_MTHD": "rcptMthd",
    "WANTED_REG_DT": "regDt",
    "CLOSE_DT": "closeDt",
    "INFO_SVC": "infoSvc",
    "WANTED_INFO_URL": "wantedInfoUrl",
    "ZIP_CD": "zipCd",
    "STRTNM_CD": "strtnmCd",
    "BASIC_ADDR": "basicAddr",
    "DETAIL_ADDR": "detailAddr",
    "RD_CNT": "rdCnt",
    "SHERE_CNT": "shereCnt",
    "BIZ_NO": "busino",
    "INTRST_CNT": "intrstCnt",
}


def qident(name: str) -> str:
    return "`" + name.replace("`", "``") + "`"


def sql_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def fetch_text(url: str, timeout: int = 60) -> str:
    req = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(req, timeout=timeout) as res:
        charset = res.headers.get_content_charset() or "utf-8"
        return res.read().decode(charset, errors="replace")


def build_api_url(page: int, display: int) -> str:
    if not WORK24_AUTH_KEY:
        raise RuntimeError("WORK24_AUTH_KEY is required")

    params = {
        "authKey": WORK24_AUTH_KEY,
        "returnType": "XML",
        "callTp": "L",
        "startPage": str(page),
        "display": str(display),
    }
    return OPENAPI_URL + "?" + urlencode(params)


def text_of(parent: ElementTree.Element, tag: str) -> str:
    child = parent.find(tag)
    if child is None or child.text is None:
        return ""
    return child.text.strip()


def parse_page(xml_text: str) -> Tuple[int, List[Dict[str, str]]]:
    root = ElementTree.fromstring(xml_text)
    message = text_of(root, "message")
    if message:
        code = text_of(root, "messageCd")
        raise RuntimeError(f"Work24 API error {code}: {message}")

    total_text = text_of(root, "total")
    total = int(total_text) if total_text else 0
    rows: List[Dict[str, str]] = []
    for wanted in root.findall("wanted"):
        row = {child.tag: (child.text or "").strip() for child in list(wanted)}
        wanted_auth_no = row.get("wantedAuthNo", "")
        if wanted_auth_no:
            rows.append(row)
    return total, rows


def collect_rows(display: int = 100, sleep_seconds: float = 0.03) -> Tuple[int, List[Dict[str, str]]]:
    total, first_rows = parse_page(fetch_text(build_api_url(1, display)))
    rows_by_id: Dict[str, Dict[str, str]] = {
        row["wantedAuthNo"]: row for row in first_rows if row.get("wantedAuthNo")
    }

    page_count = (total + display - 1) // display if total else 0
    for page in range(2, page_count + 1):
        time.sleep(sleep_seconds)
        _, page_rows = parse_page(fetch_text(build_api_url(page, display)))
        for row in page_rows:
            wanted_auth_no = row.get("wantedAuthNo")
            if wanted_auth_no:
                rows_by_id[wanted_auth_no] = row

        if page % 100 == 0:
            print(f"fetched_pages={page}/{page_count} unique_rows={len(rows_by_id)}", file=sys.stderr)

    return total, list(rows_by_id.values())


def mysql_defaults_file() -> Path:
    if not DB_PASSWORD:
        raise RuntimeError("JOBABA_DB_PASSWORD is required")

    fd, path = tempfile.mkstemp(prefix="jobaba_work24_source_", suffix=".cnf")
    os.close(fd)
    cnf = Path(path)
    cnf.write_text(
        "\n".join(
            [
                "[client]",
                f"host={DB_HOST}",
                f"port={DB_PORT}",
                f"user={DB_USER}",
                f"password={DB_PASSWORD}",
                f"database={DB_NAME}",
                "default-character-set=utf8mb4",
                "local-infile=1",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    cnf.chmod(0o600)
    return cnf


def run_mysql(defaults_file: Path, sql: str) -> str:
    proc = subprocess.run(
        [MYSQL, f"--defaults-extra-file={defaults_file}", "--local-infile=1", "-N", "-B", "-e", sql],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"mysql failed with code {proc.returncode}")
    return proc.stdout


def get_table_columns(defaults_file: Path) -> List[str]:
    sql = f"""
SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = {sql_string(TABLE)}
ORDER BY ORDINAL_POSITION;
"""
    return [line.strip() for line in run_mysql(defaults_file, sql).splitlines() if line.strip()]


def mapped_value(column: str, row: Dict[str, str], now_text: str) -> str:
    if column == "REG_DT" or column == "UPD_DT":
        return now_text
    if column == "REG_USR" or column == "UPD_USR":
        return "WORK24_API"
    if column == "USE_YN":
        return "Y"
    if column == "DEL_YN":
        return "N"
    if column == "CL_CD":
        return row.get("jobsCd", "")
    if column == "JOB_CAREER_CD":
        return row.get("careerCd", "")
    if column == "JOB_ACDMCR_CD":
        return row.get("minEdubgCd", "")
    if column == "JOB_EMP_TP_CD":
        return row.get("empTpCd", "")
    if column == "JOB_AREA_CD":
        return row.get("regionCd", "")
    if column == "SEOUL_CAPITAL_AREA_YN":
        return ""

    api_field = FIELD_MAP.get(column)
    if not api_field:
        return ""
    return row.get(api_field, "")


def write_tsv(path: Path, columns: List[str], rows: List[Dict[str, str]]) -> None:
    now_text = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        for row in rows:
            writer.writerow([mapped_value(column, row, now_text) for column in columns])


def build_load_sql(tsv_path: Path, columns: List[str], expected_count: int) -> str:
    return f"""
DROP TABLE IF EXISTS {qident(STAGING)};
CREATE TABLE {qident(STAGING)} LIKE {qident(TABLE)};

LOAD DATA LOCAL INFILE {sql_string(str(tsv_path))}
INTO TABLE {qident(STAGING)}
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\\t'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\\n'
({", ".join(qident(column) for column in columns)});

SET @loaded_count := (SELECT COUNT(*) FROM {qident(STAGING)});
SET @expected_count := {expected_count};
SET @swap_sql := IF(
    @loaded_count = @expected_count,
    'RENAME TABLE {TABLE} TO {PREV}, {STAGING} TO {TABLE}',
    'DO 0'
);

DROP TABLE IF EXISTS {qident(PREV)};
PREPARE swap_stmt FROM @swap_sql;
EXECUTE swap_stmt;
DEALLOCATE PREPARE swap_stmt;

SELECT @expected_count AS expected_count,
       @loaded_count AS loaded_count,
       (SELECT COUNT(*) FROM {qident(TABLE)}) AS final_count;
"""


def main() -> int:
    total, rows = collect_rows()
    if not rows:
        raise RuntimeError("no Work24 source rows collected")

    defaults_file = mysql_defaults_file()
    try:
        columns = get_table_columns(defaults_file)
        if "WANTED_AUTH_NO" not in columns:
            raise RuntimeError(f"{TABLE}.WANTED_AUTH_NO column not found")

        with tempfile.TemporaryDirectory(prefix="jobaba_work24_source_") as tmp:
            tsv_path = Path(tmp) / "work24_source.tsv"
            write_tsv(tsv_path, columns, rows)
            result = run_mysql(defaults_file, build_load_sql(tsv_path, columns, len(rows))).strip()
            print(f"api_total={total}")
            print(f"unique_rows={len(rows)}")
            print(result)
            if len(rows) != total:
                print(f"warning: API total({total}) != unique rows({len(rows)})", file=sys.stderr)
            return 0
    finally:
        defaults_file.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, ElementTree.ParseError) as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
