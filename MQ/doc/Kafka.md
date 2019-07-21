# Kafka架构

## 架构图

![kafkacluster](image\Kafka\kafkacluster.png)

## 基本概念

- kafka以topic为单位管理Record
- 一则Record就是一个消息，通常包含key,value,timestamp（时间戳）

- **Broker**:Kafka 集群包含一个或多个服务器，这种服务器被称为 broker
- **Partition:**物理上的概念，每个 Topic 包含一个或多个 Partition.

## Topic & 日志关系

- 每一个分区中的record都已一个不可变的id序列，从0~n，值大小表示数据进入分区的顺序。也通常将id称为该Record在分区中的位置offset ；Kafka不同于其他传统消息队列（消息一旦消费后，立即删除，传统MQ消息无法重复消费），是通过日志的过期时间log.retention.hours=168 参数配置服务器存储消息的时间，一旦数据过期，无论该Record是否被消费，该记录都会被清除。

  ![img](image\Kafka\log&topic.png)

- Kafka需要维持的元数据只有一个–消费消息在Partition中的offset值，Consumer每消费一个消息，offset就会加1。其实消息的状态完全是由Consumer控制的，Consumer可以跟踪和重设这个offset值，这样的话Consumer就可以读取任意位置的消息。

  ![img](image\Kafka\partion_consumer.png)

## 分区&消费者

- High-level API封装了对集群中一系列broker的访问，可以透明的消费一个topic。它自己维持了已消费消息的状态，即每次消费的都是下一个消息。High-level API还支持以组的形式消费topic，如果consumers有同一个组名，那么kafka就相当于一个队列消息服务，而各个consumer均衡的消费相应partition中的数据。若consumers有不同的组名，那么此时kafka就相当与一个广播服务，会把topic中的所有消息广播到每个consumer。

  ![img](image\Kafka\consumer&consumer.png)

# Kafka安装

- 安装JDK，并且配置JAVA_HOME
- 必须配置主机名和IP映射关系
- 同步时钟
- 安装zookeeper集群（并且正常启动）
- 安装配置kafka

```bash
[root@CentOSX ~]# tar -zxf kafka_2.11-0.11.0.0.tgz -C /usr/ 
#修改文件名
[root@CentOSX ~]# cd /usr
[root@CentOSX usr]# mv kafka_2.11-0.11.0.0/ kafka_2.11/
[root@CentOSX usr]# cd kafka_2.11/
[root@CentOSX kafka_2.11]# vim config/server.properties 

############################# Server Basics #############################
broker.id=0|1|2
delete.topic.enable=true
############################# Socket Server Settings #############################
listeners=PLAINTEXT://CentOSA|B|C:9092
############################# Log Basics #############################
log.dirs=/usr/kafka-logs
############################# Log Retention Policy #############################
log.retention.hours=168
############################# Zookeeper #############################
zookeeper.connect=CentOSA:2181,CentOSB:2181,CentOSC:2181
```

+ 启动&停止Kafka集群

```bash
[root@CentOSX ~]# cd /usr/kafka_2.11/
[root@CentOSX kafka_2.11]# ./bin/kafka-server-start.sh -daemon  config/server.properties 
[root@CentOSX kafka_2.11]# vi bin/kafka-server-stop.sh 
#pre
PIDS=$(ps ax | grep -i 'kafka\.Kafka' | grep java | grep -v grep | awk '{print $1}')

if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
  exit 1
else
  kill -s TERM $PIDS
fi
#替换为
PIDS=$(jps | grep Kafka | awk '{print $1}')
if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
  exit 1
else 
  kill -s TERM $PIDS
fi
```

+ Kafka测试

```bash
//创建topic分区
[root@CentOSA kafka_2.11]# ./bin/kafka-topics.sh --create --zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 --topic topic01 --partitions 3 --replication-factor 3 
结果：Created topic "topic01".
//启动消费者
[root@CentOSB kafka_2.11]# ./bin/kafka-console-consumer.sh --bootstrap-server CentOSA:9092,CentOSB:9092,CentOSC:9092 --topic topic01 --from-beginning
//启动生产者
[root@CentOSC kafka_2.11]# ./bin/kafka-console-producer.sh --broker-list CentOSA:9092,CentOSB:9092,CentOSC:9092 --topic topic01 
> hello kafka
```

# Topic基本操作

- 创建topic

```bash
[root@CentOSA kafka_2.11-0.11.0.0]# ./bin/kafka-topics.sh 
							--create 
							--zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 
							--topic topic01 
							--partitions 3 
							--replication-factor 3
```

> `partitions`:分区的个数，`replication-factor`副本因子

- 查看topic详情

