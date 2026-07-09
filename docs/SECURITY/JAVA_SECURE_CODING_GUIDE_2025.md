# Java 시큐어코딩 가이드 2025 적용 MD

이 문서는 Java 개발 시 바로 적용할 수 있도록 Oracle `Secure Coding Guidelines for Java SE` 2025년 6월판과 국내 `소프트웨어 보안약점 진단가이드(2021.11 개정)`를 결합해 재구성한 실무용 MD다.

## 기준 문서

- Oracle Secure Coding Guidelines for Java SE
  - 문서 버전: 11.0
  - 최종 업데이트: 2025년 6월
  - URL: https://www.oracle.com/java/technologies/javase/seccodeguide.html
- 국내 소프트웨어 보안약점 진단가이드
  - 개정: 2021년 11월
  - 로컬 파일: `/Users/tanauxd/Dropbox/100.DEV/00. 공통사용(보안 포함)/소프트웨어_보안약점_진단가이드(2021).pdf`

## 사용 원칙

- 이 문서의 항목은 권장사항이 아니라 개발, 코드리뷰, QA 시 기본 준수 기준이다.
- 항목을 만족하지 않는 코드는 보안 결함으로 지적하고 수정한다.
- 예외가 필요한 경우 예외 사유, 남는 위험, 대체 통제, 검증 방법을 작업 기록에 남긴다.
- `검토함`, `고려함`, `문제없음`만으로 완료 처리하지 않는다. 적용한 통제 또는 적용하지 못한 사유를 반드시 남긴다.

## 적용 대상

- Java 8 이상 애플리케이션
- Spring Boot, Spring MVC, Spring Security
- Servlet, Filter, Interceptor, Controller, Service, Repository
- JSP, JSTL, Thymeleaf
- JPA, Hibernate, MyBatis, JDBC, JdbcTemplate
- Maven, Gradle 기반 프로젝트
- XML, JSON, YAML, 파일 업로드, 외부 URL 호출, 역직렬화 처리 코드

## 원문 기준 매핑

| 기준 | 이 문서 반영 방식 |
|---|---|
| Oracle Fundamentals | 기본 원칙, 권한 제한, 신뢰 경계, 외부 라이브러리 관리 |
| Oracle Denial of Service | 자원 제한, try-with-resources, 정수 오버플로우, 예외 처리 |
| Oracle Confidential Information | 민감정보 보호, 로그/예외/메모리/파일 노출 방지 |
| Oracle Injection and Inclusion | SQL, OS command, XML, LDAP, XSS, 동적 include 방지 |
| Oracle Input Validation | allowlist, 정규화, 범위 검증, canonicalization |
| Oracle Mutability | mutable 객체 노출과 내부 상태 변조 방지 |
| Oracle Object Construction | 생성자 중 안전하지 않은 호출, finalizer/cleaner 오용 방지 |
| Oracle Serialization and Deserialization | Java serialization, XMLDecoder, JSON polymorphic typing 제한 |
| Oracle Access Control | 권한검사 위치, 접근제어, capability 누출 방지 |
| 국내 구현단계 보안약점 | 49개 구현단계 보안약점 분류 기준 반영 |

## 1. 기본 원칙

- [ ] 코드는 안전함을 추론하기 쉬운 단순 구조로 작성한다.
- [ ] 보안 경계와 신뢰 경계를 기능 설계 단계에서 명시한다.
- [ ] 외부 입력은 신뢰 경계를 넘는 순간 검증, 정규화, 인코딩한다.
- [ ] 보안검사는 정해진 서버 측 진입점에서 수행한다.
- [ ] 권한은 최소 권한으로 부여하고, 높은 권한 코드는 낮은 권한 코드와 분리한다.
- [ ] 보안 관련 전제조건, 예외, 권한 요구사항은 Javadoc 또는 개발 문서에 기록한다.
- [ ] 외부 라이브러리와 프레임워크의 보안 업데이트를 추적하고 지연 없이 반영한다.

## 2. 입력데이터 검증 및 표현

### 2.1 SQL 삽입

