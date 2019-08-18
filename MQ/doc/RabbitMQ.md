

# 一、底层架构

## 1.背景 

RabbitMQ是一个由**erlang**开发的AMQP（Advanced Message Queue ）的开源实现。AMQP 的出现其实也是应了广大人民群众的需求，虽然在同步消息通讯的世界里有很多公开标准（如 COBAR的 IIOP ，或者是 SOAP 等），但是在异步消息处理中却不是这样，只有大企业有一些商业实现（如微软的 MSMQ ，IBM 的 Websphere MQ 等），因此，在 2006 年的 6 月，Cisco 、Redhat、iMatix 等联合制定了 AMQP 的公开标准。

　　RabbitMQ是由RabbitMQ Technologies Ltd开发并且提供商业支持的。该公司在2010年4月被SpringSource（VMWare的一个部门）收购。在2013年5月被并入Pivotal。其实VMWare，Pivotal和EMC本质上是一家的。不同的是VMWare是独立上市子公司，而Pivotal是整合了EMC的某些资源，现在并没有上市。

　　RabbitMQ的官网是http://www.rabbitmq.com

## 2.基础概念 

讲解基础概念的前面，我们先来整体构造一个结构图，这样会方便们更好地去理解RabbitMQ的基本原理。 

![](image\RabbitMQ\458325-20160107091118450-1592424097.png)

通过上面这张应用相结合的结构图既能够清晰的看清楚整体的send Message到Receive Message的一个大致的流程。当然上面有很多名词都相比还没有介绍到，不要着急接下来我们就开始对其进行详细的讲解。 

### **Queue**

   Queue（队列）RabbitMQ的作用是存储消息，队列的特性是先进先出。上图可以清晰地看到Client A和Client B是生产者，生产者生产消息最终被送到RabbitMQ的内部对象Queue中去，而消费者则是从Queue队列中取出数据。可以简化成表示为：

![](image\RabbitMQ\458325-20160107091219153-26270174.png)

生产者Send Message “A”被传送到Queue中，消费者发现消息队列Queue中有订阅的消息，就会将这条消息A读取出来进行一些列的业务操作。这里只是一个消费正对应一个队列Queue，也可以多个消费者订阅同一个队列Queue，当然这里就会将Queue里面的消息平分给其他的消费者，但是会存在一个问题就是如果每个消息的处理时间不同，就会导致某些消费者一直在忙碌中，而有的消费者处理完了消息后一直处于空闲状态，因为前面已经提及到了Queue会平分这些消息给相应的消费者。这里我们就可以使用prefetchCount来限制每次发送给消费者消息的个数。详情见下图所示： 

![](image\RabbitMQ\458325-20160107091257496-665638720.png)

这里的prefetchCount=1是指每次从Queue中发送一条消息来。等消费者处理完这条消息后Queue会再发送一条消息给消费者。 

### **Exchange**

​    我们在开篇的时候就留了一个坑，就是那个应用结构图里面，消费者Client A和消费者Client B是如何知道我发送的消息是给Queue1还是给Queue2，有没有过这个问题，那么我们就来解开这个面纱，看看到底是个什么构造。首先明确一点就是生产者产生的消息并不是直接发送给消息队列Queue的，而是要经过Exchange（交换器），由Exchange再将消息路由到一个或多个Queue，当然这里还会对不符合路由规则的消息进行丢弃掉，这里指的是后续要谈到的Exchange Type。那么Exchange是怎样将消息准确的推送到对应的Queue的呢？那么这里的功劳最大的当属Binding，RabbitMQ是通过Binding将Exchange和Queue链接在一起，这样Exchange就知道如何将消息准确的推送到Queue中去。简单示意图如下所示：

![](image\RabbitMQ\458325-20160107091338246-1623413505.png)

在绑定（Binding）Exchange和Queue的同时，一般会指定一个Binding Key，生产者将消息发送给Exchange的时候，一般会产生一个Routing Key，当Routing Key和Binding Key对应上的时候，消息就会发送到对应的Queue中去。那么Exchange有四种类型，不同的类型有着不同的策略。也就是表明不同的类型将决定绑定的Queue不同，换言之就是说生产者发送了一个消息，Routing Key的规则是A，那么生产者会将Routing Key=A的消息推送到Exchange中，这时候Exchange中会有自己的规则，对应的规则去筛选生产者发来的消息，如果能够对应上Exchange的内部规则就将消息推送到对应的Queue中去。那么接下来就来详细讲解下Exchange里面类型。 

### **Exchange Type** 

#### **fanout**

​        fanout类型的Exchange路由规则非常简单，它会把所有发送到该Exchange的消息路由到所有与它绑定的Queue中。

![](image\RabbitMQ\458325-20160107091426887-423066137.png)

上图所示，生产者（P）生产消息1将消息1推送到Exchange，由于Exchange Type=fanout这时候会遵循fanout的规则将消息推送到所有与它绑定Queue，也就是图上的两个Queue最后两个消费者消费。 

#### **direct**

​        direct类型的Exchange路由规则也很简单，它会把消息路由到那些binding key与routing key完全匹配的Queue中。

![](image\RabbitMQ\458325-20160107091457637-428564110.png)

当生产者（P）发送消息时Rotuing key=booking时，这时候将消息传送给Exchange，Exchange获取到生产者发送过来消息后，会根据自身的规则进行与匹配相应的Queue，这时发现Queue1和Queue2都符合，就会将消息传送给这两个队列，如果我们以Rotuing key=create和Rotuing key=confirm发送消息时，这时消息只会被推送到Queue2队列中，其他Routing Key的消息将会被丢弃。 

