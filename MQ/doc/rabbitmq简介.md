###  1.rabbitmq简介

**RabbitMQ**是实现了高级消息队列协议（AMQP）的开源消息代理软件（亦称面向消息的中间件)。开发语言是erlang

特点：

1.除了Qpid，RabbitMQ是唯一一个实现了AMQP标准的消息服务器；

2.可靠性，RabbitMQ的持久化支持，保证了消息的稳定性；

3.高并发，RabbitMQ使用了Erlang开发语言，Erlang是为电话交换机开发的语言，天生自带高并发光环，和高可用特性；

4.集群部署简单，正是应为Erlang使得RabbitMQ集群部署变的超级简单；

5.社区活跃度高；

6.支持多种语言和操作系统



应用场景：

1.系统服务之间的解耦

2.异步消息处理

3.流量削峰

### 2.工作机制

**生产者、消费者和代理**

生产者：消息的创建者，负责创建和推送数据到消息服务器；

消费者：消息的接收方，用于处理数据和确认消息；

代理：就是RabbitMQ本身，用于扮演“快递”的角色，本身不生产消息，只是扮演“快递”的角色。

### 3.rabbitmq的组件

> 1. Connection:连接client与server的tcp连接
> 2. Channel:用于client与server的数据传输，多个Channel可以共用一个Connection
> 3. Exchange:用来接收生产者发送的消息并将这些消息路由给队列,有4个类型：direct，topic，fanout，header
>    + direct类型的exchange，只有这两个routingkey完全相同，exchange才会选择对应的binging进行消息路由。
>    + topic类型exchange的routingkey可以有通配符：'*','#'.其中'*'表示匹配一个单词， '#'则表示匹配没有或者多个单词.
>    + fanout类型exchange的路由规则很简单直接将消息路由到所有绑定的队列中，无须对消息的routingkey进行匹配操作
>    + header类型的exchange和以上三个都不一样，其路由的规则是根据header来判断(键值对)，其中的x-match为特殊的header，可以为all则表示要匹配所有的header，如果为any则表示只要匹配其中的一个header即可。
>
> 4. Binding：用于消息队列和交换器之间的关联
> 5. Queue:用来保存消息直到发送给消费者,消息的容器
> 6. VirtualHost:表示一批交换器、消息队列和相关对象，本质上就是一个 mini 版的 RabbitMQ 服务器，多个vhost是隔离的，实现了多层分离
> 7. Broker:表示消息队列服务器实体

![](image\RabbitMQ\458325-20160107091118450-1592424097.png)

### 4.代码实现

pom文件

```xml
<dependency>
  <groupId>com.rabbitmq</groupId>
  <artifactId>amqp-client</artifactId>
  <version>5.4.3</version>
</dependency>
```



1.初始化连接工厂

``` java
private String userName = "guest";
private String password = "guest";
private String virtualHost = "/";
private String hostName = "tjjhost_a";
private int port = 5672;
private ConnectionFactory connectionFactory = null;
private void initConnectionFactory(){
    connectionFactory = new ConnectionFactory();
    connectionFactory.setUsername(userName);
    connectionFactory.setPassword(password);
    connectionFactory.setVirtualHost(virtualHost);
    //集群不用先设置host和port
    connectionFactory.setHost(hostName);
    connectionFactory.setPort(port);
}
```



2.初始化连接

``` java
private Address[] addresses = new Address[]{
        new Address("tjjhost_a",5672),
        new Address("tjjhost_b", 5673),
        new Address("tjjhost_c", 5672)
};
private Connection connection = null;
private void initConnection(){
	if(null != connectionFactory){
    	try {
            connection = connectionFactory.newConnection();
 //集群           
//          connection = connectionFactory.newConnection(addresses);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

3.获取通道：

``` java
private Channel initChannel(){
        if(null != connection){
            try {
                Channel channel = connection.createChannel();
                return channel;
            } catch (IOException e) {
                e.printStackTrace();
                return null;
            }
        }
 }
