---
title: dockerfile中cmd和entrypoint用法
date: 2019-08-123 09:19:04
tags: [dockerfile, kubernetes]
---
## entrypoint cmd

在docker run image cmd arg1时，总是相当于CMD的["cmd", "arg1"]形式。 此外，docker-compose.yml的情况与docker run类似。

### Dockerfile中cmd命令的三种形式
The CMD instruction has three forms:

- CMD ["executable","param1","param2"] (exec form, this is the preferred form)
- CMD ["param1","param2"] (as default parameters to ENTRYPOINT)
- CMD command param1 param2 (shell form)

第一种(推荐)
采用中括号形式，那么第一个参数必须是命令的全路径才行。而且，一个dockerfile至多只能有一个cmd，如果有多个，只有最后一个生效。

```dockerfile
FROM ubuntu

CMD ["/bin/bash", "-c", "echo 'hello cmd!'"]
```

第二种是作为参数传递给entrypoint
第三种shell form，即没有中括号的形式。那么命令command默认是在"/bin/sh -c"下执行的。(等价于第一种的写法)

```dockerfile
FROM ubuntu

CMD echo "hello cmd!"
```

### ENTRYPOINT has two forms:

- ENTRYPOINT ["executable", "param1", "param2"] (exec form, preferred)
- ENTRYPOINT command param1 param2 (shell form)

分为命令行和shell两种。
先看命令行模式，也就是带中括号的。和cmd的中括号形式是一致的，但是这里貌似是在shell的环境下执行的，与cmd有区别。如果run命令后面有东西，那么后面的全部都会作为entrypoint的参数。如果docker run后面没有额外的东西，但是cmd有，那么cmd的全部内容会作为entrypoint的参数，这同时是cmd的第二种用法。这也是网上说的entrypoint不会被覆盖。当然如果要在run里面覆盖，也是有办法的，使用--entrypoint即可。

### docker-compose Dockerfile Kubernetes中CMD和entrypoint区别

| Description                      | Docker field name | Docker-compose  | Kubernetes field name|
| -------------                    | -------------     | -----           |----    |
| The command run by the container | Entrypoint        | Entrypoint      |command|
| The arguments passed to the command | Cmd            | command         |args|

如果要覆盖默认的Entrypoint 与 Cmd，需要遵循如下规则：(Docker 与 Kubernetes, k8s中的设置会覆盖容器默认的命令)

- 如果在容器配置中没有设置command 或者 args，那么将使用Docker镜像自带的命令及其入参。

- 如果在容器配置中只设置了command但是没有设置args,那么容器启动时只会执行该命令，Docker镜像中自带的命令及其入参会被忽略。

- 如果在容器配置中只设置了args,那么Docker镜像中自带的命令会使用该新入参作为其执行时的入参。

- 如果在容器配置中同时设置了command 与 args，那么Docker镜像中自带的命令及其入参会被忽略。容器启动时只会执行配置中设置的命令，并使用配置中设置的入参作为命令的入参。

下表涵盖了各类设置场景：

|Image Entrypoint	|Image Cmd	|Container command	|Container args	|Command run|
|---|---|---|---|---|
|[/ep-1]	|[foo bar]	| <not set>	| <not set>	|[ep-1 foo bar]|
|[/ep-1]	|[foo bar]	|[/ep-2]	|<not set>	|[ep-2]        |
|[/ep-1]	|[foo bar]	|<not set>	|[zoo boo]	|[ep-1 zoo boo]|
|[/ep-1]	|[foo bar]	|[/ep-2]	|[zoo boo]	|[ep-2 zoo boo]|

*空白表示没设置该参数*

```yaml
env:
- name: MESSAGE
  value: "hello world"
command: ["/bin/echo"]
args: ["$(MESSAGE)"]
```
