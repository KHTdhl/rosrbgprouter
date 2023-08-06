# 相关交流群
[电报群](https://t.me/+bzSRf6dtG3lhYWVl)
# 基本原理
- 利用pve lxc特性，建立透明网关与DNS解析服务器，占用资源小，性能高，稳定性好
- 将透明网关生成的非本地路由表直接导入ROS，利用ROS通过路由表进行分流
- 非本地路由表直接由透明网关进行访问，由tun网卡进行流量转发，理论上，性能更好
- DNS选取easymosdns项目，解决dns污染与分流问题
- 加入谷歌健康检测，方便ros 进行netwatch操作
# 特别感谢以下相关教程，排名不分先后
[使用RouterOS，OSPF 和OpenWRT给国内外 IP 分流](https://www.truenasscale.com/2021/12/13/195.html) 

[使用 RouterOS，OSPF 和树莓派为国内外 IP 智能分流](https://idndx.com/use-routeros-ospf-and-raspberry-pi-to-create-split-routing-for-different-ip-ranges/)

[linux下部署Clash+dashboard](https://parrotsec-cn.org/t/linux-clash-dashboard/5169)

[基于路由协议的ip分流(RouterOS为例)](https://www.chiphell.com/thread-2438228-1-1.html)