- [ ] 사용자 입력을 SQL, JPQL, HQL, native query 문자열에 직접 결합하지 않는다.
- [ ] JDBC는 `PreparedStatement`만 사용한다.
- [ ] JPA는 named parameter 또는 Criteria API를 사용한다.
- [ ] MyBatis는 사용자 입력에 `#{}`만 사용하고 `${}`를 금지한다.
- [ ] 정렬 컬럼, 정렬 방향, 테이블명은 allowlist로만 선택한다.

```java
// 금지
String sql = "SELECT * FROM users WHERE name = '" + name + "'";

// 허용
PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM users WHERE name = ?"
);
ps.setString(1, name);
```

### 2.2 코드 삽입

- [ ] 사용자 입력으로 Java source, expression, script, template 코드를 실행하지 않는다.
- [ ] `ScriptEngine`, GroovyShell, MVEL, SpEL, JEXL에 사용자 입력을 직접 전달하지 않는다.
- [ ] 동적 기능은 allowlist 명령 또는 enum dispatch로 구현한다.
- [ ] Spring Expression Language가 필요하면 evaluation context와 접근 가능한 객체를 제한한다.

### 2.3 경로 조작 및 자원 삽입

- [ ] 파일 경로 입력은 `Path.normalize()`와 `toRealPath()` 후 기준 디렉터리 내부인지 검증한다.
- [ ] `../`, 절대경로, URL encoded traversal 입력은 거부한다.
- [ ] 파일 접근은 사용자 입력 경로가 아니라 서버가 발급한 파일 ID로 처리한다.
- [ ] 템플릿명, include 경로, 다운로드 경로를 사용자 입력으로 직접 받지 않는다.

```java
Path base = uploadRoot.toRealPath();
Path target = base.resolve(serverFileName).normalize();
if (!target.startsWith(base)) {
    throw new SecurityException("invalid path");
}
```

### 2.4 크로스사이트 스크립트 XSS

- [ ] Thymeleaf는 사용자 입력 출력에 `th:text`를 사용한다.
- [ ] JSP는 `<c:out>` 또는 프로젝트 표준 escaping 함수를 사용한다.
- [ ] `th:utext`, JSP scriptlet 직접 출력, 수동 HTML 문자열 조립은 금지한다.
- [ ] HTML 저장과 렌더링이 필요하면 OWASP Java HTML Sanitizer 같은 sanitizer를 적용한다.
- [ ] HTML 속성, URL, JavaScript 문자열에는 컨텍스트별 인코딩을 적용한다.
- [ ] 사용자 생성 콘텐츠 화면에는 CSP를 적용한다.

### 2.5 운영체제 명령어 삽입

- [ ] 사용자 입력을 OS command 문자열에 결합하지 않는다.
- [ ] `Runtime.exec(String)`과 `ProcessBuilder("sh", "-c", ...)` 사용을 금지한다.
- [ ] 실행 가능한 명령은 allowlist로 제한한다.
- [ ] 명령 인자는 배열로 전달하고 timeout을 설정한다.

```java
// 허용
ProcessBuilder pb = new ProcessBuilder("tar", "-xf", safeFileName);
Process p = pb.start();
```

### 2.6 위험한 형식 파일 업로드

- [ ] 업로드 확장자는 서버 allowlist로 검증한다.
- [ ] MIME 타입과 파일 시그니처를 서버에서 검증한다.
- [ ] 파일 크기 제한을 적용한다.
- [ ] 저장 파일명은 UUID 또는 보안 난수로 생성한다.
- [ ] 업로드 파일은 실행 가능한 webroot, static, template 경로 밖에 저장한다.
- [ ] 업로드 파일에는 실행 권한을 부여하지 않는다.

### 2.7 신뢰되지 않은 URL 주소로 자동접속 연결

- [ ] `next`, `returnUrl`, `redirect` 값을 그대로 `redirect:` 또는 `sendRedirect()`에 전달하지 않는다.
- [ ] 리다이렉트 URL은 allowlist prefix 또는 서버 route name만 허용한다.
- [ ] 외부 URL 리다이렉트는 허용 도메인과 `https` scheme만 허용한다.
- [ ] 허용되지 않은 URL은 기본 안전 경로로 대체한다.

### 2.8 부적절한 XML 외부개체 참조 XXE

