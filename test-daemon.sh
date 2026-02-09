#!/bin/bash

# --- 설정 변수 ---
# 서비스 이름 (파라미터로 받거나 기본값 사용)
SERVICE_NAME=${1:-testdaemon}
CONF_DIR="/etc/testdaemon"
CONF_FILE="${CONF_DIR}/${SERVICE_NAME}.conf"

# --- 로깅 함수 ---
# systemd journal에 남기기 위해 logger 사용 (태그: 서비스명)
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
    # 5초마다 대기 (시스템 부하 없음)
    # 백그라운드 대기 후 wait를 사용하여 시그널을 즉시 감지하도록 함
    sleep 5 &
    wait $!
done