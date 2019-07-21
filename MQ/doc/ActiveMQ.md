# 引言

**Apache ActiveMQ**是Apache软件基金会所研发的开放源代码消息中间件；由于ActiveMQ是一个纯Java程序，因此只需要操作系统支持Java虚拟机，ActiveMQ便可执行。 

# 特点

1. 将数据从一个应用程序传送到另一个应用程序，或者从软件的一个模块传送到另外一个模块；  

  2. 负责建立网络通信的通道，进行数据的可靠传送。   
  3. 保证数据不重发，不丢失  
  4. 能够实现跨平台操作，能够为不同操作系统上的软件集成技工数据传送服务 

# 安装

安装版本`apache-activemq-5.15.3-bin.tar.gz`，需要Java 8运行环境

```bash
#移动软件到/usr目录下
[root@HzBank usr]# mv apache-activemq-5.15.3-bin.tar.gz /usr
#解压压缩包
[root@HzBank usr]# tar -zxvf apache-activemq-5.15.3-bin.tar.gz
[root@HzBank usr]# cd apache-activemq-5.15.3/bin
#启动activeMQ
[root@HzBank bin]# ./activemq start
INFO: Loading '/usr/apache-activemq-5.15.3//bin/env'
INFO: Using java '/usr/java/latest/bin/java'
INFO: Starting - inspect logfiles specified in logging.properties and log4j.properties to get details
INFO: pidfile created : '/usr/apache-activemq-5.15.3//data/activemq.pid' (pid '75252')
```

在[http://IP:8161/admin](http://114.115.206.18:8161/admin) 打开，默认用户名密码 admin/admin 

![](image\ActiveMQ\1556112238870.png)

# 五种消息类型

 JMS API 定义了5种消息体格式，也叫消息类型，可以使用不同形式发送接收数据并可以兼容现有的消息格式，下面描述这5种类型： 

1. TextMessage：java.lang.String对象，如xml文件内容。
2. MapMessage：key/value键值对的集合，key是String对象，值类型可以是Java任何基本类型。 
3. BytesMessage：字节流。
4. StreamMessage：Java 中的输入输出流。
5. ObjectMessage：Java中的可序列化对象。

另外，还有一种是Message，没有消息体，只有消息头和属性。 

# 与SpringBoot集成

+ 引入依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-activemq</artifactId>
</dependency>

<dependency>
    <groupId>org.apache.activemq</groupId>
    <artifactId>activemq-pool</artifactId>
</dependency>

<!--SpringBoot 2.0版本之后使用pool要引入此依赖-->
<dependency>
    <groupId>org.messaginghub</groupId>
    <artifactId>pooled-jms</artifactId>
</dependency>
```

+ 编写配置文件

```properties
spring.application.name=activeMQ

spring.activemq.broker-url=tcp://HzBank:61616
spring.activemq.user=admin
spring.activemq.password=admin
spring.activemq.in-memory=true
spring.activemq.pool.enabled=true
#最大连接数
spring.activemq.pool.max-connections=10
##空闲时间
spring.activemq.pool.idle-timeout=30s
```

## P2P模式

+ 生产者

```java
package com.hzbank.producer;

import org.apache.activemq.command.ActiveMQQueue;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import javax.jms.Destination;
import java.util.Date;

@Component
public class JmsProducer {

    @Autowired
    private JmsTemplate jmsTemplate;

    Destination destination = new ActiveMQQueue("p2p");

    /**
     * 发送消息
     */
    public void sendMessage(){

        String message="点对点模式测试 "+new Date().toLocaleString();
        jmsTemplate.convertAndSend(destination,message);
        System.out.println("Producer: send "+message);
    }
}
```

+ 消费者

```java
package com.hzbank.consumer;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class JmsConsumer {

    @JmsListener(destination = "p2p")
    public void receive(String message){
        System.out.println("Consumer: reveive  "+message);
    }

}
```

+ 启动类

```java
package com.hzbank;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ActiveMQApplication  {
    public static void main(String[] args) {
        SpringApplication.run(ActiveMQApplication.class,args);
    }
}
```

+ 测试类

```java
package com.hzbank.test;

import com.hzbank.ActiveMQApplication;
import com.hzbank.producer.JmsProducer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(classes = ActiveMQApplication.class)
public class JmsTest {

    @Autowired
    private JmsProducer jmsProducer;

    @Test
    public void send(){
        jmsProducer.sendMessage();
    }
}
```

+ 测试结果

```basic
Producer: send 点对点模式测试 2019-4-24 23:09:13
Consumer: reveive  点对点模式测试 2019-4-24 23:09:13
```

## Topic模式

+ 默认只能发送和接收queue消息，如果要发送和接收topic消息，需要在application.properties文件中加入：

```properties
spring.jms.pub-sub-domain=true
```

+ 生产者

```java
package com.hzbank.producer;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import javax.jms.Topic;
import java.util.Date;

@Component
public class TopicProducer {

    @Autowired
    private JmsTemplate jmsTemplate;

    @Autowired
    private Topic topic;

    public void sendMessage(){
        String message="发布订阅模式测试 "+new Date().toLocaleString();
        jmsTemplate.convertAndSend(topic,message);
        System.out.println("Producer: send "+message);
    }
}

```

+ config配置类

```java
package com.hzbank.config;

import org.apache.activemq.command.ActiveMQTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.jms.Queue;
import javax.jms.Topic;

@Configuration
public class JmsConfig {

    @Bean
    public Topic topic() {
        return new ActiveMQTopic("topic");
    }
}
```

+ 消费者

```java
//消费者1
package com.hzbank.consumer;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class TopicConsumer1 {

    @JmsListener(destination = "topic")
    public void receiver(String msg) {
        System.out.println("Consumer1: reveive "+msg);
    }
}


//消费者2
package com.hzbank.consumer;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class TopicConsumer2 {

    @JmsListener(destination = "topic")
    public void receiver(String msg) {
        System.out.println("Consumer2: reveive "+msg);
    }
}
```

+ 启动类

```basic
不变
```

+ 测试类

```java
package com.hzbank.consumer;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class TopicConsumer2 {

    @JmsListener(destination = "topic")
    public void receiver(String msg) {
        System.out.println("Consumer2: reveive "+msg);
    }
}
```
测试结果

```basic
Producer: send 发布订阅模式测试 2019-4-25 17:25:22

Consumer1: reveive 发布订阅模式测试 2019-4-25 17:25:22
Consumer2: reveive 发布订阅模式测试 2019-4-25 17:25:22
```