- [ ] XML 파서는 DTD, 외부 엔티티, 외부 parameter entity, XInclude를 비활성화한다.
- [ ] `XMLConstants.FEATURE_SECURE_PROCESSING`을 적용한다.
- [ ] XML 입력 크기와 depth를 제한한다.
- [ ] XML 업로드 기능은 XXE 테스트 케이스로 검증한다.

```java
DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
factory.setXIncludeAware(false);
factory.setExpandEntityReferences(false);
```

### 2.9 XML 삽입

- [ ] XPath, XQuery 문자열에 사용자 입력을 직접 결합하지 않는다.
- [ ] XML 노드명, 속성명, XPath 조각은 allowlist로 제한한다.
- [ ] XML 출력에 사용자 입력을 넣을 때 XML escaping을 적용한다.
- [ ] XML 문서를 문자열 결합으로 생성하지 않고 안전한 XML builder를 사용한다.

### 2.10 LDAP 삽입

- [ ] LDAP filter 문자열에 사용자 입력을 직접 결합하지 않는다.
- [ ] LDAP 필터 값은 RFC 4515 escaping을 적용한다.
- [ ] LDAP attribute 이름은 allowlist로 제한한다.
- [ ] LDAP 바인딩 계정은 최소 권한으로 설정한다.

### 2.11 크로스사이트 요청 위조 CSRF

- [ ] 쿠키 기반 인증을 쓰는 모든 상태 변경 요청에는 Spring Security CSRF 토큰 검증을 적용한다.
- [ ] `csrf().disable()`은 금지한다.
- [ ] 예외가 필요한 REST API는 예외 경로, 인증 방식, 대체 방어를 작업 기록에 남긴다.
- [ ] Thymeleaf/JSP form에는 CSRF hidden input을 포함한다.
- [ ] AJAX/fetch 요청에는 CSRF 토큰을 헤더 또는 본문에 포함한다.
- [ ] `SameSite` 쿠키만으로 CSRF 방어를 대체하지 않는다.

### 2.12 서버사이드 요청 위조 SSRF

- [ ] 사용자 입력 URL로 서버가 직접 요청하지 않는다.
- [ ] 외부 호출 대상 scheme, host, port를 allowlist로 제한한다.
- [ ] loopback, 사설 IP, link-local, cloud metadata IP 요청을 차단한다.
- [ ] DNS 확인 후 최종 IP를 검증한다.
- [ ] 리다이렉트 후 최종 URL도 다시 검증한다.
- [ ] `RestTemplate`, `WebClient`, Apache HttpClient에는 connect/read timeout을 설정한다.

### 2.13 HTTP 응답분할

- [ ] 응답 헤더에 사용자 입력을 넣을 때 CR/LF 문자를 제거하거나 거부한다.
- [ ] 파일 다운로드명은 안전한 `Content-Disposition` builder 또는 RFC 5987 인코딩을 사용한다.
- [ ] `Location`, `Set-Cookie`, `Content-Disposition` 값은 검증된 helper로 생성한다.
- [ ] 헤더 값에 `\r`, `\n`, `%0d`, `%0a`가 포함되면 요청을 거부한다.

### 2.14 정수형 오버플로우

- [ ] 외부 입력 숫자는 타입, 최소값, 최대값을 검증한다.
- [ ] 파일 크기, 페이지 크기, 반복 횟수, 금액, 수량은 상한을 적용한다.
- [ ] 크기 계산에는 `Math.addExact`, `Math.multiplyExact`, `Objects.checkFromIndexSize`를 사용한다.
- [ ] overflow 발생 시 요청을 거부하거나 명시 오류로 처리한다.

### 2.15 보안기능 결정에 사용되는 부적절한 입력값

- [ ] 인증, 인가, 관리자 여부, 결제 상태를 쿠키, hidden field, query parameter 값만으로 결정하지 않는다.
- [ ] 보안 결정은 서버 세션, DB, 서명된 토큰, 권한 저장소를 기준으로 수행한다.
- [ ] 클라이언트가 보낸 `role`, `userId`, `price`, `isAdmin` 값을 신뢰하지 않는다.
- [ ] JWT는 서명, 만료, issuer, audience, algorithm을 검증한다.

### 2.16 메모리 버퍼 오버플로우

