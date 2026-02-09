# Debian 패키징 후속 작업 가이드

이 문서는 데비안 PC에서 deb 패키지를 빌드하고 설치하는 방법을 설명합니다.

## 1. 사전 준비

testdaemon-deb 폴더를 데비안 PC로 복사합니다.

```bash
# 예시: scp를 사용하여 전송
scp -r testdaemon-deb user@debian-pc:/home/user/
```

또는 USB, 네트워크 공유 등을 사용하여 전송합니다.

## 2. deb 패키지 빌드

데비안 PC에서 다음 명령어를 실행합니다.

```bash
# testdaemon-deb 폴더가 있는 디렉토리로 이동
cd /path/to/testdaemon-deb/..

# deb 패키지 생성
dpkg-deb --build testdaemon-deb

# 또는 특정 이름으로 생성
dpkg-deb --build testdaemon-deb testdaemon_1.0.0_all.deb
```

성공하면 `testdaemon-deb.deb` 또는 `testdaemon_1.0.0_all.deb` 파일이 생성됩니다.

## 3. 패키지 정보 확인 (선택 사항)

```bash
# 패키지 정보 확인
dpkg-deb --info testdaemon_1.0.0_all.deb

# 패키지 내용 확인
dpkg-deb --contents testdaemon_1.0.0_all.deb
```

## 4. 패키지 설치

```bash
# deb 패키지 설치
sudo dpkg -i testdaemon_1.0.0_all.deb
```

설치 후 postinst 스크립트가 자동으로 실행되며, 다음 메시지가 표시됩니다:
```
testdaemon has been installed successfully.
To start the service, run: sudo systemctl start testdaemon
To enable auto-start on boot, run: sudo systemctl enable testdaemon
```

## 5. 서비스 시작 및 테스트

```bash
# 서비스 시작
sudo systemctl start testdaemon

# 서비스 상태 확인
sudo systemctl status testdaemon

# 로그 확인 (실시간)
sudo journalctl -u testdaemon -f
```

예상 로그 출력:
```
... STARTING: 데몬 프로세스 시작 (PID: ...)
... CONFIG_LOADED: /etc/testdaemon/testdaemon.conf 내용을 불러왔습니다 -> [ TEST_MODE=ACTIVE ... ]
... RUNNING: 서비스 대기 상태 진입...
```

## 6. 부팅 시 자동 시작 설정 (선택 사항)

```bash
# 부팅 시 자동 시작 활성화
sudo systemctl enable testdaemon

# 활성화 상태 확인
sudo systemctl is-enabled testdaemon
```

## 7. 서비스 중지 테스트

```bash
# 서비스 중지
sudo systemctl stop testdaemon

# 로그에서 정상 종료 메시지 확인
sudo journalctl -u testdaemon -n 20
```

예상 로그:
```
... SHUTDOWN_SIGNAL_RECEIVED: 데몬이 정상적으로 종료되었습니다.
... systemd[1]: Deactivated successfully.
```

## 8. 패키지 제거

### 일반 제거 (설정 파일 유지)
```bash
sudo dpkg -r testdaemon
```

### 완전 제거 (설정 파일 포함)
```bash
sudo dpkg --purge testdaemon
```

제거 시 prerm 및 postrm 스크립트가 자동으로 실행되어:
- 서비스 중지
- 서비스 비활성화
- systemd 재로드
- (purge 시) 설정 파일 삭제

## 9. 패키지 재설치 (문제 발생 시)

```bash
# 완전 제거
sudo dpkg --purge testdaemon

# 재설치
sudo dpkg -i testdaemon_1.0.0_all.deb
```

## 10. DEBIAN/control 수정 사항 (필요 시)

현재 control 파일의 Maintainer 정보를 실제 정보로 변경하세요:

```bash
# testdaemon-deb/DEBIAN/control 파일 수정
Maintainer: Your Name <your.email@example.com>
```

수정 후 다시 `dpkg-deb --build` 명령으로 패키지를 재생성합니다.

## 11. 문제 해결

### 패키지 빌드 오류
- DEBIAN 스크립트들의 실행 권한 확인: `chmod 755 testdaemon-deb/DEBIAN/*inst testdaemon-deb/DEBIAN/*rm`
- control 파일 형식 확인 (빈 줄, 들여�기 등)

### 서비스 시작 실패
```bash
# 상세 로그 확인
sudo journalctl -xeu testdaemon

# 스크립트 실행 권한 확인
ls -l /usr/local/bin/test-daemon.sh

# 수동 실행 테스트
sudo /usr/local/bin/test-daemon.sh testdaemon
```

### 설정 파일 문제
```bash
# 설정 파일 확인
cat /etc/testdaemon/testdaemon.conf

# 권한 확인
ls -la /etc/testdaemon/
```

## 12. 참고 사항

- 이 패키지는 Architecture: all로 설정되어 있어 모든 데비안 기반 시스템에서 사용 가능합니다.
- systemd를 사용하는 시스템에서만 작동합니다.
- 루트 권한으로 실행되므로 프로덕션 환경에서는 보안을 고려하여 사용하세요.
- 테스트 목적의 더미 데몬이므로 실제 서비스 기능은 없습니다.