#### **topic**

​      前面提到的direct规则是严格意义上的匹配，换言之Routing Key必须与Binding Key相匹配的时候才将消息传送给Queue，那么topic这个规则就是模糊匹配，可以通过通配符满足一部分规则就可以传送。它的约定是：

1. routing key为一个句点号“. ”分隔的字符串（我们将被句点号“. ”分隔开的每一段独立的字符串称为一个单词），如“stock.usd.nyse”、“nyse.vmw”、“quick.orange.rabbit”
2. binding key与routing key一样也是句点号“. ”分隔的字符串
3. binding key中可以存在两种特殊字符“*”与“#”，用于做模糊匹配，其中“*”用于匹配一个单词，“#”用于匹配多个单词（可以是零个）

![](image\RabbitMQ\458325-20160107091636856-880162406.png)

当生产者发送消息Routing Key=F.C.E的时候，这时候只满足Queue1，所以会被路由到Queue中，如果Routing Key=A.C.E这时候会被同是路由到Queue1和Queue2中，如果Routing Key=A.F.B时，这里只会发送一条消息到Queue2中。 

#### **headers**

headers类型的Exchange不依赖于routing key与binding key的匹配规则来路由消息，而是根据发送的消息内容中的headers属性进行匹配。
在绑定Queue与Exchange时指定一组键值对；当消息发送到Exchange时，RabbitMQ会取到该消息的headers（也是一个键值对的形式），对比其中的键值对是否完全匹配Queue与Exchange绑定时指定的键值对；如果完全匹配则消息会路由到该Queue，否则不会路由到该Queue。

$$
Exchange规则 
$$

| 类型名称 | 类型描述                                                     |
| -------- | ------------------------------------------------------------ |
| fanout   | 把所有发送到该Exchange的消息路由到所有与它绑定的Queue中      |
| dierct   | Routing Key==Binding Key                                     |
| topic    | 模糊匹配，主题模式                                           |
| headers  | Exchange不依赖于routing key与binding key的匹配规则来路由消息，而是根据发送的消息内容中的headers属性进行匹配。 |

## 3.基本对象

#### 　　ConnectionFactory、Connection、Channel

　　ConnectionFactory、Connection、Channel都是RabbitMQ对外提供的API中最基本的对象。Connection是RabbitMQ的socket链接，它封装了socket协议相关部分逻辑。ConnectionFactory为Connection的制造工厂。
　　Channel是我们与RabbitMQ打交道的最重要的一个接口，我们大部分的业务操作是在Channel这个接口中完成的，包括定义Queue、定义Exchange、绑定Queue与Exchange、发布消息等。

　　Connection就是建立一个TCP连接，生产者和消费者的都是通过TCP的连接到RabbitMQ Server中的，这个后续会再程序中体现出来。

　　Channel虚拟连接，建立在上面TCP连接的基础上，数据流动都是通过Channel来进行的。为什么不是直接建立在TCP的基础上进行数据流动呢？如果建立在TCP的基础上进行数据流动，建立和关闭TCP连接有代价。频繁的建立关闭TCP连接对于系统的性能有很大的影响，而且TCP的连接数也有限制，这也限制了系统处理高并发的能力。但是，在TCP连接中建立Channel是没有上述代价的。

## 4.可靠性分析

### Introduction

​    有很多人问过我这么一类问题：RabbitMQ如何确保消息可靠？很多时候，笔者的回答都是：说来话长的事情何来长话短说。的确，要确保消息可靠不只是单单几句就能够叙述明白的，包括Kafka也是如此。可靠并不是一个绝对的概念，曾经有人也留言说过类似全部磁盘损毁也会导致消息丢失，笔者戏答：还有机房被炸了也会导致消息丢失。可靠性是一个相对的概念，在条件合理的范围内系统所能确保的多少个9的可靠性。一切尽可能的趋于完美而无法企及于完美。

​    我们可以尽可能的确保RabbitMQ的消息可靠。在详细论述RabbitMQ的消息可靠性之前，我们先来回顾下消息在RabbitMQ中的经由之路。

![](image\RabbitMQ\introduction.png)

如图所示，从AMQP协议层面上来说：

1. 消息先从生产者Producer出发到达交换器Exchange；
2. 交换器Exchange根据路由规则将消息转发对应的队列Queue之上；
3. 消息在队列Queue上进行存储；
4. 消费者Consumer订阅队列Queue并进行消费。

我们对于消息可靠性的分析也从这四个阶段来一一探讨。

### Phase 1

> 消息先从生产者Producer出发到达交换器Exchange

​    消息从生产者发出到达交换器Exchange，在这个过程中可以发生各种情况，生产者客户端发送出去之后可以发生网络丢包、网络故障等造成消息丢失。一般情况下如果不采取措施，生产者无法感知消息是否已经正确无误的发送到交换器中。如果消息在传输到Exchange的过程中发生失败而可以让生产者感知的话，生产者可以进行进一步的处理动作，比如重新投递相关消息以确保消息的可靠性。

