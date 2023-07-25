# 相关交流群
[电报群](https://t.me/+bzSRf6dtG3lhYWVl)
# 基本原理
- 利用pve lxc特性，建立透明网关与DNS解析服务器，占用资源小，性能高
- 将透明网关生成的非本地路由表直接导入ROS，利用ROS通过路由表进行分流
- 非本地路由表直接由透明网关进行访问，由tun网卡进行流量转发，理论上，性能更好
- DNS选取easymosdns项目，解决dns污染与分流问题
# 特别感谢以下相关教程，排名不分先后
[使用RouterOS，OSPF 和OpenWRT给国内外 IP 分流](https://www.truenasscale.com/2021/12/13/195.html) 

[使用 RouterOS，OSPF 和树莓派为国内外 IP 智能分流](https://idndx.com/use-routeros-ospf-and-raspberry-pi-to-create-split-routing-for-different-ip-ranges/)

[linux下部署Clash+dashboard](https://parrotsec-cn.org/t/linux-clash-dashboard/5169)

[基于路由协议的ip分流(RouterOS为例)](https://www.chiphell.com/thread-2438228-1-1.html)
# PVE设置
## 添加虚拟网卡
进入宿主机网络配置，创建新的网桥，命名为vmbr5，不桥接任何接口，**添加完成后，点击应用配置**
# LXC模板制作
首先创建一个非特权   ubuntu22.04容器，创建完成后
## 修改对应id容器的配置文件
宿主机pve的（/etc/pve/lxc）文件夹下，文件名称 xxx.conf
在文件末端添加一下内容，开启容器相关服务的权限
```
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop: 
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```
## 相关配置
进入相关容器选项
开启以下内容
- 嵌套
- nfs
- smb/cifs
- fuse
**配置正确的网关与dns服务器，将容器进行联网**
## 基础设置
开启容器，登录后，开启第三方ssh连接，方便后续操作
```
nano /etc/ssh/sshd_config
#编辑相关文件
#PermitRootLogin prohibit-password
修改为
PermitRootLogin yes
#保存后退出
service ssh restart
#重启ssh服务
```
### 制作模板
在左侧相关容器右键，转换成模板，方便后续不同服务使用。
# 网络信息
演示信息
- 本地局域网网段  192.168.10.0/24
- 透明网关网段   192.168.255.0/24
- 本地ros内网端口名称 bridge1
# ROS配置透明网关联网
## 所需工具安装
```
apt update
apt install vim curl bird2 -y
```
添加虚拟网卡，vmber5到ros，一般无需重启设备，ros自动识别
在ros终端执行以下内容,设置时候注意对应网段与接口，否则容易联网失败
```

/ip/address
add address=192.168.255.1/24 network=192.168.255.0 interface=ether5 comment=pass
#该网段与当前内网网段区分开，不处于同一网段


/routing/table
add name=bypass fib

/ip route
add distance=1 gateway=pppoe-out1 routing-table=bypass comment=pass
add distance=1 dst-address=192.168.0.0/16 gateway=bridge1 routing-table=bypass comment=pass

/routing/bgp/templat
set default router-id=192.168.255.1 comment=router1
/routing/bgp/connection
add name=clash local.role=ebgp remote.address=192.168.255.163 .as=65531 routing-table=bypass router-id=192.168.255.1 as=65530 multihop=yes
```
# 透明网关
## 创建相关容器
右键刚才创建的模板，模式选择完整克隆，创建完成后，修改相关网络配置
```
本地接口名称：eth0
桥接端口：vmbr0
ipv4：同网段
网关：旁路由网关
```
## clash安装
cd /home
创建一个名称为installclash.sh的脚本
```
#!/bin/bash

echo "开始下载 clash premium"
wget https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-amd64-2023.07.22.gz
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
```
赋予执行权限并运行脚本
```
chmod +x installclash.sh

./installclash.sh
```

## 配置文件修改
在线和本地二选一，
```
#以下为配置文件模板
interface-name: eth0
tun:
    enable: true
    stack: system
    auto-detect-interface: true
port: 7890
socks-port: 7891
redir-port: 7893
allow-lan: true
profile:
  # open tracing exporter API
  tracing: true
mode: Rule
external-ui: /etc/clash/ui
secret: '123456789'
external-controller: 0.0.0.0:9013
log-level: silent
proxy-providers:
  在线方式:
   type: http
   path: /etc/clash/XXX.yaml
   url: XXXXXXXXXXXXXX
   #写入订阅地址，会自动更新。
   interval: 3600 
   filter: ''
   health-check:
     enable: true
     url: http://www.gstatic.com/generate_204
     interval: 300

  #本地方式:
    #type: file
    #path: /etc/clash/XXX.yaml
    #如果无法使用在线地址，请使用本地文件
    #filter: ''
    #health-check:
      #enable: true
      #url: http://www.gstatic.com/generate_204
      #interval: 300     
proxy-groups:  
  - name: PROXY
    type: select
    url: http://www.gstatic.com/generate_204
    interval: 3600
    use:
      - 在线方式
      # -本地方式 
    proxies:
      - DIRECT
   
rules:
  - MATCH,PROXY
```
# 修改bird2配置文件
将/etc/bird/bird.conf文件修改为以下内容
```
log syslog all;

router id 192.168.255.163;

protocol device {
        scan time 60;
}

protocol kernel {
        ipv4 {
              import none;
              export all;
        };
}

protocol static {
        ipv4;
        include "routes4.conf";
}

protocol bgp {
        local as 65531;
        neighbor 192.168.255.1 as 65530;
        source address 192.168.255.163;
        ipv4 {
                import none;
                export all;
        };
}
```
## 路由表生成
在home文件夹新新建一个名称为routerlist.sh的脚本,写入以下内容
```
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
```
## 透明网关启动
```
sudo systemctl enable clash
#开机启动
sudo systemctl start clash
#开始启动



sudo systemctl status clash
#状态查看
```
## 修改透明网关地址
关机后，修改为以下地址，启动路由
```
本地接口名称：eth0
桥接端口：vmbr5
ipv4：192.168.255.163
网关：192.168.255.1
```
此时ros应该在路由表中接收到相关路由信息
## 指定可访问的ip和端口
在ros中执行以下命令
```
/ip firewall address-list add list=proxy address=192.168.10.32
# 添加局域网需要使用透明网关的ip,创建一个列表


/ip firewall mangle add action=mark-routing chain=prerouting src-address-list=proxy dst-port=80,443 dst-address-type=!local new-routing-mark=bypass
#将源地址列表为proxy、目标端口为80和443、且目标地址类型为非本地的流量标记为bypass，需要开启passthrough，这样的话   只有指定机器的80和443流入bypass路由表
```
## 添加健康检测脚本
脚本文件内容，该脚本断网后禁止ping，用来关闭相关隧道，做监测用
```
#!/usr/bin/bash
COUNT=0
MAX_COUNT=3
while [ $COUNT -lt $MAX_COUNT ]
do
        SER=0
        NET=0
        if [ $(curl --connect-timeout 5 --interface utun -w "%{http_code}" -s https://www.google.com/generate_204) -eq 204 ];then
                NET=1
        fi
        if /etc/init.d/bird status|grep Active|grep -q running;then
                SER=1
        fi
        if [ $NET -eq 1 ] && [ $SER -eq 0 ];then
                /etc/init.d/bird start
                echo 0 >/proc/sys/net/ipv4/icmp_echo_ignore_all
                exit 0
        fi
        if [ $NET -eq 0 ] && [ $SER -eq 1 ];then
                let COUNT+=1
                if [ $COUNT -eq $MAX_COUNT ];then
                        /etc/init.d/bird stop
                        echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_all
                fi
                continue
        fi
        exit 0
done
```

添加定时
```
* * * * * /home/check.sh
```
# DNS服务器配置
## 解绑53端口
```
sudo mkdir -p /etc/systemd/resolved.conf.d
#创建一个新的配置文件
vim /etc/systemd/resolved.conf.d/dns.conf
#编辑配置文件

[Resolve]
DNS=127.0.0.1
DNSStubListener=no

sudo mv /etc/resolv.conf /etc/resolv.conf.backup
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl reload-or-restart systemd-resolved 
```
## DNS服务器配置
## easymosdns安装
ip分流的最开始，我们就要建立一个无污染，能获得正确地址的dns解析服务器，这里选择的easymosdns。非常方便部署，开箱即用，另外可以部署到服务器中，搭建doh服务器，给其他朋友用，本教程采用的是本地的部署方案。
## 创建相关容器
右键刚才创建的模板，模式选择完整克隆，创建完成后，修改相关网络配置
```
本地接口名称：eth0
桥接端口：vmbr0
ipv4：192.168.10.9/24
网关：主路由

```

## easymosdns安装
```
cd /home
wget https://github.com/IrineSistiana/mosdns/releases/download/v4.5.3/mosdns-linux-amd64.zip
wget https://mirror.apad.pro/dns/easymosdns.tar.gz
unzip mosdns-linux-amd64.zip "mosdns" -d /usr/local/bin
chmod +x /usr/local/bin/mosdns
tar xzf easymosdns.tar.gz
mv easymosdns /etc/mosdns
mosdns service install -d /etc/mosdns -c config.yaml
mosdns service start




相关配置文件及redis缓存开启参考项目价绍
```
