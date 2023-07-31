#!/bin/bash

current_time=$(date +"%Y-%m-%d-%H:%M:%S")
host_tmp=./switchhost_content_$current_time_$$
host_file=/etc/hosts
start_line="# --- SWITCHHOSTS_CONTENT_START ---"
if [[ -f "$1" ]]; then
    ref_host="$1"                                       # 手动指定hosts文件
else
    ref_host=/mnt/c/Windows/System32/drivers/etc/hosts  # 从Windows上获取hosts配置
fi

touch $host_tmp && tail -f $host_tmp &

current_time=$(date +"%Y-%m-%d %H:%M:%S")
echo -e "\e[0;35m[$current_time] --> 开始同步Windows的swichhosts内容\e[0m" # purple

src_found_flag=false
cat $ref_host | while read line; do
    if [ "$line" = "$start_line" ]; then
        src_found_flag=true
    fi

    # 如果找到了目标行，则输出该行及后续的所有行
    if $src_found_flag; then
        echo "$line" >> "$host_tmp"
    fi
done

# 3. 复制至 /etc/hosts
echo -en "\e[0;35m --> 获取swichhosts内容完毕，是否将新内容 $host_tmp 同步到 /etc/hosts[Y/n]:\e[0m" # purple
read -p "" reply
if [[ ${reply} != "n" || ${reply} != "N" ]]; then
    dst_found_flag=false
    while read line; do
        # 找到原来swichhosts的内容的开头
        if [ "$line" = "$start_line" ]; then
            dst_found_flag=true
            current_time=$(date +"%Y-%m-%d %H:%M:%S")
            echo "" >> "$host_tmp.tmp"
            echo "" >> "$host_tmp.tmp"
            echo "# Synchronized from the Windows host at $current_time" >> "$host_tmp.tmp"
            echo "" >> "$host_tmp.tmp"
            cat "$host_tmp" >> "$host_tmp.tmp"
            break
        fi

        echo $line >> "$host_tmp.tmp"
    done < "$host_file"

    if ! $dst_found_flag; then
        current_time=$(date +"%Y-%m-%d %H:%M:%S")
        echo "" >> "$host_tmp.tmp"
        echo "" >> "$host_tmp.tmp"
        echo "# Synchronized from the Windows host at $current_time" >> "$host_tmp.tmp"
        echo "" >> "$host_tmp.tmp"
        cat "$host_tmp" >> "$host_tmp.tmp"
    fi

    # 备份hosts文件
    sudo cp /etc/hosts{,.bak}

    # 将临时文件重命名为原始文件
    mv "$host_tmp.tmp" "$host_file"

    # 删除临时文件
    # rm -f ./switchhost_content_*

    # 恢复hosts文件
    # sudo cp /etc/hosts{.bak,}
fi
echo -e "\e[0;36m --> 全部操作完成，Enjoy!\e[0m" # cyan