- [ ] JNI, JNA, Unsafe, direct buffer, native library 사용 코드는 입력 길이와 bounds를 명시적으로 검증한다.
- [ ] native code 호출 전 배열 길이, offset, size를 검증한다.
- [ ] `sun.misc.Unsafe`와 reflection 기반 메모리 접근을 금지한다.
- [ ] native library는 신뢰 가능한 출처와 무결성을 검증한 뒤 로드한다.

### 2.17 포맷 스트링 삽입

- [ ] 사용자 입력을 format string 자체로 사용하지 않는다.
- [ ] `String.format(userInput, ...)`, `MessageFormat.format(userInput, ...)` 패턴을 금지한다.
- [ ] 로그 메시지 포맷 문자열에 사용자 입력을 직접 사용하지 않는다.
- [ ] 사용자 메시지는 고정 템플릿에 값만 바인딩한다.

## 3. 보안기능

### 3.1 적절한 인증 없는 중요 기능 허용

- [ ] 보호 대상 URL, Controller, Handler, API에는 Spring Security, Filter, Interceptor 중 프로젝트 표준 인증 장치를 적용한다.
- [ ] 비밀번호 변경, 이메일 변경, MFA 변경, 계좌 변경 등 민감 기능에는 재인증을 적용한다.
- [ ] `permitAll()` 추가 시 공개 사유를 코드리뷰에 남긴다.
- [ ] 인증 없는 중요 기능은 보안 결함으로 지적하고 수정한다.

### 3.2 부적절한 인가

- [ ] 객체 접근 시 소유자 또는 권한 조건을 DB 조회 조건에 포함한다.
- [ ] 관리자 기능은 role, authority, permission 검사를 서버에서 수행한다.
- [ ] URL 직접 접근과 API 직접 호출을 모두 차단한다.
- [ ] 대량 조회, export, 통계 API도 권한검사를 적용한다.

### 3.3 중요한 자원에 대한 잘못된 권한 설정

- [ ] 설정 파일, 키 파일, 업로드 저장소, 로그 파일 권한은 최소 권한으로 설정한다.
- [ ] 컨테이너와 서버에서 애플리케이션은 root 권한으로 실행하지 않는다.
- [ ] 임시 파일은 안전한 API로 생성하고 world writable 위치를 사용하지 않는다.
- [ ] `Files.createFile`, `Files.createDirectory` 사용 시 권한 정책을 명시한다.

### 3.4 취약한 암호화 알고리즘 사용

- [ ] DES, RC2, RC4, MD5, SHA-1을 보안 목적으로 사용하지 않는다.
- [ ] ECB 모드는 금지한다.
- [ ] 암호화는 JCA/JCE 또는 검증된 라이브러리를 사용한다.
- [ ] 대칭키 암호화는 AES-GCM 등 AEAD 방식을 우선 사용한다.
- [ ] 자체 암호 알고리즘을 만들지 않는다.

### 3.5 암호화되지 않은 중요정보

- [ ] 비밀번호, 토큰, 주민번호, 계좌번호, API 키를 평문 저장하지 않는다.
- [ ] 비밀번호는 bcrypt, Argon2, PBKDF2 등 비밀번호 해시로 저장한다.
- [ ] 중요정보 전송에는 TLS를 사용한다.
- [ ] 쿠키에는 민감정보 원문을 저장하지 않는다.
- [ ] 백업 데이터도 암호화한다.

### 3.6 하드코드된 중요정보

- [ ] Java 코드, properties, yaml, test fixture, 문서에 실제 비밀값을 넣지 않는다.
- [ ] 비밀값은 환경변수, Vault, Secret Manager, Kubernetes Secret 등 프로젝트 표준 저장소에서 읽는다.
- [ ] Git에 커밋된 비밀값을 발견하면 즉시 폐기하고 재발급한다.
- [ ] 예시 값은 실제 형식과 혼동되지 않는 placeholder를 사용한다.

### 3.7 충분하지 않은 키 길이 사용

- [ ] RSA 키는 최소 2048비트 이상을 사용한다.
- [ ] 대칭키는 최소 128비트 이상, 신규 구현은 256비트를 우선 사용한다.
- [ ] HMAC secret과 JWT secret은 충분한 엔트로피를 가진 난수로 생성한다.
- [ ] 키 길이가 부족한 기존 키는 교체 계획을 수립하고 교체한다.

### 3.8 적절하지 않은 난수 값 사용

