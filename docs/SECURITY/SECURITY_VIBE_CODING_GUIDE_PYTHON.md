# Security Vibe Coding Guide for Python

이 문서는 Python, Django, Flask, FastAPI, Jinja2, SQLAlchemy 프로젝트에서 `docs/SECURITY/SECURITY_VIBE_CODING_GUIDE.md`와 함께 적용하는 언어별 보안 지침이다.

국내 `Python 시큐어코딩 가이드(2023년 개정본)` 기준까지 상세 적용해야 하는 경우 `docs/SECURITY/PYTHON_SECURE_CODING_GUIDE_2023.md`를 함께 적용한다.

## Python 공통 필수 규칙

- [ ] 사용자 입력은 API 경계에서 스키마, DTO, Form, Serializer, Pydantic 모델 중 프로젝트 표준 방식으로 검증한다.
- [ ] SQL은 ORM 파라미터 바인딩 또는 DB-API 파라미터 바인딩만 사용한다.
- [ ] 사용자 입력을 f-string, `%`, `format()`, 문자열 결합으로 SQL, 명령어, 경로, 템플릿에 삽입하지 않는다.
- [ ] 쿠키 기반 인증을 사용하는 상태 변경 요청에는 프레임워크 CSRF 보호를 반드시 적용한다.
- [ ] 템플릿 출력은 기본 자동 이스케이프를 유지하고, `safe`, `Markup`, `|safe`는 보안 검토 없이 사용하지 않는다.
- [ ] 업로드 파일은 확장자, MIME, 파일 시그니처, 크기, 저장 경로를 서버에서 모두 검증한다.
- [ ] `pickle`, `marshal`, `shelve`, unsafe YAML 로더로 신뢰할 수 없는 데이터를 역직렬화하지 않는다.
- [ ] 운영 환경에서는 debug 모드, 상세 오류 페이지, stacktrace 응답을 비활성화한다.
- [ ] 비밀값은 `.env`, OS secret, Secret Manager 등 런타임 설정으로 주입하고 저장소에 커밋하지 않는다.

## Django 필수 규칙

- [ ] 인증이 필요한 View에는 `login_required`, `LoginRequiredMixin`, DRF permission 중 프로젝트 표준 장치를 적용한다.
- [ ] 객체 단위 권한이 필요한 조회, 수정, 삭제에는 `request.user` 기준 소유권 또는 권한 검사를 서버에서 수행한다.
- [ ] 상태 변경 View에는 CSRF middleware를 활성화하고, `@csrf_exempt`를 사용하지 않는다.
- [ ] AJAX 상태 변경 요청에는 `X-CSRFToken` 또는 프로젝트 표준 동등 방어를 포함한다.
- [ ] ORM 조회에는 `filter(field=value)`, parameterized query, QuerySet API를 사용하고 raw SQL 문자열 결합을 금지한다.
- [ ] `raw()`, `extra()`, custom SQL을 쓰는 경우 파라미터 바인딩을 적용하고 리뷰에서 근거를 남긴다.
- [ ] `DEBUG=False`, `ALLOWED_HOSTS`, `SECURE_*`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `CSRF_COOKIE_HTTPONLY` 설정을 운영 기준으로 검증한다.

## Flask 필수 규칙

- [ ] 인증이 필요한 route에는 프로젝트 표준 decorator, before_request, extension 기반 인증 검사를 적용한다.
- [ ] 상태 변경 route에는 Flask-WTF, CSRFProtect, 또는 동등한 서버 검증 CSRF 토큰을 적용한다.
- [ ] `render_template_string()`에는 사용자 입력을 전달하지 않는다.
- [ ] Jinja2 autoescape를 끄지 않는다.
- [ ] `app.run(debug=True)`, `PROPAGATE_EXCEPTIONS=True`, 상세 오류 노출 설정을 운영 환경에 적용하지 않는다.
- [ ] session secret key는 코드에 하드코딩하지 않고 환경변수 또는 secret 저장소에서 로드한다.

## FastAPI 필수 규칙

