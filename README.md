# testdaemon - Systemd Control Test Daemon

systemd 서비스 제어를 테스트하기 위한 무해한 더미 데몬입니다. 최소한의 시스템 리소스를 사용하며 외부 의존성이 없고, systemd journal에 명확한 로그를 남깁니다.

## 특징

- **경량**: sleep loop를 사용하여 CPU 사용량 최소화
- **무의존성**: 외부 라이브러리나 패키지 불필요
- **명확한 로깅**: 시작/종료/설정 로드 시 systemd journal에 로그 기록
- **Graceful Shutdown**: SIGTERM 신호를 받으면 정상 종료
- **설정 파일 지원**: `/etc/testdaemon/testdaemon.conf`에서 설정 로드

## 프로젝트 구조

```
TEST-DAEMON/
├── README.md                    # 이 파일
├── project-info.md              # 상세 프로젝트 설명 및 수동 설치 가이드
├── post-packaging.md            # Debian PC에서 패키징 작업 가이드
├── test-daemon.sh               # 데몬 실행 스크립트
├── test-daemon.service          # systemd 유닛 파일
├── testdaemon.conf              # 설정 파일 예시
└── testdaemon-deb/              # deb 패키지 빌드 디렉토리
    ├── DEBIAN/
    │   ├── control              # 패키지 메타데이터
    │   ├── postinst             # 설치 후 스크립트
    │   ├── prerm                # 제거 전 스크립트
    │   └── postrm               # 제거 후 스크립트
    ├── usr/local/bin/
    │   └── test-daemon.sh
    └── etc/
        ├── systemd/system/
        │   └── test-daemon.service
        └── testdaemon/
            └── testdaemon.conf
```

## 설치 방법

### 방법 1: deb 패키지 설치 (권장)

1. **testdaemon-deb** 폴더를 Debian/Ubuntu 시스템으로 복사합니다.

2. 패키지를 빌드합니다:
```bash
dpkg-deb --build testdaemon-deb testdaemon_1.0.0_all.deb
```

3. 패키지를 설치합니다:
```bash
sudo dpkg -i testdaemon_1.0.0_all.deb
```

4. 서비스를 시작합니다:
```bash
sudo systemctl start testdaemon
```

자세한 내용은 [post-packaging.md](post-packaging.md)를 참조하세요.

### 방법 2: 수동 설치

1. 스크립트 설치:
```bash
sudo cp test-daemon.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/test-daemon.sh
```

2. systemd 유닛 파일 설치:
```bash
sudo cp test-daemon.service /etc/systemd/system/testdaemon.service
```

3. 설정 디렉토리 및 파일 생성:
```bash
sudo mkdir -p /etc/testdaemon
sudo cp testdaemon.conf /etc/testdaemon/
```

4. systemd 재로드 및 서비스 시작:
```bash
sudo systemctl daemon-reload
sudo systemctl start testdaemon
```

자세한 내용은 [project-info.md](project-info.md)를 참조하세요.

## 사용법

### 서비스 시작
```bash
sudo systemctl start testdaemon
```

### 서비스 상태 확인
```bash
sudo systemctl status testdaemon
```

### 로그 확인 (실시간)
```bash
sudo journalctl -u testdaemon -f
```

### 로그 확인 (최근 20줄)
```bash
sudo journalctl -u testdaemon -n 20
```

### 서비스 중지
```bash
sudo systemctl stop testdaemon
```

### 부팅 시 자동 시작 활성화
```bash
sudo systemctl enable testdaemon
```

### 부팅 시 자동 시작 비활성화
```bash
sudo systemctl disable testdaemon
```

## 로그 예시

### 시작 로그
```
[2024-01-15 10:30:45] [info] STARTING: 데몬 프로세스 시작 (PID: 12345)
[2024-01-15 10:30:45] [info] CONFIG_LOADED: /etc/testdaemon/testdaemon.conf 내용을 불러왔습니다 -> [ TEST_MODE=ACTIVE DEBUG_LEVEL=5 TARGET_SYSTEM=CONTROL_NODE_01 ]
[2024-01-15 10:30:45] [info] RUNNING: 서비스 대기 상태 진입...
```

### 종료 로그
```
[2024-01-15 10:35:20] [info] SHUTDOWN_SIGNAL_RECEIVED: 데몬이 정상적으로 종료되었습니다.
```

### 설정 파일이 없을 때
```
[2024-01-15 10:30:45] [warning] CONFIG_MISSING: 설정 파일이 존재하지 않습니다 (/etc/testdaemon/testdaemon.conf). 기본 모드로 동작합니다.
```

## 설정 파일

`/etc/testdaemon/testdaemon.conf` 파일을 수정하여 데몬 동작을 커스터마이즈할 수 있습니다:

```conf
TEST_MODE=ACTIVE
DEBUG_LEVEL=5
TARGET_SYSTEM=CONTROL_NODE_01
```

설정 내용은 데몬 시작 시 로그에 기록됩니다.

## 제거

### deb 패키지로 설치한 경우

일반 제거 (설정 파일 유지):
```bash
sudo dpkg -r testdaemon
```

완전 제거 (설정 파일 포함):
```bash
sudo dpkg --purge testdaemon
```

### 수동 설치한 경우

```bash
sudo systemctl stop testdaemon
sudo systemctl disable testdaemon
sudo rm /etc/systemd/system/testdaemon.service
sudo rm /usr/local/bin/test-daemon.sh
sudo rm -rf /etc/testdaemon
sudo systemctl daemon-reload
```

## 시스템 요구사항

- **OS**: Linux (systemd 사용 시스템)
- **권한**: root (systemd 서비스로 실행)
- **의존성**: bash, systemd, logger

## 용도

- systemd 서비스 제어 학습 및 테스트
- 자동화 스크립트 개발 시 테스트용 더미 서비스
- CI/CD 파이프라인에서 서비스 관리 테스트

## 주의사항

- 이 데몬은 실제 기능이 없는 테스트용입니다.
- 루트 권한으로 실행되므로 프로덕션 환경 사용 시 보안을 고려하세요.
- 5초마다 sleep하는 간단한 루프만 실행합니다.

## 문서

- [project-info.md](project-info.md) - 상세 프로젝트 설명 및 수동 설치 가이드
- [post-packaging.md](post-packaging.md) - deb 패키징 작업 가이드

## 라이선스

MIT License

## 기여

이슈나 풀 리퀘스트는 언제든지 환영합니다.
