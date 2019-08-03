---
tags: [nfs]
---
# ubuntu16.04 搭建nfs服务器

## 一、服务器端：

### 1.1安装NFS服务：

#执行以下命令安装NFS服务器，

#apt会自动安装nfs-common、rpcbind等13个软件包

`sudo apt install nfs-kernel-server`

### 1.2编写配置文件：

#编辑/etc/exports 文件：

sudo vi /etc/exports

#/etc/exports文件的内容如下：
```
/tmp *(rw,sync,no_subtree_check,no_root_squash)
/data *(rw,sync,no_subtree_check,no_root_squash)
/logs *(rw,sync,no_subtree_check,no_root_squash)
```
 

### 1.3创建共享目录

#在服务器端创建/tmp /data和/logs共享目录
```
sudo mkdir -p /tmp
sudo mkdir -p /data
sudo mkdir -p /logs
```
 

### 1.4重启nfs服务：

`sudo service nfs-kernel-server restart`

### 1.5常用命令工具：

#在安装NFS服务器时，已包含常用的命令行工具，无需额外安装。

#显示已经mount到本机nfs目录的客户端机器。

`sudo showmount -e localhost`

#将配置文件中的目录全部重新export一次！无需重启服务。

`sudo exportfs -rv`

 

#查看NFS的运行状态

`sudo nfsstat`

 

#查看rpc执行信息，可以用于检测rpc运行情况

`sudo rpcinfo``

 

#查看网络端口，NFS默认是使用111端口。

`sudo netstat -tu -4`

  

## 二、客户端：

### 2.1安装客户端工具：

#在需要连接到NFS服务器的客户端机器上，

#需要执行以下命令，安装nfs-common软件包。

#apt会自动安装nfs-common、rpcbind等12个软件包

`sudo apt install nfs-common`

 

### 2.2查看NFS服务器上的共享目录

#显示指定的（192.168.3.167）NFS服务器上export出来的目录

`sudo showmount -e 192.168.3.167`

 

### 2.3创建本地挂载目录

`sudo mkdir -p /mnt/data`

`sudo mkdir -p /mnt/logs`

 

### 2.4挂载共享目录

#将NFS服务器192.168.3.167上的目录，挂载到本地的/mnt/目录下

`sudo mount -t nfs 192.168.3.167:/data /mnt/data`

`sudo mount -t nfs 192.168.3.167:/logs /mnt/logs`

  

#注：在没有安装nfs-common或者nfs-kernel-server软件包的机器上，

#直接执行showmount、exportfs、nfsstat、rpcinfo等命令时，

#系统会给出友好的提示，

#比如直接showmount会提示需要执行sudo apt install nfs-common命令，

#比如直接rpcinfo会提示需要执行sudo apt install rpcbind命令。

### 2.5卸载文件系统命令
`umount /mnt/data`
`umount /mnt/logs`