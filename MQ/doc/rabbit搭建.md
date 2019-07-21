###  1. 安装：

####  1）安装erlang: 

版本：20.1

安装包：esl-erlang_20.1-1_centos_6_amd64.rpm

命令 :yum install esl-erlang_20.1-1_centos_6_amd64.rpm

​         rpm -ivh --nodeps esl-erlang_20.1-1_centos_6_amd64.rpm

#### 2）安装rabbitmq：

版本：3.7.3

安装包：rabbitmq-server-3.7.3-1.el6.noarch.rpm 

命令 : rpm -ivh rabbitmq-server-3.7.3-1.el6.noarch.rpm 

#### 3）可能出现的问题

socat is needed by rabbitmq-server-3.7.3-1.el6.noarch.rpm 

解决：先yum -y install socat，如果报错没有socat包或是找不到socat包，安装centos的epel的扩展源
yum -y install epel-release 之后执行yum -y install socat

###   2.rabbitmq配置

#### 1）rabbitmq-env.conf配置

RabbitMQ的配置可以由三种方式进行定制。
环境变量，配置文件，运行时参数和策略

文件位置：/etc/rabbitmq/rabbitmq-env.conf，不可改变。
rabbitmq-env.conf定义的变量会覆盖rabbitmq启动脚本的内置参数。
常用环境变量：
RABBITMQ_NODE_IP_ADDRESS= //IP地址，空串bind所有地址，指定地址bind指定网络接口
RABBITMQ_NODE_PORT=       //TCP端口号，默认是5672
RABBITMQ_NODENAME=        //节点名称。默认是rabbit
RABBITMQ_CONFIG_FILE= //配置文件路径 ，即rabbitmq.config文件路径
RABBITMQ_MNESIA_BASE=     //mnesia所在路径  
RABBITMQ_LOG_BASE=        //日志所在路径     日志目录：/var/log/rabbitmq/rabbit@[hostname].log
RABBITMQ_PLUGINS_DIR=     //插件所在路径

####  2）rabbitmq.config配置

简单的rabbitmq配置可无需配置文件，只有需要定制复杂应用时，才需要用到配置文件

文件位置：/usr/share/doc/rabbitmq-server-3.7.3/rabbitmq.config.example
复制文件到指定目录：cp /usr/share/doc/rabbitmq-server-3.7.3/rabbitmq.config.example  /etc/rabbitmq/rabbitmq.config

常用配置：
tcp_listerners    #设置rabbimq的监听端口，默认为[5672]。
disk_free_limit     #磁盘低水位线，若磁盘容量低于指定值则停止接收数据，默认值为{mem_relative, 1.0},即与内存相关联1：1，也可定制为多少byte.
vm_memory_high_watermark    #设置内存低水位线，若低于该水位线，则开启流控机制，默认值是0.4，即内存总量的40%。
hipe_compile     #将部分rabbimq代码用High Performance Erlang compiler编译，可提升性能，该参数是实验性，若出现erlang vm segfaults，应关掉。
force_fine_statistics    #该参数属于rabbimq_management，若为true则进行精细化的统计，但会影响性能。
frame_max     #包大小，若包小则低延迟，若包则高吞吐，默认是131072=128K。
heartbeat     #客户端与服务端心跳间隔，设置为0则关闭心跳，默认是600秒。



启动命令：service rabbitmq-server start

启动服务：rabbitmqctl start_app 



#### 2）角色权限操作

##### 用户管理：

1.新增一个用户

rabbitmqctl  add_user  Username  Password

2.删除一个用户

rabbitmqctl  delete_user  Username

3 .修改用户的密码

rabbitmqctl  change_password  Username  Newpasswor

4.查看当前用户列表

rabbitmqctl  list_users

##### 用户角色

用户角色可分为五类，超级管理员, 监控者, 策略制定者, 普通管理者以及其他。

1.超级管理员(administrator)：

可登陆管理控制台(启用management plugin的情况下)，可查看所有的信息，并且可以对用户，策略(policy)进行操作。

2.监控者(monitoring)：