​    为此AMQP协议在建立之初就考虑到这种情况而提供了事务机制。RabbitMQ客户端中与事务机制相关的方法有三个：channel.txSelect、channel.txCommit以及channel.txRollback。channel.txSelect用于将当前的信道设置成事务模式，channel.txCommit用于提交事务，而channel.txRollback用于事务回滚。在通过channel.txSelect方法开启事务之后，我们便可以发布消息给RabbitMQ了，如果事务提交成功，则消息一定到达了RabbitMQ中，如果在事务提交执行之前由于RabbitMQ异常崩溃或者其他原因抛出异常，这个时候我们便可以将其捕获，进而通过执行channel.txRollback方法来实现事务回滚。注意这里的RabbitMQ中的事务机制与大多数数据库中的事务概念并不相同，需要注意区分。

   事务确实能够解决消息发送方和RabbitMQ之间消息确认的问题，只有消息成功被RabbitMQ接收，事务才能提交成功，否则我们便可在捕获异常之后进行事务回滚，与此同时可以进行消息重发。但是使用事务机制的话会“吸干”RabbitMQ的性能，那么有没有更好的方法既能保证消息发送方确认消息已经正确送达，又能基本上不带来性能上的损失呢？从AMQP协议层面来看并没有更好的办法，但是RabbitMQ提供了一个改进方案，即**发送方确认机制（publisher confirm）**。

​    生产者将信道设置成confirm（确认）模式，一旦信道进入confirm模式，所有在该信道上面发布的消息都会被指派一个唯一的ID（从1开始），一旦消息被投递到所有匹配的队列之后，RabbitMQ就会发送一个确认（Basic.Ack）给生产者（包含消息的唯一ID），这就使得生产者知晓消息已经正确到达了目的地了。RabbitMQ回传给生产者的确认消息中的deliveryTag包含了确认消息的序号，此外RabbitMQ也可以设置channel.basicAck方法中的multiple参数，表示到这个序号之前的所有消息都已经得到了处理。

![](image\RabbitMQ\publisher-confirm.png)

​    事务机制在一条消息发送之后会使发送端阻塞，以等待RabbitMQ的回应，之后才能继续发送下一条消息。相比之下，发送方确认机制最大的好处在于它是异步的，一旦发布一条消息，生产者应用程序就可以在等信道返回确认的同时继续发送下一条消息，当消息最终得到确认之后，生产者应用便可以通过回调方法来处理该确认消息，如果RabbitMQ因为自身内部错误导致消息丢失，就会发送一条nack（Basic.Nack）命令，生产者应用程序同样可以在回调方法中处理该nack命令。

​    生产者通过调用channel.confirmSelect方法（即Confirm.Select命令）将信道设置为confirm模式，之后RabbitMQ会返回 Confirm.Select-Ok命令表示同意生产者将当前信道设置为confirm模式。所有被发送的后续消息都被ack或者nack一次，不会出现一条消息即被ack又被nack的情况。并且RabbitMQ也并没有对消息被confirm的快慢做任何保证。

![](image\RabbitMQ\confirm-select.png)

​    事务机制和publisher confirm机制两者是互斥的，不能共存。如果企图将已开启事务模式的信道再设置为publisher confirm模式，RabbitMQ会报错：{amqp_error, precondition_failed, "cannot switch from tx to confirm mode", 'confirm.select'}，或者如果企图将已开启publisher confirm模式的信道在设置为事务模式的话，RabbitMQ也会报错：{amqp_error, precondition_failed, "cannot switch from confirm to tx mode", 'tx.select' }。

​    事务机制和publisher confirm机制确保的是消息能够正确的发送至RabbitMQ，这里的“发送至RabbitMQ”的含义是指消息被正确的发往至RabbitMQ的交换器，如果此交换器没有匹配的队列的话，那么消息也将会丢失。所以在使用这两种机制的时候要确保所涉及的交换器能够有匹配的队列。更进一步的讲，发送方要配合mandatory参数或者备份交换器一起使用来提高消息传输的可靠性。

### Phase 2

> 交换器Exchange根据路由规则将消息转发对应的队列Queue之上

​    **mandatory**(强制的)和**immediate**是channel.basicPublish方法中的两个参数，它们都有当消息传递过程中不可达目的地时将消息返回给生产者的功能。而RabbitMQ提供的备份交换器（Alternate Exchange）可以将未能被交换器路由的消息（没有绑定队列或者没有匹配的绑定）存储起来，而不用返回给客户端。

​    RabbitMQ 3.0版本开始去掉了对于immediate参数的支持，对此RabbitMQ官方解释是：immediate参数会影响镜像队列的性能，增加代码复杂性，建议采用TTL和DLX的方法替代。所以本文只简单介绍mandatory和备份交换器。

​    当mandatory参数设为true时，交换器无法根据自身的类型和路由键找到一个符合条件的队列的话，那么RabbitMQ会调用Basic.Return命令将消息返回给生产者。当mandatory参数设置为false时，出现上述情形的话，消息直接被丢弃。 那么生产者如何获取到没有被正确路由到合适队列的消息呢？这时候可以通过调用channel.addReturnListener来添加ReturnListener监听器实现。使用mandatory参数的关键代码如下所示：

```java
channel.basicPublish(EXCHANGE_NAME, "", true, MessageProperties.PERSISTENT_TEXT_PLAIN, "mandatory test".getBytes());
channel.addReturnListener(new ReturnListener() {
   public void handleReturn(int replyCode, String replyText, String exchange, String routingKey, AMQP
           .BasicProperties basicProperties, byte[] body) throws IOException {
       String message = new String(body);
       System.out.println("Basic.Return返回的结果是：" + message);
   }
});
```

