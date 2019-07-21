# Lock

## Lock中的四个方法

- lock()是平常使用得最多的一个方法，就是用来获取锁。如果锁已被其他线程获取，则进行等待。unLock()方法是用来释放锁的。
- tryLock()方法是有返回值的，它表示用来尝试获取锁，如果获取成功，则返回true，如果获取失败（即锁已被其他线程获取），则返回false，也就说这个方法无论如何都会立即返回。在拿不到锁时不会一直在那等待。
- tryLock(long time, TimeUnit unit)方法和tryLock()方法是类似的，只不过区别在于这个方法在拿不到锁时会等待一定的时间，在时间期限之内如果还拿不到锁，就返回false。如果如果一开始拿到锁或者在等待期间内拿到了锁，则返回true。
- lockInterruptibly()方法比较特殊，当通过这个方法去获取锁时，如果线程正在等待获取锁，则这个线程能够响应中断，即中断线程的等待状态。也就使说，当两个线程同时通过lock.lockInterruptibly()想获取某个锁时，假若此时线程A获取到了锁，而线程B只有在等待，那么对线程B调用threadB.interrupt()方法能够中断线程B的等待过程。

## 可重入锁(ReentrantLock)

ReentrantLock是唯一实现了Lock接口的类，并且ReentrantLock提供了更多的方法。 

### ReentrantLock的调用过程

经过观察ReentrantLock把所有Lock接口的操作都委派到一个Sync类上，该类继承了AbstractQueuedSynchronizer（队列同步器）：

```java
public class ReentrantLock implements Lock, java.io.Serializable {
    private static final long serialVersionUID = 7373984872572414699L;
    /** Synchronizer providing all implementation mechanics */
    private final Sync sync;

    /**
     * Base of synchronization control for this lock. Subclassed
     * into fair and nonfair versions below. Uses AQS state to
     * represent the number of holds on the lock.
     */
    abstract static class Sync extends AbstractQueuedSynchronizer {
```

Sync又有两个子类： 

```java
final static class NonfairSync extends Sync//非公平锁
 
final static class FairSync extends Sync//公平锁 
```

 显然是为了支持公平锁和非公平锁而定义，默认情况下为非公平锁。  先理一下Reentrant.lock()方法的调用过程（默认非公平锁）： 

![](/home/buyilihao/Learning/Java%E5%9F%BA%E7%A1%80/%E7%BA%BF%E7%A8%8B%E5%92%8C%E9%94%81/image/%E9%94%81%E6%9C%BA%E5%88%B6/0_13119022769n5R.gif)

其实通过上面调用过程及AbstractQueuedSynchronizer的注释可以发现，AbstractQueuedSynchronizer中抽象了绝大多数Lock的功能，而只把tryAcquire方法延迟到子类中实现。tryAcquire方法的语义在于用具体子类判断请求线程是否可以获得锁，无论成功与否AbstractQueuedSynchronizer都将处理后面的流程。 

### 加锁

Sync.nonfairTryAcquire

nonfairTryAcquire方法将是lock方法间接调用的第一个方法，每次请求锁时都会首先调用该方法。 

```java
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {//CAS算法
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc 	= c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

该方法会首先判断当前状态，如果c=0说明没有线程正在竞争该锁，如果不c !=0 说明有线程正拥有了该锁。  如果发现c=0，则通过CAS设置该状态值为acquires,acquires的初始调用值为1，每次线程重入该锁都会+1，每次unlock都会-1，但为0时释放锁。如果CAS设置成功，则可以预计其他任何线程调用CAS都不会再成功，也就认为当前线程得到了该锁，也作为Running线程，很显然这个Running线程并未进入等待队列。  如果c !=0 但发现自己已经拥有锁，只是简单地++acquires，并修改status值，但因为没有竞争，所以通过setStatus修改，而非CAS，也就是说这段代码实现了偏向锁的功能，并且实现的非常漂亮。 

### 解锁