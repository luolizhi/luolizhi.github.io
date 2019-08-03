---
title: fluentd
date: 2018-03-23 13:36:46
tags: [k8s,fluentd,kafka,mongo]
---
# kubernetes 安装fluentd收集日志原理
通过在每台node上部署一个以DaemonSet方式运行的fluentd来收集每台node上的日志。
Fluentd将docker日志目录/var/lib/docker/containers和/var/log目录挂载到Pod中，然后Pod会在node节点的/var/log/pods目录中创建新的目录，可以区别不同的容器日志输出，该目录下有一个日志文件链接到/var/lib/docker/contianers目录下的容器日志输出。



## k8s集群部署步骤--kafka
1. 使用~/k8s/fluentd/fluentd-kubernetes-daemonset/docker-image/v0.12/alpine-kafka文件夹下面的dockerfile，构建镜像。
2. 使用~/k8s/fluentd/fluentd-kubernetes-daemonset/my-yaml的yaml文件部署
```$xslt
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  template:
    metadata:
      labels:
        k8s-app: fluentd-logging
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: k8s/fluent/fluentd-kubernetes-daemonset:kafka
        env:
          - name:  FLUENT_KAFKA_BROKERS
            value: "10.0.0.24:9092"
          - name: FLUENT_KAFKA_SCHEME
            value: "http"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      nodeSelector:
        kubernetes.io/hostname: "10.0.1.65"
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```
修改环境变量FLUENT_KAFKA_BROKERS的值，镜像中会调用这个值。
镜像中flentd.congf文件内容为：
```$xslt

@include kubernetes.conf


<match **>
  @type kafka_buffered

  # list of seed brokers
  brokers "#{ENV['FLUENT_KAFKA_BROKERS']}"

  # buffer settings
  buffer_type file
  buffer_path /var/log/td-agent/buffer/td
  flush_interval 3s

  # topic settings
  default_topic test

  # data type settings
  output_data_type json
  compression_codec gzip

  # producer settings
  max_send_retries 1
  required_acks -1
</match>
```
default_topic的值也是可以作用环境变量。
具体可以参见下面设置环境变量，然后通过yaml文件注入
```$xslt
@include kubernetes.conf

<match **>
  type kafka_buffered

  brokers "#{ENV['FLUENT_KAFKA_BROKERS']}"

  default_topic "#{ENV['FLUENT_KAFKA_DEFAULT_TOPIC'] || nil}"
  default_partition_key "#{ENV['FLUENT_KAFKA_DEFAULT_PARTITION_KEY'] || nil}"
  default_message_key "#{ENV['FLUENT_KAFKA_DEFAULT_MESSAGE_KEY'] || nil}"
  output_data_type "#{ENV['FLUENT_KAFKA_OUTPUT_DATA_TYPE'] || 'json'}"
  output_include_tag "#{ENV['FLUENT_KAFKA_OUTPUT_INCLUDE_TAG'] || false}"
  output_include_time "#{ENV['FLUENT_KAFKA_OUTPUT_INCLUDE_TIME'] || false}"
  exclude_topic_key "#{ENV['FLUENT_KAFKA_EXCLUDE_TOPIC_KEY'] || false}"
  exclude_partition_key "#{ENV['FLUENT_KAFKA_EXCLUDE_PARTITION_KEY'] || false}"
  get_kafka_client_log "#{ENV['FLUENT_KAFKA_GET_KAFKA_CLIENT_LOG'] || false}"

  # ruby-kafka producer options
  max_send_retries "#{ENV['FLUENT_KAFKA_MAX_SEND_RETRIES'] || 1}"
  required_acks "#{ENV['FLUENT_KAFKA_REQUIRED_ACKS'] || -1}"
  ack_timeout "#{ENV['FLUENT_KAFKA_ACK_TIMEOUT'] || nil}"
  compression_codec "#{ENV['FLUENT_KAFKA_COMPRESSION_CODEC'] || nil}"
  max_send_limit_bytes "#{ENV['FLUENT_KAFKA_MAX_SEND_LIMIT_BYTES'] || nil}"
  discard_kafka_delivery_failed "#{ENV['FLUENT_KAFKA_DISCARD_KAFKA_DELIVERY_FAILED'] || false}"
</match>

```
后续可以把这些都作为环境变量从新构建镜像。(注意：没有注入默认值为nil的变量需要注释掉)(巨坑)

## k8s集群部署步骤--mongo
1. 使用https://github.com/luolizhi/k8s_dockerfile/tree/master/fluentd-k8s-daemonset/v0.12/alpine-mongo文件下的Dockerfile构建
fluentd-mongo-image镜像

2. 修改上面目录下的镜像名称，修改环境变量mongo的参数值。