- [ ] 요청 본문, 쿼리, 경로 파라미터는 Pydantic 모델과 타입 제약으로 검증한다.
- [ ] 인증이 필요한 endpoint에는 dependency 기반 인증 검사를 적용한다.
- [ ] 리소스 소유권 또는 역할 검사가 필요한 endpoint에는 dependency 또는 service 계층에서 서버 측 권한 검사를 수행한다.
- [ ] 쿠키 기반 인증을 쓰는 상태 변경 endpoint에는 CSRF 토큰 검증을 직접 구현하거나 검증된 middleware를 적용한다.
- [ ] CORS는 허용 origin, method, header를 명시하고 `allow_origins=["*"]`와 credential 허용을 함께 사용하지 않는다.
- [ ] OpenAPI 문서 노출은 운영 정책에 따라 제한하고, 내부 endpoint를 공개 문서에 노출하지 않는다.

## 입력값 검증

- [ ] 문자열 길이, 숫자 범위, 날짜 범위, enum, 정렬 키, 페이지 크기 제한을 서버에서 검증한다.
- [ ] 정규식 검증은 허용목록 방식으로 작성하고 ReDoS 가능성이 있는 중첩 반복 패턴을 사용하지 않는다.
- [ ] 파일명, 경로, URL, redirect 대상은 허용목록 또는 canonical path 검증을 적용한다.
- [ ] 클라이언트 검증만으로 서버 검증을 대체하지 않는다.

## SQL Injection 방지

허용:

```python
cursor.execute("SELECT * FROM users WHERE id = %s", [user_id])
session.query(User).filter(User.id == user_id).one_or_none()
```

금지:

```python
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
cursor.execute("SELECT * FROM users WHERE id = " + user_id)
```

- [ ] 동적 정렬 컬럼은 사용자 입력을 그대로 쓰지 않고 서버 정의 허용목록으로 매핑한다.
- [ ] `text()` 또는 raw SQL은 반드시 바인딩 파라미터를 사용한다.

## XSS 방지

- [ ] Jinja2, Django Template의 자동 이스케이프를 유지한다.
- [ ] HTML을 허용해야 하는 입력은 sanitizer 라이브러리로 허용 태그와 속성을 제한한다.
- [ ] JSON 응답은 `application/json`으로 반환하고 HTML 컨텍스트에 직접 삽입하지 않는다.
- [ ] CSP를 적용할 수 있는 프로젝트에서는 `script-src`, `object-src`, `base-uri`, `frame-ancestors` 기준을 검토한다.

## 명령 실행과 파일 처리

- [ ] `subprocess`는 list 인자와 `shell=False`를 사용한다.
- [ ] 사용자 입력을 OS 명령어, 옵션, 파일 경로에 직접 연결하지 않는다.
- [ ] 필요한 명령과 옵션은 서버 측 허용목록으로 매핑한다.
- [ ] 업로드 파일은 웹 루트 바깥에 저장하고 난수 파일명으로 저장한다.
- [ ] 압축 해제 시 zip slip 방지를 위해 대상 경로가 허용 디렉터리 안인지 검증한다.

## 역직렬화와 파서

- [ ] 신뢰할 수 없는 데이터에 `pickle.loads()`, `yaml.load()`, `marshal.loads()`를 사용하지 않는다.
- [ ] YAML은 `yaml.safe_load()`를 사용한다.
- [ ] XML 파싱은 XXE 방어가 적용된 라이브러리 또는 안전 설정을 사용한다.
- [ ] 대용량 JSON, XML, CSV 처리는 크기와 row 수 제한을 적용한다.

## 의존성 및 공급망

- [ ] 의존성 추가 전 라이선스, 유지보수 상태, 최근 취약점, transitive dependency를 확인한다.
- [ ] `pip-audit`, `safety`, `poetry audit` 중 프로젝트 표준 명령으로 취약점 점검을 실행한다.
- [ ] `requirements.txt`, `poetry.lock`, `Pipfile.lock` 등 lock 파일을 유지한다.
- [ ] 패키지 설치 스크립트와 post-install 동작을 검토한다.

## 완료 전 보안 게이트

Python 보안 관련 변경 완료 전 다음 기록을 남긴다.

```markdown
Security check:
- Common guide: docs/SECURITY/SECURITY_VIBE_CODING_GUIDE.md applied
- Python guide: docs/SECURITY/SECURITY_VIBE_CODING_GUIDE_PYTHON.md applied
- Detailed guide: docs/SECURITY/PYTHON_SECURE_CODING_GUIDE_2023.md checked when needed
- Auth/authz: none | applied | changed
- Input validation: none | applied | changed
- SQL/command/template/path risk: checked
- CSRF/CORS/session/cookie: checked
- File/deserialization/dependency: checked
- Test or QA: <command or manual verification>
- Exceptions: none | <documented exception and compensating control>
```