上面代码中生产者没有成功的将消息路由到队列，此时RabbitMQ会通过Basic.Return返回“mandatory test”这条消息，之后生产者客户端通过ReturnListener监听到了这个事件，上面代码的最后输出应该是“Basic.Return返回的结果是：mandatory test”。

​    生产者可以通过ReturnListener中返回的消息来重新投递或者其它方案来提高消息的可靠性。

​    **备份交换器**，英文名称Alternate Exchange，简称AE，或者更直白的可以称之为“备胎交换器”。生产者在发送消息的时候如果不设置mandatory参数，那么消息在未被路由的情况下将会丢失，如果设置了mandatory参数，那么需要添加ReturnListener的编程逻辑，生产者的代码将变得复杂化。如果你不想复杂化生产者的编程逻辑，又不想消息丢失，那么可以使用备份交换器，这样可以将未被路由的消息存储在RabbitMQ中，再在需要的时候去处理这些消息。 可以通过在声明交换器（调用channel.exchangeDeclare方法）的时候添加alternate-exchange参数来实现，也可以通过策略的方式实现。如果两者同时使用的话，前者的优先级更高，会覆盖掉Policy的设置。

​    参考下图，如果此时我们发送一条消息到normalExchange上，当路由键等于“normalKey”的时候，消息能正确路由到normalQueue这个队列中。如果路由键设为其他值，比如“errorKey”，即消息不能被正确的路由到与normalExchange绑定的任何队列上，此时就会发送给myAe，进而发送到unroutedQueue这个队列。

![](image\RabbitMQ\alternate exchange.png)

备份交换器其实和普通的交换器没有太大的区别，为了方便使用，建议设置为fanout类型，如若读者想设置为direct或者topic的类型也没有什么不妥。需要注意的是消息被重新发送到备份交换器时的路由键和从生产者发出的路由键是一样的。备份交换器的实质就是原有交换器的一个“备胎”，所有无法正确路由的消息都发往这个备份交换器中，可以为所有的交换器设置同一个AE，不过这里需要提前确保的是AE已经正确的绑定了队列，最好类型也是fanout的。如果备份交换器和mandatory参数一起使用，那么mandatory参数无效。

###  Phase 3

> 消息在队列Queue上进行存储

​    mandatory或者AE可以让消息在路由到队列之前得到极大的可靠性保障，但是消息存入队列之后的可靠性又如何保证？

​    首先是持久化。持久化可以提高队列的可靠性，以防在异常情况（重启、关闭、宕机等）下的数据丢失。队列的持久化是通过在声明队列时将durable参数置为true实现的，如果队列不设置持久化，那么在RabbitMQ服务重启之后，相关队列的元数据将会丢失，此时数据也会丢失。正所谓“皮之不存，毛将焉附”，队列都没有了，消息又能存在哪里呢？队列的持久化能保证其本身的元数据不会因异常情况而丢失，但是并不能保证内部所存储的消息不会丢失。要确保消息不会丢失，需要将其设置为持久化。通过将消息的投递模式（BasicProperties中的deliveryMode属性）设置为2即可实现消息的持久化。

​    设置了**队列和消息的持久化**，当RabbitMQ服务重启之后，消息依旧存在。单单只设置队列持久化，重启之后消息会丢失；单单只设置消息的持久化，重启之后队列消失，既而消息也丢失。单单设置消息持久化而不设置队列的持久化显得毫无意义。

> 1. 队列持久化需要在声明队列时添加参数 durable=True，这样在rabbitmq崩溃时也能保存队列
> 2. 仅仅使用durable=True ，只能持久化队列，不能持久化消息
> 3. 消息持久化需要在消息生成时，添加参数 properties=pika.BasicProperties(delivery_mode=2)

在持久化的消息正确存入RabbitMQ之后，还需要有一段时间（虽然很短，但是不可忽视）才能存入磁盘之中。RabbitMQ并不会为每条消息都做同步存盘（调用内核的fsync6方法）的处理，可能仅仅保存到操作系统缓存之中而不是物理磁盘之中。如果在这段时间内RabbitMQ服务节点发生了宕机、重启等异常情况，消息保存还没来得及落盘，那么这些消息将会丢失。

​    如果在Phase1中采用了事务机制或者publisher confirm机制的话，服务端的返回是在消息落盘之后执行的，这样可以进一步的提高了消息的可靠性。但是即便如此也无法避免单机故障且无法修复（比如磁盘损毁）而引起的消息丢失，这里就需要引入**镜像队列**。镜像队列相当于配置了副本，绝大多数分布式的东西都有多副本的概念来确保HA。在镜像队列中，如果主节点（master）在此特殊时间内挂掉，可以自动切换到从节点（slave），这样有效的保证了高可用性，除非整个集群都挂掉。虽然这样也不能完全的保证RabbitMQ消息不丢失（比如机房被炸。。。），但是配置了镜像队列要比没有配置镜像队列的可靠性要高很多，在实际生产环境中的关键业务队列一般都会设置镜像队列。

### Phase 4 

> 消费者Consumer订阅队列Queue并进行消费

进一步的从消费者的角度来说，如果在消费者接收到相关消息之后，还没来得及处理就宕机了，这样也算数据丢失。

​    为了保证消息从队列可靠地达到消费者，RabbitMQ提供了**消息确认机制**（message acknowledgement）。消费者在订阅队列时，可以指定autoAck参数，当autoAck等于false时，RabbitMQ会等待消费者显式地回复确认信号后才从内存（或者磁盘）中移去消息（实质上是先打上删除标记，之后再删除）。当autoAck等于true时，RabbitMQ会自动把发送出去的消息置为确认，然后从内存（或者磁盘）中删除，而不管消费者是否真正的消费到了这些消息。