可登陆管理控制台(启用management plugin的情况下)，同时可以查看rabbitmq节点的相关信息(进程数，内存使用情况，磁盘使用情况等)

3.策略制定者(policymaker)：

可登陆管理控制台(启用management plugin的情况下), 同时可以对policy进行管理。但无法查看节点的相关信息(上图红框标识的部分)。

与administrator的对比，administrator能看到这些内容

4.普通管理者(management)

仅可登陆管理控制台(启用management plugin的情况下)，无法看到节点信息，也无法对策略进行管理。

5.其他

无法登陆管理控制台，通常就是普通的生产者和消费者。

###### 设置用户角色的命令为：

rabbitmqctl  set_user_tags  User  Tag

User为用户名， Tag为角色名(对应于上面的administrator，monitoring，policymaker，management，或其他自定义名称)。

也可以给同一用户设置多个角色，例如：rabbitmqctl  set_user_tags  hncscwc  monitoring  policymaker

##### 用户权限

用户权限指的是用户对exchange，queue的操作权限，包括配置权限，读写权限。配置权限会影响到exchange，queue的声明和删除。读写权限影响到从queue里取消息，向exchange发送消息以及queue和exchange的绑定(bind)操作。

例如： 将queue绑定到某exchange上，需要具有queue的可写权限，以及exchange的可读权限；向exchange发送消息需要具有exchange的可写权限；从queue里取数据需要具有queue的可读权限。

1.设置用户权限

rabbitmqctl  set_permissions  -p  VHostPath  User  ConfP  WriteP  ReadP

2.查看(指定hostpath)所有用户的权限信息

rabbitmqctl  list_permissions  [-p  VHostPath]

3.查看指定用户的权限信息

rabbitmqctl  list_user_permissions  User

4.清除用户的权限信息

rabbitmqctl  clear_permissions  [-p VHostPath]  User

##### 虚拟机操作
rabbitmqctl add_vhost  [vhost_name]

rabbitmqctl delete_vhos t[vhsost_name]

rabbitmqctl list_vhost

#### 3.集群搭建

集群是保证可靠性的一种方式，同时可以通过水平扩展以达到增加消息吞吐量能力的目的

#####  普通模式：节点仅有相同的元数据，即队列的结构

1.统一每个节点的erlang.cookie : scp /var/lib/rabbitmq/.erlang.cookie root@node2:/var/lib/rabbitmq

2.rabbitmqctl stop_app   –关掉rabbitmq2服务

3.rabbitmqctl join_cluster rabbit@rabbitmq1 — rabbitmq2加入rabbitmq1, rabbitmq2必须能通过rabbitmq1的主机名ping通rabbitmq1。

4.rabbitmqctl start_app  –启动rabbitmq2服务

##### 镜像模式：消息实体会主动在镜像节点之间实现同步，而不是像普通模式那样，在 consumer 消费数据时临时读取

Usage:
rabbitmqctl [-n <node>] [-t <timeout>] [-q] set_policy [-p <vhost>] [--priority <priority>] [--apply-to <apply-to>] <name> <pattern>  <definition>

name: 策略名称
vhost: 指定vhost, 默认值 /
pattern: 需要镜像的正则
definition: 
	ha-mode: 指明镜像队列的模式，有效值为 all/exactly/nodes
	all：表示在集群所有的节点上进行镜像，无需设置ha-params
	exactly：表示在指定个数的节点上进行镜像，节点的个数由ha-params指定
	nodes：表示在指定的节点上进行镜像，节点名称通过ha-params指定
	ha-params: ha-mode 模式需要用到的参数
	ha-sync-mode: 镜像队列中消息的同步方式，有效值为automatic，manually 自动或手动同步
apply-to: 可选值3个，默认all
	exchanges 表示镜像 exchange (并不知道意义所在)
	queues表示镜像 queue
	all表示镜像 exchange和queue
priority：可选参数，policy的优先级

rabbitmqctl set_policy  --apply-to queues ts "^f|^s" '{"ha-mode":"all","ha-sync-mode":"automatic"}'