---
title: traefik v2.1
date: 2019-12-17 20:11:20
tags: [kubernetes, traefik]
---

# traefik v2.1

我们都知道，你们都知道：Traefik 2.0 包含了许多新功能：TCP，中间件，规则语法，YAML 支持，CRD，WebUI，canary，mirroring, provider namespaces，新文档以及许多其他不起眼的更改将帮助我们将喜爱的产品推向更高的高度。

<!-- 

All this was accompanied by tools to help the community seamlessly make the transition: We developed a [migration tool](https://github.com/containous/traefik-migration-tool),  launched a [community forum](https://community.containo.us/) to foster good communication and support, wrote new tutorials to help people have a [fresh start with Traefik](https://containo.us/blog/traefik-2-0-docker-101-fc2893944b9d/) (including [details about new TLS options](https://containo.us/blog/traefik-2-tls-101-23b4fbee81f1/)), and of course we added a [migration guide in our documentation](https://docs.traefik.io/migration/v1-to-v2/). 

--> 

所有这些都伴随着帮助社区无缝过渡的工具：我们开发了[迁移工具](https://github.com/containous/traefik-migration-tool)，发起了一个[社区论坛](https://community.containo.us/)以促进良好的沟通和支持，编写了新教程以帮助人们重新开始使用 [Traefik](https://containo.us/blog/traefik-2-0-docker-101-fc2893944b9d/)（包括有关新 TLS 的详细信息），当然我们在文档中添加了[迁移指南](https://docs.traefik.io/migration/v1-to-v2/)。

感谢我们从社区获得的（大量）反馈，我们知道我们可以做得更好，并且为我们提供了正确方向的一些指导。

但是在谈论我们学到的东西以及如何利用这些知识之前，让我们先谈谈 2.1 中引入的更改。

## Consul Catalog Is Back!

 对于 Consul Catalog 迷来说，好消息是 Traefik 2.1 将其重新列入了受支持的提供商列表！ （但请保留，因为我确定其他人也会效仿。）

## Improving the CRD

 ### Stickiness

`stickiness `是负载均衡器在将客户端发送给客户端后继续使用相同目标的功能。 我们的 CRD 用户现在可以使用此选项！

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myName
  namespace: myNamespace
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: Host(`some-domain`)
    services:
    - kind: Service
      name: myService
      namespace: myNamespace
      port: 80
      sticky:
        cookie: {} # Once a pod is selected for a client, it will stay the same for future calls
```

## Service Load Balancing & Mirroring

在 2.0 中引入的服务负载平衡和镜像以前只能使用 `file provider` 进行配置。 通过 2.1 和 `TraefikService` 对象的引入，我们利用 Traefik 的 CRD 在 Kubernetes 中启用这种配置，这是第一个带有镜像的示例：

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-route-to-mirroring
  namespace: default

spec:
  entryPoints:
    - web
  routes:
  - match: Host(`some-domain`) && PathPrefix(`/some/path`)
    kind: Rule
    services:
    - name: mirroring-example #targets the mirroring-example service
      namespace: default
      kind: TraefikService # we want to target the TraefikService we've declared (and not a K8S service named mirroring-example)
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: mirroring-example
  namespace: default
spec:
  mirroring:
    name: v1 #sends 100% of the requests to the K8S service "v1" ...
    mirrors:
      - name: v2 # ... and sends a copy of 10% of the requests to v2
        percent: 10
        port: 80
```

对于第二个示例，让我们看看如何使用服务负载平衡进行金丝雀部署：

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-route-to-canary
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`some-domain`) && PathPrefix(`/some/path`)
    kind: Rule
    services:
    - name: mirror1
      namespace: default
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: canary-example
  namespace: default

spec:
  weighted:
    services:
      - name: v1
        weight: 80
        port: 80
      - name: v2
        weight: 20
        port: 80
```

现在，我们可以随意更改每个服务（v1 和 v2）的权重！

## Mixing Regular (Kubernetes) Services with TraefikServices

<!--

When you define a target (with the `name` attribute) for your `IngressRoute`, by default, it targets a regular `Service`. If you want to target the new `TraefikService` objects, you just specify the `kind` attribute. What's great with this system is that you can chain and combine them at will, creating intricate patterns depending on your needs. 

-->

默认情况下，当您为 `IngressRoute` 定义目标（使用 `name` 属性）时，它以常规 `Service` 为目标。 如果要定位新的 `TraefikService` 对象，则只需指定 `kind` 属性。 该系统的优点是您可以随意链接和组合它们，并根据需要创建复杂的模式。

下面是同时利用服务和 `TraefikServices` 并同时使用镜像和服务负载平衡的示例！

![1576463361091](C:\Users\lukey\AppData\Local\Temp\1576463361091.png)



```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: route-to-mirroring
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`some-domain`) && PathPrefix(`/some/path`)
    kind: Rule
    services:
    - name: mirroring-example
      namespace: default
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: mirroring-example
  namespace: default
