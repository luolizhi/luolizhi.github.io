---
title: centos搭建ftp服务器
date: 2018-12-1 10:50:27
tags: [ftp]
---
# centos搭建ftp服务器

系统环境
`Centos7.2`

安装步骤
通过yum来安装vsftpd
`sudo yum -y install vsftpd`

设置为开机启动
`sudo chkconfig vsftpd on`

修改配置
`vim /etc/vsftpd/vsftpd.conf`

修改如下
```
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES      #这行可能需自己写
pam_service_name=vsftpd
userlist_enable=YES
```
> 注：chroot_local_user #是否将所有用户限制在主目录,YES为启用 NO禁用.(该项默认值是NO,即在安装vsftpd后不做配置的话，ftp用户是可以向上切换到要目录之外的)

配置保存后，重启vsftpd服务
`sudo service vsftpd restart`

添加用户
添加vsftpd账号,并制定ftp
`sudo useradd d /home/ftpdir -s /sbin/nologin vsftpd`

为账号设置密码，按提示操作
sudo passwd vsftpd
为用户的目录修改权限，实现上传和下载文件
`sudo chmod o+w /home/ftpdir`

配置Centos防火墙
添加ip_conntrack_ftp模块
`sudo vi /etc/sysconfig/iptables-config`

添加下面一行
`IPTABLES_MODULES="ip_conntrack_ftp"`

打开ftp端口21
`sudo vi /etc/sysconfig/iptables`
添加下面一行

`-A INPUT -m state --state NEW -m tcp -p tcp --dport 21 -j ACCEPT`

重启iptables使新的规则生效
`sudo service iptables restart`

测试
可用WinSCP进行测试
