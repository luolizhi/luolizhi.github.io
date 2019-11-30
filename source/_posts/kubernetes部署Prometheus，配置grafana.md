---
title: prometheus部署
date: 2018-12-1 18:29:38
tags: [k8s, prometheus, grafana]
---
# kubernetes部署Prometheus 注意事项
安装参考
https://blog.qikqiak.com/post/kubernetes-monitor-prometheus-grafana/

## 需要在grafana中增加Prometheus为datasource


## 配置报警监控先在alerting中配置channel，比如钉钉，email等（）grafana4.4.3集成了钉钉。然后在配置的dashboard的graph中增加规则，触发告警系统。
