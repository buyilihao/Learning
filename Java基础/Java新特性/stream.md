## Stream是什么

Stream是Java8中新加入的api，更准确的说:

> Java 8 中的 Stream 是对集合（Collection）对象功能的增强，它专注于对集合对象进行各种非常便利、高效的聚合操作，或者大批量数据操作 。Stream API 借助于同样新出现的 Lambda 表达式，极大的提高编程效率和程序可读性.

以前我们处理复杂的数据只能通过各种for循环，不仅不美观，而且时间长了以后可能自己都看不太明白以前的代码了，但有Stream以后，通过filter，map，limit等等方法就可以使代码更加简洁并且更加语义化。

![](.\assets\fuse.svg)

Stream的效果就像上图展示的它可以先把数据变成符合要求的样子（map），吃掉不需要的东西（filter）然后得到需要的东西（collect）。

## Stream的方法

```java
package com.aliyun.learning;

import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class Steam {
    public static void main(String[] args) {
        //forEach: Stream 提供了新的方法 'forEach' 来迭代流中的每个数据。以下代码片段使用 forEach 输出了10个随机数：
        Random random = new Random();
        random.ints().limit(10).forEach(System.out::println);

        //map 方法用于映射每个元素到对应的结果，以下代码片段使用 map 输出了元素对应的平方数：
        List<Integer> numbers = Arrays.asList(3, 2, 2, 3, 7, 3, 5);
        List<Integer> squaresList = numbers.stream().map( i -> i*i).distinct().collect(Collectors.toList());
        squaresList.stream().forEach(System.out::println);

        //filter 方法用于通过设置的条件过滤出元素。以下代码片段使用 filter 方法过滤出空字符串：
        List<String>strings = Arrays.asList("abc", "", "bc", "efg", "abcd","", "jkl");
        long count = strings.stream().filter(string -> string.isEmpty()).count();
        System.out.println(count);

        //limit 方法用于获取指定数量的流。 以下代码片段使用 limit 方法打印出 10 条数据：
        Random random = new Random();
        random.ints().limit(10).forEach(System.out::println);

        //sorted 方法用于对流进行排序。以下代码片段使用 sorted 方法对输出的 10 个随机数进行排序：
        Random random = new Random();
        random.ints().limit(10).map(i -> Math.abs(i)).sorted().forEach(System.out::println);//默认升序

        //Collectors 类实现了很多归约操作，例如将流转换成集合和聚合元素。Collectors 可用于返回列表或字符串
        List<String>strings = Arrays.asList("abc", "", "bc", "efg", "abcd","", "jkl");
        List<String> filtered = strings.stream().filter(string -> !string.isEmpty()).collect(Collectors.toList());

        System.out.println("筛选列表: " + filtered);
        String mergedString = strings.stream().filter(string -> !string.isEmpty()).collect(Collectors.joining(", "));
        System.out.println("合并字符串: " + mergedString);
    }
}

```

## Stream的应用

```java
public static void main(String[] args) {
        User user1 = new User("lh",18,17000.00);
        User user2 = new User("lx",17,10000.00);
        User user3 = new User("lfj",20,3000.00);
        List<User> userList = new ArrayList<>();
        userList.add(user1);
        userList.add(user2);
        userList.add(user3);

        //list转map，name为key，salary为value
        Map<String, Double> map = userList.stream().collect(Collectors.toMap(User::getName, User::getSalary));
        for (Map.Entry<String, Double> entry : map.entrySet()) {
            System.out.println(entry.getKey()+"---"+entry.getValue());
        }

        //抽取list属性形成新的list
        List<String> nameList = userList.stream().map(User::getName).collect(Collectors.toList());
        for (String name : nameList) {
            System.out.println(name);
        }
    }
```

## 串行与并行

Stream可以分为串行与并行两种，串行流和并行流差别就是单线程和多线程的执行。

- default Stream stream() ： 返回串行流
- default Stream parallelStream() ： 返回并行流

stream()和parallelStream()方法返回的都是java.util.stream.Stream<E>类型的对象，说明它们在功能的使用上是没差别的。唯一的差别就是单线程和多线程的执行。

## 性能问题

结果可以总结如下：

> 1.对于简单操作，比如最简单的遍历，Stream串行API性能明显差于显示迭代，但并行的Stream API能够发挥多核特性。
>
> 2.对于复杂操作，Stream串行API性能可以和手动实现的效果匹敌，在并行执行时Stream API效果远超手动实现。
>
> 所以，如果出于性能考虑，1. 对于简单操作推荐使用外部迭代手动实现，2. 对于复杂操作，推荐使用Stream API， 3. 在多核情况下，推荐使用并行Stream API来发挥多核优势，4.单核情况下不建议使用并行Stream API。
>
> 如果出于代码简洁性考虑，使用Stream API能够写出更短的代码。即使是从性能方面说，尽可能的使用Stream API也另外一个优势，那就是只要Java Stream类库做了升级优化，代码不用做任何修改就能享受到升级带来的好处。



