---
title: ansible 基本语法
tags: [linux, ansible]
---

# ansible 基本语法

[Ansible中文权威指南](http://ansible-tran.readthedocs.io/en/latest/)  
[Ansible教程](http://docs.linux.xyz/docs/show/123)  
[Ansible基础学习](https://github.com/fasss/redis-in-action/wiki/ansible%E5%9F%BA%E7%A1%80%E5%AD%A6%E4%B9%A0)  

- ## command模块：是Ansible默认执行模块，在远程主机执行 shell 指令
**用法**  
下面两种方法等价，默认执行command
`ansible all -a "pwd" `
`ansible all -m command -a "pwd"`

```yml
# 关闭系统
-command: /sbin/shutdown -t now

# 当指定的文件存在时，跳过不执行该命令
-command: /usr/bin/make_database.sh arg1 arg2 creates=/path/to/database

# 当指定不文件存在时，则该命令将会执行
-command: /usr/bin/make_database.sh arg1 arg2 creates=/path/to/database
```

注：这个模块不支持管道和重定向，要支持管道可以用-m shell 或者-m raw，shell 和 raw 语法一样，它们支持管道和重定向，如：
```yml
- shell: ifconfig|grep inet|grep -Ev '127.'|cut -d':' -f2|cut -d' ' -f1

- raw: ifconfig|grep inet|grep -Ev '127.'|cut -d':' -f2|cut -d' ' -f1 > /tmp/ip.log
```

- ## file模块：设置文件的属性

**用法**  
`ansible all -m stat -a "path=/root/ansible" `

    (1) 创建目录：
        -a "path=  state=directory"
    (2) 创建链接文件：
        -a "path=  src=  state=link"
    (3) 删除文件：
        -a "path=  state=absent"

```yaml
# 创建文件夹,recurse=yes 递归，相当于 mkdir -p
- file: path=/root/soft/ state=directory mode=0755 recurse=yes

# 创建文件
- file: path=/etc/foo.conf state=touch mode="u=rw,g-wx,o-rwx"

# 删除文件
- file: path=/root/soft state=absent 

# 修改文件目录属性
- file: path=/root/soft mode=750 owner=ops group=ops

# 创建文件软件链接
- file: src=/file/link dest=/path/symlink owner=foo group=foo state=link

# 批量创建文件软件链接
- file: src=/tmp/{{ item.src }} dest={{ item.dest }} state=link
 with_items:
 - { src: 'x', dest: 'y' }
 - { src: 'z', dest: 'k' }
```
```bash
[root@localhost ansible]# ansible all -m file -a "path=/root/ansible state=directory"
192.168.101.229 | SUCCESS => {
    "changed": true, 
    "gid": 0, 
    "group": "root", 
    "mode": "0755", 
    "owner": "root", 
    "path": "/root/ansible", 
    "secontext": "unconfined_u:object_r:admin_home_t:s0", 
    "size": 6, 
    "state": "directory", 
    "uid": 0
}
192.168.101.104 | SUCCESS => {
    "changed": true, 
    "gid": 0, 
    "group": "root", 
    "mode": "0755", 
    "owner": "root", 
    "path": "/root/ansible", 
    "secontext": "unconfined_u:object_r:admin_home_t:s0", 
    "size": 6, 
    "state": "directory", 
    "uid": 0
}
192.168.100.197 | SUCCESS => {
    "changed": false, 
    "gid": 0, 
    "group": "root", 
    "mode": "0755", 
    "owner": "root", 
    "path": "/root/ansible", 
    "secontext": "unconfined_u:object_r:admin_home_t:s0", 
    "size": 21, 
    "state": "directory", 
    "uid": 0
}

```
- ## copy模块：复制文件到远程主机

**用法**  
`ansible all -m copy -a "src=/root/ansible/testfile dest=/root/ansible/testfile  mode=600"
```yml
# 复制 redis 服务脚本到远程主机机器，force 为强制性复制
- copy: src=/data/ansible/file/redis/redis-server dest=/etc/init.d/ mode=750 owner=root group=root force=yes

# 复制目录，directory_mode 目录模式
- copy: src=/root/nginx dest=/root/nginx mode=750 owner=ops group=ops directory_mode=yes

# 复制前对文件进行备份，backup=yes
- copy: src=/srv/myfiles/foo.conf dest=/etc/foo.conf owner=foo group=foo mode="u+rw,g-wx,o-rwx" backup=yes

# 多个文件的复制，采用循环 with_items
- copy: src={{ item }} dest=/root/
 with_items:
 - /data/a.sh
 - /logs/b.py

# 文件通配符循环 with_fileglob
- copy: src={{ item }} dest=/etc/fooapp/ owner=root mode=600
 with_fileglob:
 - /playbooks/files/fooapp/*
```


```bash
[root@localhost ansible]# ansible all -m copy -a "src=/root/ansible/testfile dest=/root/ansible/testfile  mode=600"
192.168.101.229 | SUCCESS => {
    "changed": true, 
    "checksum": "795f9549ca9d7715279a63ff49b5b801da3ec0ad", 
    "dest": "/root/ansible/testfile", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "82f25f5116f96ba86889e004f41ecb86", 
    "mode": "0600", 
    "owner": "root", 
    "secontext": "system_u:object_r:admin_home_t:s0", 
    "size": 22, 
    "src": "/root/.ansible/tmp/ansible-tmp-1533262319.99-21402740317520/source", 
    "state": "file", 
    "uid": 0
}
192.168.101.104 | SUCCESS => {
    "changed": true, 
    "checksum": "795f9549ca9d7715279a63ff49b5b801da3ec0ad", 
    "dest": "/root/ansible/testfile", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "82f25f5116f96ba86889e004f41ecb86", 
    "mode": "0600", 
    "owner": "root", 
    "secontext": "system_u:object_r:admin_home_t:s0", 
    "size": 22, 
    "src": "/root/.ansible/tmp/ansible-tmp-1533262319.98-120771157809251/source", 
    "state": "file", 
    "uid": 0
}
192.168.100.197 | SUCCESS => {
    "changed": false, 
    "checksum": "795f9549ca9d7715279a63ff49b5b801da3ec0ad", 
    "dest": "/root/ansible/testfile", 
    "gid": 0, 
    "group": "root", 
    "mode": "0600", 
    "owner": "root", 
    "path": "/root/ansible/testfile", 
    "secontext": "unconfined_u:object_r:admin_home_t:s0", 
    "size": 22, 
    "state": "file", 
    "uid": 0
}

```
        libel
- ##  stat模块
**用法**  
`ansible all -m stat -a "path=/root/ansible"`

判断文件是否存在
```yml
# 判断一个路径是存在，且是一个目录
- stat: path=/path/to/something
 register: reg
- debug: msg="Path exists and is a directory"
 when: reg.stat.isdir is defined and p.stat.isdir

# 判断文件属主是否发生改变
- stat: path=/etc/foo.conf
 register: reg
- fail: msg="Oh,file ownership has changed"
 when: re.stat.pw_name != "root"

# 判断文件是否存
- stat: path=/path/to/something
 register: reg
- debug: msg="file doesn't exist"
 when: not reg.stat.exists
- debug: msg="file is exist"
 when: reg.stat.exists
```

- ##  hostname模块：管理主机名

**用法**  
    name=
appserver 是group name，在/etc/ansible/hosts中设置
```bash
[root@localhost ansible]# ansible all -a "hostname"
192.168.101.104 | SUCCESS | rc=0 >>
localhost.localdomain

192.168.100.197 | SUCCESS | rc=0 >>
localhost.localdomain

192.168.101.229 | SUCCESS | rc=0 >>
localhost.localdomain

[root@localhost ansible]# ansible appserver -a "hostname"   
192.168.101.229 | SUCCESS | rc=0 >>
localhost.localdomain

192.168.101.104 | SUCCESS | rc=0 >>
localhost.localdomain

192.168.100.197 | SUCCESS | rc=0 >>
localhost.localdomain

```
- ## yum模块：使用yum命令完成程序包管理

**用法**  
`ansible all -m yum -a "name=lrzsz"  `
    
```yml
- name: 安装最新版本的 Apache
 yum: name=httpd state=latest

- name: 删除 Apache
 yum: name=httpd state=absent

- name: 从指定的 yum 源安装最新版本的 Apache
 yum: name=httpd enablerepo=epel state=present

- name: 安装指定 url 的 RPM 包
yum: name=http://mirrors.sohu.com/fedora-epel/6/x86_64/epel-release-6-8.noarch.rpm state=present

- name: 安装指定版本号的 Apache
 yum: name=httpd-2.2.29-1.4.amzn1 state=present

- name: 更新系统所有的包
 yum: name=* state=latest

- name: 从本地路径上安装指定的 nginx
 yum: name=/usr/local/src/nginx-release-centos-6-0.el6.ngx.noarch.rpm s
tate=present

- name: 安装系统开发工具包
 yum: name="@Development tools" state=present 
```

```bash
ansible all -m yum -a "name=samba" //安装
ansible all -m yum -a "name=samba state=removed"  //卸载
```

- ## service模块：主要用于系统服务管理,包括启动、关闭、重启、以及设置开机启动等

**用法**  
`ansible all -m service -a "name=vdftpd state=started enabled=yes" `
```yml
# 启动服务,并设置开机启动
- service: name=vsftpd state=started enabled=yes

# 关闭服务
- service: name=vsftpd state=stopped

# 重启服务
- service: name=vsftpd state=restarted

# 重载服务
- service: name=vsftpd state=reloaded 
```
- ## group模块：增加或删除组
**用法**  
`ansible all -m group -a "name=ftp gid=1024 state=present"`

```yml
# 创建用户组
group: name=lipeibin gid=1024 state=present

# 删除用户组
group: name=lipeibin state=absent 
```

- ## user模块：用户管理
**用法**  
`ansible all -m user -a "name=ftp groups=ftp"` 

```yml
# 创建用户 lipeibin
- user: name=lipeibin groups=lipeibin shell=/sbin/nologin state=present

# 删除用户 lipeibin,并删除用户主目录/home/lipeibin
- user: name=lipeibin state=absent remove=yes

# 创建用户 lipeibin,并且设置密码，归属 ops 组
- user: name=lipeibin password=”19890506”| password_hash('sha512') group=ops

# 设置用户有效时间
- user: name=lipeibin shell=/bin/bash groups=ops expires=1422403387
```




```
ansible all -m file -a "path=/root/ansible state=directory"   //在所有节点上创建文件夹  -file模块
ansible all -m copy -a "src=/root/ansible/testfile dest=/root/ansible/testfile  mode=600"  //复制文件到所有节点  copy模块
ansible all -m shell  -a "netstat -nltp | grep 80"  //检测端口

```
- ## replace模块主要用于搜索匹配替换，类似于 linux 命令 sed
**用法**  
`ansible all -m replace ???  `
```yml
# 把 old.host.name 替换成 new.host.name
- replace: dest=/etc/hosts regexp='(\s+)old\.host\.name(\s+.*)?$' replace='\1new.host.name\2' owner=jdoe group=jdoe mode=644 backup=yes

# 把 Listen 80 和 NameVirtualHost 80 分别替换成 Listen 127.0.0.1:8080 和 Name
VirtualHost 127.0.0.1:8080
 - replace: dest=/etc/apache/ports regexp='^(NameVirtualHost|Listen)\s+80\s*$' replace='\1 127.0.0.1:8080''
```


# PlayBook

### 核心元素：

    Tasks：任务，由模块定义的操作的列表；
    Variables：变量
    Templates：模板，即使用了模板语法的文本文件；
    Handlers：由特定条件触发的Tasks；
    Roles：角色；

    playbook的基础组件：
        Hosts：运行指定任务的目标主机；
        remote_user：在远程主机以哪个用户身份执行；
            sudo_user：非管理员需要拥有sudo权限；
        tasks：任务列表
            模块，模块参数：
                格式：
                    (1) action: module arguments
                    (2) module: arguments

### 运行playbook，使用ansible-playbook命令

    (1) 检测语法
        ansible-playbook  --syntax-check  /path/to/playbook.yaml
    (2) 测试运行  -C 是测试
        ansible-playbook -C /path/to/playbook.yaml
            --list-hosts
            --list-tasks
            --list-tags
    (3) 运行
        ansible-playbook  /path/to/playbook.yaml
            -t TAGS, --tags=TAGS
            --skip-tags=SKIP_TAGS
            --start-at-task=START_AT
  
  
```
ansible-playbook -C group.yml 
```

- ## tags：给指定的任务定义一个调用标识；

使用格式：

    - name: NAME
        module: arguments
        tags: TAG_ID


- ## Variables：变量

    类型：

        内建：
            (1) facts
        自定义：
            (1) 命令行传递；
                -e VAR=VALUE
            (2) 在hosts Inventory中为每个主机定义专用变量值；
                (a) 向不同的主机传递不同的变量 ；
                    IP/HOSTNAME variable_name=value
                (b) 向组内的所有主机传递相同的变量 ；
                    [groupname:vars]
                    variable_name=value
            (3) 在playbook中定义
                vars:
                    - var_name: value
                    - var_name: value
            (4) Inventory还可以使用参数：
                用于定义ansible远程连接目标主机时使用的属性，而非传递给playbook的变量；
                    ansible_ssh_host
                    ansible_ssh_port
                    ansible_ssh_user
                    ansible_ssh_pass
                    ansible_sudo_pass
                    ...
            (5) 在角色调用时传递
                roles:
                    - { role: ROLE_NAME, var: value, ...}
                    变量调用：
                    ` var_name `

