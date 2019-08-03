---
title: kubernetes 常用命令
date: 2018-03-22 17:14:33
tags: [kubernetes]
---

## kubectl get pods -o wide

## 使用nslookup查看这些Pod的DNS
```$ kubectl run -i --tty --image busybox dns-test --restart=Never --rm /bin/sh
/ # nslookup web-0.nginx
Server:    10.0.0.10
Address 1: 10.0.0.10 kube-dns.kube-system.svc.cluster.local```

## 用kubectl run来创建一个CronJob：
```bash
kubectl run hello --schedule="*/1 * * * *" --restart=OnFailure --image=busybox -- /bin/sh -c "date; echo Hello from the Kubernetes cluster"
```

## 三种容器类型
+ 静态容器组：bare pod, IP和Hostname恒定；

+ 有状态伸缩组： Deployment, IP和Hostname恒定，支持IP池；

+ 无状态伸缩组： StatefulSets, 支持IP池，IP随机分配，灵活度更高。

*斜体*
**黑体**
## k8s容器命名规则
![](../../png/kubernetes-container-naming-rule.jpg)