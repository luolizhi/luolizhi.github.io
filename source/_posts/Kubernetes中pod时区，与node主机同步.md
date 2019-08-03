---
title: Kubernetes中pod时区，与node主机同步
date: 2018-04-03 10:52:04
tags: [kubernetes,pod]
---

k8s集群中的pod时间与主机不同步，解决这个问题基本上可以有两种思路：
- 直接修改镜像的时间设置，好处是应用部署时无需做特殊设置，但是需要手动构建Docker镜像。
- 部署应用时，单独读取主机的“/etc/localtime”文件，即创建pod时同步时区，无需修改镜像，但是每个应用都要单独设置。

这里为了快速、简单的解决这个问题，先使用第二种方案，yaml文件中设置时区同步，只需要映射主机的“/etc/localtime”文件。

这里给出一个demo
```yaml
# test-jar-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: test-jar
  labels:
    app: test-jar
spec:
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  type: NodePort
  ports:
  - port: 8080
#    targetPort: 8080
  selector:
    app: test-jar
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: test-jar
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: test-jar
    spec:
      containers:
      - name: test-jar
        image: lukey123/kubernetes:test-jar
#        resources:
#          requests:
#            cpu: 100m
#            memory: 100Mi
#        env:
#        - name: GET_HOSTS_FROM
#          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: 8080
```
修改后的yaml文件为

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-jar
  labels:
    app: test-jar
spec:
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  type: NodePort
  ports:
  - port: 8080
#    targetPort: 8080
  selector:
    app: test-jar
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: test-jar
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: test-jar
    spec:
      containers:
      - name: test-jar
        image: lukey123/kubernetes:test-jar
        volumeMounts: #这里是增加的部分
        - name: host-time
          mountPath: /etc/localtime
#        resources:
#          requests:
#            cpu: 100m
#            memory: 100Mi
#        env:
#        - name: GET_HOSTS_FROM
#          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: 8080
      volumes: #这里是增加的部分
       - name: host-time
         hostPath:
           path: /etc/localtime
```

接着进入pod执行就可以看到时间已经同步了
```bash
$ kubectl exec -it test-jar-57d5474cbc-dv7xr  /bin/sh
# date
Tue Apr  3 10:40:15 CST 2018
```