​    采用消息确认机制后，只要设置autoAck参数为false，消费者就有足够的时间处理消息（任务），不用担心处理消息过程中消费者进程挂掉后消息丢失的问题，因为RabbitMQ会一直等待持有消息直到消费者显式调用Basic.Ack命令为止。

​    当autoAck参数置为false，对于RabbitMQ服务端而言，队列中的消息分成了两个部分：一部分是等待投递给消费者的消息；一部分是已经投递给消费者，但是还没有收到消费者确认信号的消息。如果RabbitMQ一直没有收到消费者的确认信号，并且消费此消息的消费者已经断开连接，则RabbitMQ会安排该消息重新进入队列，等待投递给下一个消费者，当然也有可能还是原来的那个消费者。

​    RabbitMQ不会为未确认的消息设置过期时间，它判断此消息是否需要重新投递给消费者的唯一依据是消费该消息的消费者连接是否已经断开，这么设计的原因是RabbitMQ允许消费者消费一条消息的时间可以很久很久。

​    如果消息消费失败，也可以调用Basic.Reject或者Basic.Nack来拒绝当前消息而不是确认，如果只是简单的拒绝那么消息会丢失，需要将相应的requeue参数设置为true，那么RabbitMQ会重新将这条消息存入队列，以便可以发送给下一个订阅的消费者。如果requeue参数设置为false的话，RabbitMQ立即会把消息从队列中移除，而不会把它发送给新的消费者。

​    还有一种情况需要考虑：requeue的消息是存入队列头部的，即可以快速的又被发送给消费，如果此时消费者又不能正确的消费而又requeue的话就会进入一个无尽的循环之中。对于这种情况，笔者的建议是在出现无法正确消费的消息时不要采用requeue的方式来确保消息可靠性，而是重新投递到新的队列中，比如设定的死信队列中，以此可以避免前面所说的死循环而又可以确保相应的消息不丢失。对于死信队列中的消息可以用另外的方式来消费分析，以便找出问题的根本。

**配置文件**

```yaml
spring:
  application:
    name: rabbitmq
  rabbitmq: #rabbitmq配置文件
    host: 192.168.88.129
    port: 5672
    username: admin
    password: 123456
    publisher-confirms: true #发布确认 生产者发送消息到Exchange时生效
    publisher-returns: true #发布返回 Exchange发送消息到Queue时生效
    listener:
      simple:
        acknowledge-mode: manual #消息确认接收 none(不确认),manual(手动确认),auto(自动确认)。Queue发送消息到消费者时生效
```



# 二、RabbitMQ安装

## 安装Erlang

**安装编译工具**

```bash
yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel1
```

1. **下载erlang**

官方下载地址：<http://erlang.org/download/otp_src_18.3.tar.gz>

```bash
wget   http://erlang.org/download/otp_src_18.3.tar.gz
```

2. **安装** 

```bash
#解压
tar xvf otp_src_18.3.tar.gz
cd otp_src_18.3

#配置 '--prefix'指定的安装目录
./configure --prefix=/usr/local/erlang --with-ssl -enable-threads -enable-smmp-support -enable-kernel-poll --enable-hipe --without-javac

#安装
make && make install
```

3. **配置erlang环境变量** 

```bash
vim /etc/profile

#在文件末尾添加下面代码 'ERLANG_HOME'等于上一步'--prefix'指定的目录
ERLANG_HOME=/usr/local/erlang
PATH=$ERLANG_HOME/bin:$PATH
export ERLANG_HOME
export PATH

#使环境变量生效
source /etc/profile

#输入命令检验是否安装成功
erl
#如下输出表示安装成功
[root@HzBank ~]# erl
Erlang/OTP 18 [erts-7.3] [source] [64-bit] [async-threads:10] [hipe] [kernel-poll:false]

Eshell V7.3  (abort with ^G)
1> 
```

## 安装RabbitMQ

1. **下载RabbitMQ**

官方下载地址<http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server-generic-unix-3.6.1.tar.xz>

2. **安装** 

   安装XZ解压工具

```bash
#下载xz软件包
wget --no-check-certificate https://tukaani.org/xz/xz-5.2.3.tar.gz

#解压压缩包
tar xzvf xz-5.2.3.tar.gz

#指定安装目录
cd xz-5.2.3
./configure --prefix=/opt/gnu/xz

#安装
make && make install 

#修改环境变量
vim /etc/profile
#设置环境变量，在 export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL 一行的上面添加如下内容:
export XZ_HOME=/opt/gnu/xz
export PATH=$XZ_HOME/bin:$PATH

#使环境变量生效
source /etc/profile
```

**RabbitMQ3.6版本无需make、make install 解压就可以用**

```bash
#解压rabbitmq，官方给的包是xz压缩包，所以需要使用xz命令
xz -d rabbitmq-server-generic-unix-3.6.1.tar.xz

#xz解压后得到.tar包，再用tar命令解压
tar -xvf rabbitmq-server-generic-unix-3.6.1.tar

#移动目录 看个人喜好
cp -rf ./rabbitmq_server-3.6.1 /usr/local/
cd /usr/local/

#修改文件夹名
mv rabbitmq_server-3.6.1 rabbitmq-3.6.1

#开启管理页面插件
cd ./rabbitmq-3.6.1/sbin/
./rabbitmq-plugins enable rabbitmq_management
```

