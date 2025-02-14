#!/system/bin/sh
MODDIR=${0%/*}
MODID=${MODDIR##*/}
CONFIG_FILE="$MODDIR/AWF_config.conf"

read_config() {
  local result=$(sed -n "s/^$1//p" "$CONFIG_FILE")
  echo ${result:-$2}
}

echo "正在读取当前配置文件..."
sleep 0.3
FAIL_1=$(read_config "FAIL_1=" "None")
FAIL_2=$(read_config "FAIL_2=" "None")
FAIL_3=$(read_config "FAIL_3=" "None")
FAIL_4=$(read_config "FAIL_4=" "None")
FAIL_5=$(read_config "FAIL_5=" "None")
TIMEOUT=$(read_config "TIMEOUT=" "None")
echo "读取完毕！解析中..."

