#!/system/bin/sh
MODDIR=${0%/*}
MODID=${MODDIR##*/}
CONFIG_FILE="$MODDIR/AWF_config.conf"
LOG_FILE="$MODDIR/AWF_log.log"
BOOT_LOG="$MODDIR/AWF_boot_log1.log"

module_log() {
  local log_level=$1
  local log_message=$2

  case $log_level in
    1) log_level="INFO" ;;
    2) log_level="WARN" ;;
    3) log_level="ERROR" ;;
    4) log_level="ACTION" ;;
  esac

  echo "[$(date '+%m-%d %H:%M:%S')] [$log_level] - $log_message" >> "$LOG_FILE"
}

module_log "1" "post-fs-data.sh 执行中..."

# 检查目录中是否存在文件AWF_skip1
if [ -f "$MODDIR/AWF_skip1" ]; then
    rm "$MODDIR/AWF_skip1"
    module_log "2" "文件AWF_skip1存在，脚本将退出。"
    exit 0
else
    module_log "1" "文件AWF_skip1不存在，脚本继续运行。"
fi

if [ -f "$CONFIG_FILE" ]; then
    grep -E '^[a-zA-Z_][a-zA-Z0-9_]*=[^(){};&|]*$' $CONFIG_FILE | sed 's/^/export /' > safe_config.sh
    # 较为安全的配置文件加载方式
    source safe_config.sh
    # God bless you.
    module_log "1" "配置文件存在，已完成加载"
else
    module_log "2" "配置文件不存在，使用默认配置"
    export FAIL_1=1
    export FAIL_2=2
    export FAIL_3=3
    export FAIL_4=4
    export FAIL_5=0
fi

if [ -f "$BOOT_LOG" ]; then
    Frequency=$(cat "$BOOT_LOG")
else
    Frequency=0
fi

Frequency=$((Frequency + 1))
echo "$Frequency" > "$BOOT_LOG"

case "$Frequency" in
    1) ACTION=1       ;;
    2) ACTION=$FAIL_1 ;;
    3) ACTION=$FAIL_2 ;;
    4) ACTION=$FAIL_3 ;;
    5) ACTION=$FAIL_4 ;;
    6) ACTION=$FAIL_5 ;;
    *) ACTION=0       ;;
esac

module_log "2" "尝试启动次数: $Frequency"

case "$ACTION" in
    1)  module_log "1" "尝试开机，进入系统"
        exit 0
        ;;
    2)
        module_log "4" "禁用所有 Magisk 模块"
        ls "/data/adb/modules" | while read i; do
            [[ "$i" = "$MODID" ]] && continue
            touch "/data/adb/modules/$i/disable" &>/dev/null
        done
        touch "$MODDIR/AWF_skip1"
        reboot
        ;;
    3)
        module_log "4" "进入 Recovery"
        touch "$MODDIR/AWF_skip1"
        reboot recovery
        ;;
    4)
        module_log "4" "进入 Fastboot"
        touch "$MODDIR/AWF_skip1"
        reboot bootloader
        ;;
    5)
        module_log "4" "进入 深刷模式 (EDL)"
        touch "$MODDIR/AWF_skip1"
        reboot autodloader
        ;;
    0)
        module_log "4" "关机"
        rm $BOOT_LOG
        reboot -p
        poweroff
        shutdown # Hope it works :P
        ;;
esac
