#!/bin/bash

# 下载 routes4.conf 文件
echo "下载 routes4.conf 文件..."
curl -L -o routes4.conf https://github.com/haotianlPM/nchnroutes-k/releases/download/v1.0.0/routes4.conf

# 下载 routes6.conf 文件
echo "下载 routes6.conf 文件..."
curl -L -o routes6.conf https://github.com/haotianlPM/nchnroutes-k/releases/download/v1.0.0/routes6.conf

# 获取文件大小（单位为 KB）
filesize_routes4=$(stat -c%s routes4.conf)
filesize_routes6=$(stat -c%s routes6.conf)
filesize_routes4_kb=$((filesize_routes4/1024))
filesize_routes6_kb=$((filesize_routes6/1024))

# 如果两个文件大小都大于 400KB，则将它们复制到 /etc/bird 文件夹下，并执行 birdc configure 命令
if [ "$filesize_routes4_kb" -gt "400" ] && [ "$filesize_routes6_kb" -gt "400" ]; then
  echo "复制 routes4.conf 文件到 /etc/bird 文件夹..."
  cp -f routes4.conf /etc/bird/routes4.conf
  
  echo "复制 routes6.conf 文件到 /etc/bird 文件夹..."
  cp -f routes6.conf /etc/bird/routes6.conf
  
  # 循环执行 birdc configure 命令，直到出现 Reconfigured 为止
  echo "执行 birdc configure 命令..."
  while true; do
    if birdc configure | grep -q "Reconfigured"; then
      echo "BIRD 配置已重新加载！"
      break
    fi
    sleep 1
  done
else
  echo "文件大小不满足要求，未执行复制和 birdc configure 命令。"
fi
