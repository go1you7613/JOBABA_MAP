# Security Vibe Coding Guide for Java

이 문서는 Java, Spring Boot, Spring MVC, Spring Security, JSP, Thymeleaf, Maven, Gradle 프로젝트에서 `SECURITY_VIBE_CODING_GUIDE.md`와 함께 적용하는 언어별 보안 지침이다.

공통 파일의 원칙을 먼저 적용하고, Java 구현에서는 이 파일의 필수 규칙을 추가로 적용한다.

Oracle `Secure Coding Guidelines for Java SE` 2025년 6월판과 국내 `소프트웨어 보안약점 진단가이드(2021.11 개정)` 기준까지 상세 적용해야 하는 경우 `docs/SECURITY/JAVA_SECURE_CODING_GUIDE_2025.md`를 함께 적용한다.

## 적용 대상

- Java 8 이상 애플리케이션
- Spring Boot, Spring MVC, Spring Security
- JSP, JSTL, Thymeleaf
- JPA, Hibernate, MyBatis, JDBC, JdbcTemplate
- Maven, Gradle 기반 프로젝트
- Servlet Filter, Interceptor, Controller, Service, Repository 코드

## Java 공통 필수 규칙

- [ ] 보호 대상 Controller, Handler, API에는 Spring Security, Filter, Interceptor 중 프로젝트 표준 인증 장치를 반드시 적용한다.
- [ ] 관리자 기능, 소유자 리소스, 상태 변경 API에는 서버 측 권한검사를 반드시 적용한다.
- [ ] 사용자 입력은 Controller DTO 또는 Form 객체에서 Bean Validation으로 검증한다.
- [ ] DB 쿼리는 JPA 파라미터, MyBatis `#{}` 바인딩, `PreparedStatement`, `JdbcTemplate` 파라미터 바인딩만 사용한다.
- [ ] 문자열 결합으로 SQL, JPQL, HQL, MyBatis `${}` 구문에 사용자 입력을 삽입하지 않는다.
- [ ] 파일 업로드는 확장자, MIME, 파일 시그니처, 크기, 저장 경로를 서버에서 모두 검증한다.
- [ ] 운영 환경에서는 debug, actuator 상세 노출, stacktrace 응답을 비활성화한다.

## 인증과 인가

### Spring Security

- [ ] `SecurityFilterChain` 또는 기존 보안 설정에 보호 URL 규칙을 반드시 추가한다.
- [ ] 기본 인증 제외 경로는 로그인, 정적 리소스, 헬스체크처럼 명시된 경로만 허용한다.
- [ ] `permitAll()`을 새로 추가할 때는 공개 사유를 코드리뷰에 남긴다.
- [ ] 관리자 URL은 `hasRole`, `hasAuthority`, `@PreAuthorize` 중 프로젝트 표준 방식으로 제한한다.
- [ ] 메서드 단위 권한이 필요한 Service에는 `@PreAuthorize` 또는 명시 권한검사를 적용한다.
- [ ] 사용자 ID, 게시글 ID, 파일 ID 등 객체 ID 접근은 소유자 검증을 서버에서 수행한다.

### 금지 패턴

```java
// 금지: 인증 없이 관리자 기능 노출
@GetMapping("/admin/users")
public String users() {
    return "admin/users";
}

// 금지: 클라이언트에서 받은 userId를 신뢰
orderService.getOrders(request.getParameter("userId"));
```

### 필수 패턴

```java
@PreAuthorize("hasRole('ADMIN')")
@GetMapping("/admin/users")
public String users() {
    return "admin/users";
}

@GetMapping("/orders/{orderId}")
public OrderResponse detail(@PathVariable Long orderId, Authentication auth) {
    return orderService.getOwnedOrder(orderId, auth.getName());
}
```

## CSRF

