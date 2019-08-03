---
title: centos7 安装ansible
tags: [ansible]
---
# centos7 安装ansible

## 1. 每个节点安装 依赖工具
```
# 文档中脚本默认均以root用户执行
# 安装 epel 源并更新
yum install epel-release -y
yum update
# 安装python
yum install python -y
```

## 2. 在deploy 节点安装及准备ansible
```
yum install -y ansible
```
## 3.在deploy节点配置免密码登陆
```
ssh-keygen -t rsa -b 2048 回车 回车 回车
ssh-copy-id $IPs    #$IPs为所有节点地址包括自身，按照提示输入yes 和root密码
```
**批量添加密码的脚本**
```
#!/bin/bash
for i in $(seq 111 116);
do
ip="10.0.1."$i;
echo $ip
sshpass -p '123456' ssh-copy-id -o StrictHostKeyChecking=no  $ip
done
```

## 4. 验证ansible安装，正常能看到每个节点返回 SUCCESS
```
ansible all -m ping 
```
