# 公共模块

## 新建项目usercenter

### 引入依赖

```xml
<dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>1.18.6</version>
        </dependency>
```

### 暴露的接口

```java
public interface UserCenter {
    /**
     * 单条查询
     * @param id
     * @return
     */
    User findOne(Integer id);

    /**
     * 查询全部
     * @return
     */
    List<User> findAll();
}
```

### 对应的实体类

```java
@Data
public class User implements Serializable {
    private Integer id;
    private String name;
    private Integer age;
}
```

# 服务提供者

## 新建项目server01

### 引入依赖

注意dubbo-springboot的版本号是0.2.0

````xml
<parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.3.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>1.8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.hzbank</groupId>
            <artifactId>usercenter</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.47</version>
        </dependency>
        <dependency>
            <groupId>com.alibaba.boot</groupId>
            <artifactId>dubbo-spring-boot-starter</artifactId>
            <version>0.2.0</version>
        </dependency>
        <dependency>
            <groupId>io.netty</groupId>
            <artifactId>netty-all</artifactId>
            <version>4.1.24.Final</version>
        </dependency>
        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-lang3</artifactId>
            <version>3.7</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>1.18.6</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>2.0.0</version>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.47</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
````

### 暴露接口的实现类

两个实现类，用group区分，注意@Service是dubbo包下的

```java
package com.hzbank.service.impl;

import com.alibaba.dubbo.config.annotation.Service;
import com.hzbank.dao.UserDao;
import com.hzbank.dubbo.entity.User;
import com.hzbank.dubbo.service.UserCenter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.List;

@Service(group = "qq")
@Component
public class QqServiceImpl implements UserCenter {

    @Autowired
    private UserDao userDao;


    @Override
    public User findOne(Integer id) {
        return null;
    }

    @Override
    public List<User> findAll() {
        return userDao.selectAll();
    }
}
```

```java
package com.hzbank.service.impl;

import com.alibaba.dubbo.config.annotation.Service;
import com.hzbank.dao.UserDao;
import com.hzbank.dubbo.entity.User;
import com.hzbank.dubbo.service.UserCenter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;

@Service(group = "wx")
@Component
public class WxServiceImpl implements UserCenter {

    @Autowired
    private UserDao userDao;

    @Value("${spring.application.name}")
    private String applicationName;

    @Override
    public User findOne(Integer id) {
        User user = userDao.selectById(id);
        user.setName(applicationName);
        return user;
    }

    @Override
    public List<User> findAll() {
        return null;
    }
}
```

### Dao接口

```java
package com.hzbank.dao;

import com.hzbank.dubbo.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Mapper
public interface UserDao {

    @Select(value = "select * from user where id=#{id}")
    User selectById(Integer id);

    @Select(value = "select * from user")
    List<User> selectAll();
}
```

### 启动类

服务端要加上@EnableDubbo注解

```java
@SpringBootApplication
@EnableDubbo
public class ServerApplication01 {
    public static void main(String[] args) {
        SpringApplication.run(ServerApplication01.class, args);
    }
}
```

### 配置文件

application.yml

```yaml
server:
  port: 8080

spring:
  application:
    name: server01
  profiles:
    include: mybatis,dubboServer
```

application-dubboServer.yml

```yml
dubbo:
  #注册中心
  registry:
    id: my-registry
    address: zookeeper://127.0.0.1:2181
    client: curator
  #扫包路径
  scan:
    base-packages: com.hzbank.service.impl
  #配置协议 dubbo 端口 20880
  protocol:
    name: dubbo
    port: 20880
    server: netty4
  #运维界面配置
  application:
    name: server
    qos-enable: true
    qos-port: 22222
    qos-accept-foreign-ip: false
```

application-mybatis.yml

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    url: jdbc:mysql://localhost:3306/test?useSSL=false
    username: root
    password: 123456
    type: com.zaxxer.hikari.HikariDataSource
    # springboot2.0 默认整合了hikari数据库连接池
    hikari:
      minimum-idle: 5 # 最小空闲连接数
      maximum-pool-size: 20 # 连接池中最大连接数
      auto-commit: true
      idle-timeout: 30000 # 一个连接idle状态的最大时长（毫秒），超时则被释放（retired），缺省:10分钟
      max-lifetime: 180000 # 一个连接的生命时长（毫秒），超时而且没被使用则被释放（retired），缺省:30分钟
      connection-timeout: 30000 #等待连接池分配连接的最大时长（毫秒），超过这个时长还没可用的连接则发生SQLException， 缺省:30秒
      connection-test-query: SELECT 1
      pool-name: DatebookHikariCP


#show sql
logging:
  level:
    com:
      hzbank:
        redis:
          dao: debug
```

## 新建项目server02

服务端的集群只需修改配置文件的server.port和dubbo协议的port即可

### 配置文件

application-dubboServer.yml

```yml
dubbo:
  #注册中心
  registry:
    id: my-registry
    address: zookeeper://127.0.0.1:2181
    client: curator
  #扫包路径
  scan:
    base-packages: com.hzbank.service.impl
  #配置协议 dubbo 端口 20880
  protocol:
    name: dubbo
    port: 20881
    server: netty4
  #运维界面配置
  application:
    name: server
    qos-enable: false
```

## 新建项目server03

### 配置文件

application-dubboServer.yml

```yaml
dubbo:
  #注册中心
  registry:
    id: my-registry
    address: zookeeper://127.0.0.1:2181
    client: curator
  #扫包路径
  scan:
    base-packages: com.hzbank.service.impl
  #配置协议 dubbo 端口 20880
  protocol:
    name: dubbo
    port: 20882
    server: netty4
  #运维界面配置
  application:
    name: server03
    qos-enable: false
```

# 服务消费者

## 新建项目client

依赖和服务提供者一样

### Controller

```java
package com.hzbank.controller;

import com.alibaba.dubbo.config.annotation.Reference;
import com.hzbank.dubbo.entity.User;
import com.hzbank.dubbo.service.UserCenter;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class UserController {

    @Reference(group = "wx")
    private UserCenter userCenter;

    @GetMapping("findOne/{id}")
    public User findOne(@PathVariable("id") Integer id){
        return userCenter.findOne(id);
    }

    @GetMapping("findAll")
    public List<User> findAll(){
        return userCenter.findAll();
    }
}
```

### 启动类

```java
@SpringBootApplication
public class ClientApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClientApplication.class, args);
    }
}
```

### 配置文件

application.yml

```yaml
server:
  port: 9000

spring:
  profiles:
    include: dubboClient
```

application-dubboClient.yml

```yaml
dubbo:
  registry:
    id: my-registry
    address: zookeeper://127.0.0.1:2181
    client: curator
  application:
    name: client
    qos-enable: false #一个模块开启qos即可，否则netty会报端口占用
  consumer:
    cluster: failover #集群容错策略
    loadbalance: roundrobin #负载均衡策略
```