```

4.绑定交换机和队列

######   headers交换机:

``` java
private String exchangeName = "headers-test";
private String exchangeType = "headers";
private String queueName = "first";
private Map<String, Object> aHeader = new HashMap();
aHeader.put("id","123");
aHeader.put("name","test");
aHeader.put("x-match", "all");//匹配规则  all:匹配所有  any:匹配任意一个
private void bind(){
	Channel channel = initChannel();
    if(null != channel){
    	try {
            	//交换机
                channel.exchangeDeclare(exchangeName, exchangeType, true);//是否持久化
                //队列
                //durable：true、false true：在服务器重启时，能够存活（持久化）
                //exclusive ：是否为当前连接的专用队列，在连接断开后，会自动删除该队列
                //autodelete：当没有任何消费者使用时，自动删除该队列
                //arguments：高级参数(Map<String, Object> arguments)   
                	//1.x-message-ttl：队列中的所有消息的生存周期
            		//2.x-expires:当队列在指定的时间没有被访问,就会被删除
                	//3.x-max-length:限定队列的消息的最大值长度，超过指定长度将会把最早的几条删除掉
                	//4.x-max-length-bytes:限定队列最大占用的空间大小， 一般受限于内存、磁盘的大小
                    //5.x-dead-letter-exchange:当队列消息长度大于最大长度、或者过期的等，将从队列						中删除的消息推送到指定的交换机中去而不是丢弃掉
                    //6.x-dead-letter-routing-key:将删除的消息推送到指定交换机的指定路由键的队列
                    //7.x-max-priority:优先级队列,优先级更高（数值更大的）的消息先被消费
                    //8.x-queue-mode:先将消息保存到磁盘上，不放在内存中，当消费者开始消费的时候才加                       载到内存中
                channel.queueDeclare(queueName,true, false, false, null);
                //交换机和队列绑定
                channel.queueBind(queueName, exchangeName, "", aHeader);
        } catch (IOException e) {
                e.printStackTrace();
    	}
	}
}
```

###### topic,direct交换机：

``` java
private String exchangeName = "direct-test";//direct-test,topic-test
private String exchangeType = "direct";//direct，topic
private String queueName = "first";
private routkey = "a";//direct:routkey完全匹配，topic：通过routkey匹配符合条件的消息
private void bind(){
	Channel channel = initChannel();
    if(null != channel){
    	try {
                channel.exchangeDeclare(exchangeName, exchangeType, true);//是否持久化
                channel.queueDeclare(queueName,true, false, false, null);
                channel.queueBind(queueName, exchangeName, routkey, null);
        } catch (IOException e) {
                e.printStackTrace();
    	}
	}
}
```



###### fanout交换机：

```java
private String exchangeName = "fanout-test";
private String exchangeType = "fanout";
private String queueName = "first";
private Channel bind(){
	Channel channel = initChannel();
    if(null != channel){
    	try {
                channel.exchangeDeclare(exchangeName, exchangeType, true);//是否持久化
                channel.queueDeclare(queueName,true, false, false, null);
                channel.queueBind(queueName, exchangeName, "", null);
        } catch (IOException e) {
                e.printStackTrace();
            	return null;
    	}
	}
    return channel;
}
```



5.生产者：

``` java
public void sendMessage(String message, String exchangeName, String routkey, Channel channel){
        if(channel != null){
            byte[] bytes = message.getBytes();
            try {
                Map<String, Object> header = new HashMap();
                header.put("name","tjj");
                header.put("id","123");
                //发送消息
                channel.basicPublish(exchangeName, routkey,
                        new AMQP.BasicProperties.Builder().contentType("text/plain")
                                .deliveryMode(2) //持久化的
                                .priority(1) //优先级
                                .headers(header)//headers交换机，需要设置headers
                                .build()
                        ,bytes);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
```



6.消费者

```java
public void initListener(final String queueName){
        boolean autoAck = true;//是否自动确认消息,true自动确认,false 不自动要手动调用
        try {
            final Channel channel = connection.initChannel();
            channel.basicConsume(queueName, autoAck, "myConsumerTag",
                    new DefaultConsumer(channel) {//创建消费者
                        @Override
                        public void handleDelivery(String consumerTag, Envelope envelope,AMQP.BasicProperties properties, byte[] body)throws IOException{
                            long deliveryTag = envelope.getDeliveryTag();//接收标志
                            System.out.println(queueName + "收到消息：" + new String(body));
//                            channel.basicAck(deliveryTag, false);
                        }
                    });
        } catch (IOException e) {
            e.printStackTrace();
        }
}
```

