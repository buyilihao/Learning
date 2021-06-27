## @Cacheable

@Cacheable可以标记在一个方法上，也可以标记在一个类上。当标记在一个方法上时表示该方法是支持缓存的，当标记在一个类上时则表示该类所有的方法都是支持缓存的。对于一个支持缓存的方法，Spring会在其被调用后将其返回值缓存起来，以保证下次利用同样的参数来执行该方法时可以直接从缓存中获取结果，而不需要再次执行该方法。

在 @Cacheable 注解的使用中，共有 9 个属性供我们来使用，这 9 个属性分别是： `value`、 `cacheNames`、 `key`、 `keyGenerator`、 `cacheManager`、 `cacheResolver`、 `condition`、 `unless`、 `sync`。

### 1. value/cacheNames 属性

如下图所示，这两个属性代表的意义相同，根据`@AliasFor`注解就能看出来了。`这两个属性都是用来指定缓存组件的名称，即将方法的返回结果放在哪个缓存中，属性定义为数组，可以指定多个缓存`

```java
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface Cacheable {
    @AliasFor("cacheNames")
    String[] value() default {};

    @AliasFor("value")
    String[] cacheNames() default {};

    String key() default "";

    String keyGenerator() default "";

    String cacheManager() default "";

    String cacheResolver() default "";

    String condition() default "";

    String unless() default "";

    boolean sync() default false;
}
```

### 2. key属性

key属性是用来指定Spring缓存方法的返回结果时对应的key的。该属性支持SpringEL表达式。当我们没有指定该属性时，Spring将使用默认策略生成key。我们这里先来看看自定义策略，至于默认策略会在后文单独介绍。

​       自定义策略是指我们可以通过Spring的EL表达式来指定我们的key。这里的EL表达式可以使用方法参数及它们对应的属性。使用方法参数时我们可以直接使用“#参数名”或者“#p参数index”。下面是几个使用参数作为key的示例。

```java
	@Cacheable(value="users", key="#id")
   public User find(Integer id) {
      return null;
   }

	@Cacheable(value="users", key="#p0")
   public User find(Integer id) {
      return null;
   }

   @Cacheable(value="users", key="#user.id")
   public User find(User user) {
      return null;
   }

   @Cacheable(value="users", key="#p0.id")
   public User find(User user) {
      return null;
   }
```

| 位置          | 名字               | 描述                                                         | 示例                 |
| ------------- | ------------------ | ------------------------------------------------------------ | -------------------- |
| methodName    | root object        | 当前被调用的方法名                                           | #root.method.name    |
| method        | root object        | 当前被调用的方法                                             | #root.methodName     |
| target        | root object        | 当前被调用的目标对象                                         | #root.target         |
| targetClass   | root object        | 当前被调用的目标对象类                                       | #root.targetClass    |
| args          | root object        | 当前被调用的方法的参数列表                                   | #root.args[0]        |
| caches        | root object        | 当前方法调用使用的缓存列表（如@Cacheable(value={“cache1”,“cache2”})），则有两个cache | #root.caches[0].name |
| argument name | evaluation context | 方法参数的名字. 可以直接 #参数名 ，也可以使用 #p0或#a0 的形式，0代表参数的索引； | #id、#p0、#a0        |
| result        | evaluation context | 方法执行后的返回值（仅当方法执行之后的判断有效，如’unless’、'cache put’的表达式 'cacheevict’的表达式beforeInvocation=false） | #result              |

### 3. keyGenerator 属性

​       key 的生成器。如果觉得通过参数的方式来指定比较麻烦，我们可以自己指定 key 的生成器的组件 id。`key/keyGenerator属性：二选一使用。`我们可以通过自定义配置类方式，将 keyGenerator 注册到 IOC 容器来使用。

```java
import org.springframework.cache.interceptor.KeyGenerator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.lang.reflect.Method;
import java.util.Arrays;

@Configuration
public class MyCacheConfig {

    @Bean("myKeyGenerator")
    public KeyGenerator keyGenerator(){
        return new KeyGenerator(){

            @Override
            public Object generate(Object target, Method method, Object... params) {
                return method.getName()+ Arrays.asList(params).toString();
            }
        };
    }

    /
     * 支持 lambda 表达式编写
     */
    /*@Bean("myKeyGenerator")
    public KeyGenerator keyGenerator(){
        return ( target,  method, params)-> method.getName()+ Arrays.asList(params).toString();
    }*/
}

```

### 4. cacheManager/cacheResolver 属性

`用来指定缓存管理器。`针对不同的缓存技术，需要实现不同的 cacheManager。

### condition 属性

​       条件判断属性，用来指定符合指定的条件下才可以缓存。也可以通过 *SpEL* 表达式进行设置。这个配置规则和上面表格中的配置规则是相同的。

```java
@Cacheable(value = "user",condition = "#id>0")//传入的 id 参数值>0才进行缓存
User getUser(Integer id);

@Cacheable(value = "user",condition = "#a0>1")//传入的第一个参数的值>1的时候才进行缓存
User getUser(Integer id);

@Cacheable(value = "user",condition = "#a0>1 and #root.methodName eq 'getUser'")//传入的第一个参数的值>1 且 方法名为 getUser 的时候才进行缓存
User getUser(Integer id);
```

### 5. unless 属性

