# JOBABA MAP EC2 개발서버 배포 안내

이 문서는 `jobaba-map.tanauxd.com` 개발서버의 JOBABA MAP 배포 절차입니다. 사용자가 EC2 배포를 명시적으로 요청한 경우에만 수행합니다.

## 접속 정보

| 항목 | 값 |
| --- | --- |
| SSH 키 | `~/.ssh/jobaba_map_lightsail_dev.pem` (RSA 2048) |
| 접속 계정 | `ubuntu` |
| 서버 IP | `43.203.21.169` (ap-northeast-2) |
| 도메인 | `jobaba-map.tanauxd.com` |
| 배포 경로 | `/opt/projects/active/jobaba_map/` |
| 외부 포트 | `18081` → `jobaba-map-gateway:8080` |

키 파일 권한은 최초 1회 확인합니다.

```bash
chmod 400 ~/.ssh/jobaba_map_lightsail_dev.pem
ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169
```

`ubuntu` 계정은 Docker 그룹에 속하지 않으므로, 원격의 모든 Docker 명령은 `sudo docker ...`로 실행합니다.

## 배포 원칙

- 로컬 테스트·빌드 성공 후에만 배포합니다.
- 전송 전 서버의 `be-biz.jar`, `fe-web.war`를 반드시 백업합니다.
- `jobaba-map-db`는 재생성하거나 초기화하지 않습니다.
- 재빌드·기동 대상은 `jobaba-map-fe-web`, `jobaba-map-be-biz`만입니다. Gateway와 DB는 유지합니다.
- 실패 시 `.last-jobaba-deploy-backup`에 저장된 타임스탬프로 즉시 롤백합니다.

## 배포 절차

### 1. 로컬 테스트·빌드

```bash
cd ~/Dropbox/100.DEV/JOBABA_MAP/backend
JAVA_HOME=/opt/homebrew/opt/openjdk@11 PATH=/opt/homebrew/opt/openjdk@11/bin:$PATH \
  ./gradlew clean test :be-biz:bootJar :fe-web:bootWar

cp be-biz/build/libs/be-biz-1.0.0.jar ../tmp/jobaba_map_deploy/be-biz.jar
cp fe-web/build/libs/fe-web-1.0.0.war ../tmp/jobaba_map_deploy/fe-web.war
```

### 2. 서버 상태 확인 및 백업

```bash
ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  'cd /opt/projects/active/jobaba_map && sudo docker ps --format "{{.Names}}\\t{{.Status}}"'

TS=$(date +%Y%m%d-%H%M%S)
ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  "cd /opt/projects/active/jobaba_map && \
   cp be-biz.jar be-biz.jar.bak-$TS && cp fe-web.war fe-web.war.bak-$TS && \
   echo $TS > .last-jobaba-deploy-backup && echo backup-done-$TS"
```

### 3. 전송 및 컨테이너 재기동

`scp`로 두 배포 아티팩트만 전송합니다.

```bash
cd ~/Dropbox/100.DEV/JOBABA_MAP/tmp/jobaba_map_deploy
scp -i ~/.ssh/jobaba_map_lightsail_dev.pem be-biz.jar fe-web.war \
  ubuntu@43.203.21.169:/opt/projects/active/jobaba_map/

ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  'cd /opt/projects/active/jobaba_map && \
   sudo docker compose build jobaba-map-fe-web jobaba-map-be-biz && \
   sudo docker compose up -d jobaba-map-fe-web jobaba-map-be-biz'
```

### 4. 배포 후 검증

```bash
ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  'sudo docker ps --format "{{.Names}}\\t{{.Status}}" && \
   sudo docker logs jobaba-map-be-biz --tail 15'

curl -s -o /dev/null -w "%{http_code}\\n" https://jobaba-map.tanauxd.com/map
curl -s -o /dev/null -w "%{http_code}\\n" \
  'http://43.203.21.169:18081/api/v1/map/jobs?swLat=37.4&swLng=126.8&neLat=37.6&neLng=127.1&size=1'
```

두 HTTP 상태 코드가 모두 `200`인지 확인하고, 브라우저에서 지도·목록·API 렌더링을 확인합니다. HTTP의 `/map/index.html`은 HTTPS로 리디렉션된 뒤에도 현재 라우팅에서 404이므로, 지도 화면 검증에는 `/map`을 사용합니다.

## 롤백

```bash
TS=$(ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  'cat /opt/projects/active/jobaba_map/.last-jobaba-deploy-backup')
ssh -i ~/.ssh/jobaba_map_lightsail_dev.pem ubuntu@43.203.21.169 \
  "cd /opt/projects/active/jobaba_map && \
   cp be-biz.jar.bak-$TS be-biz.jar && cp fe-web.war.bak-$TS fe-web.war && \
   sudo docker compose build jobaba-map-fe-web jobaba-map-be-biz && \
   sudo docker compose up -d jobaba-map-fe-web jobaba-map-be-biz"
```
