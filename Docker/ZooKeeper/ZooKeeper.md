# 镜像下载

```powershell
PS C:\Windows\system32> docker pull zookeeper
Using default tag: latest
latest: Pulling from library/zookeeper
fc7181108d40: Pull complete
73f08ce352c8: Pull complete
eac271a34b40: Pull complete
9ba0eff26192: Pull complete
ac4c9fe65e23: Pull complete
18a36aec0f39: Pull complete
bba2d87ab531: Pull complete
f75afd732baa: Pull complete
Digest: sha256:6e6efbba52ffe5f85358db96a0088a43b582c94f2e5703a0462a10aeeab38667
Status: Downloaded newer image for z
```

# 单机搭建

- **启动容器并添加映射**

```powershell
>> docker run --privileged=true -d --name zookeeper --publish 2181:2181  -d zookeeper:latest
```

> 参数解释：
>
> --privileged：root权限                                                     -d：已守护线程启动
>
> --name：容器的名字                                                       --publish：映射容器端口到本机端口2181

- **查看容器是否启动**

```shell
>> docker container ls
```

# 集群搭建

因为一个一个地启动 ZK 太麻烦了, 所以为了方便起见, 我直接使用 docker-compose 来启动 ZK 集群。首先确保已经安装`docker-compose`.

首先创建一个network

```shell
# docker network create zk-cluster
```

创建一个名为 **docker-compose.yml** 的文件, 其内容如下:

```yaml
zookeeper1:
    image: zookeeper:latest
    container_name: zookeeper1
    net: zk-cluster
    environment:
        - SERVER_ID=1
        - ADDITIONAL_ZOOKEEPER_1=server.1=0.0.0.0:2888:3888
        - ADDITIONAL_ZOOKEEPER_2=server.2=zookeeper2:2888:3888 
        - ADDITIONAL_ZOOKEEPER_3=server.3=zookeeper3:2888:3888
zookeeper2:
    image: zookeeper:latest
    container_name: zookeeper2
    net: zk-cluster
    environment:
        - SERVER_ID=2
        - ADDITIONAL_ZOOKEEPER_1=server.1=zookeeper1:2888:3888
        - ADDITIONAL_ZOOKEEPER_2=server.2=0.0.0.0:2888:3888 
        - ADDITIONAL_ZOOKEEPER_3=server.3=zookeeper3:2888:3888
zookeeper3:
    image: zookeeper:latest
    container_name: zookeeper3
    net: zk-cluster
    environment:
        - SERVER_ID=3
        - ADDITIONAL_ZOOKEEPER_1=server.1=zookeeper1:2888:3888
        - ADDITIONAL_ZOOKEEPER_2=server.2=zookeeper2:2888:3888 
        - ADDITIONAL_ZOOKEEPER_3=server.3=0.0.0.0:2888:3888
```

这个配置文件会告诉 Docker 分别运行三个 zookeeper 镜像, 三个容器使用同一个net：zk-cluster，**SERVER_ID** 和 **ADDITIONAL_ZOOKEEPER** 是搭建 ZK 集群需要设置的两个环境变量, 其中 **SERVER_ID** 表示 ZK 服务的 id, 它是1-255 之间的整数, 必须在集群中唯一. **ADDITIONAL_ZOOKEEPER_1** 是ZK 集群的主机列表. 

接着我们在 docker-compose.yml 当前目录下运行: 

```powershell
# docker-compose up
Starting zookeeper1 ... done
Starting zookeeper2 ... done
Starting zookeeper3 ... done
# docker-compose up -d 后台运行
```

查看当前对应容器IP

```shell
root@ubuntu18:/home/buyilihao# docker inspect zookeeper1|grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.0.3",
root@ubuntu18:/home/buyilihao# docker inspect zookeeper2|grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.0.2",
root@ubuntu18:/home/buyilihao# docker inspect zookeeper3|grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.20.0.4",
```

springboot-dubbo的properties配置文件

```properties
dubbo.registry.address = zookeeper://172.20.0.2:2181?backup=172.20.0.3:2181,172.20.0.4:2182
```



