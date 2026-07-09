#!/usr/bin/env python3
"""Load Work24 public-sector job postings using only the official Work24 OpenAPI."""

from __future__ import annotations

from dataclasses import dataclass
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Tuple
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen
from xml.etree import ElementTree


MYSQL = os.environ.get("MYSQL_BIN", "mysql")
DB_HOST = os.environ.get("JOBABA_DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("JOBABA_DB_PORT", "3306")
DB_USER = os.environ.get("JOBABA_DB_USER", "jobaba")
DB_PASSWORD = os.environ.get("JOBABA_DB_PASSWORD")
DB_NAME = os.environ.get("JOBABA_DB_NAME", "jobaba_map")
WORK24_AUTH_KEY = os.environ.get("WORK24_AUTH_KEY")

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_SQL = ROOT / "db" / "work24_public_job_schema.sql"
TABLE = "tb_work24_public_job"

OPENAPI_URL = "https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo210L01.do"
USER_AGENT = "Mozilla/5.0 (compatible; JOBABA-MAP/1.0)"
PUBLIC_CO_TP = "04"


@dataclass(frozen=True)
class PublicJob:
    wanted_auth_no: str
    info_type_cd: str
    info_type_group: str
    inst_nm: str


def sql_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def fetch_text(url: str, timeout: int = 30) -> str:
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
        "coTp": PUBLIC_CO_TP,
    }
    return OPENAPI_URL + "?" + urlencode(params)


def text_of(parent: ElementTree.Element, tag: str) -> str:
    child = parent.find(tag)
    if child is None or child.text is None:
        return ""
    return child.text.strip()


def info_type_group_from_url(url: str) -> str:
    if not url:
        return "tb_workinfoworknet"
    query = parse_qs(urlparse(url).query)
    return query.get("infoTypeGroup", ["tb_workinfoworknet"])[0] or "tb_workinfoworknet"


def parse_page(xml_text: str) -> Tuple[int, List[PublicJob]]:
    root = ElementTree.fromstring(xml_text)
    message = text_of(root, "message")
    if message:
        code = text_of(root, "messageCd")
        raise RuntimeError(f"Work24 API error {code}: {message}")

    total_text = text_of(root, "total")
    total = int(total_text) if total_text else 0
    jobs: List[PublicJob] = []
    for wanted in root.findall("wanted"):
        wanted_auth_no = text_of(wanted, "wantedAuthNo")
        inst_nm = text_of(wanted, "company")
        info_type_cd = text_of(wanted, "infoSvc") or "VALIDATION"
        info_type_group = info_type_group_from_url(text_of(wanted, "wantedInfoUrl"))
        if wanted_auth_no and inst_nm:
            jobs.append(PublicJob(wanted_auth_no, info_type_cd, info_type_group, inst_nm))
    return total, jobs


def collect_public_jobs(display: int = 100, sleep_seconds: float = 0.05) -> Tuple[int, Dict[Tuple[str, str, str], PublicJob]]:
    total, first_jobs = parse_page(fetch_text(build_api_url(1, display)))
    jobs = {
        (job.wanted_auth_no, job.info_type_cd, job.info_type_group): job
        for job in first_jobs
    }

    page_count = (total + display - 1) // display if total else 0
    for page in range(2, page_count + 1):
        time.sleep(sleep_seconds)
        _, page_jobs = parse_page(fetch_text(build_api_url(page, display)))
        for job in page_jobs:
            jobs[(job.wanted_auth_no, job.info_type_cd, job.info_type_group)] = job

    return total, jobs


def mysql_defaults_file() -> Path:
    if not DB_PASSWORD:
        raise RuntimeError("JOBABA_DB_PASSWORD is required")

    fd, path = tempfile.mkstemp(prefix="jobaba_work24_public_", suffix=".cnf")
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
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    cnf.chmod(0o600)
    return cnf


def run_mysql(defaults_file: Path, sql: str) -> str:
    proc = subprocess.run(
        [MYSQL, f"--defaults-extra-file={defaults_file}", "-N", "-B", "-e", sql],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"mysql failed with code {proc.returncode}")
    return proc.stdout


def load_jobs(defaults_file: Path, total: int, jobs: Dict[Tuple[str, str, str], PublicJob]) -> str:
    schema_sql = SCHEMA_SQL.read_text(encoding="utf-8")
    if jobs:
        values = ",\n".join(
            f"({sql_string(job.wanted_auth_no)}, {sql_string(job.info_type_cd)}, "
            f"{sql_string(job.info_type_group)}, {sql_string(job.inst_nm)}, 'P')"
            for job in sorted(jobs.values(), key=lambda item: (item.wanted_auth_no, item.info_type_cd, item.info_type_group))
        )
        insert_sql = f"""
INSERT INTO tmp_work24_public_job_load (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP, INST_NM, INST_TYPE)
VALUES
{values};
"""
    else:
        insert_sql = ""

    sql = f"""
{schema_sql}

DROP TEMPORARY TABLE IF EXISTS tmp_work24_public_job_load;
CREATE TEMPORARY TABLE tmp_work24_public_job_load LIKE {TABLE};

{insert_sql}

SET @loaded_count := (SELECT COUNT(*) FROM tmp_work24_public_job_load);

DELETE FROM {TABLE};
INSERT INTO {TABLE} (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP, INST_NM, INST_TYPE)
SELECT WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP, INST_NM, INST_TYPE
FROM tmp_work24_public_job_load;

SELECT {total} AS api_total,
       @loaded_count AS loaded_count,
       (SELECT COUNT(*) FROM {TABLE}) AS final_count;
"""
    return run_mysql(defaults_file, sql).strip()


def main() -> int:
    total, jobs = collect_public_jobs()

    defaults_file = mysql_defaults_file()
    try:
        result = load_jobs(defaults_file, total, jobs)
        print(f"coTp={PUBLIC_CO_TP}")
        print(f"api_total={total}")
        print(f"unique_jobs={len(jobs)}")
        print(result)
        if len(jobs) != total:
            print(f"warning: API total({total}) != unique jobs({len(jobs)})", file=sys.stderr)
        return 0
    finally:
        defaults_file.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, ElementTree.ParseError) as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