- [ ] 보안 토큰, 인증코드, 임시 비밀번호, 세션 ID는 `SecureRandom`으로 생성한다.
- [ ] 보안 목적으로 `java.util.Random`, `Math.random()`을 사용하지 않는다.
- [ ] 난수 seed를 고정하지 않는다.
- [ ] 토큰은 충분한 길이와 만료 시간을 가진다.

### 3.9 취약한 비밀번호 허용

- [ ] 비밀번호 최소 길이를 정책으로 정의하고 서버에서 검증한다.
- [ ] 알려진 유출 비밀번호, 사용자 ID와 동일한 비밀번호, 반복 문자 비밀번호를 거부한다.
- [ ] 관리자와 중요 계정에는 MFA를 적용한다.
- [ ] 로그인 실패 횟수 제한과 지연 정책을 적용한다.

### 3.10 부적절한 전자서명 확인

- [ ] 서명된 코드, 패키지, 문서, 토큰은 서명 검증 후 사용한다.
- [ ] 서명 검증 실패 시 처리를 중단한다.
- [ ] 검증에 사용하는 공개키와 신뢰 anchor는 안전한 저장소에서 관리한다.
- [ ] 서명 검증 예외를 무시하지 않는다.

### 3.11 부적절한 인증서 유효성 검증

- [ ] TLS 인증서 검증을 비활성화하지 않는다.
- [ ] 모든 인증서를 신뢰하는 `TrustManager`를 금지한다.
- [ ] 모든 hostname을 허용하는 `HostnameVerifier`를 금지한다.
- [ ] 자체 서명 인증서가 필요하면 명시 truststore를 사용한다.
- [ ] 인증서 만료, hostname mismatch 오류를 무시하지 않는다.

### 3.12 사용자 하드디스크에 저장되는 쿠키를 통한 정보 노출

- [ ] 쿠키에는 비밀번호, 토큰 원문, 개인정보를 저장하지 않는다.
- [ ] 세션 쿠키에는 `HttpOnly`, `Secure`, `SameSite`를 설정한다.
- [ ] 권한 정보는 서버 세션 또는 DB에서 확인한다.
- [ ] 장기 쿠키는 만료 시간과 회전 정책을 적용한다.

### 3.13 주석문 안에 포함된 시스템 주요정보

- [ ] 주석에 계정, 비밀번호, API 키, 내부 URL, 운영 절차, 우회 방법을 남기지 않는다.
- [ ] TODO 주석에 임시 인증 우회, 테스트 계정 정보를 남기지 않는다.
- [ ] 코드리뷰에서 비밀정보가 포함된 주석을 발견하면 제거하고 해당 비밀값을 폐기한다.

### 3.14 솔트 없이 일방향 해시 함수 사용

- [ ] 비밀번호 해시에 단순 SHA-256, SHA-512를 단독 사용하지 않는다.
- [ ] 비밀번호는 bcrypt, Argon2, PBKDF2처럼 salt와 반복 비용이 포함된 알고리즘으로 저장한다.
- [ ] 사용자별 고유 salt를 사용한다.
- [ ] pepper를 쓰면 코드가 아니라 시크릿 저장소에서 읽는다.

### 3.15 무결성 검사 없는 코드 다운로드

- [ ] 외부에서 다운로드한 JAR, class, plugin, script를 무결성 검증 없이 실행하지 않는다.
- [ ] 다운로드 대상은 HTTPS와 allowlist 도메인으로 제한한다.
- [ ] hash, signature, checksum을 검증한다.
- [ ] 런타임에 원격 코드를 다운로드해 실행하는 설계를 금지한다.

### 3.16 반복된 인증시도 제한 기능 부재

- [ ] 로그인, 비밀번호 재설정, OTP, 인증코드 검증에 rate limit을 적용한다.
- [ ] 계정별, IP별, 디바이스별 실패 횟수 제한을 적용한다.
- [ ] 반복 실패 시 지연, 잠금, 추가 인증 중 하나를 적용한다.
- [ ] 실패 로그에는 비밀번호와 토큰 원문을 남기지 않는다.

## 4. 시간 및 상태

### 4.1 경쟁조건: 검사 시점과 사용 시점 TOCTOU

