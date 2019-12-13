## 一、数据源配置

> ###### 多数据源配置的时候注意，必须要有一个主数据源，即 `MasterDataSourceConfig` 配置
>
> - @Primary 标志这个 Bean 如果在多个同类 Bean 候选时，该 Bean 优先被考虑。「多数据源配置的时候注意，必须要有一个主数据源，用 @Primary 标志该 Bean
> - @MapperScan 扫描 Mapper 接口并容器管理，包路径精确到 master，为了和下面 cluster 数据源做到精确区分
> - @Value 获取全局配置文件 [application.properties](https://link.jianshu.com?t=http://application.properties) 的 kv 配置,并自动装配sqlSessionFactoryRef 表示定义了 key ，表示一个唯一 SqlSessionFactory 实例

## 二、依赖

```xml
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>2.1.1</version>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid</artifactId>
            <version>1.1.20</version>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
        </dependency>
        <dependency>
            <groupId>com.microsoft.sqlserver</groupId>
            <artifactId>sqljdbc4</artifactId>
            <version>4.0</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
```

## 三、配置文件

```yml
# 多数据源配置
spring:
  datasource:
    bqk:
      driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
      url: jdbc:sqlserver://ip:port;databasename=xx
      username: 
      password: 
      test-while-idle: true
      #获取连接时候验证，会影响性能
      test-on-borrow: true
      #在连接归还到连接池时是否测试该连接
      test-on-return: true
      #空闲连接回收的时间间隔，与test-while-idle一起使用，设置5分钟
      time-between-eviction-runs-millis: 300000
      #连接池空闲连接的有效时间 ，设置30分钟
      min-evictable-idle-time-millis: 1800000
      validation-query: SELECT 1
    poc:
      driver-class-name: com.mysql.cj.jdbc.Driver
      url: jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
      username: 
      password: 
      test-while-idle: true
      validation-query: SELECT 1

#show sql
logging:
  level:
    com:
      aliyun:
        esl:
          dao: debug
```

## 四、ConfigurationProperties

### 1. properties1

```java
@Data
@Component("DataBase2Properties")
@ConfigurationProperties(prefix = "spring.datasource.poc")
public class DataBase2Properties {
    private String url;
    private String username;
    private String password;
    private String driverClassName;
    private String validationQuery;
    private boolean testWhileIdle;
}
```

### 2. properties2

```java
@Data
@Component("DataBase1Properties")
@ConfigurationProperties(prefix = "spring.datasource.bqk")
public class DataBase1Properties {
    private String url;
    private String username;
    private String password;
    private String driverClassName;
    private String validationQuery;
    private boolean testWhileIdle;
    private boolean testOnBorrow;
    private boolean testOnReturn;
    private int timeBetweenEvictionRunsMillis;
    private int minEvictableIdleTimeMillis;
}
```

## 五、Configuration

### 1. config1

```java
@Configuration
@MapperScan(basePackages = "com.aliyun.esl.dao.bqk", sqlSessionTemplateRef = "bqkSqlSessionTemplate")
public class DataBaseAConfig {

    @Autowired
    public DataBase1Properties properties;

    @Bean(name = "bqkDataSource")
    @Primary
    public DataSource bqkDataSource() {
        DataSource dataSource = new DruidDataSource();
        WrapperBeanCopier.copyProperties(properties,dataSource);

        return dataSource;
    }

    @Bean(name = "bqkSqlSessionFactory")
    @Primary
    public SqlSessionFactory bqkSqlSessionFactory(@Qualifier("bqkDataSource") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mappers/bqk/*.xml"));
        return bean.getObject();
    }

    @Bean(name = "bqkTransactionManager")
    @Primary
    public DataSourceTransactionManager bqkTransactionManager(@Qualifier("bqkDataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    @Bean(name = "bqkSqlSessionTemplate")
    @Primary
    public SqlSessionTemplate bqkSqlSessionTemplate(@Qualifier("bqkSqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```

### 2. config2

```java
@Configuration
@MapperScan(basePackages = "com.aliyun.esl.dao.poc", sqlSessionTemplateRef = "pocSqlSessionTemplate")
public class DataBase2Config {

    @Autowired
    public DataBase2Properties properties;

    @Bean(name = "pocDataSource")
    public DataSource pocDataSource() {
        DataSource dataSource = new DruidDataSource();
        WrapperBeanCopier.copyProperties(properties,dataSource);

        return dataSource;
    }

    @Bean(name = "pocSqlSessionFactory")
    public SqlSessionFactory pocSqlSessionFactory(@Qualifier("pocDataSource") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mappers/poc/*.xml"));
        return bean.getObject();
    }

    @Bean(name = "pocTransactionManager")
    public DataSourceTransactionManager pocTransactionManager(@Qualifier("pocDataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    @Bean(name = "pocSqlSessionTemplate")
    public SqlSessionTemplate pocSqlSessionTemplate(@Qualifier("pocSqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```

## 六、事务一致性