- [ ] 쿠키 기반 세션 인증을 쓰는 Spring MVC 화면과 상태 변경 요청에는 Spring Security CSRF를 활성화한다.
- [ ] `csrf().disable()`은 금지한다. REST API 등 예외가 필요하면 예외 경로, 인증 방식, 대체 방어를 보안 기록에 남긴다.
- [ ] Thymeleaf/JSP form에는 CSRF hidden input을 반드시 포함한다.
- [ ] AJAX/fetch 요청에는 CSRF 토큰을 헤더에 포함하고 서버에서 검증한다.
- [ ] QA에서 쿠키 기반 상태 변경 API에 CSRF 토큰 검증이 없으면 보안 결함으로 지적하고 수정한다.

### Thymeleaf

```html
<form method="post" th:action="@{/users}">
  <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}">
</form>
```

### JavaScript

```html
<meta name="_csrf" th:content="${_csrf.token}">
<meta name="_csrf_header" th:content="${_csrf.headerName}">
```

```javascript
const token = document.querySelector('meta[name="_csrf"]').content;
const header = document.querySelector('meta[name="_csrf_header"]').content;

fetch('/api/users', {
  method: 'POST',
  headers: { [header]: token },
  body: JSON.stringify(payload)
});
```

## 입력값 검증

- [ ] Request DTO에는 `@NotNull`, `@NotBlank`, `@Size`, `@Pattern`, `@Min`, `@Max`, `@Email` 등 Bean Validation을 적용한다.
- [ ] Controller 메서드에는 `@Valid` 또는 `@Validated`를 적용한다.
- [ ] enum, status, role, sort 값은 allowlist로 검증한다.
- [ ] `BindingResult` 또는 전역 예외 처리에서 검증 실패를 안전한 오류 응답으로 변환한다.
- [ ] Service 레이어에서 보안상 중요한 값은 한 번 더 검증한다.

```java
public record UserCreateRequest(
    @NotBlank
    @Size(max = 50)
    String name,

    @Email
    @Size(max = 100)
    String email
) {}

@PostMapping("/users")
public ResponseEntity<Void> create(@Valid @RequestBody UserCreateRequest request) {
    userService.create(request);
    return ResponseEntity.ok().build();
}
```

## SQL Injection 방지

### 필수

- [ ] JPA는 named parameter 또는 method query를 사용한다.
- [ ] MyBatis는 사용자 입력에 `#{}`만 사용한다.
- [ ] JDBC는 `PreparedStatement`만 사용한다.
- [ ] 정렬 컬럼, 정렬 방향, 테이블명은 allowlist로만 선택한다.

### 금지

```java
// 금지: 문자열 결합 SQL
String sql = "SELECT * FROM users WHERE name = '" + name + "'";

// 금지: MyBatis ${}에 사용자 입력 삽입
ORDER BY ${sort}
```

### 허용

```java
@Query("select u from User u where u.name = :name")
List<User> findByName(@Param("name") String name);
```

```xml
SELECT * FROM users
WHERE name = #{name}
```

## XSS 방지

- [ ] Thymeleaf에서는 사용자 입력 출력에 `th:text`를 사용한다.
- [ ] JSP에서는 JSTL `<c:out>` 또는 escapeXml 적용 출력을 사용한다.
- [ ] `th:utext`, JSP scriptlet 출력, 수동 문자열 HTML 조립은 금지한다.
- [ ] HTML 저장과 렌더링이 필요하면 OWASP Java HTML Sanitizer 등 검증된 sanitizer를 적용한다.
- [ ] JavaScript 문자열, URL, HTML 속성에 서버 데이터를 넣을 때 컨텍스트별 인코딩을 적용한다.

```html
<!-- 허용 -->
<span th:text="${user.name}"></span>

<!-- 금지 -->
<span th:utext="${user.profileHtml}"></span>
```

## 파일 업로드와 다운로드

- [ ] `MultipartFile.getOriginalFilename()` 값을 저장 파일명으로 사용하지 않는다.
- [ ] 저장 파일명은 UUID 또는 서버 생성 난수값으로 만든다.
- [ ] `Path.normalize()` 후 저장 기준 디렉터리 내부인지 검증한다.
- [ ] 업로드 파일은 실행 가능한 정적 리소스 경로 밖에 저장한다.
- [ ] 다운로드는 파일 경로가 아니라 파일 ID로 요청받고, 서버에서 경로 조회와 권한검사를 수행한다.
- [ ] 다운로드 응답에는 안전한 `Content-Type`과 `Content-Disposition`을 지정한다.