- [ ] 권한, 잔액, 재고, 상태값 확인과 변경은 하나의 트랜잭션에서 처리한다.
- [ ] 중복 요청에는 idempotency key 또는 unique constraint를 적용한다.
- [ ] 상태 변경 작업에는 DB lock, optimistic lock, version field 중 필요한 통제를 적용한다.
- [ ] 파일 권한 확인 후 파일 사용 사이에 경로가 바뀌지 않도록 안전한 파일 핸들을 사용한다.

### 4.2 종료되지 않는 반복문 또는 재귀 함수

- [ ] 반복문, 재귀, pagination, retry에는 종료 조건과 최대 횟수를 설정한다.
- [ ] 외부 API 재시도에는 backoff와 최대 재시도 횟수를 설정한다.
- [ ] 사용자 입력으로 반복 횟수, 페이지 크기, 검색 범위를 무제한 설정하지 않는다.
- [ ] 장시간 작업은 timeout과 취소 처리를 구현한다.

## 5. 에러처리

### 5.1 오류 메시지 정보노출

- [ ] 사용자 응답에 stacktrace, SQL, 내부 경로, 환경변수, class name을 노출하지 않는다.
- [ ] 운영 환경에서 detailed error와 debug mode를 비활성화한다.
- [ ] 에러 응답은 일반 메시지와 추적 ID만 반환한다.
- [ ] 상세 오류는 서버 로그에 남기되 민감정보는 마스킹한다.

### 5.2 오류상황 대응 부재

- [ ] 외부 API, DB, 파일, 큐, 캐시 호출 실패를 처리한다.
- [ ] 실패 시 안전한 기본값 또는 명시적 오류 응답을 반환한다.
- [ ] 예외 발생 후 인증/인가 검사가 우회되는 흐름을 만들지 않는다.
- [ ] 장애 상황은 로그, 메트릭, 알림 중 프로젝트 표준 방식으로 기록한다.

### 5.3 부적절한 예외 처리

- [ ] 광범위한 `catch (Exception e) {}` 또는 빈 catch block을 금지한다.
- [ ] 예외를 잡고 성공 응답을 반환하지 않는다.
- [ ] 보안 검증 실패는 명확히 거부 응답으로 처리한다.
- [ ] 예외 로그에는 민감정보를 포함하지 않는다.

## 6. 코드오류

### 6.1 Null Pointer 역참조

- [ ] 외부 입력, 세션, DB 조회 결과, 인증 사용자처럼 null이 될 수 있는 값은 사용 전에 명시적으로 처리한다.
- [ ] `Optional`은 반환값의 부재 표현에만 사용하고 필드나 파라미터 남용을 금지한다.
- [ ] null 처리 누락으로 보안 검사가 건너뛰어지지 않게 한다.
- [ ] 정적 분석 도구의 nullness 경고를 무시하지 않는다.

### 6.2 부적절한 자원 해제

- [ ] 파일, stream, DB connection, lock은 try-with-resources 또는 finally로 해제한다.
- [ ] 임시 파일은 사용 후 삭제한다.
- [ ] connection pool과 transaction lifecycle을 명확히 관리한다.
- [ ] 예외가 발생해도 자원이 해제되도록 구현한다.

### 6.3 해제된 자원 사용

- [ ] close된 stream, connection, session, entity manager를 재사용하지 않는다.
- [ ] 비동기 작업에 request-scoped 자원을 넘기지 않는다.
- [ ] transaction 종료 후 lazy-loaded 객체 사용으로 예외가 발생하지 않도록 DTO로 변환한다.

### 6.4 초기화되지 않은 변수 사용

- [ ] 보안 결정에 쓰는 변수는 명시 기본값과 실패 기본값을 가진다.
- [ ] 인증/인가 상태 변수는 실패 시 deny로 초기화한다.
- [ ] partial initialization 객체가 외부로 노출되지 않게 한다.

### 6.5 신뢰할 수 없는 데이터의 역직렬화

- [ ] 신뢰할 수 없는 입력에 Java native serialization을 사용하지 않는다.
- [ ] `ObjectInputStream`은 allowlist filter 없이 사용하지 않는다.
- [ ] `XMLDecoder`를 신뢰할 수 없는 입력에 사용하지 않는다.
- [ ] Jackson default typing과 polymorphic deserialization은 allowlist 없이 사용하지 않는다.
- [ ] 역직렬화 대상 크기와 depth를 제한한다.

