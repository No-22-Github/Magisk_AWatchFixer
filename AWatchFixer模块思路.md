# AWatchFixer模块具体思路

## post-fs-data.sh
1. 输出日志到日志文件
2. 启动`AWF_pfd_brick_rescue.sh`

### AWF_pfd_brick_rescue.sh
1. 读取配置文件，加载救砖对策
2. 如果有`AWF_skip1`文件，就删除文件，跳过以下步骤，直接开机
3. 记录开机次数到`AWF_boot_log1.log`
4. 如果开机次数≥2，根据开机次数执行对应策略，并创建`AWF_skip1`文件，重启尝试开机或进入对应模式

## service.sh
1. 输出日志到日志文件
2. 删除`AWF_boot_log.log`
3. 启动`AWF_s_brick_rescue.sh`

### AWF_s_brick_rescue.sh
1. 读取配置文件，加载救砖对策
2. 如果有`AWF_skip2`文件，就删除文件，跳过以下步骤，直接开机
3. 记录开机次数到`AWF_boot_log2.log`
4. 如果开机次数≥2，根据开机次数执行对应策略，并创建`AWF_skip2`文件，重启尝试开机或进入对应模式
5. 进入`check_boot_status`函数循环，等待时间≥`$TIMEOUT`时间时，创建`AWF_skip2`文件，执行救砖操作
