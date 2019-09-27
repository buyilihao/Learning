# 单机安装

## 下载镜像

```powershell
# docker search fastdfs
# docker pull season/fastdfs
Digest: sha256:408acdebaa278e8ed875f7c63aa0c7ac8e633cf92f615d8295d279e137217003
Status: Downloaded newer image for season/fastdfs:latest
docker.io/season/fastdfs:latest
```

+ 当前目录创建所需文件夹

```shell
# mkdir -p ./data/tracker

    目录: D:\Learning\Docker\FastDFS\data


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        2019/8/21     21:12                tracker

# mkdir -p ./data/storage

    目录: D:\Learning\Docker\FastDFS\data


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        2019/8/21     21:13                storage

# mkdir -p ./data/store_path

    目录: D:\Learning\Docker\FastDFS\data


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        2019/8/21     21:13                store_path
```

## 创建tracke容器

```shell
# docker run -it -d --name fastdfs-tracker -p 22122:22122 -v D:/Learning/Docker/FastDFS/data/tracker:/fastdfs/tracker/data season/fastdfs tracker
b412512119e403137be6c91a970489c7b0112b725f830ca4af5c2f9a4fadf839
# docker container ls 查看容器是否正常
```

>命令说明：
>
>**-p 3306:3306 :** 将容器的22122端口映射到主机的22122端口
>
>**-- name fastdfs-tracker:** 容器的名字fastdfs-tracker
>
>**-v：**把本地文件夹映射到容器的文件夹
>
>**--net=fastdfs**: 使用网络
>
>**-d **：后台启动

## 创建storage容器

```shell
# docker run -it -d --name fastdfs-storage -v D:/Learning/Docker/FastDFS/data/storage:/fastdfs/storage/data -v D:/Learning/Docker/FastDFS/data/store_path:/fastdfs/store_path season/fastdfs storage
ba243f2aa2e0c59940688ddb1b20f5428461c29dc0dca69c87ee4fc0702f191d
```

+ 拷贝storage.conf出来

```shell
#  docker cp fastdfs-storage:/fdfs_conf/storage.conf .
```

+ 查看fastdfs-tracker的IP

```shell
# docker exec -it fastdfs-tracker bash
root@d9ab5557216b:/# cat /etc/hosts
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.18.0.2      d9ab5557216b
```

+ 修改tracker_server=172.18.0.2:22122，再复制进去

```shell
# docker cp D:/Learning/Docker/FastDFS/storage.conf fastdfs-storage:/fdfs_conf/
```

+ 重启容器，进入容器查看是否运行成功

```shell
# docker restart fastdfs-storage
# docker exec -it fastdfs-storage bash
# fdfs_monitor fdfs_conf/storage.conf
```

出现以下，说明创建成功

```shell
[2019-08-22 12:50:36] DEBUG - base_path=/fastdfs/storage, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

server_count=1, server_index=0

tracker server is 172.17.0.3:22122

group count: 1

Group 1:
group name = group1
disk total space = 153603 MB
disk free space = 60423 MB
trunk free space = 0 MB
storage server count = 1
active server count = 1
storage server port = 23000
storage HTTP port = 8888
store path count = 1
subdir count per path = 256
current write server index = 0
current trunk file id = 0
```

## 创建client容器

```shell
# docker run -it --name fdfs_sh season/fastdfs sh
root@8402358d3603:/# exit
exit #退出容器（退出后容器关闭）
```

拷贝client.conf出来

```shell
# docker cp fdfs_sh:/fdfs_conf/client.conf .
```

修改tracker_server=172.18.0.2:22122，再复制进去

```shell
# docker cp D:/Learning/Docker/FastDFS/client.conf fdfs_sh:/fdfs_conf/
```

启动client容器

```shell
# docker container start fdfs_sh
```

进入client容器

```shell
# docker exec -it fdfs_sh bash
root@8402358d3603:/# cd fdfs_conf/
root@8402358d3603:/fdfs_conf# echo hello world>hello.txt
root@8402358d3603:/fdfs_conf# fdfs_upload_file client.conf hello.txt
group1/M00/00/00/rBEABF1elWeAYP7uAAAADFmwwCQ581.txt #上传成功
```