## 7. 캡슐화

### 7.1 잘못된 세션에 의한 데이터 정보 노출

- [ ] 로그인 성공 후 세션 ID를 재발급한다.
- [ ] 로그아웃 시 서버 세션을 무효화한다.
- [ ] 세션에는 최소 식별자만 저장한다.
- [ ] 권한 변경, 비밀번호 변경, MFA 변경 후 기존 세션 무효화 또는 재인증을 적용한다.
- [ ] 캐시된 사용자별 응답은 사용자 식별자와 권한 범위를 포함해 분리한다.

### 7.2 제거되지 않고 남은 디버그 코드

- [ ] 운영 코드에 debug endpoint, 테스트 계정, 인증 우회, mock flag를 남기지 않는다.
- [ ] `System.out.println`, `printStackTrace`, breakpoint성 코드를 운영 코드에 남기지 않는다.
- [ ] Spring Boot devtools와 actuator 민감 endpoint는 운영에서 비활성화하거나 인증을 적용한다.
- [ ] 디버그 플래그는 운영 배포에서 실패하도록 검증한다.

### 7.3 Public 메소드로부터 반환된 Private 배열

- [ ] 내부 mutable 배열, collection, map을 외부에 그대로 반환하지 않는다.
- [ ] 내부 상태를 반환해야 하면 defensive copy, immutable collection, DTO로 반환한다.
- [ ] getter가 내부 mutable 객체를 직접 노출하지 않게 한다.

```java
public List<String> roles() {
    return List.copyOf(this.roles);
}
```

### 7.4 Private 배열에 Public 데이터 할당

- [ ] 외부에서 받은 mutable 객체를 내부 상태에 그대로 저장하지 않는다.
- [ ] 배열, list, map 입력은 defensive copy 후 저장한다.
- [ ] 생성자와 setter에서 mutable 객체 aliasing을 차단한다.

```java
public User(List<String> roles) {
    this.roles = List.copyOf(roles);
}
```

## 8. API 오용

### 8.1 DNS lookup에 의존한 보안결정

- [ ] DNS 이름만으로 내부/외부 접근 허용을 결정하지 않는다.
- [ ] host allowlist와 IP allowlist를 함께 검증한다.
- [ ] DNS rebinding을 막기 위해 최종 IP가 사설 IP, loopback, link-local인지 확인한다.
- [ ] DNS 확인 이후 실제 연결 대상 IP도 검증한다.
- [ ] 보안 결정은 인증, 서명, 네트워크 정책, 방화벽 정책으로 수행한다.

### 8.2 취약한 API 사용

- [ ] `Runtime.exec(String)`, `ProcessBuilder("sh", "-c", ...)`, `ObjectInputStream`, `XMLDecoder`, insecure `TrustManager`, insecure `HostnameVerifier` 사용을 금지한다.
- [ ] `MessageDigest.getInstance("MD5")`, `SHA-1`, `Cipher.getInstance("AES/ECB/...")`를 보안 목적으로 사용하지 않는다.
- [ ] `Random`과 `Math.random()`을 보안 목적으로 사용하지 않는다.
- [ ] 위험 API 사용이 발견되면 안전 API로 교체하거나 예외 사유와 대체 통제를 기록한다.

## 9. Spring/Spring Boot 필수 적용

### 9.1 Spring Security

- [ ] 모든 보호 URL은 `SecurityFilterChain`에 인증 규칙을 추가한다.
- [ ] 관리자 URL은 `hasRole`, `hasAuthority`, `@PreAuthorize` 중 프로젝트 표준 방식으로 제한한다.
- [ ] Method Security가 필요한 Service에는 `@PreAuthorize` 또는 명시 권한검사를 적용한다.
- [ ] `permitAll()`과 `web.ignoring()` 범위를 최소화한다.

### 9.2 Spring MVC 입력 검증

- [ ] Request DTO에는 Bean Validation을 적용한다.
- [ ] Controller에는 `@Valid` 또는 `@Validated`를 적용한다.
- [ ] validation 실패는 전역 예외 처리에서 안전한 오류 응답으로 변환한다.
- [ ] enum, status, role, sort 값은 allowlist로 제한한다.