3. **启动** 

```bash
#启动命令，该命令ctrl+c后会关闭服务
./rabbitmq-server

#在后台启动Rabbit
./rabbitmq-server -detached

#关闭服务
./rabbitmqctl stop

#关闭服务(kill) 找到rabbitmq服务的pid   [不推荐]
ps -ef|grep rabbitmq
kill -9 ****
```

4. **添加管理员账号** 

```bash
#进入RabbitMQ安装目录
cd /usr/local/rabbitmq-3.6.1/sbin

#需要先开启服务

#添加用户
#rabbitmqctl add_user Username Password
./rabbitmqctl add_user rabbitadmin 123456

#分配用户标签
#./rabbitmqctl set_user_tags User Tag
#[administrator]:管理员标签
./rabbitmqctl set_user_tags rabbitadmin administrator
```

## **登录管理界面** 

1. 浏览器输入地址：http://ip:15672/  输入用户名和密码（默认都是guest）

# 三、SpringBoot整合

## P2P模式

+ 在mq中简单模式是一种最为基本的mq的使用，这个只是用到我们上面的三种名词，即消费者、生产者和队列，channel不管是哪个模式都必须得有的。 简单模式的工作特点，其实就是是生成者直接将消息发送给队列，消费者直接从队列取消息，中间没有其他的东西，并且1对1的。 

![](image/RabbitMQ/easyModel.png)

+ 引入依赖

```xml
<dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    
    	<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
        </dependency>
    </dependencies>
```

+ yml配置文件，配置关于RabbitMQ的连接和用户信息 

```yaml
spring:
  application:
    name: rabbitmq
  rabbitmq: #rabbitmq配置文件
    host: 192.168.88.129
    port: 5672
    username: admin
    password: 123456
```

- 创建消息生产者`Sender`。通过注入`AmqpTemplate`接口的实例来实现消息的发送，`AmqpTemplate`接口定义了一套针对AMQP协议的基础操作。在Spring Boot中会根据配置来注入其具体实现。在该生产者，我们会产生一个字符串，并发送到名为`hello`的队列中。

```java
@Component
public class EasySender {

    @Autowired
    private AmqpTemplate template;

    public void send(){
        String content = "RabbitMQ " + new Date().toLocaleString();
        System.err.println("Sender："+content);
        template.convertAndSend("hello",content);
    }
}
```

+ 创建消息消费者`Receiver`。通过`@RabbitListener`注解定义该类对`hello`队列的监听，并用`@RabbitHandler`注解来指定对消息的处理方法。所以，该消费者实现了对`hello`队列的消费，消费操作为输出消息的字符串内容。

```java
@Component
@RabbitListener(queues = "hello")
public class HelloReceiver {

    @RabbitHandler
    public void process(String hello) {
        System.err.println("Receiver："+hello);
    }
}
```

+ 创建RabbitMQ的配置类`RabbitConfig`，用来配置队列、交换器、路由等高级信息。这里我们以入门为主，先以最小化的配置来定义，以完成一个基本的生产和消费过程。

```java
@Configuration
public class RabbitConfig {

    @Bean
    public Queue heloQueue() {
        return new Queue("hello");
    }
}
```

+ 创建应用主类 

```java
@SpringBootApplication
public class RabbitMQApplication {
    public static void main(String[] args) {
        SpringApplication.run(RabbitMQApplication.class,args);
    }
}
```

+ 创建单元测试类，用来调用消息生产 

```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(classes = RabbitMQApplication.class)
public class RabbitMQApplicationTest {

    @Autowired
    private Sender sender;

    @Test
    public void hello() throws Exception {
        sender.send();
    }
}
```

完成程序编写之后，下面开始尝试运行。首先确保RabbitMQ Server已经开始，然后进行下面的操作：

- 启动应用主类，从控制台中，我们看到如下内容，程序创建了一个访问`ip:5672`中`RabbitMQ`的连接。

```java
Created new connection: rabbitConnectionFactory#797cf65c:0/SimpleConnection@63b1d4fa [delegate=amqp://admin@192.168.88.129:5672/, localPort= 9532]
```

同时，我们通过RabbitMQ的控制面板，可以看到Connection和Channels中包含当前连接的条目。

- 运行单元测试类，我们可以看到控制台中输出下面的内容，消息被发送到了RabbitMQ Server的`hello`队列中。

```java
Sender：RabbitMQ 2019-3-25 17:43:37
```

- 切换到应用主类的控制台，我们可以看到类似如下输出，消费者对`hello`队列的监听程序执行了，并输出了接受到的消息信息。

```java
Receiver：RabbitMQ 2019-3-25 17:43:37
```

## Work模式

其实工作模式，可以理解为简单模式的升级版，他是允许一对多的方式。 

![](image\RabbitMQ\workModel.png)

多个消费者去消费消息的时候，默认的是轮询模式。 

+ Secnder不变，Receiver消费者设置两个

```java
@Component
@RabbitListener(queues = "rabbitMQ")
public class RabbitMQReceiver {

    @RabbitHandler
    public void process(String message){
        System.err.println("Receiver 2:"+message);
    }
}

@Component
@RabbitListener(queues = "hello")
public class HelloReceiver {

    @RabbitHandler
    public void process(String hello) {
        System.err.println("Receiver 1："+hello);
    }
}
```

+ 使用测试类测试结果：默认轮询策略

