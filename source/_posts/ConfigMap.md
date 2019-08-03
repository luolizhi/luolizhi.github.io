---
title: ConfigMap
date: 2018-03-22 17:19:12
tags: [k8s,configmap]
---
## ConfigMap概览
ConfigMap允许您将配置文件从容器镜像中解耦，从而增强容器应用的可移植性。

ConfigMap API资源保存配置数据的键值对，可以在pods中使用或者可以用于存储系统组件的配置数据。ConfigMap类似于Secrets,但是旨在更方便的使用不包含敏感信息的字符串。

> 注意：ConfigMap只引用属性文件，而不会替换它们。可以把ConfigMap联想成Linux中的/etc目录和它里面的内容。例如，假如您使用ConfigMap创建了Kubernetes Volume，ConfigMap中的每个数据项都代表该volume中的一个文件。  


ConfigMap的data项中包含了配置数据。如下所示，可以是很简单的——如使用 —from-literal 参数定义的每个属性；也可以很复杂——如使用—from-file参数定义的配置文件或者json对象。

## 创建Configmap的四种方法

- 通过直接在命令行中指定configmap参数创建，即`--from-literal`
- 通过指定文件创建，即将一个配置文件创建为一个ConfigMap`--from-file=<文件>`
```$xslt
> 配置文件app.properties
> 创建命令（可以有多个--from-file）：   
> ```kubectl create configmap test-config2 --from-file=./app.properties```  
```
- 通过指定目录创建，即将一个目录下的所有配置文件创建为一个ConfigMap，`--from-file=<目录>`  
 
- 通过yaml文件来创建，另一种是通过kubectl直接在命令行下创建。事先写好标准的configmap的yaml文件，然后kubectl create -f 创建

*************
----------------------
## Pod中使用ConfigMap的三种方法
- 第一种是通过环境变量的方式，直接传递给pod 
   > 使用configmap中指定的key  
   >> 使用valueFrom、configMapKeyRef、name、key指定要用的key:    
   ```
   apiVersion: v1
      kind: Pod
      metadata:
        name: dapi-test-pod
      spec:
        containers:
          - name: test-container
            image: k8s.gcr.io/busybox
            command: [ "/bin/sh", "-c", "env" ]
            env:
              - name: SPECIAL_LEVEL_KEY
                valueFrom:
                  configMapKeyRef:
                    name: special-config
                    key: special.how
              - name: LOG_LEVEL
                valueFrom:
                  configMapKeyRef:
                    name: env-config
                    key: log_level
        restartPolicy: Never
     ```
     
   > 使用configmap中所有的key
   >> 还可以通过envFrom、configMapRef、name使得configmap中的所有key/value对都自动变成环境变量：  
   
   ```
   apiVersion: v1
   kind: Pod
   metadata:
     name: dapi-test-pod
   spec:
     containers:
       - name: test-container
         image: k8s.gcr.io/busybox
         command: [ "/bin/sh", "-c", "env" ]
         envFrom:
         - configMapRef:
             name: special-config
     restartPolicy: Never
   ```
   
- 第二种是通过在pod的命令行下运行的方式(启动命令中)
在命令行下引用时，需要先设置为环境变量，之后可以通过$(VAR_NAME)设置容器启动命令的启动参数：

```
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/sh", "-c", "echo $(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never
```

- 第三种是作为volume的方式挂载到pod内
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-configmap
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx-configmap
    spec:
      containers:
      - name: nginx-configmap
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:     
        - name: config-volume4
          mountPath: /tmp/config4
      volumes:
      - name: config-volume4
        configMap:
          name: test-config4
```

## 限制
- 我们必须在 Pod 使用 ConfigMap 之前，创建好 ConfigMap（除非您把 ConfigMap 标志成”optional”）。如果您引用了一个不存在的 ConfigMap， 那这个Pod是无法启动的。就像引用了不存在的 Key 会导致 Pod 无法启动一样。
- 如果您使用envFrom来从 ConfigMap 定义环境变量，无效的 Key 会被忽略。Pod可以启动，但是无效的名字将会被记录在事件日志里(InvalidVariableNames). 日志消息会列出来每个被忽略的 Key ，比如：
```
kubectl get events
LASTSEEN FIRSTSEEN COUNT NAME          KIND  SUBOBJECT  TYPE      REASON                            SOURCE                MESSAGE
0s       0s        1     dapi-test-pod Pod              Warning   InvalidEnvironmentVariableNames   {kubelet, 127.0.0.1}  Keys [1badkey, 2alsobad] from the EnvFrom configMap default/myconfig were skipped since they are considered invalid environment variable names.
```

- ConfigMaps 存在于指定的 命名空间.则这个 ConfigMap 只能被同一个命名空间里的 Pod 所引用。
- Kubelet 不支持在API服务里找不到的Pod使用ConfigMap，这个包括了每个通过 Kubectl 或者间接通过复制控制器创建的 Pod， 不包括通过Kubelet 的 --manifest-url 标志, --config 标志, 或者 Kubelet 的 REST API。（注意：这些并不是常规创建 Pod 的方法）
## configmap的热更新研究
更新 ConfigMap 后:
+ 使用该 ConfigMap 挂载的 Env 不会同步更新
+ 使用该 ConfigMap 挂载的 Volume 中的数据需要一段时间（实测大概10秒）才能同步更新  
ENV 是在容器启动的时候注入的，启动之后 kubernetes 就不会再改变环境变量的值，且同一个 namespace 中的 pod 的环境变量是不断累加的，参考 Kubernetes中的服务发现与docker容器间的环境变量传递源码探究。为了更新容器中使用 ConfigMap 挂载的配置，可以通过滚动更新 pod 的方式来强制重新挂载 ConfigMap，也可以在更新了 ConfigMap 后，先将副本数设置为 0，然后再扩容。

ps 一个demo
先创建一个如下所示的配置文件。

```$xslt
apiVersion: v1
data:
  DASHBOARD.CONF.INI: |
    [mysqld]
    log-bin = mysql-bin
    [port]
    serviceport="80"
  IMAGE_VERSION: v2.0
  OTHERKEY: OTHERVALUE
  REPLICAS: "2"
kind: ConfigMap
metadata:
  name: tst-config
  namespace: default
```  

然后将对应的key设置成容器的环境变量。  

```$xslt
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
    - name: test-container
      image: busybox:latest
      command: [ "/bin/sh", "-c", "env" ]
      env:
        - name: REPLICAS
          valueFrom:
            configMapKeyRef:
              name: tst-config
              key: REPLICAS
        - name: OTHERKEY
          valueFrom:
            configMapKeyRef:
              name: tst-config
              key: OTHERKEY
        - name: IMAGE_VERSION
          valueFrom:
            configMapKeyRef:
              name: tst-config
              key: IMAGE_VERSION
  restartPolicy: Never
```  

当Pod结束后会输出
```$xslt
REPLICAS=2
IMAGE_VERSION=v2.0
OTHERKEY=OTHERVALUE
```