spec:
  mirroring:
    name: canary-example
    kind: TraefikService
    mirrors:
      - name: service-mirror
        percent: 20
        port: 80
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: canary-example
  namespace: default
spec:
  weighted:
    services:
      - name: v1
        port: 80
        weight: 80
      - name: v2
        weight: 20
        port: 80
```

## Note on Updating the CRD for 2.1

在将 `traefik` 从 v2.0 升级到 v2.1时，需要应用新的 `CRD` 并增强现有的 `ClusterRole` 定义。 您将在以下[指南](https://docs.traefik.io/migration/v2/)中找到方法。

### v2.0 to v2.1

在 v2.1 中，添加了一个名为 `TraefikService` 的新 `CRD`。 将 `traefik` 更新到 v2.1 时，需要先增加 CRD 并增强现有的 ClusterRole 定义的权限，以允许 Traefik 使用该 CRD。

要添加该 CRD 并增加权限，需要将以下定义应用于群集。

`TraefikService`  定义



```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: traefikservices.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TraefikService
    plural: traefikservices
    singular: traefikservice
  scope: Namespaced
```

`ClusterRole` , 63-70行增加了对 `traefikservice` 的支持。

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller

rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
    resources:
      - middlewares
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - ingressroutes
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - ingressroutetcps
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - tlsoptions
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - traefikservices
    verbs:
      - get
      - list
      - watch
```



升级步骤：

```bash
kubectl apply -f  traefik-service-crd.yaml
kubectl apply -f  traefik-ClusterRole.yaml
kubectl set image deployment/traefik traefik=traefik:v2.1 -n traefik-system
```



## More Control On Internal Routing

在 2.0 中，我们进行了更改，以确保人们能够正确保护 Traefik 提供的一些关键服务，例如 API 和仪表板（您可以在 Traefik＆Docker 101 [文章](https://containo.us/blog/traefik-2-0-docker-101-fc2893944b9d/)中看到一个示例）。 

在进一步配置内部服务的能力同时始终为用户提供更多控制权的同时，2.1 仪表板现在可以显示所涉及的内部路由器和服务。

## Migrating to 2.X Made Easy

有了如此多的新选项来自定义 Traefik 以满足您的各种需求，我们了解到迁移到 2.x 时可能会有些失落，尤其是因为 Traefik 是您运行而忘记的那种软件（因为它可以昼夜工作，无需用户的任何其他干预）。

> 我们一直在努力工作，以使此迁移过程只需几分钟。

因此，如果您正在考虑迁移但还没有完成任务，我们希望为您指明正确的方向：

- 本[指南](https://containo.us/blog/traefik-2-0-docker-101-fc2893944b9d/)可帮助您真正了解 Traefik 2 如何在 Docker 设置上工作，并向您显示 5 分钟足以使您充分了解如何使用它。
- 如果您正在寻找有关如何配置 HTTPS / TLS 的信息，我们将为您提供这个[指南](https://containo.us/blog/traefik-2-tls-101-23b4fbee81f1/)！
- 如果您不想浪费时间在 Kubernetes 中转换 Ingress 对象（谁愿意？），我们开发了一个[迁移工具](https://github.com/containous/traefik-migration-tool)，可以为您处理它。
- 哦，[迁移工具](https://github.com/containous/traefik-migration-tool)还可以转换您的 acme.json 证书文件。
- 并且始终可以随时在我们的社区论坛中进行对话，我们会阅读所有内容，并在可能的情况下尽力提供答案。

## Supporting the 1.X Branch for Two Years!

我们的社区很重要，我们不希望用户急于迁移到版本 2。我们希望看到人们逐渐爱上 Traefik 必须提供和迁移的新工具。 因此，我们决定将对 1.X 版本的支持扩展到 2021 年底。

没错：您需要先实现两年的飞跃！ （而且我们相信，在此之前，您会发现迁移到 2.X 的好处。）



原文链接：<https://containo.us/blog/traefik-2-1-in-the-wild/> 