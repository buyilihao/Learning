# Synchronized关键字

`synchronized`锁什么？ 锁对象。

锁的对象包括：this，临界资源对象，Class 类对象。

> synchronized 除了保障原子性外，其实也保障了可见性。因为 synchronized 无论是同步的方法还是同步的代码块，都会先把主内存的数据拷贝到工作内存中，同步代码块结束，会把工作内存中的数据更新到主内存中，这样主内存中的数据一定是最新的。更重要的是禁用了乱序重组以及保证了值对存储器的写入，这样就可以保证可见性。

## Java的内置锁

- 每个java对象都可以用做一个实现同步的锁，这些锁成为内置锁。线程进入同步代码块或方法的时候会自动获得该锁，在退出同步代码块或方法时会释放该锁。获得内置锁的唯一途径就是进入这个锁的保护的同步代码块或方法。
- java内置锁是一个互斥锁，这就是意味着最多只有一个线程能够获得该锁，当线程A尝试去获得线程B持有的内置锁时，线程A必须等待或者阻塞，知道线程B释放这个锁，如果B线程不释放这个锁，那么A线程将永远等待下去。

## Java的对象锁和类锁

- java的对象锁和类锁在锁的概念上基本上和内置锁是一致的，但是，两个锁实际是有很大的区别的，对象锁是用于对象实例方法，或者一个对象实例上的，类锁是用于类的静态方法或者一个类的class对象上的。我们知道，类的对象实例可以有很多个，但是每个类只有一个class对象，所以不同对象实例的对象锁是互不干扰的，但是每个类只有一个类锁。但是有一点必须注意的是，其实类锁只是一个概念上的东西，并不是真实存在的，它只是用来帮助我们理解锁定实例方法和静态方法的区别的。

## 对象锁的synchronized修饰方法和代码块 

```java
public class TestSynchronized{    
    public void test1(){    
         synchronized(this){    
              int i = 5;    
              while( i-- > 0){    
                   System.out.println(Thread.currentThread().getName() + " : " + i);    
                   try{    
                        Thread.sleep(500);    
                   }   
                   catch (InterruptedException ie){    
                   }    
              }    
         }    
    }    
      
    public synchronized void test2(){    
        int i = 5;    
         while( i-- > 0){    
              System.out.println(Thread.currentThread().getName() + " : " + i);    
             try{    
                   Thread.sleep(500);    
              }   
              catch (InterruptedException ie){    
              }    
         }    
    }    
     
    public static void main(String[] args) {    
         final TestSynchronized myt2 = new TestSynchronized();    
         Thread test1 = new Thread(  new Runnable() {  public void run() {  myt2.test1();  }  }, "test1"  );    
         Thread test2 = new Thread(  new Runnable() {  public void run() { myt2.test2();   }  }, "test2"  );    
         test1.start();;    
         test2.start();    
//         TestRunnable tr=new TestRunnable();  
//         Thread test3=new Thread(tr);  
//         test3.start();  
    }   
}
```

结果

```java
test2 : 4  
test2 : 3  
test2 : 2  
test2 : 1  
test2 : 0  
test1 : 4  
test1 : 3  
test1 : 2  
test1 : 1  
test1 : 0
```

上述的代码，第一个方法时用了同步代码块的方式进行同步，传入的对象实例是this，表明是当前对象，当然，如果需要同步其他对象实例，也不可传入其他对象的实例；第二个方法是修饰方法的方式进行同步。因为第一个同步代码块传入的this，所以两个同步代码所需要获得的对象锁都是同一个对象锁，下面main方法时分别开启两个线程，分别调用test1和test2方法，那么两个线程都需要获得该对象锁，另一个线程必须等待。上面也给出了运行的结果可以看到：直到test2线程执行完毕，释放掉锁，test1线程才开始执行。 

## 类锁的修饰（静态）方法和代码块 