```java
Receiver 1：RabbitMQ 2019-3-26 20:52:21
Receiver 2: RabbitMQ 2019-3-26 20:52:33
Receiver 1：RabbitMQ 2019-3-26 20:52:46
Receiver 2: RabbitMQ 2019-3-26 20:53:00
Receiver 1：RabbitMQ 2019-3-26 20:53:15
```

## Fanout模式

广播模式，即Exchange Type=fanout，给Fanout交换机发送消息，绑定了这个交换机的所有队列都收到这个消息。不是通过routingKey来使队列和交互机连接，直接通过交换机和队列绑定。  

![](image\RabbitMQ\fanoutModel.png)

x表示的就是我们之前所说的交换机，生产者并不是将消息直接发送给队列的，而是通过交换机，然后通过交换机绑定队列 。类似于公众号，生产者其实就可以理解为微信的公众号，然后消费者可以理解为用户，然后关注可以理解为用户绑定的队列。这样你发送东西的时候，你会将数据发送到你粉丝的队列中，然后不同的粉丝通过不同的队列去取数据，这样就能达到公众号的效果。 

+ RabbitMQ的配置类`RabbitConfig`

```java
@Configuration
public class RabbitConfig {

    //创建两个队列
    @Bean
    public Queue heloQueue() {
        return new Queue("hello");
    }

    @Bean
    public Queue rabbitQueue(){
        return new Queue("rabbitMQ");
    }

    //创建一个fanout的交换机
    @Bean
    public FanoutExchange fanoutExchange() {
        return new FanoutExchange("fanoutExchange");
    }

    //将交换机和队列绑定
    @Bean
    public Binding bindFanout1(Queue heloQueue,FanoutExchange fanoutExchange) {
        return BindingBuilder.bind(heloQueue).to(fanoutExchange);
    }

    @Bean
    public Binding bindFanout2(Queue rabbitQueue,FanoutExchange fanoutExchange) {
        return BindingBuilder.bind(rabbitQueue).to(fanoutExchange);
    }
}
```

+ Sender生产者

```java
@Component
public class FanoutSender {
    @Autowired
    private AmqpTemplate template;

    public void send(){
        String content = "RabbitMQ" + new Date().toLocaleString();
        System.err.println("Sender："+content);
        //第一个是交换机名字，第二个是模式类型，第三个是消息内容
        template.convertAndSend("fanoutExchange","fanout",content);
    }
}
```

+ Receiver消费者

```java
@Component
@RabbitListener(queues = "rabbitMQ")
public class RabbitMQReceiver {

    @RabbitHandler
    public void process(String message){
        System.err.println("Receiver 2:"+message);
    }
}

@Component
@RabbitListener(queues = "hello")
public class HelloReceiver {

    @RabbitHandler
    public void process(String hello) {
        System.err.println("Receiver 1："+hello);
    }
}
```

+ 使用测试类测试结果：两个消费者都能接受到

```java
Receiver 2: RabbitMQ 2019-3-26 21:29:46
Receiver 1：RabbitMQ 2019-3-26 21:29:46

Receiver 1：RabbitMQ 2019-3-26 21:30:09
Receiver 2: RabbitMQ 2019-3-26 21:30:09
```

## Routing模式

路由模式，direct路由器背后的路由算法很简单：只有当消息的路由键routing key与队列的绑定键binding key完全匹配时，该消息才会进入该队列。 

![](image\RabbitMQ\routingModel.png)

从这个图可以看到交换机和每一个队列中间都有个连线，这个连线都有一个值，其实这个值就是routingKey，而这个连线就相当于绑定，通过routingKey将交换机与队列进行绑定，这样的话，我们可以设置什么样的数据发给c1，什么样的数据发送给c2，只要设置相应的routingKey就能到达我们的要求

+ RabbitMQ的配置类`RabbitConfig`

```java
public class RabbitConfig {

    private static String EXCHANGE_NAME = "directExchange";

    //创建两个队列
    @Bean
    public Queue helloQueue() {
        return new Queue("hello");
    }

    @Bean
    public Queue rabbitQueue(){
        return new Queue("rabbitMQ");
    }

    //创建一个direct类型的交换机
    @Bean
    public DirectExchange directExchange() {
        return new DirectExchange(EXCHANGE_NAME);
    }

    //将交换机和队列绑定
    @Bean
    public Binding bindDirect(Queue helloQueue,DirectExchange directExchange) {
        //routing key is hello
        return BindingBuilder.bind(helloQueue).to(directExchange).with("hello");
    }

    @Bean
    public Binding bindDirect1(Queue helloQueue,DirectExchange directExchange) {
        //routing key is world
        return BindingBuilder.bind(helloQueue).to(directExchange).with("world");
    }

    @Bean
    public Binding bindDirect3(Queue rabbitQueue,DirectExchange directExchange) {
        //routing key is rabbitMQ
        return BindingBuilder.bind(rabbitQueue).to(directExchange).with("rabbitMQ");
    }
}
```

+ Sender发送者

```java
@Component
public class DirectSender {

    private static String EXCHANGE_NAME = "directExchange";

    @Autowired
    private AmqpTemplate template;

    String content = "RabbitMQ " + new Date().toLocaleString();

    public void sendHello(){

        System.err.println("Sender："+content);
        //第一个是交换机的名称，第二个是routingKey，第三个是消息。
        template.convertAndSend(EXCHANGE_NAME,"hello",content+" Hello");
    }

    public void sendWorld(){
        System.err.println("Sender："+content);
        //第一个是交换机的名称，第二个是routingKey，第三个是消息。
        template.convertAndSend(EXCHANGE_NAME,"world",content+" World");
    }

    public void sendRabbitMQ(){
        System.err.println("Sender："+content);
        //第一个是交换机的名称，第二个是routingKey，第三个是消息。
        template.convertAndSend(EXCHANGE_NAME,"rabbitMQ",content+" RabbitMQ");
    }
}
```