### 9.3 Thymeleaf/JSP

- [ ] Thymeleaf 사용자 입력 출력은 `th:text`를 사용한다.
- [ ] JSP 사용자 입력 출력은 `<c:out>` 또는 프로젝트 표준 escaping 함수를 사용한다.
- [ ] `th:utext`, JSP scriptlet 직접 출력, EL escape 우회는 금지한다.

### 9.4 Actuator와 운영 설정

- [ ] 운영 환경에서 debug, devtools, detailed error를 비활성화한다.
- [ ] actuator는 필요한 endpoint만 노출한다.
- [ ] 민감 actuator endpoint에는 인증과 관리자 권한을 적용한다.
- [ ] `server.error.include-stacktrace=never`를 운영 기본값으로 둔다.

## 10. 의존성 및 공급망 보안

### 10.1 Maven

- [ ] `pom.xml` 변경 시 새 dependency, plugin, repository를 확인한다.
- [ ] 임의 외부 repository 추가는 금지한다.
- [ ] `mvn dependency:tree`로 의존성 변화를 확인한다.
- [ ] OWASP Dependency-Check, Snyk, Dependabot 중 프로젝트 표준 점검을 실행한다.

### 10.2 Gradle

- [ ] `build.gradle` 또는 `build.gradle.kts` 변경 시 새 dependency, plugin, repository를 확인한다.
- [ ] `mavenLocal()`과 임의 HTTP repository는 운영 빌드에서 금지한다.
- [ ] `./gradlew dependencies`로 의존성 변화를 확인한다.
- [ ] dependency lock 또는 version catalog 변경을 확인한다.

## 11. QA에서 즉시 결함으로 지적할 패턴

- 사용자 입력을 결합한 SQL, JPQL, HQL, MyBatis `${}` 실행
- `csrf().disable()` 또는 쿠키 기반 상태 변경 요청의 CSRF 검증 누락
- 인증 없는 중요 기능 또는 관리자 기능
- 소유자 검증 없는 객체 조회, 수정, 삭제
- `Runtime.exec(String)` 또는 shell command에 사용자 입력 결합
- `ObjectInputStream` 또는 `XMLDecoder`로 신뢰할 수 없는 입력 역직렬화
- 모든 인증서를 신뢰하는 `TrustManager`
- 모든 hostname을 허용하는 `HostnameVerifier`
- `MD5`, `SHA-1`, `DES`, `AES/ECB` 보안 목적 사용
- `Random`, `Math.random()` 보안 토큰 생성
- stacktrace, SQL, 내부 경로가 사용자 응답에 노출
- `th:utext`, JSP scriptlet로 사용자 입력 렌더링
- 파일 경로를 요청 파라미터로 직접 받아 다운로드
- 업로드 파일을 webroot/static/template 경로에 저장
- SSRF allowlist 없이 사용자 입력 URL 호출
- 운영 환경 actuator 민감 endpoint 공개

## 12. 개발 완료 전 점검 게이트

작업 완료 보고에는 다음을 포함한다.

```text
Java secure coding gate:
- Source guides: Oracle Java SE 2025 + 국내 보안약점 진단가이드 2021 applied
- Input validation/expression: none | applied | changed
- Auth/authz/security function: none | applied | changed
- Time/state/DoS: none | checked | changed
- Error handling: checked
- Code error/resource/deserialization: checked
- Encapsulation/session/debug: checked
- API misuse: checked
- Spring checks: Spring Security | MVC validation | template output | actuator | not applicable
- Dependency scan/tree: checked | not run with reason
- Tests or QA: <command, browser check, unit test, or manual verification>
- Exceptions: none | <documented exception and compensating control>
```

## 관련 문서

- `docs/SECURITY/SECURITY_VIBE_CODING_GUIDE.md`
- `docs/SECURITY/SECURITY_VIBE_CODING_GUIDE_JAVA.md`
- Oracle Secure Coding Guidelines for Java SE: https://www.oracle.com/java/technologies/javase/seccodeguide.html
- 국내 보안약점 진단가이드: `/Users/tanauxd/Dropbox/100.DEV/00. 공통사용(보안 포함)/소프트웨어_보안약점_진단가이드(2021).pdf`
