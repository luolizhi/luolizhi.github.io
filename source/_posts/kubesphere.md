---
title: kubesphere
date: 2019-08-23 10:20:27
tags: [kubesphere,kubernetes]
---

## KubeSphere 安装(all-in-one)

KubeSphere 帮助企业在云、虚拟化及物理机等任何环境中快速构建、部署及运维容器架构，轻松实现服务治理、 DevOps 与 CI/CD 、应用管理、大数据、人工智能、IAM 以及监控日志等业务场景。

### 环境准备

[安装参考](https://kubesphere.io/docs/advanced-v2.0/zh-CN/installation/all-in-one)

- centos7.6 8核16G，100G系统盘

### 准备安装包

在线版（2.0.2）
`curl -L https://kubesphere.io/download/stable/advanced-2.0.2 > advanced-2.0.2.tar.gz && tar -zxf advanced-2.0.2.tar.gz && cd kubesphere-all-advanced-2.0.2/scripts`

### 安装 KubeSphere

1. 建议使用 root 用户安装，执行 install.sh 脚本：

`$ ./install.sh`
2. 输入数字 1 选择第一种即 all-in-one 模式开始安装：

```bash
################################################
         KubeSphere Installer Menu
################################################
*   1) All-in-one
*   2) Multi-node
*   3) Quit
################################################
https://kubesphere.io/               2018-07-08
################################################
Please input an option: 1
```

3. 测试 KubeSphere 单节点安装是否成功：

(1) 待安装脚本执行完后，当看到如下 "Successful" 界面，则说明 KubeSphere 安装成功。

```bash
successsful!
#####################################################
###              Welcome to KubeSphere!           ###
#####################################################

Console: http://192.168.0.8:30880
Account: admin
Password: P@88w0rd

NOTE：Please modify the default password after login.
#####################################################
```


## kubesphere 安装（在现有k8s集群上）

安装脚本地址：https://github.com/kubesphere/ks-installer

一直有helm报错未能成功安装。

## 安装过程的问题

- openldap 这个组件启动报错，因为 ks-account 组件又是依赖 openldap 这个组件的，所以同样启动报错，在安装过程中 openldap 出现了类似如下错误信息。

```bash
rm: cannot remove ‘/container/service/slapd/assets/config/bootstrap/ldif/readonly-user’: Directory not empty 
rm: cannot remove ‘/container/service/slapd/assets/config/bootstrap/schema/mmc’: Directory not empty 
rm: cannot remove ‘/container/service/slapd/assets/config/replication’: Directory not empty 
rm: cannot remove ‘/container/service/slapd/assets/config/tls’: Directory not empty *** /container/run/startup/slapd 

failed with status 1
```

解决方法： 修改kubesphere/roles/prepare/base/templates/ks-account-init.yaml.j2文件，在 openldap 这个 Deployment 下面容器中添加启动参数--copy-service

```bash
#vim kubesphere/roles/prepare/base/templates/ks-account-init.yaml.j2 +122

    spec:
      containers:
      - env:
        - name: LDAP_ORGANISATION
          value: kubesphere
        - name: LDAP_DOMAIN
          value: kubesphere.io
        - name: LDAP_ADMIN_PASSWORD
          value: admin
        image: {{ openldap_repo }}:{{ openldap_tag }}
        imagePullPolicy: IfNotPresent
        args:    # 添加该启动参数
        - --copy-service
        name: openldap
```

- sonarqube安装报错

解决方法：不安装sonarqube，修改conf/vars.yml文件，将true改为false

```bash
#vim conf/vars.yml +210

## sonarqube
sonarqube_enable: false #改为false
```
