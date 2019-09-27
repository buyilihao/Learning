# IOC/DI

> 使用XML文件解析+发射+工厂设计模式

使用工厂设计模式，根据beanId找到配置文件的ClassName，反射创建对象，根据property标签的name属性值，反射找到对应的set方法，反射调用set方法将value的值赋值给属性。

# AOP

## 思想

面向切面编程，在不修改目标类的方法代码的情况下，在运行时动态地为目标对象的目标方法增加额外功能，实现解耦合，提高代码的可维护性。

## JDK动态代理

如果目标类有接口，使用JDK的Proxy的静态方法newProxyInstance(ClassLoader，目标对象的接口，增强功能)，内部执行动态字节码技术，生产代理类的对象

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class JdkProxy {

    public static void main(String[] args) {
        // 1. 创建目标对象
        UserService us = new UserServiceImpl();
        // 2. 获取目标对象的所有接口
        Class<?>[] interfaces = us.getClass().getInterfaces();
        // 3. 增强功能
        InvocationHandler handler=(Object proxy, Method method, Object[] args1)->{
            System.out.println("------前置增强------");

            Object invoke = method.invoke(us, args1);//调用目标类的方法

            System.out.println("------后置增强------");
            return invoke;
        };

        // 4. 类加载器生产类对象
        ClassLoader classLoader = us.getClass().getClassLoader();
        // 5. 组装生产代理类的对象
        UserService instance = (UserService) Proxy.newProxyInstance(classLoader, interfaces, handler);

        instance.login("lihao","123456");
    }
}
```

## Cglib动态代理

如果目标类没有接口，使用cglib的Enhancer对象，绑定目标类对象，增强功能，基于字节码技术动态生成基于继承的代理类对象。

```java
import org.springframework.cglib.proxy.Enhancer;
import org.springframework.cglib.proxy.InvocationHandler;

import java.lang.reflect.Method;

public class CglibProxy {
    public static void main(String[] args) {
        //1.目标类
        UserService us=new UserService();
        //2.增强功能
        InvocationHandler handler=new InvocationHandler() {
            @Override
            public Object invoke(Object o, Method method, Object[] args) throws Throwable {
                System.out.println("------前置增强------");

                Object invoke = method.invoke(us, args);//调用目标类的方法

                System.out.println("------后置增强------");
                return invoke;
            }
        };
        //3.组装Enhancer
        Enhancer enhancer=new Enhancer();
        enhancer.setSuperclass(us.getClass());//绑定父类
        enhancer.setCallback(handler);//绑定增强功能
        UserService service = (UserService) enhancer.create();//生产代理类

        service.login("lihao","123456");
    }
}
```