```bash
[root@CentOSA kafka_2.11-0.11.0.0]# ./bin/kafka-topics.sh 
                                --describe 
                                --zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 
                                --topic topic01 
Topic:topic01	PartitionCount:3	ReplicationFactor:3	Configs:
	Topic: topic01	Partition: 0	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: topic01	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: topic01	Partition: 2	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1

```

- 查看所有Topic

```bash
[root@CentOSA kafka_2.11-0.11.0.0]# ./bin/kafka-topics.sh 
						--list 
						--zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 
topic01
topic02
topic03
```

- 删除topic

```bash
[root@CentOSA kafka_2.11-0.11.0.0]# ./bin/kafka-topics.sh 
				--delete 
				--zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 
				--topic topic03
Topic topic03 is marked for deletion.
Note: This will have no impact if delete.topic.enable is not set to true.
```

- 修改Topic

```bash
[root@CentOSA kafka_2.11-0.11.0.0]# ./bin/kafka-topics.sh 
								--alter 
								--zookeeper CentOSA:2181,CentOSB:2181,CentOSC:2181 
								--topic topic02 
								--partitions 2
WARNING: If partitions are increased for a topic that has a key, the partition logic or ordering of the messages will be affected

```

# Java API Kafka

- 导入Maven依赖

```xml
<!--kafka依赖-->
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-clients</artifactId>
    <version>0.11.0.0</version>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-lang3</artifactId>
    <version>3.7</version>
</dependency>
<!--kafka流处理-->
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-streams</artifactId>
    <version>0.11.0.0</version>
</dependency>
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-log4j12</artifactId>
    <version>1.7.2</version>
</dependency>
```

+ AdminClient 

```java
public class KafkaAdminClientDemo {
    public static void main(String[] args) {
        //加载配置文件，创建客户端
        Properties props = new Properties();
        props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, "CentOSA:9092,CentOSB:9092,CentOSC:9092");
        AdminClient adminClient = KafkaAdminClient.create(props);
        List<NewTopic> topics = Arrays.asList(new NewTopic("topic01", 3, (short) 3));
        CreateTopicsResult topics1 = adminClient.createTopics(topics);
        KafkaFuture<Void> kafkaFuture = topics1.all();
        System.out.println(kafkaFuture);
        adminClient.close();
    }
}
```

+ 生产者

```java
public class ProducerDemo {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                  "CentOSA:9092,CentOSB:9092,CentOSC:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ObjectSerializer.class);
        //创建生产者
        KafkaProducer<String, Object> producer = new KafkaProducer<String, Object>(props);
        //创建ProducerRecord
        for (int i = 0; i < 5; i++) {
            ProducerRecord<String, Object> record = new ProducerRecord<String, Object>
                ("topic01", "00" + i, new Student("lihao", 18, 10000 + (1000 * i)));
            producer.send(record);
            producer.flush();
        }
        producer.close();
    }
}
```

**消费者**

```java
public class ConsumerDemo102 {
    public static void main(String[] args) {
        //加载配置文件，分组信息
        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
                  "CentOSA:9092,CentOSB:9092,CentOSC:9092");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.GROUP_ID_CONFIG,"group1");
        //创建消费者	
        KafkaConsumer<String, String> consumer = new KafkaConsumer<String, String>(props);
        //订阅相关的topic
        consumer.subscribe(Arrays.asList("topic01"));
        //获取消息
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(1000);
            for (ConsumerRecord<String, String> record : records) {
                String key = record.key();
                String value = record.value();
                long timestamp = record.timestamp();
                long offset = record.offset();
                int partition = record.partition();
                System.out.println(key+"=>"+value+"\t offset "+offset+" 
                                   ,partition:"+partition+"\t"+timestamp);
            }
        }
    }
}
```

+ kafka传送对象

```java
public class ObjectSerializer implements Serializer<Object> {
    public void configure(Map<String, ?> map, boolean isKey) {}
    public byte[] serialize(String topic, Object o) {
        return SerializationUtils.serialize((Serializable) o);
    }
    public void close() {}
}
---
public class ObjectDeserializer implements Deserializer<Object> {
    public void configure(Map<String, ?> configs, boolean isKey) {
    }
    public Object deserialize(String topic, byte[] data) {
        return SerializationUtils.deserialize(data);
    }
    public void close() {
    }
}   
```

+ 如何干预kafka分区

```java
props.put(ProducerConfig.PARTITIONER_CLASS_CONFIG,XxxPartitioner.class)
public class XxxPartitioner implements Partitioner {
    public int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster){
        List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
        int numPartitions = partitions.size();
        return (key.hashCode()&Integer.MAX_VALUE)%numPartitions；
    }
    public void close(){
        
    }
}
```

