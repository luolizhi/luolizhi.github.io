---
title: helm 安装 logstash 同步mysql数据到elasticsearch
date: 2019-08-25 13:25:34
tags: [logstash, kubernetes]
---

## 安装

helm安装到kubernetes集群
参考地址：https://github.com/helm/charts/tree/master/stable/logstash

## 配置文件详解

### logstash-input-jdbc

使用 logstash-input-jdbc 插件读取 mysql 的数据，这个插件的工作原理比较简单，就是定时执行一个 sql，然后将 sql 执行的结果写入到流中，增量获取的方式没有通过 binlog 方式同步，而是用一个递增字段作为条件去查询，每次都记录当前查询的位置，由于递增的特性，只需要查询比当前大的记录即可获取这段时间内的全部增量，一般的递增字段有两种，AUTO_INCREMENT 的主键 id 和 ON UPDATE CURRENT_TIMESTAMP 的 update_time 字段，id 字段只适用于那种只有插入没有更新的表，update_time 更加通用一些，建议在 mysql 表设计的时候都增加一个 update_time 字段

```yaml
input {
  jdbc {
    jdbc_driver_library => "../mysql-connector-java-5.1.38.jar"
    jdbc_driver_class => "com.mysql.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://<mysql_host>:3306/woa"
    jdbc_user => "<username>"
    jdbc_password => "<password>"
    schedule => "* * * * *"
    statement => "SELECT * FROM table WHERE update_time >= :sql_last_value"
    use_column_value => true
    tracking_column_type => "timestamp"
    tracking_column => "update_time"
    last_run_metadata_path => "syncpoint_table"
  }
}
```

- jdbc_driver_library: jdbc mysql 驱动的路径
- jdbc_driver_class: 驱动类的名字，mysql 填 com.mysql.jdbc.Driver 就好了
- jdbc_connection_string: mysql 地址
- jdbc_user: mysql 用户
- jdbc_password: mysql 密码
- schedule: 执行 sql 时机，类似 crontab 的调度
- statement: 要执行的 sql，以 ":" 开头是定义的变量，可以通过 parameters 来设置变量，这里的 sql_last_value 是内置的变量，表示上一次 sql 执行中 update_time 的值，这里 - update_time 条件是 >= 因为时间有可能相等，没有等号可能会漏掉一些增量
- use_column_value: 使用递增列的值
- tracking_column_type: 递增字段的类型，numeric 表示数值类型, timestamp 表示时间戳类型
- tracking_column: 递增字段的名称，这里使用 update_time 这一列，这列的类型是 timestamp
- last_run_metadata_path: 同步点文件，这个文件记录了上次的同步点，重启时会读取这个文件，这个文件可以手动修改

### logstash-output-elasticsearch

```yaml
output {
  elasticsearch {
    hosts => ["127.0.0.1"]
    user => "<user>"
    password => "<password>"
    index => "table"
    document_id => "%{id}"
  }
}
```

- hosts: es 集群地址
- user: es 用户名
- password: es 密码
- index: 导入到 es 中的 index 名，这里我直接设置成了 mysql 表的名字
- document_id: 导入到 es 中的文档 id，这个需要设置成主键，否则同一条记录更新后在 es 中会出现两条记录，%{id} 表示引用 mysql 表中 id 字段的值

## 定制jdbc镜像

```Dockerfile
FROM docker.elastic.co/logstash/logstash-oss:7.1.1
RUN logstash-plugin install logstash-input-jdbc
ADD mysql-connector-java-5.1.38.jar /usr/share/logstash/mysql-connector-java-5.1.38.jar
```

镜像docker.elastic.co/logstash/logstash-oss:7.1.1的工作目录为/usr/share/logstash/

所以其他配置可以以此为当前目录配置相对路径。

## 自定义value值

```yaml
service:
  type: NodePort

## Custom files that can be referenced by plugins.
## Each YAML heredoc will become located in the logstash home directory under
## the files subdirectory.
## 默认会在/usr/share/logstash/files/目录下生成单独的文件，供后面output自定义template使用,可以定义多个template文件。文件格式请严格参考another-template.json,特别是properties字段。
files:
  # logstash-template.json: |-
  #   {
  #     "order": 0,
  #     "version": 1,
  #     "index_patterns": [
  #       "logstash-*"
  #     ],
  #     "settings": {
  #       "index": {
  #         "refresh_interval": "5s"
  #       }
  #     },
  #     "mappings": {
  #       "doc": {
  #         "_meta": {
  #           "version": "1.0.0"
  #         },
  #         "enabled": false
  #       }
  #     },
  #     "aliases": {}
  #   }
  #  another-template.json: |-
  #   {
  #     "order": 0,
  #     "version": 1,
  #     "index_patterns": [
  #       "test*"
  #     ],
  #     "settings": {
  #       "index": {
  #         "refresh_interval": "5s"
  #       }
  #     },
  #     "mappings": {
  #       "_doc": {
  #         "_source": {
  #           "enabled": false
  #         },
  #         "properties": {
  #           "host_name": {
  #             "type": "keyword"
  #           },
  #           "created_at": {
  #             "type": "date",
  #             "format": "EEE MMM dd HH:mm:ss Z yyyy"
  #           }
  #         }
  #       }
  #     },
  #     "aliases": {}
  #   }  


## NOTE: To achieve multiple pipelines with this chart, current best practice
## is to maintain one pipeline per chart release. In this way configuration is
## simplified and pipelines are more isolated from one another.

inputs:
  main: |-
    input {
      jdbc {
        jdbc_connection_string => "jdbc:mysql://<host>:3306/<database>"
        jdbc_user => "<user_name>"
        jdbc_password => "<password>"
        jdbc_driver_library => "/usr/share/logstash/mysql-connector-java-5.1.38.jar" #全路径
        # jdbc_driver_library => "./mysql-connector-java-5.1.38.jar" # 也可以使用相对路径，默认路径为/usr/share/logstash/
        jdbc_driver_class => "com.mysql.jdbc.Driver"
        jdbc_paging_enabled => "true"
        schedule => "* * * * *"
        statement => "SELECT  * from user"
        type => "helloworld"
      }
      # udp {
      #   port => 1514
      #   type => syslog
      # }
      # tcp {
      #   port => 1514
      #   type => syslog
      # }
      beats {
        port => 5044
      }
      # http {
      #   port => 8080
      # }
      # kafka {
      #   ## ref: https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
      #   bootstrap_servers => "kafka-input:9092"
      #   codec => json { charset => "UTF-8" }
      #   consumer_threads => 1
      #   topics => ["source"]
      #   type => "example"
      # }
    }
filters:
  # main: |-
  #   filter {
  #   }

outputs:
  main: |-
    output {
      # stdout { codec => rubydebug }
      elasticsearch {
        hosts => ["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]
        manage_template => false
        index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
      }
      # kafka {
      #   ## ref: https://www.elastic.co/guide/en/logstash/current/plugins-outputs-kafka.html
      #   bootstrap_servers => "kafka-output:9092"
      #   codec => json { charset => "UTF-8" }
      #   compression_type => "lz4"
      #   topic_id => "destination"
      # }
      elasticsearch {
        hosts => ["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]
        # index名
        index => "hello"
        # 需要关联的数据库中有有一个id字段，对应索引的id号
        manage_template => true
        template =>"/usr/share/logstash/files/logstash-template.json"  #也可以使用相对路径"./files/logstash-template.json"
        template_overwrite =>true
        template_name => "helloword"
      }
    }
```
