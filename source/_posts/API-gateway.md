---
title: API-gateway
date: 2019-08-27 09:25:34
tags: [gateway, 微服务]
---

## 开源API网关比较

| 开源网关             | 简介                                                         |
| -------------------- | ------------------------------------------------------------ |
| zuul                 | Netflix 开源，基于 JVM 路由和服务端的负载均衡器。（已经停止维护） |
| kong                 | 基于 OpenResty（Nginx + Lua 模块）编写的高可用、易扩展的，由 Mashape 公司开源的 API Gateway 项目 。 |
| spring cloud gateway | Spring Cloud 团队的一个全新项目，基于 Spring 5.0、SpringBoot2.0、Project Reactor 等技术开发的网关， 目标是替代 Netflix Zuul 。 |
| Traefik              | 一个现代 HTTP 反向代理和负载均衡器，可以轻松部署微服务，Traeffik 可以与您现有的组件（Docker、Swarm，Kubernetes，Marathon，Consul，Etcd，…）集成，并自动动态配置。 |



从开源社区活跃度来看，无疑是Kong和Traefik较好；
从成熟度来看，较好的是Kong、Traefik；
从性能角度来看，Kong要比其他几个领先一些；
从架构优势的扩展性来看，Kong有丰富的插件，Ambassador也有插件但不多，而Zuul是完全需要自研，但Zuul由于与Spring Cloud深度集成，使用度也很高。

## API 网关

[选型参考,原理讲解](https://zhaohuabing.com/post/2019-03-29-how-to-choose-ingress-for-service-mesh/)

API 网关出现的原因是微服务架构的出现，不同的微服务一般会有不同的网络地址，而外部客户端可能需要调用多个服务的接口才能完成一个业务需求，如果让客户端直接与各个微服务通信，会有以下的问题：

> - 客户端会多次请求不同的微服务，增加了客户端的复杂性。
> - 存在跨域请求，在一定场景下处理相对复杂。
> - 认证复杂，每个服务都需要独立认证。
> - 难以重构，随着项目的迭代，可能需要重新划分微服务。例如，可能将多个服务合并成一个或者将一个服务拆分成多个。如果客户端直接与微服务通信，那么重构将会很难实施。
> - 某些微服务可能使用了防火墙 / 浏览器不友好的协议，直接访问会有一定的困难。
