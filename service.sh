#!/system/bin/sh
MODDIR=${0%/*}
MODID=${MODDIR##*/}
CONFIG_FILE="$MODDIR/AWF_config.conf"
LOG_FILE="$MODDIR/AWF_log.log"
BOOT_LOG="$MODDIR/AWF_boot_log2.log"

read_config() {
  local result=$(sed -n "s/^$1//p" "$CONFIG_FILE")
  echo ${result:-$2}
}

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

    sync "$LOG_FILE"
}

module_log "1" "service.sh 执行中..."
rm "$MODDIR/AWF_boot_log1.log"
module_log "4" "删除 AWF_boot_log1.log 日志"

# 检查设备是否卡在开机动画或未完成启动
check_boot_status() {
    local start_time=$(date +%s)  # 获取当前时间戳

    while true; do
        # 获取当前时间戳
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))

        # 检查开机动画状态
        bootanim_status=$(getprop init.svc.bootanim)
        boot_completed=$(getprop sys.boot_completed)

        # 如果开机动画正在显示，继续等待
        if [ "$bootanim_status" = "running" ]; then
            if [ $elapsed_time -ge $TIMEOUT ]; then
                module_log "3" "设备卡在开机动画超过 $TIMEOUT 秒，触发救砖逻辑"
                return 1  # 超时，触发救砖
            fi
            sleep 10
            continue
        fi

        # 检查是否完成启动
        if [ "$boot_completed" = "1" ]; then
            module_log "1" "设备已成功启动，未卡在开机动画"
            return 0  # 启动完成
        fi

        # 如果经过时间超过最大等待时间，仍未完成启动，则触发救砖
        if [ $elapsed_time -ge $TIMEOUT ]; then
            module_log "3" "设备未完成启动，超过 $TIMEOUT 秒，触发救砖逻辑"
            return 1
        fi

        sleep 10
    done
}

# 检查目录中是否存在文件AWF_skip2
if [ -f "$MODDIR/AWF_skip2" ]; then
    rm "$MODDIR/AWF_skip2"
    module_log "2" "文件AWF_skip2存在，不执行救砖"
    module_log "4" "启动开机守护模式"
    if ! check_boot_status; then
        module_log "3" "卡在开机动画超过 "$TIMEOUT" 秒，重启"
        reboot
    else
        module_log "4" "启动正常，删除了启动次数日志文件"
        rm "$BOOT_LOG"
        exit 0
    fi
else
    module_log "1" "文件AWF_skip2不存在，脚本继续运行"
fi

module_log "4" "读取配置文件中..."
FAIL_1=$(read_config "FAIL_1=" "1")
FAIL_2=$(read_config "FAIL_2=" "2")
FAIL_3=$(read_config "FAIL_3=" "3")
FAIL_4=$(read_config "FAIL_4=" "4")
FAIL_5=$(read_config "FAIL_5=" "0")
TIMEOUT=$(read_config "TIMEOUT=" "180")

# 获取启动次数
if [ -f "$BOOT_LOG" ]; then
    Frequency=$(cat "$BOOT_LOG")
else
    Frequency=0
fi

Frequency=$((Frequency + 1))
echo "$Frequency" > "$BOOT_LOG"

# 设置针对不同启动次数的行动
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
        ;;
    2)
        module_log "4" "禁用所有 Magisk 模块"
        ls "/data/adb/modules" | while read i; do
            [[ "$i" = "$MODID" ]] && continue
            touch "/data/adb/modules/$i/disable" &>/dev/null
        done
        touch "$MODDIR/AWF_skip2"
        reboot
        ;;
    3)
        module_log "4" "进入 Recovery"
        touch "$MODDIR/AWF_skip2"
        reboot recovery
        ;;
    4)
        module_log "4" "进入 Fastboot"
        touch "$MODDIR/AWF_skip2"
        reboot bootloader
        ;;
    5)
        module_log "4" "进入 深刷模式 (EDL)"
        touch "$MODDIR/AWF_skip2"
        reboot autodloader
        ;;
    0)
        module_log "4" "关机"
        rm $BOOT_LOG
        reboot -p
        poweroff
        shutdown
        ;;
esac

# 检查开机状态
if ! check_boot_status; then
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
            touch "$MODDIR/AWF_skip2"
            reboot
            ;;
        3)
            module_log "4" "进入 Recovery"
            touch "$MODDIR/AWF_skip2"
            reboot recovery
            ;;
        4)
            module_log "4" "进入 Fastboot"
            touch "$MODDIR/AWF_skip2"
            reboot bootloader
            ;;
        5)
            module_log "4" "进入 深刷模式 (EDL)"
            touch "$MODDIR/AWF_skip2"
            reboot autodloader
            ;;
        0)
            module_log "4" "关机"
            rm $BOOT_LOG
            reboot -p
            poweroff
            shutdown
            ;;
    esac
else
    if [ -f "$BOOT_LOG" ]; then
        rm "$BOOT_LOG"
        module_log "4" "启动正常，删除了启动次数日志文件"
    fi
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 65536 ]
    then
        cp "$LOG_FILE" "$LOGFILE.old" && rm "$LOG_FILE"
        touch "$LOGFILE"
        module_log "4" "日志文件达到 64KB 及以上 已备份并重新创建"
    fi
    module_log "1" "启动正常，无需救砖"
fi
