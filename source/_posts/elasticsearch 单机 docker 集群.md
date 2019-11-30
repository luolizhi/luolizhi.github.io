---
title: elasticsearch 单机 docker 集群
date: 2019-08-15 09:19:04
tags: [docker, elasticsearch]
---

## 单机docker启动 elasticsearch 集群

> 安装版本 elasticsearch 6.7 [参考网址](https://www.elastic.co/guide/en/elasticsearch/reference/6.7/docker.html), kibana 6.7 [参考网址](https://www.elastic.co/guide/en/kibana/6.7/docker.html)

> 注意镜像名称是elasticsearch-oss:6.7.0，这个-oss表示不包括X-Pack的ES镜像，这也是在6.0+版本后划分的，剩下两种类型是basic(默认)和platinum，具体官方说明可以看下图。

### 开发环境

`docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:6.7.2`

### 生产环境

The vm.max_map_count setting should be set permanently in /etc/sysctl.conf:

```bash
$ grep vm.max_map_count /etc/sysctl.conf
vm.max_map_count=262144
#为空需要修改
echo "vm.max_map_count=262144" > /etc/sysctl.conf
sysctl -p
```

- 启动
`docker-compose up`

- 停止
`docker-compose down -v`

```yaml
#docker-compose.yaml
version: '2.2'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.7.2 #可以换成私有镜像
    container_name: elasticsearch
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - esnet
  elasticsearch2:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.7.2
    container_name: elasticsearch2
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "discovery.zen.ping.unicast.hosts=elasticsearch"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata2:/usr/share/elasticsearch/data
    networks:
      - esnet

volumes:
  esdata1:
    driver: local
  esdata2:
    driver: local

networks:
  esnet:
```

### 测试集群

```bash
curl http://127.0.0.1:9200/_cat/health
1472225929 15:38:49 docker-cluster green 2 2 4 2 0 0 0 0 - 100.0%
```

## 插件支持

### ik analysis

IK是国内用得比较多的中文分词器，与ES安装集成也比较简单，首先进入dockerdocker exec -it elasticsearch bash，然后用命令./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.3.2/elasticsearch-analysis-ik-6.3.2.zip安装即可(需对应es版本)，安装完使用docker restart elasticsearch重启服务即可。IK支持两种分词方式，ik_smart和ik_max_word，前者分词粒度没有后者细，可以针对实际情况进行选择。

### head plugin

elasticsearch-head插件也是测试的时候用得比较多的插件，以前用ES2的时候是借助plugin脚本安装的，但这种方式在ES5.0之后被废弃了，然后作者也推荐了好几种方式，可以借助npm运行该服务，或者用docker运行服务，不过为了简单起见我最后选的是[Chrome extension](https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm/)这种方式。

## kibana 安装

- 启动
`docker-compose up`

- 停止
`docker-compose down -v`

```yaml
#docker-compose.yaml
version: '2'
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:6.7.2  #修改为自定义镜像
    environment:
      SERVER_NAME: kibana.example.org   #kibana server.name的值
      ELASTICSEARCH_HOSTS: http://elasticsearch.example.org  #修改为es集群的地址
```

## 单个docker-compose.yaml

```yaml
version: '2.2'
services:
  elasticsearch:
    image: harbor.cty.com/library/elasticsearch-oss-ik-config:6.7.0
    container_name: elasticsearch1
    environment:
      - cluster.name=elasticsearch
      - node.name=node1
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
      - 9300:9300
    networks:
      - esnet
  elasticsearch2:
    image: harbor.cty.com/library/elasticsearch-oss-ik-config:6.7.0
    container_name: elasticsearch2
    environment:
      - cluster.name=elasticsearch
      - node.name=node2
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "discovery.zen.ping.unicast.hosts=elasticsearch"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata2:/usr/share/elasticsearch/data
    networks:
      - esnet
  kibana:
    image: harbor.cty.com/library/kibana-oss:6.7.0
    environment:
      - "SERVER_NAME=kibana"
      - "ELASTICSEARCH_HOSTS=http://192.168.1.150:9200"  #ip地址不能换
    ports:
      - "5601:5601"  
    depends_on:
      - elasticsearch
      - elasticsearch2
volumes:     #路径默认在/var/lib/docker/volumes/
  esdata1:
    driver: local
  esdata2:
    driver: local

networks:
  esnet:
```

