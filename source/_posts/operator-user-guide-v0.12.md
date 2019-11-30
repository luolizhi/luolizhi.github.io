---
title: Operator SDK User Guide（翻译）
date: 2019-11-30 10:29:38
tags: [kubernetes, operator]
---


# Operator SDK 用户指南 v0.12（翻译）

<!-- 
This guide walks through an example of building a simple memcached-operator using the operator-sdk CLI tool and controller-runtime library API. To learn how to use Ansible or Helm to create an operator, see the [Ansible Operator User Guide][ansible_user_guide] or the [Helm Operator User Guide][helm_user_guide]. The rest of this document will show how to program an operator in Go.
 -->
本指南介绍了使用 operator-sdk CLI 工具和控制器运行时库的 API 构建简单的 memcached-operator 的示例。 要了解如何使用 Ansible 或 Helm 创建 operator，查看 [Ansible Operator 用户指南][ansible_user_guide] 或者 [Helm Operator 用户指南][helm_user_guide]。本文档的其余部分将展示如何在 Go 中编写 operator。

[原文链接](https://github.com/operator-framework/operator-sdk/blob/v0.12.x/doc/user-guide.md)

<!-- 
## Prerequisites

- [git][git_tool]
- [go][go_tool] version v1.12+.
- [mercurial][mercurial_tool] version 3.9+
- [docker][docker_tool] version 17.03+.
- [kubectl][kubectl_tool] version v1.11.3+.
- Access to a Kubernetes v1.11.3+ cluster.

**Note**: This guide uses [minikube][minikube_tool] version v0.25.0+ as the local Kubernetes cluster and [quay.io][quay_link] for the public registry.
 -->
## 先决条件

- [git][git_tool]
- [go][go_tool] 版本 v1.12+.
- [mercurial][mercurial_tool] 版本 3.9+
- [docker][docker_tool] 版本 17.03+.
- [kubectl][kubectl_tool] 版本 v1.11.3+.
- 可以访问版本 v1.11.3+ Kubernetes 集群。

**注意**：本指南使用 [minikube][minikube_tool] 版本 v0.25.0+ 作为本地 Kubernetes 集群，同时使用 [quay.io][quay_link] 作为公共镜像仓库。

<!-- 
## Install the Operator SDK CLI

Follow the steps in the [installation guide][install_guide] to learn how to install the Operator SDK CLI tool.

## Create a new project

Use the CLI to create a new memcached-operator project:
-->
## 安装 Operator SDK CLI

请按照 [安装指南][install_guide] 中的步骤进行操作，以了解如何安装 Operator SDK CLI 工具。

## 创建一个新项目

使用 CLI 创建一个新的 memcached-operator 项目：

```sh
$ mkdir -p $HOME/projects
$ cd $HOME/projects
$ operator-sdk new memcached-operator --repo=github.com/example-inc/memcached-operator
$ cd memcached-operator
```
<!-- 
To learn about the project directory structure, see [project layout][layout_doc] doc.
 -->
要了解项目目录结构，请查看 [项目布局][layout_doc] 文档。

<!-- 
#### A note on dependency management

`operator-sdk new` generates a `go.mod` file to be used with [Go modules][go_mod_wiki]. The `--repo=<path>` flag is required when creating a project outside of `$GOPATH/src`, as scaffolded files require a valid module path. Ensure you activate module support before using the SDK. From the [Go modules Wiki][go_mod_wiki]:

> You can activate module support in one of two ways:
> - Invoke the go command in a directory with a valid go.mod file in the current directory or any parent of it and the environment variable GO111MODULE unset (or explicitly set to auto).
> - Invoke the go command with GO111MODULE=on environment variable set.
 -->
#### 有关依赖管理的说明

`operator-sdk new` 生成一个 `go.mod` 文件，该文件供 [Go modules][go_mod_wiki] 使用。 当在 `$GOPATH/src` 路径之外创建项目时， 必须使用 `--repo=<path>` 参数，因为脚手架文件需要一个有效的模块路径。使用 SDK 之前，请确认开启支持 go module。从 [Go modules Wiki][go_mod_wiki] 中：

> 你能通过以下两种方式之一开启支持 go module：
> - 调用 go 命令的当前目录或其任何父目录中具有有效 go.mod 文件，并且未设置环境变量 GO111MODULE（或将其显式设置为 auto）。
> - 使用 go 命令设置 GO111MODULE=on 环境变量。

<!-- 
##### Vendoring

By default `--vendor=false`, so an operator's dependencies are downloaded and cached in the Go modules cache. Calls to `go {build,clean,get,install,list,run,test}` by `operator-sdk` subcommands will use an external modules directory. Execute `go help modules` for more information.

The Operator SDK can create a [`vendor`][go_vendoring] directory for Go dependencies if the project is initialized with `--vendor=true`.
-->
##### Vendoring

默认情况下 `--vendor=false`，因此 operator 的依赖项下载并缓存在 Go modules 缓存中。通过 `operator-sdk` 子命令对 `go {build,clean,get,install,list,run,test}` 的条用将会使用一个外部 modules 目录。执行 `go help modules` 获取更多信息。

项目初始化使用 `--vendor=true` 参数，Operator SDK 能够为 Go 项目依赖创建 [`vendor`][go_vendoring] 文件夹。

<!-- 
#### Operator scope

Read the [operator scope][operator_scope] documentation on how to run your operator as namespace-scoped vs cluster-scoped.
 -->
#### Operator 范围

阅读 [operator scope][operator_scope] 文档，了解如何在命令空间范围或者集群范围内运行你的operator。

<!-- 
### Manager
The main program for the operator `cmd/manager/main.go` initializes and runs the [Manager][manager_go_doc].

The Manager will automatically register the scheme for all custom resources defined under `pkg/apis/...` and run all controllers under `pkg/controller/...`.

The Manager can restrict the namespace that all controllers will watch for resources:
```Go
mgr, err := manager.New(cfg, manager.Options{Namespace: namespace})
```
By default this will be the namespace that the operator is running in. To watch all namespaces leave the namespace option empty:
```Go
mgr, err := manager.New(cfg, manager.Options{Namespace: ""})
```

By default the main program will set the manager's namespace using the value of `WATCH_NAMESPACE` env defined in `deploy/operator.yaml`.
 -->
### Manager
operator 的主程序位于 `cmd/manager/main.go` 会初始化并运行 [Manager][manager_go_doc]。

Manager 会自动为 `pkg/apis/...` 下所有自定义资源注册 scheme，并运行 `pkg/controller/...` 下所有的控制器。

Manager 可以限制所有控制器将监听资源的名称空间：
```Go
mgr, err := manager.New(cfg, manager.Options{Namespace: namespace})
```
默认情况下，operator 只会监听其运行的名称空间的资源。要监听所有名称空间，请将名称空间选项留空：
```Go
mgr, err := manager.New(cfg, manager.Options{Namespace: ""})
```

默认情况下，主程序将会使用定义在 `deploy/operator.yaml` 中 `WATCH_NAMESPACE` 的值设置 manager 的名称空间的值。

<!-- 
## Add a new Custom Resource Definition

Add a new Custom Resource Definition(CRD) API called Memcached, with APIVersion `cache.example.com/v1alpha1` and Kind `Memcached`.

```sh
$ operator-sdk add api --api-version=cache.example.com/v1alpha1 --kind=Memcached
```

This will scaffold the Memcached resource API under `pkg/apis/cache/v1alpha1/...`.
 -->
## 添加新的自定义资源定义

使用 APIVersion 值为 `cache.example.com/v1alpha1` 和 Kind 值为 `Memcached` 来添加一个名为 Memcached 的自定义资源定义（CRD）API。

```sh
$ operator-sdk add api --api-version=cache.example.com/v1alpha1 --kind=Memcached
```

这将在 `pkg/apis/cache/v1alpha1/...` 目录下生成 Memcached 资源 API。

<!-- 
### Define the spec and status

Modify the spec and status of the `Memcached` Custom Resource(CR) at `pkg/apis/cache/v1alpha1/memcached_types.go`:

```Go
type MemcachedSpec struct {
	// Size is the size of the memcached deployment
	Size int32 `json:"size"`
}
type MemcachedStatus struct {
	// Nodes are the names of the memcached pods
	Nodes []string `json:"nodes"`
}
```

After modifying the `*_types.go` file always run the following command to update the generated code for that resource type:

```sh
$ operator-sdk generate k8s
```
 -->
### 定义规格和状态

在 `pkg/apis/cache/v1alpha1/memcached_types.go` 处修改  `Memcached` 自定义资源(CR) 的spec 和 status：

```Go
type MemcachedSpec struct {
	// Size is the size of the memcached deployment
	Size int32 `json:"size"`
}
type MemcachedStatus struct {
	// Nodes are the names of the memcached pods
	Nodes []string `json:"nodes"`
}
```

修改 `*_types.go` 之后，始终运行以下命令更新该资源类型的生成代码：

```sh
$ operator-sdk generate k8s
```

<!-- 
### OpenAPI validation
To update the OpenAPI validation section in the CRD `deploy/crds/cache.example.com_memcacheds_crd.yaml`, run the following command.

```console
$ operator-sdk generate openapi
```
This validation section allows Kubernetes to validate the properties in a Memcached Custom Resource when it is created or updated. An example of the generated YAML is as follows:

```YAML
spec:
  validation:
    openAPIV3Schema:
      properties:
        spec:
          properties:
            size:
              format: int32
              type: integer
```

To learn more about OpenAPI v3.0 validation schemas in Custom Resource Definitions, refer to the [Kubernetes Documentation][doc_validation_schema].
 -->
### OpenAPI 验证
要更新CRD `deploy/crds/cache.example.com_memcacheds_crd.yaml` 中的 OpenAPI 验证部分，请运行以下命令。

```console
$ operator-sdk generate openapi
```
该验证部分允许 Kubernetes 在创建或更新 Memcached 自定义资源时验证其属性。 生成的 YAML 的示例如下：

```YAML
spec:
  validation:
    openAPIV3Schema:
      properties:
        spec:
          properties:
            size:
              format: int32
              type: integer
```

要在 “自定义资源定义” 中了解有关 OpenAPI v3.0 验证架构的更多信息，请参考 [Kubernetes Documentation][doc_validation_schema] 文档。

<!-- 
## Add a new Controller

Add a new [Controller][controller-go-doc] to the project that will watch and reconcile the Memcached resource:

```sh
$ operator-sdk add controller --api-version=cache.example.com/v1alpha1 --kind=Memcached
```

This will scaffold a new Controller implementation under `pkg/controller/memcached/...`.

For this example replace the generated Controller file `pkg/controller/memcached/memcached_controller.go` with the example [`memcached_controller.go`][memcached_controller] implementation.

The example Controller executes the following reconciliation logic for each `Memcached` CR:
- Create a memcached Deployment if it doesn't exist
- Ensure that the Deployment size is the same as specified by the `Memcached` CR spec
- Update the `Memcached` CR status using the status writer with the names of the memcached pods

The next two subsections explain how the Controller watches resources and how the reconcile loop is triggered. Skip to the [Build](#build-and-run-the-operator) section to see how to build and run the operator.
 -->
## 添加一个新的控制器

向项目中增加一个新的 [控制器][controller-go-doc]，该项目就能监听并调和 Memcached 资源：

```sh
$ operator-sdk add controller --api-version=cache.example.com/v1alpha1 --kind=Memcached
```

这将在 `pkg/controller/memcached/...` 目录下生成新的控制器实现。

在此示例中，将生成的控制器文件 `pkg/controller/memcached/memcached_controller.go` 替换为示例 [`memcached_controller.go`][memcached_controller] 实现。

示例控制器对每一个 `Memcached` CR 执行以下调和逻辑：
- 创建 memcached Deployment（如果不存在）
- 确认 Deployment 的大小与  `Memcached` CR spec 的值大小相同
- 使用状态写入器将memcached pods 名称更新 `Memcached` CR status 值

接下来的两个小节说明了 Controller 如何监听资源以及如何触发调和循环。跳至 [Build](#build-and-run-the-operator) 部分以了解如何构建和运行operator。 

<!-- 
### Resources watched by the Controller

Inspect the Controller implementation at `pkg/controller/memcached/memcached_controller.go` to see how the Controller watches resources.

The first watch is for the Memcached type as the primary resource. For each Add/Update/Delete event the reconcile loop will be sent a reconcile `Request` (a namespace/name key) for that Memcached object:

```Go
err := c.Watch(
  &source.Kind{Type: &cachev1alpha1.Memcached{}}, &handler.EnqueueRequestForObject{})
```

The next watch is for Deployments but the event handler will map each event to a reconcile `Request` for the owner of the Deployment. Which in this case is the Memcached object for which the Deployment was created. This allows the controller to watch Deployments as a secondary resource.

```Go
err := c.Watch(&source.Kind{Type: &appsv1.Deployment{}}, &handler.EnqueueRequestForOwner{
    IsController: true,
    OwnerType:    &cachev1alpha1.Memcached{},
  })
```
 -->
### 控制器监听的资源

在 `pkg/controller/memcached/memcached_controller.go` 上检查 Controller 的实现，以查看 Controller 如何监听资源。

首先要注意的是将 Memcached 类型作为一级资源。对于每一个 Add/Update/Delete 事件，将向调和循环发送该 Memcached 对象的调和 `Request` (一个 名称空间/名字 关键字)：

```Go
err := c.Watch(
  &source.Kind{Type: &cachev1alpha1.Memcached{}}, &handler.EnqueueRequestForObject{})
```

下一个监听对象是 Deployments，但事件处理程序会将每个事件映射到 Deployment 所有者的调和 `Request` 中。 在本例中就是 Memcached 对象，因为 Memcached 对象创建了 Deployment 。 这使控制器可以将 Deployment 视为二级资源来监听。

```Go
err := c.Watch(&source.Kind{Type: &appsv1.Deployment{}}, &handler.EnqueueRequestForOwner{
    IsController: true,
    OwnerType:    &cachev1alpha1.Memcached{},
  })
```

<!-- 
#### Controller configurations

There are a number of useful configurations that can be made when initialzing a controller and declaring the watch parameters. For more details on these configurations consult the upstream [controller godocs][controller_godocs]. 

- Set the max number of concurrent Reconciles for the controller via the [`MaxConcurrentReconciles`][controller_options]  option. Defaults to 1.
  ```Go
  _, err := controller.New("memcached-controller", mgr, controller.Options{
	  MaxConcurrentReconciles: 2,
	  ...
  })
  ```
- Filter watch events using [predicates][event_filtering]
- Choose the type of [EventHandler][event_handler_godocs] to change how a watch event will translate to reconcile requests for the reconcile loop. For operator relationships that are more complex than primary and secondary resources, the [`EnqueueRequestsFromMapFunc`][enqueue_requests_from_map_func] handler can be used to transform a watch event into an arbitrary set of reconcile requests.
 -->
#### Controller 配置

初始化控制器和声明监听参数时，可以进行许多有用的配置。有关这些配置的更多详细信息，请查看上游 [controller godocs] [controller_godocs] 文档。

- 通过 [`MaxConcurrentReconciles`][controller_options] 参数设置控制器的最大并发调和数。默认值是1。
  ```Go
  _, err := controller.New("memcached-controller", mgr, controller.Options{
	  MaxConcurrentReconciles: 2,
	  ...
  })
  ```
- 使用 [predicates][event_filtering] 过滤监听事件
- 选择 [EventHandler][event_handler_godocs] 的类型来修改监听事件将如何转换为调和循环的调和请求。 operator 的关系比一级资源和二级资源更加复杂，使用 [`EnqueueRequestsFromMapFunc`][enqueue_requests_from_map_func] 能将监听事件转换成任意的调和请求集。


<!-- 
### Reconcile loop

Every Controller has a Reconciler object with a `Reconcile()` method that implements the reconcile loop. The reconcile loop is passed the [`Request`][request-go-doc] argument which is a Namespace/Name key used to lookup the primary resource object, Memcached, from the cache:

```Go
func (r *ReconcileMemcached) Reconcile(request reconcile.Request) (reconcile.Result, error) {
  // Lookup the Memcached instance for this reconcile request
  memcached := &cachev1alpha1.Memcached{}
  err := r.client.Get(context.TODO(), request.NamespacedName, memcached)
  ...
}
```

Based on the return values, [`Result`][result_go_doc] and error, the `Request` may be requeued and the reconcile loop may be triggered again:

```Go
// Reconcile successful - don't requeue
return reconcile.Result{}, nil
// Reconcile failed due to error - requeue
return reconcile.Result{}, err
// Requeue for any reason other than error
return reconcile.Result{Requeue: true}, nil
```

You can set the `Result.RequeueAfter` to requeue the `Request` after a grace period as well:
```Go
import "time"

// Reconcile for any reason than error after 5 seconds
return reconcile.Result{RequeueAfter: time.Second*5}, nil
```

**Note:** Returning `Result` with `RequeueAfter` set is how you can periodically reconcile a CR.

For a guide on Reconcilers, Clients, and interacting with resource Events, see the [Client API doc][doc_client_api].
 -->
### 调和循环

每个 Controller 都有一个 Reconciler 对象，该对象有实现了调和循环的 `Reconcile()` 方法。 该方法接受 [`Request`][request-go-doc] 参数，这个参数的 Namespace/Name 值用来从缓存中查找一级资源对象 Memcached：

```Go
func (r *ReconcileMemcached) Reconcile(request reconcile.Request) (reconcile.Result, error) {
  // Lookup the Memcached instance for this reconcile request
  memcached := &cachev1alpha1.Memcached{}
  err := r.client.Get(context.TODO(), request.NamespacedName, memcached)
  ...
}
```

根据返回值，[`Result`][result_go_doc] 和 error，这个 `Request` 可能会重新入队列并可能再次触发协和循环：

```Go
// Reconcile successful - don't requeue
return reconcile.Result{}, nil
// Reconcile failed due to error - requeue
return reconcile.Result{}, err
// Requeue for any reason other than error
return reconcile.Result{Requeue: true}, nil
```

你还可以将 `Result.RequeueAfter` 设置成在一段时间后 `Request` 重新进入队列：
```Go
import "time"

// Reconcile for any reason than error after 5 seconds
return reconcile.Result{RequeueAfter: time.Second*5}, nil
```

**注意：** 通过设置返回值 `Result` 中的 `RequeueAfter` 可以定期的调和一个 CR 资源。 

有关调和器，客户端以及与资源事件的交互指南，请查看 [Client API doc][doc_client_api]。

<!-- 
## Build and run the operator

Before running the operator, the CRD must be registered with the Kubernetes apiserver:

```sh
$ kubectl create -f deploy/crds/cache.example.com_memcacheds_crd.yaml
```

Once this is done, there are two ways to run the operator:

- As a Deployment inside a Kubernetes cluster
- As Go program outside a cluster
 -->
## 构建并运行 operator

在运行 operator 之前，CRD 必须注册到 Kubernetes apiserver 中：

```sh
$ kubectl create -f deploy/crds/cache.example.com_memcacheds_crd.yaml
```

完成此操作后，有两种方法可以运行 operator：

- 在 Kubernetes 集群中的deploymet
- 在 Kubernetes 集外的 Go 程序

<!-- 
### 1. Run as a Deployment inside the cluster

**Note**: `operator-sdk build` invokes `docker build` by default, and optionally `buildah bud`. If using `buildah`, skip to the `operator-sdk build` invocation instructions below. If using `docker`, make sure your docker daemon is running and that you can run the docker client without sudo. You can check if this is the case by running `docker version`, which should complete without errors. Follow instructions for your OS/distribution on how to start the docker daemon and configure your access permissions, if needed.

**Note**: If a `vendor/` directory is present, run
 -->
### 1. 在集群中运行一个deploymet

**注意**: 默认情况下，`operator-sdk build` 会调用 `docker build`，也可以选择调用 `buildah bud`。如果使用 `buildah`，请跳到下面的 `operator-sdk build` 调用说明。如果使用 `docker`，确认你的 docker 守护进程正在运行，并且可以在没有 sudo 的情况下运行 docker 客户端。您可以通过运行 docker version 来检查是否存在这种情况，该版本应该正确无误。 请根据你的 OS/distribution 上的说明，了解如何启动 docker 守护进程并根据需要配置访问权限。

**注意**: 如果存在 `vendor/` 目录，运行下面命令：

```sh
$ go mod vendor
```

<!-- 
before building the memcached-operator image.

Build the memcached-operator image and push it to a registry:
 -->
在构建 memcached-operator 镜像之前。

构建 memcached-operator 镜像并推送到镜像仓库： 
```sh
$ operator-sdk build quay.io/example/memcached-operator:v0.0.1
$ sed -i 's|REPLACE_IMAGE|quay.io/example/memcached-operator:v0.0.1|g' deploy/operator.yaml
$ docker push quay.io/example/memcached-operator:v0.0.1
```

<!-- 
**Note**
If you are performing these steps on OSX, use the following `sed` command instead:
```sh
$ sed -i "" 's|REPLACE_IMAGE|quay.io/example/memcached-operator:v0.0.1|g' deploy/operator.yaml
```

The Deployment manifest is generated at `deploy/operator.yaml`. Be sure to update the deployment image as shown above since the default is just a placeholder.

Setup RBAC and deploy the memcached-operator:
 -->
**注意**
如果你是在 OSX 系统上执行，使用下面的 `sed` 命令：
```sh
$ sed -i "" 's|REPLACE_IMAGE|quay.io/example/memcached-operator:v0.0.1|g' deploy/operator.yaml
```

部署清单在 `deploy/operator.yaml` 目录中生成。由于默认值是一个占位符，因此请确认按照上述命令更新 deployment 镜像。

设置 RBAC 然后部署 memcached-operator：

```sh
$ kubectl create -f deploy/service_account.yaml
$ kubectl create -f deploy/role.yaml
$ kubectl create -f deploy/role_binding.yaml
$ kubectl create -f deploy/operator.yaml
```

<!-- 
Verify that the memcached-operator is up and running:
 -->
验证 memcached-operator 已经启动并正在运行:

```sh
$ kubectl get deployment
NAME                     DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
memcached-operator       1         1         1            1           1m
```

<!-- 
### 2. Run locally outside the cluster

This method is preferred during development cycle to deploy and test faster.

Set the name of the operator in an environment variable:

```sh
export OPERATOR_NAME=memcached-operator
```

Run the operator locally with the default Kubernetes config file present at `$HOME/.kube/config`:

```sh
$ operator-sdk up local --namespace=default
2018/09/30 23:10:11 Go Version: go1.10.2
2018/09/30 23:10:11 Go OS/Arch: darwin/amd64
2018/09/30 23:10:11 operator-sdk Version: 0.0.6+git
2018/09/30 23:10:12 Registering Components.
2018/09/30 23:10:12 Starting the Cmd.
```

You can use a specific kubeconfig via the flag `--kubeconfig=<path/to/kubeconfig>`.
 -->
### 2. 在集群外本地运行

在开发周期中，首选此方法来更快地部署和测试。

设置一个 operator 名称的环境变量：

```sh
export OPERATOR_NAME=memcached-operator
```

使用保存 `$HOME/.kube/config` 中的默认 kubernetes 配置文件在本地运行 operator：

```sh
$ operator-sdk up local --namespace=default
2018/09/30 23:10:11 Go Version: go1.10.2
2018/09/30 23:10:11 Go OS/Arch: darwin/amd64
2018/09/30 23:10:11 operator-sdk Version: 0.0.6+git
2018/09/30 23:10:12 Registering Components.
2018/09/30 23:10:12 Starting the Cmd.
```

你可以通过参数 `--kubeconfig=<path/to/kubeconfig>` 指定特定的 kubeconfig 使用。

<!-- 

## Create a Memcached CR

Create the example `Memcached` CR that was generated at `deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml`:
 -->
## 创建一个 Memcached CR

示例 `Memcached` CR 会生成在 `deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml` 中：
```sh
$ cat deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml
apiVersion: "cache.example.com/v1alpha1"
kind: "Memcached"
metadata:
  name: "example-memcached"
spec:
  size: 3

$ kubectl apply -f deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml
```

<!-- 
Ensure that the memcached-operator creates the deployment for the CR:
 -->
确认 memcached-operator 为 CR 创建了 deployment：

```sh
$ kubectl get deployment
NAME                     DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
memcached-operator       1         1         1            1           2m
example-memcached        3         3         3            3           1m
```

<!-- 
Check the pods and CR status to confirm the status is updated with the memcached pod names:
 -->
检查 pods 和 CR 的状态以确认其状态已经用 memcached pod 名称更新了：

```sh
$ kubectl get pods
NAME                                  READY     STATUS    RESTARTS   AGE
example-memcached-6fd7c98d8-7dqdr     1/1       Running   0          1m
example-memcached-6fd7c98d8-g5k7v     1/1       Running   0          1m
example-memcached-6fd7c98d8-m7vn7     1/1       Running   0          1m
memcached-operator-7cc7cfdf86-vvjqk   1/1       Running   0          2m
```

```sh
$ kubectl get memcached/example-memcached -o yaml
apiVersion: cache.example.com/v1alpha1
kind: Memcached
metadata:
  clusterName: ""
  creationTimestamp: 2018-03-31T22:51:08Z
  generation: 0
  name: example-memcached
  namespace: default
  resourceVersion: "245453"
  selfLink: /apis/cache.example.com/v1alpha1/namespaces/default/memcacheds/example-memcached
  uid: 0026cc97-3536-11e8-bd83-0800274106a1
spec:
  size: 3
status:
  nodes:
  - example-memcached-6fd7c98d8-7dqdr
  - example-memcached-6fd7c98d8-g5k7v
  - example-memcached-6fd7c98d8-m7vn7
```

<!-- 
### Update the size

Change the `spec.size` field in the memcached CR from 3 to 4 and apply the change:
 -->
### 更新大小

将 memcached CR 中的 `spec.size` 字段从3更改为4，并应用更改：

```sh
$ cat deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml
apiVersion: "cache.example.com/v1alpha1"
kind: "Memcached"
metadata:
  name: "example-memcached"
spec:
  size: 4

$ kubectl apply -f deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml
```

<!-- 
Confirm that the operator changes the deployment size:
 -->
确认 operator 改变了 deployment 的大小：

```sh
$ kubectl get deployment
NAME                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
example-memcached    4         4         4            4           5m
```

<!-- 
### Cleanup

Clean up the resources:
 -->
### 清理

清理资源：

```sh
$ kubectl delete -f deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml
$ kubectl delete -f deploy/operator.yaml
$ kubectl delete -f deploy/role_binding.yaml
$ kubectl delete -f deploy/role.yaml
$ kubectl delete -f deploy/service_account.yaml
```

<!-- 
## Advanced Topics

### Adding 3rd Party Resources To Your Operator

The operator's Manager supports the Core Kubernetes resource types as found in the client-go [scheme][scheme_package] package and will also register the schemes of all custom resource types defined in your project under `pkg/apis`.
 -->
## 进阶主题

### 增加第三方资源到你的 operator 中

operator 的 Manager 支持在 client-go [scheme][scheme_package] 包中找到 Kubernetes 核心资源类型，并将你项目中 `pkg/apis` 目录下定义的所有自定义资源类型的 schemes 注册到 Kubernetes apiserver 中。
```Go
import (
  "github.com/example-inc/memcached-operator/pkg/apis"
  ...
)

// Setup Scheme for all resources
if err := apis.AddToScheme(mgr.GetScheme()); err != nil {
  log.Error(err, "")
  os.Exit(1)
}
```

<!-- 
To add a 3rd party resource to an operator, you must add it to the Manager's scheme. By creating an `AddToScheme()` method or reusing one you can easily add a resource to your scheme. An [example][deployments_register] shows that you define a function and then use the [runtime][runtime_package] package to create a `SchemeBuilder`.

#### Register with the Manager's scheme

Call the `AddToScheme()` function for your 3rd party resource and pass it the Manager's scheme via `mgr.GetScheme()`.

Example:
 -->
要将第三方资源添加到 operator 中，你必须将其添加到 Manager's scheme 中。通过创建一个 `AddToScheme()` 方法或者重用一个方法，你可以轻松地将资源加到你的 scheme 中。一个[示例]][deployments_register] 显示你定义一个函数，然后使用 [runtime][runtime_package] 包创建一个 `SchemeBuilder`。

### 注册 Manager 的 scheme

为你的第三方资源调用 `AddToScheme()` 方法，并通过 `mgr.GetScheme()` 将其传递给 Manager's scheme。

示例：
```go
import (
  ....

  routev1 "github.com/openshift/api/route/v1"
)

func main() {
  ....

  // Adding the routev1
  if err := routev1.AddToScheme(mgr.GetScheme()); err != nil {
    log.Error(err, "")
    os.Exit(1)
  }

  ....

  // Setup all Controllers
  if err := controller.AddToManager(mgr); err != nil {
    log.Error(err, "")
    os.Exit(1)
  }
}
```

<!--
**NOTES:**
 
* After adding new import paths to your operator project, run `go mod vendor` if a `vendor/` directory is present in the root of your project directory to fulfill these dependencies.
* Your 3rd party resource needs to be added before add the controller in `"Setup all Controllers"`.

### Handle Cleanup on Deletion

To implement complex deletion logic, you can add a finalizer to your Custom Resource. This will prevent your Custom Resource from being
deleted until you remove the finalizer (ie, after your cleanup logic has successfully run). For more information, see the
[official Kubernetes documentation on finalizers](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#finalizers).

**Example:**

The following is a snippet from the controller file under `pkg/controller/memcached/memcached_controller.go`
 -->
**注意:**

* 在将新的 import 路径添加到你的operator 项目中后，如果项目的根目录中存在 `vendor/` 目录，请运行 `go mod vendor` 以满足这些依赖。
* 需要先添加您的第三方资源，然后才能在 `"Setup all Controllers"` 中添加控制器。

### 在删除的时候做些清理工作

要实现复杂的删除逻辑，你可以在自定义资源中增加一个 finalizer。这将阻止你的自定义资源被删除，直到你删除 finalizer（例如，在清理逻辑成功运行之后）。有关更多信息，请参考[official Kubernetes documentation on finalizers](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#finalizers)。

**示例：**

以下是 `pkg/controller/memcached/memcached_controller.go` 控制器文件的摘录。
```Go

const memcachedFinalizer = "finalizer.cache.example.com"

func (r *ReconcileMemcached) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name)
	reqLogger.Info("Reconciling Memcached")

	// Fetch the Memcached instance
	memcached := &cachev1alpha1.Memcached{}
	err := r.client.Get(context.TODO(), request.NamespacedName, memcached)
	if err != nil {
		// If the resource is not found, that means all of
		// the finalizers have been removed, and the memcached
		// resource has been deleted, so there is nothing left
		// to do.
		if apierrors.IsNotFound(err) {
			return reconcile.Result{}, nil
		}
		return reconcile.Result{}, fmt.Errorf("could not fetch memcached instance: %s", err)
	}

	...

	// Check if the Memcached instance is marked to be deleted, which is
	// indicated by the deletion timestamp being set.
	isMemcachedMarkedToBeDeleted := memcached.GetDeletionTimestamp() != nil
	if isMemcachedMarkedToBeDeleted {
		if contains(memcached.GetFinalizers(), memcachedFinalizer) {
			// Run finalization logic for memcachedFinalizer. If the
			// finalization logic fails, don't remove the finalizer so
			// that we can retry during the next reconciliation.
			if err := r.finalizeMemcached(reqLogger, memcached); err != nil {
				return reconcile.Result{}, err
			}

			// Remove memcachedFinalizer. Once all finalizers have been
			// removed, the object will be deleted.
			memcached.SetFinalizers(remove(memcached.GetFinalizers(), memcachedFinalizer))
			err := r.client.Update(context.TODO(), memcached)
			if err != nil {
				return reconcile.Result{}, err
			}
		}
		return reconcile.Result{}, nil
	}

	// Add finalizer for this CR
	if !contains(memcached.GetFinalizers(), memcachedFinalizer) {
		if err := r.addFinalizer(reqLogger, memcached); err != nil {
			return reconcile.Result{}, err
		}
	}

	...

	return reconcile.Result{}, nil
}

func (r *ReconcileMemcached) finalizeMemcached(reqLogger logr.Logger, m *cachev1alpha1.Memcached) error {
	// TODO(user): Add the cleanup steps that the operator
	// needs to do before the CR can be deleted. Examples
	// of finalizers include performing backups and deleting
	// resources that are not owned by this CR, like a PVC.
	reqLogger.Info("Successfully finalized memcached")
	return nil
}

func (r *ReconcileMemcached) addFinalizer(reqLogger logr.Logger, m *cachev1alpha1.Memcached) error {
	reqLogger.Info("Adding Finalizer for the Memcached")
	m.SetFinalizers(append(m.GetFinalizers(), memcachedFinalizer))

	// Update CR
	err := r.client.Update(context.TODO(), m)
	if err != nil {
		reqLogger.Error(err, "Failed to update Memcached with finalizer")
		return err
	}
	return nil
}

func contains(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

func remove(list []string, s string) []string {
	for i, v := range list {
		if v == s {
			list = append(list[:i], list[i+1:]...)
		}
	}
	return list
}
```

<!-- 
### Metrics

To learn about how metrics work in the Operator SDK read the [metrics section][metrics_doc] of the user documentation.
 -->
### Metrics

要了解 operator SDK 中 metrics 如何工作，请阅读用户文档 [metrics section][metrics_doc]。

<!-- 
## Leader election

During the lifecycle of an operator it's possible that there may be more than 1 instance running at any given time e.g when rolling out an upgrade for the operator.
In such a scenario it is necessary to avoid contention between multiple operator instances via leader election so that only one leader instance handles the reconciliation while the other instances are inactive but ready to take over when the leader steps down.

There are two different leader election implementations to choose from, each with its own tradeoff.

- [Leader-for-life][leader_for_life]: The leader pod only gives up leadership (via garbage collection) when it is deleted. This implementation precludes the possibility of 2 instances mistakenly running as leaders (split brain). However, this method can be subject to a delay in electing a new leader. For instance when the leader pod is on an unresponsive or partitioned node, the [`pod-eviction-timeout`][pod_eviction_timeout] dictates how long it takes for the leader pod to be deleted from the node and step down (default 5m).
- [Leader-with-lease][leader_with_lease]: The leader pod periodically renews the leader lease and gives up leadership when it can't renew the lease. This implementation allows for a faster transition to a new leader when the existing leader is isolated, but there is a possibility of split brain in [certain situations][lease_split_brain].

By default the SDK enables the leader-for-life implementation. However you should consult the docs above for both approaches to consider the tradeoffs that make sense for your use case.

The following examples illustrate how to use the two options:
 -->
## 领导人选举

在 operator 的生命周期内，例如在为 operator 升级时，在任何给定的时间可能有多个实例在运行。
在这种情况下，有必要避免通过领导者选举在多个 operator 实例之间发生争用，以便只有一个领导者实例处理调和，而其他实例处于非活动状态，但准备好在领导者下台时接管。

有两种不同的领导者选举实现方式可供选择，每种实现方式都有其自身的取舍。

- [Leader-for-life][leader_for_life]：领导者 pod 仅在被删除时才放弃领导（通过垃圾回收）。此实现避免了 2 个实例错误地作为领导者运行（脑裂）的可能性。但是，此方法可能会导致选举新领导人的时间延迟。例如，当领导者 pod 在无响应或者在一个分区的节点上时，[`pod-eviction-timeout`][pod_eviction_timeout] 参数指示从节点删除领导者 pod 时间并下台的时间（默认是5m）。
- [Leader-with-lease][leader_with_lease]：领导者 pod 会定期续签领导租约，并在无法续签租约是放弃领导。这种实现方式可以更快的转移领导权，但是在 [certain situations][lease_split_brain] 可以会出现脑裂的情况。

默认情况下，operator SDK 使用 leader-for-life 的方式。但是，你应该参考上述两种方法的文档，以考虑对你的用例有意义的折衷方案。

下面的示例说明了如何使用这两个选项：

<!-- 
### Leader for life

A call to `leader.Become()` will block the operator as it retries until it can become the leader by creating the configmap named `memcached-operator-lock`.
 -->
### Leader for life

通过对 `leader.Become()` 方法的调用阻止 operator 重新成为领导，直到其创建名为 `memcached-operator-lock` 的 configmap。

```Go
import (
  ...
  "github.com/operator-framework/operator-sdk/pkg/leader"
)

func main() {
  ...
  err = leader.Become(context.TODO(), "memcached-operator-lock")
  if err != nil {
    log.Error(err, "Failed to retry for leader lock")
    os.Exit(1)
  }
  ...
}
```
<!-- 
If the operator is not running inside a cluster `leader.Become()` will simply return without error to skip the leader election since it can't detect the operator's namespace.
 -->
如果 operator 不在集群中运行，则 `leader.Become()` 将返回无错误的消息以跳过领导人选举，因为它无法检测 operator 的命名空间。

<!-- 
### Leader with lease

The leader-with-lease approach can be enabled via the [Manager Options][manager_options] for leader election.
 -->
### Leader with lease

可以通过 [Manager Options][manager_options] 启用领导者租用方式进行领导人选举。

```Go
import (
  ...
  "sigs.k8s.io/controller-runtime/pkg/manager"
)

func main() {
  ...
  opts := manager.Options{
    ...
    LeaderElection: true,
    LeaderElectionID: "memcached-operator-lock"
  }
  mgr, err := manager.New(cfg, opts)
  ...
}
```

<!-- 
When the operator is not running in a cluster, the Manager will return an error on starting since it can't detect the operator's namespace in order to create the configmap for leader election. You can override this namespace by setting the Manager's `LeaderElectionNamespace` option.
 -->
当 operator 不在集群中运行时，Manager 将在启动时返回错误，因为它无法检测到 operator 的名称空间以创建用于领导者选举的 configmap。 您可以通过设置 Manager 的 `LeaderElectionNamespace` 选项来覆盖此命名空间。

[enqueue_requests_from_map_func]: https://godoc.org/sigs.k8s.io/controller-runtime/pkg/handler#EnqueueRequestsFromMapFunc
[event_handler_godocs]: https://godoc.org/sigs.k8s.io/controller-runtime/pkg/handler#hdr-EventHandlers
[event_filtering]:./user/event-filtering.md
[controller_options]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/controller#Options
[controller_godocs]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/controller
[operator_scope]:./operator-scope.md
[install_guide]: ./user/install-operator-sdk.md
[pod_eviction_timeout]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/#options
[manager_options]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/manager#Options
[lease_split_brain]: https://github.com/kubernetes/client-go/blob/30b06a83d67458700a5378239df6b96948cb9160/tools/leaderelection/leaderelection.go#L21-L24
[leader_for_life]: https://godoc.org/github.com/operator-framework/operator-sdk/pkg/leader
[leader_with_lease]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/leaderelection
[memcached_handler]: ../example/memcached-operator/handler.go.tmpl
[memcached_controller]: ../example/memcached-operator/memcached_controller.go.tmpl
[layout_doc]:./project_layout.md
[ansible_user_guide]:./ansible/user-guide.md
[helm_user_guide]:./helm/user-guide.md
[homebrew_tool]:https://brew.sh/
[go_mod_wiki]: https://github.com/golang/go/wiki/Modules
[go_vendoring]: https://blog.gopheracademy.com/advent-2015/vendor-folder/
[git_tool]:https://git-scm.com/downloads
[go_tool]:https://golang.org/dl/
[docker_tool]:https://docs.docker.com/install/
[mercurial_tool]:https://www.mercurial-scm.org/downloads
[kubectl_tool]:https://kubernetes.io/docs/tasks/tools/install-kubectl/
[minikube_tool]:https://github.com/kubernetes/minikube#installation
[scheme_package]:https://github.com/kubernetes/client-go/blob/master/kubernetes/scheme/register.go
[deployments_register]: https://github.com/kubernetes/api/blob/master/apps/v1/register.go#L41
[doc_client_api]:./user/client.md
[runtime_package]: https://godoc.org/k8s.io/apimachinery/pkg/runtime
[manager_go_doc]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/manager#Manager
[controller-go-doc]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg#hdr-Controller
[request-go-doc]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/reconcile#Request
[result_go_doc]: https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/reconcile#Result
[metrics_doc]: ./user/metrics/README.md
[quay_link]: https://quay.io
[doc_validation_schema]: https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#specifying-a-structural-schema