+ 消费订阅两种形式

  + subscribe方式---优点：可是自动实现组内负载均衡和故障转移

  ```java
  props.put(ConsumerConfig.GROUP_ID_CONFIG,"g1");
  kafkaConsumer.subscribe(Arrays.asList("topic02"));
  ```
  + assign方式---优点：手动指定分区信息，缺点：无法实现负载均衡和故障转移

  ```java
  TopicPartition part01=new TopicPartition("topic01",1);
  consumer.assign(Arrays.asList(part01));
  consumer.seek(part01,2);
  ```

+ offset提交方式

  + 默认客户端自动开启了自动提交功能，默认提交时间间隔是5秒钟，用户可以采取手动提交的方式实现。开启手动提交如下:

  ```java
  props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG,false);//关闭自动提交//消费代码后追加kafkaConsumer.commitAsync();
  ```

  + 或者适当调小自动提交时间间隔：

  ```java
  props.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG,1000);props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG,true);//自动提交
  ```

## Kafka Stream 

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-streams</artifactId>
    <version>0.11.0.0</version>
</dependency>
```

```java
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KStreamBuilder;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.state.KeyValueStore;
import java.util.Arrays;
import java.util.Properties;
public class KafkaStreamDemo {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "wordcount-application");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "CentOSA:9092,CentOSB:9092,CentOSC:9092");
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        KStreamBuilder builder = new KStreamBuilder();
        KStream<String, String> textLines = builder.stream("TextLinesTopic");
        KTable<String, Long> wordCounts = textLines
                .flatMapValues(textLine -> Arrays.asList(textLine.toLowerCase().split("\\W+")))
                .groupBy((key, word) -> word)
                .count("counts");
        wordCounts.to(Serdes.String(), Serdes.Long(), "WordsWithCountsTopic");
        KafkaStreams streams = new KafkaStreams(builder, props);
        streams.start();
    }
}
```
# SpringBoot整合

+ maven依赖

```xml
<dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.47</version>
        </dependency>
    </dependencies>
```

+ 实体类

```java
@Data
public class Message {
    private String id;
    private String msg;
    @JSONField(format = "yyyy-MM-dd HH:mm:ss")
    private Date sendTime;
}
```

+ properties配置文件

```properties
#============== kafka ===================
# 指定kafka 代理地址，可以多个
spring.kafka.bootstrap-servers=192.168.88.129:9092

#=============== provider  =======================
#如果该值大于零时，表示启用重试失败的发送次数
spring.kafka.producer.retries=0

# 每次批量发送消息的数量
spring.kafka.producer.batch-size=16384
#生产者可用于缓冲等待发送到服务器的记录的内存总字节数，默认值为33554432
spring.kafka.producer.buffer-memory=33554432

# 指定消息key和消息体的编解码方式
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer

#=============== consumer  =======================
# 指定默认消费者group id
spring.kafka.consumer.group-id=test-consumer-group

#当Kafka中没有初始偏移量或者服务器上不再存在当前偏移量时该怎么办，默认值为latest，表示自动将偏移重置为最新的偏移量
#可选的值为latest, earliest, none
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=true
#消费者偏移自动提交给Kafka的频率（以毫秒为单位），默认值为5000
spring.kafka.consumer.auto-commit-interval;

# 指定消息key和消息体的编解码方式
spring.kafka.consumer.key-deserializer=org.apache.kafka.common.serialization.StringDeserializer
spring.kafka.consumer.value-deserializer=org.apache.kafka.common.serialization.StringDeserializer
```

+ Sender发送者

```java
@Component
@Slf4j
public class KafkaSender {

    @Autowired
    private KafkaTemplate<String,String> template;

    private JSON json=new JSONObject();

    public void sender(){
        Message message=new Message();
        message.setId("001");
        message.setMsg("hello kafka");
        log.info("+++++++ message: "+json.toJSONString(message));
        //第一个参数时topic，第二个时key，第三个是value
        template.send("topic01","kafka",json.toJSONString(message));
    }
}
```

+ Receiver消费者

```java
@Component
@Slf4j
public class KafkaReceiver {

    //监听topic01，可以配置多个，用","分割
    @KafkaListener(topics = {"topic01"})
    public void process(ConsumerRecord record){
        //Java8新特性，解决空指针异常
        Optional<Object> message = Optional.ofNullable(record.value());
        if (message.isPresent()) {
            /*public boolean isPresent() {
                return value != null;
             }*/
            Object o = message.get();

            log.info("--------- record: "+record);
            log.info("--------- message: "+o);
        }
    }
}
```

+ springboot测试类

```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class KafkaApplicationTests {

    @Autowired
    private KafkaSender kafkaSender;

    @Test
    public void contextLoads() {
        kafkaSender.sender();
    }

}
```

