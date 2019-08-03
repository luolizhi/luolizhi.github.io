---
title: kubernetes源码结构
date: 2018-04-11 14:24:00
tags: [kubernetes,源码]
---


>kubernetes源码地址：https://github.com/kubernetes/kubernetes

## 整体结构
kubernetes源码主要分为包括pkg、cmd、plugin、test四个目录。其中各个包的主要功能如下：

1.pkg是kubernetes的主体代码，里面实现了kubernetes的主体逻辑。

2.cmd是kubernetes的所有后台进程的代码，主要是各个子模块的启动代码，具体的实现逻辑在pkg下。

3.plugin主要是kube-scheduler和一些插件

## 主要包功能介绍
以下简要介绍一下各个子包的功能

### pkg
|    包名   | 用途 |
| ---------- | --- |
|api | kubernetes api主要包括最新版本的Rest API接口的类，并提供数据格式验证转换工具类，对应版本号文件夹下的文件描述了特定的版本如何序列化存储和网络 |  
|client | Kubernetes 中公用的客户端部分，实现对对象的具体操作增删该查操作  | 
|cloudprovider |   kubernetes 提供对aws、azure、gce、cloudstack、mesos等云供应商提供了接口支持，目前包括负载均衡、实例、zone信息、路由信息等   |
|controller |  kubernetes controller主要包括各个controller的实现逻辑，为各类资源如replication、endpoint、node等的增删改等逻辑提供派发和执行   |
|credentialprovider | kubernetes credentialprovider 为docker 镜像仓库贡献者提供权限认证 |
|generated |  kubernetes generated包是所有生成的文件的目标文件，一般这里面的文件日常是不进行改动的   | 
|kubectl  | kuernetes kubectl模块是kubernetes的命令行工具，提供apiserver的各个接口的命令行操作，包括各类资源的增删改查、扩容等一系列命令工具  |
|kubelet | kuernetes kubelet模块是kubernetes的核心模块，该模块负责node层的pod管理，完成pod及容器的创建，执行pod的删除同步等操作等等    |
|master | kubernetes master负责集群中master节点的运行管理、api安装、各个组件的运行端口分配、NodeRegistry、PodRegistry等的创建工作    |
|runtime | kubernetes runtime实现不同版本api之间的适配，实现不同api版本之间数据结构的转换|


### cmd 
包括kubernetes所以后台进程的代码包括apiserver、controller manager、proxy、kubelet等进程

### plugin 
主要包括调度模块的代码实现，用于执行具体的Scheduler的调度工作，认证等。
