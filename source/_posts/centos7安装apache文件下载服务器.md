---
title: centos7安装apache文件下载服务器
date: 2018-12-1 10:50:27
tags: [apache]
---
# centos7安装apache文件下载服务器

## part.1安装httpd
`yum install -y httpd`
## part.2 设置开机启动项
`systemctl enable httpd``
## part.3 修改配置文件
配置文件地址为：
/etc/httpd/conf/httpd.conf  
修改配置文件Listen 80  
`vim /etc/httpd/conf/httpd.conf`  
例：Listen 8051 //80为默认访问端口,若该为其它端口，首先要保证端口没有被占用，访问时也需要加端口号

## part.4指定提供下载的目录地址
因apache服务显示的地址默认为 /var/www/html
我们进入此地址

cd /var/www/html  
建立文件目录软链接
输入ln -s 文件目录地址 下载地址
例：

 ln -s /home/downloads downloads
即在/var/www/html目录建立新的文件夹downloads,并且链接到/home/downloads目录

## part.5 启动服务查看效果
`systemctl httpd start`  
访问此文件目录进行下载即在浏览器输入
http://[ip]/downloads  
即可看到/home/downloads目录下的所有文件和文件夹

如果显示访问超时，需要把防火墙关闭。

`systemctl stop firewalld.service`  
再次访问即可。