```java
Path base = uploadRoot.toRealPath();
Path target = base.resolve(serverFileName).normalize();
if (!target.startsWith(base)) {
    throw new SecurityException("invalid upload path");
}
```

## XML, JSON, 역직렬화

- [ ] XML 파서는 XXE 방어 옵션을 반드시 설정한다.
- [ ] Jackson default typing은 금지한다. 다형성이 필요하면 명시 allowlist를 사용한다.
- [ ] Java native serialization으로 신뢰할 수 없는 입력을 역직렬화하지 않는다.
- [ ] YAML, XML, JSON 파싱 대상 크기와 중첩 깊이를 제한한다.

```java
DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
factory.setXIncludeAware(false);
factory.setExpandEntityReferences(false);
```

## SSRF와 외부 호출

- [ ] 사용자 입력 URL로 서버가 직접 요청하지 않는다.
- [ ] 외부 호출 대상 host, scheme, port는 allowlist로 제한한다.
- [ ] 사설 IP, loopback, link-local, metadata IP 요청을 차단한다.
- [ ] 리다이렉트 후 최종 URL도 allowlist와 사설 IP 차단을 다시 검증한다.
- [ ] `RestTemplate`, `WebClient`, HTTP Client에는 connect/read timeout을 설정한다.

## 비밀값과 설정

- [ ] `application.yml`, `application.properties`, Java 코드에 비밀번호, API 키, 토큰을 하드코딩하지 않는다.
- [ ] 운영 비밀값은 환경변수, Vault, Secret Manager, Kubernetes Secret 등 프로젝트 표준 저장소에서 읽는다.
- [ ] Actuator는 필요한 endpoint만 노출하고, 민감 endpoint에는 인증을 적용한다.
- [ ] 운영에서는 `server.error.include-stacktrace=never`로 설정한다.

## 의존성 및 빌드 보안

### Maven

- [ ] `pom.xml` 변경 시 새 dependency, scope, repository를 확인한다.
- [ ] 임의 외부 repository 추가는 금지한다. 불가피하면 사유와 승인 기록을 남긴다.
- [ ] `mvn dependency:tree`로 의존성 변화를 확인한다.
- [ ] OWASP Dependency-Check, Snyk, GitHub Dependabot, Gradle/Maven audit 중 프로젝트 표준 점검을 실행한다.

### Gradle

- [ ] `build.gradle` 또는 `build.gradle.kts` 변경 시 새 plugin, dependency, repository를 확인한다.
- [ ] `mavenLocal()`과 임의 HTTP repository는 운영 빌드에서 금지한다.
- [ ] `./gradlew dependencies`로 의존성 변화를 확인한다.
- [ ] dependency lock 또는 version catalog를 쓰는 프로젝트에서는 lock 변경을 확인한다.

## 로그와 예외

- [ ] 예외 응답에 stacktrace, SQL, 내부 경로, class name을 노출하지 않는다.
- [ ] 로그에 비밀번호, 토큰, 주민번호, 계좌번호, 세션 ID를 남기지 않는다.
- [ ] MDC에는 추적용 request ID, user ID 같은 최소 식별자만 넣는다.
- [ ] `printStackTrace()`와 `System.out.println()`을 운영 코드에 남기지 않는다.

## Java QA 명령 예시

프로젝트 표준 명령이 있으면 그 명령을 우선 사용한다.

```bash
./gradlew test
./gradlew dependencies
./mvnw test
./mvnw dependency:tree
```

## Java 완료 전 보안 게이트

작업 완료 보고에는 다음을 포함한다.

```text
Java security gate:
- Spring Security/authz: none | applied | changed
- CSRF: none | applied | exception documented
- Bean Validation: none | applied | changed
- SQL binding: checked
- XSS template output: checked
- File/path handling: none | checked | changed
- XML/deserialization/SSRF: none | checked | changed
- Dependency scan/tree: checked | not run with reason
- Tests: <command or manual verification>
```
