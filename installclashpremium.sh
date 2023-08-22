#!/bin/bash
# 软件库升级
apt update
echo "软件库升级完成"

# 安装所需软件
apt install bird2 vim -y
echo "软件安装完成"

echo "开始下载 clash premium"
wget https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-amd64-2023.08.17.gz
echo "clash premium 下载完成"

echo "开始解压"
gunzip clash-linux-amd64-2023.07.22.gz
echo "解压完成"

echo "开始重命名"
mv clash-linux-amd64-2023.07.22 clash
echo "重命名完成"

echo "开始添加执行权限"
chmod u+x clash
echo "执行权限添加完成"

echo "开始创建 /etc/clash 目录"
sudo mkdir /etc/clash
echo "/etc/clash 目录创建完成"

echo "开始复制 clash 到 /usr/local/bin"
sudo cp clash /usr/local/bin
echo "复制完成"

echo "开始下载 yacd"
cd /etc/clash
wget https://github.com/haishanh/yacd/releases/download/v0.3.7/yacd.tar.xz
echo "yacd 下载完成"

echo "开始解压 yacd"
tar -xvJf yacd.tar.xz
echo "yacd 解压完成"

echo "开始重命名 yacd"
mv public ui
echo "yacd 重命名完成"

echo "开始设置 转发"
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
echo "转发设置完成"

echo "开始创建 systemd 服务"

sudo tee /etc/systemd/system/clash.service > /dev/null <<EOF
[Unit]
Description=Clash daemon, A rule-based proxy in Go.
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/clash -d /etc/clash

[Install]
WantedBy=multi-user.target
EOF

echo "systemd 服务创建完成"
