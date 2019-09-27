# 单机搭建

## 拉取镜像

```powershell
PS C:\Users\buyil> docker search mysql #搜索镜像
PS C:\Users\buyil> docker pull mysql:5.7 #下载镜像
PS C:\Users\buyil> docker image ls #查看镜像
```

## 运行容器

```shell
PS C:\Users\buyil> docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=always -d mysql:5.7
679bedc7c78a2d6860e31a1e5e536a57561e9d30e2e6987f0c288b7f3b6bc565
PS C:\Users\buyil> docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                               NAMES
679bedc7c78a        mysql:5.7           "docker-entrypoint.s鈥?   10 seconds ago      Up 7 seconds        0.0.0.0:3306->3306/tcp, 33060/tcp   mysql
```

>命令说明：
>
>**-p 3306:3306 :** 将容器的3306端口映射到主机的3306端口
>
>**-- name mysql:** 容器的名字mysql
>
>**-e MYSQL_ROOT_PASSWORD=123456：**初始化 root 用户的密码。
>
>**--restart=always**: mysql自启动
>
>**-d **：后台运行
>
>**mysql:5.7**：使用的镜像