```java
public class TestSynchronized{    
    public void test1(){    
         synchronized(TestSynchronized.class){    
              int i = 5;    
              while( i-- > 0){    
                   System.out.println(Thread.currentThread().getName() + " : " + i);    
                   try{    
                        Thread.sleep(500);    
                   }   
                   catch (InterruptedException ie){    
                   }    
              }    
         }    
    }    
      
    public static synchronized void test2(){    
         int i = 5;    
         while( i-- > 0){    
              System.out.println(Thread.currentThread().getName() + " : " + i);    
              try{    
                   Thread.sleep(500);    
              }   
              catch (InterruptedException ie){    
              }    
         }    
    }    
      
    public static void main(String[] args){    
         final TestSynchronized myt2 = new TestSynchronized();    
         Thread test1 = new Thread(  new Runnable() {  public void run() {  myt2.test1();  }  }, "test1"  );    
         Thread test2 = new Thread(  new Runnable() {  public void run() { TestSynchronized.test2();   }  }, "test2"  );    
         test1.start();    
         test2.start();    
//         TestRunnable tr=new TestRunnable();  
//         Thread test3=new Thread(tr);  
//         test3.start();  
    }   
    
}
```

结果

```java
test1 : 4  
test1 : 3  
test1 : 2  
test1 : 1  
test1 : 0  
test2 : 4  
test2 : 3  
test2 : 2  
test2 : 1  
test2 : 0
```

其实，类锁修饰方法和代码块的效果和对象锁是一样的，因为类锁只是一个抽象出来的概念，只是为了区别静态方法的特点，因为静态方法是所有对象实例共用的，所以对应着synchronized修饰的静态方法的锁也是唯一的，所以抽象出来个类锁。 

其实这里的重点在下面这块代码，synchronized同时修饰静态和非静态方法。 

```java
public class TestSynchronized{    
    public synchronized void test1(){    
              int i = 5;    
              while( i-- > 0){    
                   System.out.println(Thread.currentThread().getName() + " : " + i);    
                   try{    
                        Thread.sleep(500);    
                   }   
                   catch (InterruptedException ie){    
                   }    
              }    
    }    
      
    public static synchronized void test2(){    
         int i = 5;    
         while( i-- > 0){    
              System.out.println(Thread.currentThread().getName() + " : " + i);    
              try{    
                   Thread.sleep(500);    
              }   
              catch (InterruptedException ie){    
              }    
         }    
    }    
      
    public static void main(String[] args){    
         final TestSynchronized myt2 = new TestSynchronized();    
         Thread test1 = new Thread(  new Runnable() {  public void run() {  myt2.test1();  }  }, "test1"  );    
         Thread test2 = new Thread(  new Runnable() {  public void run() { TestSynchronized.test2();   }  }, "test2"  );    
         test1.start();    
         test2.start();    
//         TestRunnable tr=new TestRunnable();  
//         Thread test3=new Thread(tr);  
//         test3.start();  
    }   
    
}  
 
test1 : 4  
test2 : 4  
test1 : 3  
test2 : 3  
test2 : 2  
test1 : 2  
test2 : 1  
test1 : 1  
test1 : 0  
test2 : 0
```

上面代码synchronized同时修饰静态方法和实例方法，但是运行结果是交替进行的，这证明了类锁和对象锁是两个不一样的锁，控制着不同的区域，它们是互不干扰的。同样，线程获得对象锁的同时，也可以获得该类锁，即同时获得两个锁，这是允许的。 

## 同步代码块和同步方法的不同

- 从尺寸上讲，同步代码块比同步方法小。你可以把同步代码块看成是没上锁房间里的一块用带锁的屏风隔开的空间。
- 同步代码块还可以人为的指定获得某个其它对象的key。就像是指定用哪一把钥匙才能开这个屏风的锁，你可以用本房的钥匙；你也可以指定用另一个房子的钥匙才能开，这样的话，你要跑到另一栋房子那儿把那个钥匙拿来，并用那个房子的钥匙来打开这个房子的带锁的屏风。
- 记住你获得的那另一栋房子的钥匙，并不影响其他人进入那栋房子没有锁的房间。
- 为什么要使用同步代码块呢？我想应该是这样的：首先对程序来讲同步的部分很影响运行效率，而一个方法通常是先创建一些局部变量，再对这些变量做一些 操作，如运算，显示等等；而同步所覆盖的代码越多，对效率的影响就越严重。因此我们通常尽量缩小其影响范围。
- 如何做？同步代码块。我们只把一个方法中该同 步的地方同步，比如运算。
- 另外，同步代码块可以指定钥匙这一特点有个额外的好处，是可以在一定时期内霸占某个对象的key。还记得前面说过普通情况下钥匙的使用原则吗。现在不是普通情况了。你所取得的那把钥匙不是永远不还，而是在退出同步代码块时才还。

