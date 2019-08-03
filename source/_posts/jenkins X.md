---
title: Jenkins
date: 2018-03-27 17:19:12
tags: [k8s,jenkins]
---

 Jenkins X 是一个高度集成化的CI/CD平台，基于Jenkins和Kubernetes实现，旨在解决微服务体系架构下的云原生应用的持续交付的问题，简化整个云原生应用的开发、运行和部署过程。
 # Jenkins X 部分新特性

## 1.自动化一切：自动化CI/CD流水线

选择项目类型自动生成Jenkinsfile定义流水线

自动生成Dockerfile并打包容器镜像

自动创建Helm Chart并运行在Kubernetes集群

自动关联代码库和流水线，作为代码变更自动触发（基于Webhook实现）

自动版本号自动归档

## 2. Review代码一键部署应用：基于GitOps的环境部署
所有的环境，应用列表，版本，配置信息统一放在代码库中进行版本控制

通过Pull Request实现研发和运维的协同，完成应用部署升级（Promotion）

可自动部署和手动部署，在必要的时候增加手工Review

当然这些都封装在jx命令中实现

## 3. 自动生成预览环境和信息同步反馈

预览环境用于代码Review环节中临时创建

同Pull Request工作流程集成并实现信息同步和有效通知

验证完毕后自动清理

提交和应用状态自动同步到Github注释

自动生成release notes信息供验证

# Jenkins X安装---以linux为例
- 在本地安装jx命令行工具(都要安装)
```
$curl -L https://github.com/jenkins-x/jx/releases/download/v1.2.6/jx-linux-amd64.tar.gz | tar xzv 
$sudo mv jx /usr/local/bin
```
- 使用jx创建一个k8s集群，并自动安装Jenkins X
> http://jenkins-x.io/getting-started/create-cluster/
- 在已经存在的k8s集群上安装Jenkns x
> http://jenkins-x.io/getting-started/install-on-cluster/
> jx install
