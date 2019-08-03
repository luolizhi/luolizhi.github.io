---
title: Kubernetes ZooKeeper K8SZK
date: 2018-03-26 09:05:24
tags: [kubernetes,zookeeper]
---
By default, this user is zookeeper. 
The ZooKeeper package is installed into the /opt/zookeeper directory, 
all configuration is sym linked into the /usr/etc/zookeeper/, 
and all executables are sym linked into /usr/bin. 
The ZooKeeper data directories are contained in /var/lib/zookeeper. 
This is identical to the RPM distribution that users should be familiar with.


## Headless Service

```$xslt
apiVersion: v1
kind: Service
metadata:
  name: zk-svc
  labels:
    app: zk-svc
spec:
  ports:
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  clusterIP: None
  selector:
    app: zk-svc
```

## Stateful Set

```$xslt
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: zk
spec:
  serviceName: zk-svc
  replicas: 3
```

## Container Configuration

```$xslt
containers:
      - name: k8szk
        imagePullPolicy: Always
        image: gcr.io/google_samples/k8szk:v3
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        env:
        - name : ZK_ENSEMBLE
          value: "zk-0;zk-1;zk-2"
        - name: ZK_CLIENT_PORT
          value: "2181"
        - name: ZK_SERVER_PORT
          value: "2888"
        - name: ZK_ELECTION_PORT
          value: "3888"
```