+ Receiver消费者

```java
@Component
@RabbitListener(queues = "rabbitMQ")
public class RabbitMQReceiver {

    @RabbitHandler
    public void process(String message){
        System.err.println("RabbitMQ Receiver 2: "+message);
    }
}

@Component
@RabbitListener(queues = "hello")
    public class HelloReceiver {

    @RabbitHandler
    public void process(String hello) {
        System.err.println("Hello World Receiver 1："+hello);
    }
}
```

+ 测试类

```java
	@Autowired
    private DirectSender directSender;

    @Test
    public void directSender()throws Exception {
//        directSender.sendHello();
//        directSender.sendWorld();
        directSender.sendRabbitMQ();
    }
```

+ 测试结果：根据routing key和binding key发送和接受

```java
Hello World Receiver 1：RabbitMQ 2019-3-27 18:08:10 Hello
Hello World Receiver 1：RabbitMQ 2019-3-27 18:08:41 World
RabbitMQ Receiver 2: RabbitMQ 2019-3-27 18:09:12 RabbitMQ
```

## Topic模式

主题模式，这种模式下需要RouteKey，客户端要提前绑定Exchange与Queue ，如果Exchange没有发现能够与RouteKey匹配的Queue，则会抛弃此消息 。

客户端在进行绑定时，要提供一个该队列“感兴趣”的主题，如“#.log.#”表示该队列关心所有涉及log的消息(一个RouteKey为”MQ.log.error”的消息会被转发到该队列)。“#”表示0个或若干个关键字，“*”(星号)表示一个关键字。如“log.*”能与“log.warn”匹配，无法与“log.warn.timeout”匹配；但是“log.#”能与上述两者匹配。

![](image\RabbitMQ\topicModel.png)  

+ RabbitMQ的配置类`RabbitConfig`

```java
@Configuration
public class RabbitConfig {

    private static String TOPIC_EXCHANGE_NAME = "topicExchange";

    //创建两个队列
    @Bean
    public Queue topicQueue() {
        return new Queue("topic");
    }

    @Bean
    public Queue rabbitQueue(){
        return new Queue("rabbitMQ");
    }

    //创建一个topic类型的交换机
    @Bean
    public TopicExchange topicExchange(){
        return new TopicExchange(TOPIC_EXCHANGE_NAME);
    }

    //将交换机和队列绑定
    @Bean
    public Binding bindTopic(Queue topicQueue,TopicExchange topicExchange) {
        return BindingBuilder.bind(topicQueue).to(topicExchange).with("*.orange.*");
    }

    @Bean
    public Binding bindTopic1(Queue rabbitQueue,TopicExchange topicExchange) {
        return BindingBuilder.bind(rabbitQueue).to(topicExchange).with("*.*.rabbit");
    }

    @Bean
    public Binding bindTopic2(Queue rabbitQueue,TopicExchange topicExchange) {
        return BindingBuilder.bind(rabbitQueue).to(topicExchange).with("lazy.#");
    }
}
```

- Sender发送者

```java
@Component
public class TopicSender {
    private static String EXCHANGE_NAME = "topicExchange";

    @Autowired
    private AmqpTemplate template;

    public void sender(String routingKey){
        String content = " RabbitMQ " + new Date().toLocaleString();
        System.err.println("Sender：routingKey="+routingKey+content);
        //第一个参数是交换机，第二个参数是routingKey,第三个参数是要发送的消息,支持实体对象
        template.convertAndSend(EXCHANGE_NAME,routingKey,content);
    }
}
```

- Receiver消费者

```java
@Component
@RabbitListener(queues = "rabbitMQ")
public class RabbitMQReceiver {

    @RabbitHandler
    public void process(String message){
        System.err.println("RabbitMQ Receiver 2: "+message);
    }
}

@Component
@RabbitListener(queues="topic")
public class TopicReceiver {

    @RabbitHandler
    public void process(String topic){
        System.err.println("Topic Receiver 3: "+topic);
    }

}
```

- 测试结果：根据routing key和binding key发送和接受

```java
Sender：routingKey=quick.orange.rabbit RabbitMQ 2019-3-27 23:20:09;
//队列3和队列2都能收到
RabbitMQ Receiver 2:  RabbitMQ 2019-3-27 23:20:09
Topic Receiver 3:  RabbitMQ 2019-3-27 23:20:09;

Sender：routingKey=quick.yellow.fox RabbitMQ 2019-3-27 23:21:36;
//只有队列3能收到
Topic Receiver 3:  RabbitMQ 2019-3-27 23:21:36;

Sender：routingKey=quick.orange.rabbit RabbitMQ 2019-3-27 23:16:33;
//只有队列2能收到
RabbitMQ Receiver 2:  RabbitMQ 2019-3-27 23:16:33

Sender：routingKey=quick.yellow.fox RabbitMQ 2019-3-27 22:48:43;
//该消息会被丢弃

Sender：routingKey=lazy.quick.yellow.fox RabbitMQ 2019-3-27 23:22:53;
//只有队列2能收到
RabbitMQ Receiver 2:  RabbitMQ 2019-3-27 23:22:53

```