​       unless属性，意为"除非"的意思。**优先级低于condition**，即只有 unless 指定的条件为 true 时，方法的返回值才不会被缓存。`可以在获取到结果后进行判断`

```java
@Cacheable(value = "user",unless = "#result == null")//当方法返回值为 null 时，就不缓存
User getUser(Integer id);

@Cacheable(value = "user",unless = "#a0 == 1")//如果第一个参数的值是1,结果不缓存
User getUser(Integer id);

```

### 6. sync 属性

​    该属性用来指定`是否使用异步模式`，该属性默认值为 false，默认为同步模式。`异步模式指定 sync = true 即可，异步模式下 unless 属性不可用`

## @CachePut

​       在支持Spring Cache的环境下，对于使用@Cacheable标注的方法，Spring在每次执行前都会检查Cache中是否存在相同key的缓存元素，如果存在就不再执行该方法，而是直接从缓存中获取结果进行返回，否则才会执行并将返回结果存入指定的缓存中。@CachePut也可以声明一个方法支持缓存功能。与@Cacheable不同的是使用@CachePut标注的方法在执行前不会去检查缓存中是否存在之前执行过的结果，而是每次都会执行该方法，并将执行结果以键值对的形式存入指定的缓存中。

​       @CachePut也可以标注在类上和方法上。使用@CachePut时我们可以指定的属性跟@Cacheable是一样的。

```java
@CachePut("users")//每次都会执行方法，并将结果存入指定的缓存中
   public User find(Integer id) {
      return null;
   }
```

## @CacheEvict

​       @CacheEvict是用来标注在需要清除缓存元素的方法或类上的。当标记在一个类上时表示其中所有的方法的执行都会触发缓存的清除操作。@CacheEvict可以指定的属性有value、key、condition、allEntries和beforeInvocation。其中value、key和condition的语义与@Cacheable对应的属性类似。即value表示清除操作是发生在哪些Cache上的（对应Cache的名称）；key表示需要清除的是哪个key，如未指定则会使用默认策略生成的key；condition表示清除操作发生的条件。下面我们来介绍一下新出现的两个属性allEntries和beforeInvocation。

### allEntries属性

​       allEntries是boolean类型，表示是否需要清除缓存中的所有元素。默认为false，表示不需要。当指定了allEntries为true时，Spring Cache将忽略指定的key。有的时候我们需要Cache一下清除所有的元素，这比一个一个清除元素更有效率。

```java
@CacheEvict(value="users", allEntries=true)
   public void delete(Integer id) {
      System.out.println("delete user by id: " + id);
   }
```

### beforeInvocation属性

​       清除操作默认是在对应方法成功执行之后触发的，即方法如果因为抛出异常而未能成功返回时也不会触发清除操作。使用beforeInvocation可以改变触发清除操作的时间，当我们指定该属性值为true时，Spring会在调用该方法之前清除缓存中的指定元素。

```java
@CacheEvict(value="users", beforeInvocation=true)
   public void delete(Integer id) {
      System.out.println("delete user by id: " + id);
   }
```

## 设置过期时间

自定义cacheManager，手动设置过期时间

```java
import org.apache.commons.lang3.StringUtils;
import org.springframework.data.redis.cache.RedisCache;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.cache.RedisCacheWriter;

import java.time.Duration;

/**
 * @Description: 自定义redis缓存管理
 * @author: Darcy
 * @date: 2021/6/25 22:53
 */
public class MyRedisManager extends RedisCacheManager {
    public MyRedisManager(RedisCacheWriter cacheWriter, RedisCacheConfiguration defaultCacheConfiguration) {
        super(cacheWriter, defaultCacheConfiguration);
    }

    @Override
    protected RedisCache createRedisCache(String name, RedisCacheConfiguration cacheConfig) {
        //@Cacheable设置过期时间
        String cacheKey = name;
        Integer expireTime = null;
        if (StringUtils.isNotEmpty(name) && name.contains("#")) {
            cacheKey = name.split("#")[0];
            String str = name.split("#")[1];
            if (StringUtils.isNumeric(str)) {
                expireTime = Integer.parseInt(str);
                return super.createRedisCache(name, cacheConfig.entryTtl(Duration.ofSeconds(expireTime)));
            }
        }
        return super.createRedisCache(name, cacheConfig);
    }
}

```

用自定义的cacheManager替代原来的

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheWriter;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.JdkSerializationRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;

/**
 * @Description: redis配置
 * @author: Darcy
 * @date: 2021/6/25 23:16
 */
@Configuration
public class RedisConfig {
    private final RedisConnectionFactory redisConnectionFactory;

    @Autowired
    public RedisConfig(RedisConnectionFactory redisConnectionFactory) {
        this.redisConnectionFactory = redisConnectionFactory;
    }

    @Bean
    public CacheManager cacheManager() {
        JdkSerializationRedisSerializer redisSerializer = new JdkSerializationRedisSerializer();
        RedisCacheConfiguration configuration = RedisCacheConfiguration.defaultCacheConfig().
                serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(redisSerializer));
        return new MyRedisManager(RedisCacheWriter.nonLockingRedisCacheWriter(redisConnectionFactory), configuration);
    }
}
```

使用方法，使用==#==分割

```java
@Cacheable(value = "user#30", key = "#id", condition = "#id%2==0")
    public User selectById(Integer id) {
        return userDao.selectById(id);
    }
```

