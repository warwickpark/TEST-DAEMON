# Systemd Control Test Daemon - 상세 기술 문서

이 문서는 testdaemon의 상세한 기술 정보와 수동 설치 방법을 제공합니다.

## 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [파일 구성](#파일-구성)
3. [수동 설치 가이드](#수동-설치-가이드)
4. [동작 검증 및 테스트](#동작-검증-및-테스트)
5. [제거 방법](#제거-방법)

---

## 프로젝트 개요

testdaemon은 systemd 서비스 제어를 학습하고 테스트하기 위한 무해한 더미 데몬입니다.

### 주요 특징

- **경량 설계**: sleep loop를 사용하여 CPU 및 메모리 사용량 최소화
- **무의존성**: 외부 라이브러리나 패키지 불필요 (bash, systemd, logger만 사용)
- **명확한 로깅**: systemd journal에 시작/종료/설정 로드 이벤트 기록
- **Graceful Shutdown**: SIGTERM/SIGINT 신호를 받으면 정상 종료 처리
- **설정 파일 지원**: `/etc/testdaemon/testdaemon.conf`에서 설정 로드

### 동작 원리

1. systemd가 서비스를 시작하면 `test-daemon.sh` 스크립트 실행
2. 스크립트는 설정 파일(`/etc/testdaemon/testdaemon.conf`)을 읽음
3. 설정 내용을 로그에 기록
4. 5초마다 sleep하는 무한 루프로 대기 상태 유지
5. `systemctl stop` 명령 시 SIGTERM 신호를 받아 정상 종료

---

## 파일 구성

### 1. 실행 스크립트: `test-daemon.sh`

**설치 경로**: `/usr/local/bin/test-daemon.sh`

실제 데몬 역할을 하는 bash 스크립트입니다.

```bash
#!/bin/bash

# --- 설정 변수 ---
# 서비스 이름 (파라미터로 받거나 기본값 사용)
SERVICE_NAME=${1:-testdaemon}
CONF_DIR="/etc/testdaemon"
CONF_FILE="${CONF_DIR}/${SERVICE_NAME}.conf"

# --- 로깅 함수 ---
# systemd journal에 남기기 위해 logger 사용
log_message() {
    local level=$1
    local msg=$2
    # 콘솔 출력 (systemd가 캡처) 및 syslog 전송
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg"
    logger -p "user.$level" -t "$SERVICE_NAME" "$msg"
}

# --- 종료 시그널 처리 (Trap) ---
# systemctl stop 명령 시 SIGTERM을 받게 됨
cleanup() {
    log_message "info" "SHUTDOWN_SIGNAL_RECEIVED: 데몬이 정상적으로 종료되었습니다."
    exit 0
}

# SIGTERM(15), SIGINT(2) 시그널을 받으면 cleanup 함수 실행
trap cleanup SIGTERM SIGINT

# --- 메인 로직 ---
log_message "info" "STARTING: 데몬 프로세스 시작 (PID: $$)"

# 설정 파일 확인 및 읽기
if [ -f "$CONF_FILE" ]; then
    # 파일 내용 읽기
    CONF_CONTENT=$(cat "$CONF_FILE")
    log_message "info" "CONFIG_LOADED: $CONF_FILE 내용을 불러왔습니다 -> [ $CONF_CONTENT ]"
else
    log_message "warning" "CONFIG_MISSING: 설정 파일이 존재하지 않습니다 ($CONF_FILE). 기본 모드로 동작합니다."
fi

# --- 데몬 유지 루프 ---
# CPU를 사용하지 않으면서 프로세스를 유지하기 위한 무한 루프
log_message "info" "RUNNING: 서비스 대기 상태 진입..."

while true; do
    # 5초마다 대기 (시스템 부하 없음) & 백그라운드 대기
    sleep 5 &
    wait $!
done
```

**주요 기능**:

- 서비스 이름을 파라미터로 받아 해당 설정 파일 로드
- SIGTERM/SIGINT 신호 처리 (Graceful Shutdown)
- 로그를 콘솔과 syslog 모두에 출력
- 무한 루프로 데몬 유지 (CPU 부하 없음)

---

### 2. Systemd 유닛 파일: `test-daemon.service`

**설치 경로**: `/etc/systemd/system/testdaemon.service`

systemd가 데몬을 관리하기 위한 설정 파일입니다.

```ini
[Unit]
Description=Systemd Control Test Daemon
After=network.target

[Service]
Type=simple
# 실행할 스크립트 경로 (%N은 서비스 이름인 testdaemon으로 치환됨)
ExecStart=/usr/local/bin/test-daemon.sh %N
User=root
Group=root

# 종료 시그널 설정
KillSignal=SIGTERM

# 프로세스 실패 시 자동 재시작 설정
Restart=on-failure
RestartSec=5s

SyslogIdentifier=testdaemon

[Install]
WantedBy=multi-user.target
```

**주요 설정**:

- `Type=simple`: 단순한 포그라운드 프로세스로 실행
- `ExecStart`: 실행할 스크립트 경로 (`%N`은 서비스 이름으로 치환)
- `User=root`: 루트 권한으로 실행
- `KillSignal=SIGTERM`: 종료 시 SIGTERM 신호 전송
- `Restart=on-failure`: 실패 시 자동 재시작
- `WantedBy=multi-user.target`: 멀티유저 모드에서 실행

---

### 3. 설정 파일: `testdaemon.conf`

**설치 경로**: `/etc/testdaemon/testdaemon.conf`

데몬이 시작할 때 읽어들이는 설정 파일입니다.

```conf
TEST_MODE=ACTIVE
DEBUG_LEVEL=5
TARGET_SYSTEM=CONTROL_NODE_01
```

**특징**:

- 자유로운 형식의 텍스트 파일
- 데몬 시작 시 내용 전체가 로그에 기록됨
- 실제로는 데몬 동작에 영향을 주지 않음 (테스트용)
- 설정 파일 로드 기능 테스트에 사용

---

## 수동 설치 가이드

deb 패키지를 사용하지 않고 수동으로 설치하는 방법입니다.

### Step 1: 실행 스크립트 설치

```bash
# 파일 복사
sudo cp test-daemon.sh /usr/local/bin/

# 실행 권한 부여
sudo chmod +x /usr/local/bin/test-daemon.sh
```

### Step 2: Systemd 유닛 파일 설치

```bash
# 파일 복사
sudo cp test-daemon.service /etc/systemd/system/testdaemon.service
```

### Step 3: 설정 디렉토리 및 파일 생성

```bash
# 설정 디렉토리 생성
sudo mkdir -p /etc/testdaemon

# 설정 파일 복사
sudo cp testdaemon.conf /etc/testdaemon/
```

### Step 4: Systemd 재로드 및 서비스 시작

```bash
# Systemd 설정 리로드
sudo systemctl daemon-reload

# 서비스 시작
sudo systemctl start testdaemon

# 서비스 상태 확인
sudo systemctl status testdaemon
```

### Step 5: (선택 사항) 부팅 시 자동 시작 설정

```bash
# 자동 시작 활성화
sudo systemctl enable testdaemon

# 확인
sudo systemctl is-enabled testdaemon
```

---

## 동작 검증 및 테스트

### 1. 시작 로그 확인

서비스가 정상적으로 시작되고 설정 파일을 읽었는지 확인합니다.

```bash
# 실시간 로그 확인
sudo journalctl -u testdaemon -f
```

**예상 출력**:

```log
Feb 09 18:30:45 hostname testdaemon[12345]: [2024-02-09 18:30:45] [info] STARTING: 데몬 프로세스 시작 (PID: 12345)
Feb 09 18:30:45 hostname testdaemon[12345]: [2024-02-09 18:30:45] [info] CONFIG_LOADED: /etc/testdaemon/testdaemon.conf 내용을 불러왔습니다 -> [ TEST_MODE=ACTIVE DEBUG_LEVEL=5 TARGET_SYSTEM=CONTROL_NODE_01 ]
Feb 09 18:30:45 hostname testdaemon[12345]: [2024-02-09 18:30:45] [info] RUNNING: 서비스 대기 상태 진입...
```

### 2. 종료 로그 확인 (Graceful Shutdown)

서비스를 중지했을 때 정상 종료 메시지가 남는지 확인합니다.

```bash
# 다른 터미널에서 서비스 중지
sudo systemctl stop testdaemon
```

**예상 출력 (journalctl 창에서)**:

```log
Feb 09 18:35:20 hostname testdaemon[12345]: [2024-02-09 18:35:20] [info] SHUTDOWN_SIGNAL_RECEIVED: 데몬이 정상적으로 종료되었습니다.
Feb 09 18:35:20 hostname systemd[1]: testdaemon.service: Deactivated successfully.
```

### 3. 설정 파일 수정 테스트

설정 파일을 변경한 후 서비스를 재시작하여 새 설정이 로드되는지 확인합니다.

```bash
# 설정 파일 수정
sudo nano /etc/testdaemon/testdaemon.conf

# 서비스 재시작
sudo systemctl restart testdaemon

# 로그에서 새 설정 내용 확인
sudo journalctl -u testdaemon -n 20
```

### 4. 자동 재시작 테스트

프로세스를 강제 종료했을 때 자동으로 재시작되는지 확인합니다.

```bash
# PID 확인
sudo systemctl status testdaemon | grep PID

# 프로세스 강제 종료
sudo kill -9 <PID>

# 자동 재시작 확인 (5초 후)
sudo systemctl status testdaemon
```

### 5. 부팅 후 자동 시작 테스트

```bash
# 자동 시작 활성화
sudo systemctl enable testdaemon

# 시스템 재부팅
sudo reboot

# (재부팅 후) 서비스 상태 확인
sudo systemctl status testdaemon
```

---

## 제거 방법

테스트 완료 후 시스템을 깨끗한 상태로 되돌립니다.

### 단계별 제거

```bash
# 1. 서비스 중지
sudo systemctl stop testdaemon

# 2. 자동 시작 비활성화
sudo systemctl disable testdaemon

# 3. Systemd 유닛 파일 삭제
sudo rm /etc/systemd/system/testdaemon.service

# 4. 실행 스크립트 삭제
sudo rm /usr/local/bin/test-daemon.sh

# 5. 설정 디렉토리 삭제
sudo rm -rf /etc/testdaemon

# 6. Systemd 재로드
sudo systemctl daemon-reload
```

### 제거 확인

```bash
# 서비스 목록에서 제거되었는지 확인
systemctl list-units --all | grep testdaemon

# 파일이 모두 삭제되었는지 확인
ls -l /usr/local/bin/test-daemon.sh
ls -l /etc/systemd/system/testdaemon.service
ls -ld /etc/testdaemon
```

---

## 문제 해결

### 서비스가 시작되지 않는 경우

```bash
# 상세 로그 확인
sudo journalctl -xeu testdaemon

# 스크립트 권한 확인
ls -l /usr/local/bin/test-daemon.sh

# 스크립트 수동 실행 테스트
sudo /usr/local/bin/test-daemon.sh testdaemon
```

### 설정 파일을 읽지 못하는 경우

```bash
# 설정 파일 존재 확인
ls -l /etc/testdaemon/testdaemon.conf

# 권한 확인
ls -la /etc/testdaemon/

# 경로가 올바른지 확인
cat /etc/systemd/system/testdaemon.service | grep ExecStart
```

### 로그가 나타나지 않는 경우

```bash
# systemd journal 전체 로그 확인
sudo journalctl -b

# syslog 확인
sudo tail -f /var/log/syslog | grep testdaemon

# logger 명령 테스트
logger -t testdaemon "Test message"
```

---

## 추가 정보

### 관련 문서

- [README.md](README.md) - 프로젝트 개요 및 간단한 사용법
- [post-packaging.md](post-packaging.md) - deb 패키징 작업 가이드

### systemd 관련 유용한 명령어

```bash
# 서비스 상태 확인
sudo systemctl status testdaemon

# 실시간 로그
sudo journalctl -u testdaemon -f

# 최근 로그 (n줄)
sudo journalctl -u testdaemon -n 50

# 오늘 로그
sudo journalctl -u testdaemon --since today

# 특정 시간 이후 로그
sudo journalctl -u testdaemon --since "2024-02-09 18:00:00"

# 서비스 재시작
sudo systemctl restart testdaemon

# 설정 리로드
sudo systemctl daemon-reload

# 모든 서비스 목록
systemctl list-units --type=service
```
