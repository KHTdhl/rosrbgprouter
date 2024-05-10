# 相关交流群
[电报群](https://t.me/+bzSRf6dtG3lhYWVl)
# 基本原理
- 利用pve lxc特性，建立透明网关与DNS解析服务器，占用资源小，性能高，稳定性好
- 将透明网关生成的非本地路由表直接导入ROS，利用ROS通过路由表进行分流
- 非本地路由表直接由透明网关进行访问，由tun网卡进行流量转发，理论上，性能更好
- DNS选取easymosdns项目，解决dns污染与分流问题
# 特别感谢以下相关教程，排名不分先后
[使用RouterOS，OSPF 和OpenWRT给国内外 IP 分流](https://www.truenasscale.com/2021/12/13/195.html) 

[使用 RouterOS，OSPF 和树莓派为国内外 IP 智能分流](https://idndx.com/use-routeros-ospf-and-raspberry-pi-to-create-split-routing-for-different-ip-ranges/)

[linux下部署Clash+dashboard](https://parrotsec-cn.org/t/linux-clash-dashboard/5169)

[基于路由协议的ip分流(RouterOS为例)](https://www.chiphell.com/thread-2438228-1-1.html)
# 创建lxc容器模板
## 乌班图下载
```
/var/lib/vz/template/cache
#上传文件夹
```
## 容器创建
取消特权容器勾选
其他配置根据自己实际情况设定
## 容器优化
### 容器完善
创建完成后容器，不要开机，进入对应容器的选项
勾选一下选项
- 嵌套
- nfs
- smb
- fuse
### 容器配置文件
进入pve控制台，进入/etc/pve/lxc文件夹，修改对应的配置文件，添加以下内容
```
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop: 
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```
### 开启第三方登录
```
nano /etc/ssh/sshd_config
service ssh restart
```
### 设置东八区与中文
```
timedatectl set-timezone Asia/Shanghai
# 追加本地语言配置
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
# 重新配置本地语言
dpkg-reconfigure locales
# 指定本地语言
export LC_ALL="zh_CN.UTF-8"
#中文的设置
```
### 常用软件安装
```
apt install zsh git vim curl -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
### 添加未知命令提示工具
```
nano ~/.zshrc

. /etc/zsh_command_not_found
#在文件末尾添加以上内容

source ~/.zshrc
#配置生效
```
# 轻松搭建分流DNS服务器
我们右键刚才建立好的模板，完整复制一个lxc容器，网络地址修改为192.168.10.153
```

chmod +x dns.sh
./dns.sh


crontab -e


在文件末尾添加以下内容
0 5 * * * sudo truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/rules/update-cdn
#每天5点升级域名库并清除mosdns日志文件

```
## 配置文件修改
- 调整日志级别
- 开启缓存
- 添加统计插件
- 添加dns记录详细解析
- 开启api
```
sudo mosdns service restart
```
# 透明网关的创建与设置
```
chmod +x installclash.sh

./installclash.sh
至此，透明网关安装完成，我们接下来需要一份透明配置




# 订阅地址版本，需要将节点列表里的url换为你的订阅地址，支持那种打开是文件型的订阅地址
interface-name: eth0
ipv6: false
tun:
    enable: true
    stack: system
    auto-detect-interface: false
port: 7891
socks-port: 7890
redir-port: 7893
allow-lan: true
profile:
  # open tracing exporter API
  tracing: true
mode: Rule
external-ui: /home/ui
secret: '123456789'
external-controller: 0.0.0.0:9090
log-level: silent
proxy-providers:
  节点列表:
   type: http
   path: ./profiles/proxies/foo.yaml
   url: 
   interval: 3600 
   filter: '倍率:1|专线'
   health-check:
     enable: true
     url: http://www.gstatic.com/generate_204
     interval: 300
 
proxy-groups:  
  - name: PROXY
    type: select
    url: http://www.gstatic.com/generate_204
    interval: 3600
    use:
      - 节点列表
    proxies:
      - DIRECT    
rules:
  - MATCH,PROXY



# 本地文件版本，提前将下载或者转换好的配置文件重命名为1.yaml，放入/etc/clash/文件夹
interface-name: eth0
ipv6: false
tun:
    enable: true
    stack: system
    auto-detect-interface: true
port: 7891
socks-port: 7890
redir-port: 7893
allow-lan: true
profile:
  # open tracing exporter API
  tracing: true
mode: Rule
external-ui: /home/ui
secret: '123456789'
external-controller: 0.0.0.0:9013
log-level: silent
proxy-providers:
  节点列表:
    type: file
    path: /etc/clash/1.yaml
    filter: ''
    health-check:
      enable: true
      url: http://www.gstatic.com/generate_204
      interval: 300    
 
proxy-groups:  
  - name: PROXY
    type: select
    url: http://www.gstatic.com/generate_204
    interval: 3600
    use:
      - 节点列表
    proxies:
      - DIRECT    
rules:
  - MATCH,PROXY

chmod +x installclash.sh

./installclash.sh
至此，透明网关安装完成，我们接下来需要一份透明配置

```
## 非本地ip表获取
```

cd /home

chmod +x iplist.sh
赋予权限

./iplist.sh

执行程序


crontab -e



0 5 * * * /bin/bash /home/iplist.sh

```
## 路由地址宣告
修改bird2配置文件为以下内容 ，文件在/etc/bird/bird.conf
```
log syslog all;

router id 192.168.10.100;

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
        neighbor 192.168.10.5 as 65530;
        source address 192.168.10.100;
        ipv4 {
                import none;
                export all;
        };
}
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
# ros的设置


```
首先打开routing选项，在table选项卡下，添加名称为bypass的路由表，勾选fib完成后，执行下一步

/ip route
add distance=1 gateway=pppoe-out1 routing-table=bypass comment=pass
# 添加一条路由规则，距离为1，网关为pppoe-out1，路由表为bypass，注释为pass

/routing/bgp/connection
add name=clash local.role=ebgp remote.address=192.168.10.100 .as=65531 routing-table=bypass router-id=192.168.10.5 as=65530 multihop=yes
# 添加一个BGP连接，名称为clash，本地角色为ebgp，远程地址为192.168.10.100，自治系统号为65531，路由表为bypass，路由器ID为192.168.10.5，自治系统号为65530，启用多跳选项

/ip firewall mangle add action=accept chain=prerouting src-address=192.168.10.100
# 添加一个防火墙Mangle规则，动作为接受，链为prerouting，源地址为192.168.10.253

/ip firewall address-list add list=proxy address=192.168.10.32
# 添加一个地址列表，名称为proxy，包含地址192.168.10.32
# 该地址支持ip段 例如 192.168.10.1-192.168.10.255


/ip firewall mangle add action=mark-routing chain=prerouting src-address-list=proxy dst-port=80,443 dst-address-type=!local protocol=tcp new-routing-mark=bypass
# 添加一个防火墙Mangle规则，动作为标记路由，链为prerouting，源地址列表为proxy，连接类型tcp。目标端口为80和443，目标地址类型不是本地地址，新的路由标记为bypass

重启路由
```
如果您感觉我的文章有用，或者支持我更加努力的进行创作，可以小小的支持一下！
<p align="center">
  <img src="https://private-user-images.githubusercontent.com/22527177/329613668-82c375a5-0296-4f08-97bd-2c6e0bdc7789.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MTUzNTI3MDIsIm5iZiI6MTcxNTM1MjQwMiwicGF0aCI6Ii8yMjUyNzE3Ny8zMjk2MTM2NjgtODJjMzc1YTUtMDI5Ni00ZjA4LTk3YmQtMmM2ZTBiZGM3Nzg5LmpwZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDA1MTAlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwNTEwVDE0NDY0MlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWQxYzBiM2QyZGU2MTUwMmY0MTE1MTQyMWZhZTA2YjliMmFjNWYyZDA5OGNiMjg0Mzk3NjI0NDU5ZjVhOTcwMjcmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.UPvRLwgjVzTjr_sHxTrkIV53eY9FGfgwaR11ro-4jAg" alt="Image" width="200" height="200">
</p>
