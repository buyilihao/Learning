# ArrayList

## 简单实现ArrayList

```java
import static org.hamcrest.CoreMatchers.nullValue;

public class MyArrayListTest {
	public static void main(String[] args) {
		MyArrayList2 list=new MyArrayList2();
		//顺序添加元素
		list.add("Lh");
		list.add("Zqq");
		list.add("Lyl");
		list.add("Lcg");
		list.add("Lj");
		print(list);
		
		//指定下标添加元素
		list.add(2, "Xz");
		print(list);
		
		//删除指定下标元素
		list.remove(1);
		print(list);
		
		//更新指定下标元素
		list.set(1, "Xka");
		print(list);
		
		//获取元素首次出现的下标
		System.out.println(list.indexOf("Lh"));
		
		//判断是否包含一个元素
		System.out.println(list.contains("Zqq"));
		System.out.println(list.contains("Xka"));
		
		//获取有效元素的个数
		System.out.println(list.size());
		
	}
	//定义一个遍历数组方法
	public static void print(MyArrayList2 list){
		for (int i = 0; i < list.size(); i++) {
			System.out.print(list.get(i)+"    ");
		}
		System.out.println();
	}
}
class MyArrayList{
	//创建一个对象数组
	private Object[] os=new Object[10];
	private int size=0;//size表示数组的有效长度
	
	//数组扩容
	private void expand(){
		if(size==os.length){
			os=java.util.Arrays.copyOf(os, os.length<<1);
		}
	}
	
	//顺序添加
	public void add(Object o){
		expand();
		os[size]=o;
		size++;
	}
	
	//指定下标插入
	public void add(int index,Object o){
		expand();
		for (int i =size-1; i >index-1; i--) {
			os[i+1]=os[i];
		}
		os[index]=o;
		size++;
	}
	
	//删除指定下标元素
	public void remove(int index){
		for (int i =index+1; i <size; i++) {
			os[i-1]=os[i];
		}
		os[size-1]=null;
		size--;
	}
	
	//获取指定下标元素
	public Object get(int index){
		return os[index];
	}
	
	//获取元素首次出现的下标
	public int indexOf(Object o){
		for (int i = 0; i < size; i++) {
			if(os[i].equals(o))
				return i;
		}
		return -1;
	}
	
	//更新指定下标元素
	public void set(int index,Object o) {
		os[index]=o;
	}
	
	//判断是否包含一个元素
	public boolean contains(Object o){
		return indexOf(o) >= 0;
	}
	
	//获取有效元素个数
	public int size(){
		return size;
	}
}
class MyArrayList2{
	private Object[] os=new Object[10];
	private int size=0;//记录有效元素个数
	
	//扩容
	public void expand(){
		if(size==os.length){
			os=java.util.Arrays.copyOf(os, os.length*2);
		}
	}
	
	//顺序添加
	public void add(Object data){
		expand();
		os[size++]=data;
	}
	
	//指定下标添加
	public void add(int index,Object data){
		expand();
		//需要把index下标的元素后移一位
		for (int i = size-1; i >=index; i--) {
			os[i+1]=os[i];
		}//index下标是空出来的
		os[index]=data;
		size++;
	}
	
	//删除指定下标元素
	public void remove(int index){
		//需要把index下标后面的元素向前移一位
		for (int i = index+1; i < size; i++) {
			os[i-1]=os[i];
		}
		os[size-1]=null;
		size--;
	}
	
	//更新指定下标元素
	public void set(int index,Object data){
		os[index]=data;
	}
	
	//获取指定下标元素
	public Object get(int index){
		return os[index];
	}
	
	//获取元素出现的首下标
	public int indexOf(Object data){
		for (int i = 0; i < size; i++) {
			if(data.equals(os[i])){
				return i;
			}
		}
		return -1;
	}
	
	//判断是否包含一个元素
	public boolean contains(Object data){
		return indexOf(data)>=0;
	}
	
	//获取有效元素个数
	public int size(){
		return size;
	}
}
```

## ArrayList核心源码

```java
package java.util;

import java.util.function.Consumer;
import java.util.function.Predicate;
import java.util.function.UnaryOperator;


public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable
{
    private static final long serialVersionUID = 8683452581122892189L;

    /**
     * 默认初始容量大小
     */
    private static final int DEFAULT_CAPACITY = 10;

    /**
     * 空数组（用于空实例）。
     */
    private static final Object[] EMPTY_ELEMENTDATA = {};

     //用于默认大小空实例的共享空数组实例。
      //我们把它从EMPTY_ELEMENTDATA数组中区分出来，以知道在添加第一个元素时容量需要增加多少。
    private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};

    /**
     * 保存ArrayList数据的数组
     */
    transient Object[] elementData; // non-private to simplify nested class access

    /**
     * ArrayList 所包含的元素个数
     */
    private int size;

    /**
     * 带初始容量参数的构造函数。（用户自己指定容量）
     */
    public ArrayList(int initialCapacity) {
        if (initialCapacity > 0) {
            //创建initialCapacity大小的数组
            this.elementData = new Object[initialCapacity];
        } else if (initialCapacity == 0) {
            //创建空数组
            this.elementData = EMPTY_ELEMENTDATA;
        } else {
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        }
    }

    /**
     *默认构造函数，DEFAULTCAPACITY_EMPTY_ELEMENTDATA 为0.初始化为10，也就是说初始其实是空数组 当添加第一个元素的时候数组容量才变成10
     */
    public ArrayList() {
        this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
    }

    /**
     * 构造一个包含指定集合的元素的列表，按照它们由集合的迭代器返回的顺序。
     */
    public ArrayList(Collection<? extends E> c) {
        //
        elementData = c.toArray();
        //如果指定集合元素个数不为0
        if ((size = elementData.length) != 0) {
            // c.toArray 可能返回的不是Object类型的数组所以加上下面的语句用于判断，
            //这里用到了反射里面的getClass()方法
            if (elementData.getClass() != Object[].class)
                elementData = Arrays.copyOf(elementData, size, Object[].class);
        } else {
            // 用空数组代替
            this.elementData = EMPTY_ELEMENTDATA;
        }
    }

    /**
     * 修改这个ArrayList实例的容量是列表的当前大小。 应用程序可以使用此操作来最小化ArrayList实例的存储。 
     */
    public void trimToSize() {
        modCount++;
        if (size < elementData.length) {
            elementData = (size == 0)
              ? EMPTY_ELEMENTDATA
              : Arrays.copyOf(elementData, size);
        }
    }
//下面是ArrayList的扩容机制
//ArrayList的扩容机制提高了性能，如果每次只扩充一个，
//那么频繁的插入会导致频繁的拷贝，降低性能，而ArrayList的扩容机制避免了这种情况。
    /**
     * 如有必要，增加此ArrayList实例的容量，以确保它至少能容纳元素的数量
     * @param   minCapacity   所需的最小容量
     */
    public void ensureCapacity(int minCapacity) {
        int minExpand = (elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
            // any size if not default element table
            ? 0
            // larger than default for default empty table. It's already
            // supposed to be at default size.
            : DEFAULT_CAPACITY;

        if (minCapacity > minExpand) {
            ensureExplicitCapacity(minCapacity);
        }
    }
   //得到最小扩容量
    private void ensureCapacityInternal(int minCapacity) {
        if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
              // 获取默认的容量和传入参数的较大值
            minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
        }

        ensureExplicitCapacity(minCapacity);
    }
  //判断是否需要扩容
    private void ensureExplicitCapacity(int minCapacity) {
        modCount++;

        // overflow-conscious code
        if (minCapacity - elementData.length > 0)
            //调用grow方法进行扩容，调用此方法代表已经开始扩容了
            grow(minCapacity);
    }

    /**
     * 要分配的最大数组大小
     */
    private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

    /**
     * ArrayList扩容的核心方法。
     */
    private void grow(int minCapacity) {
        // oldCapacity为旧容量，newCapacity为新容量
        int oldCapacity = elementData.length;
        //将oldCapacity 右移一位，其效果相当于oldCapacity /2，
        //我们知道位运算的速度远远快于整除运算，整句运算式的结果就是将新容量更新为旧容量的1.5倍，
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        //然后检查新容量是否大于最小需要容量，若还是小于最小需要容量，那么就把最小需要容量当作数组的新容量，
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        //再检查新容量是否超出了ArrayList所定义的最大容量，
        //若超出了，则调用hugeCapacity()来比较minCapacity和 MAX_ARRAY_SIZE，
        //如果minCapacity大于MAX_ARRAY_SIZE，则新容量则为Interger.MAX_VALUE，否则，新容量大小则为 MAX_ARRAY_SIZE。
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
    //比较minCapacity和 MAX_ARRAY_SIZE
    private static int hugeCapacity(int minCapacity) {
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
    }

    /**
     *返回此列表中的元素数。 
     */
    public int size() {
        return size;
    }

    /**
     * 如果此列表不包含元素，则返回 true 。
     */
    public boolean isEmpty() {
        //注意=和==的区别
        return size == 0;
    }

    /**
     * 如果此列表包含指定的元素，则返回true 。
     */
    public boolean contains(Object o) {
        //indexOf()方法：返回此列表中指定元素的首次出现的索引，如果此列表不包含此元素，则为-1 
        return indexOf(o) >= 0;
    }

    /**
     *返回此列表中指定元素的首次出现的索引，如果此列表不包含此元素，则为-1 
     */
    public int indexOf(Object o) {
        if (o == null) {
            for (int i = 0; i < size; i++)
                if (elementData[i]==null)
                    return i;
        } else {
            for (int i = 0; i < size; i++)
                //equals()方法比较
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
    }

    /**
     * 返回此列表中指定元素的最后一次出现的索引，如果此列表不包含元素，则返回-1。.
     */
    public int lastIndexOf(Object o) {
        if (o == null) {
            for (int i = size-1; i >= 0; i--)
                if (elementData[i]==null)
                    return i;
        } else {
            for (int i = size-1; i >= 0; i--)
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
    }

    /**
     * 返回此ArrayList实例的浅拷贝。 （元素本身不被复制。） 
     */
    public Object clone() {
        try {
            ArrayList<?> v = (ArrayList<?>) super.clone();
            //Arrays.copyOf功能是实现数组的复制，返回复制后的数组。参数是被复制的数组和复制的长度
            v.elementData = Arrays.copyOf(elementData, size);
            v.modCount = 0;
            return v;
        } catch (CloneNotSupportedException e) {
            // 这不应该发生，因为我们是可以克隆的
            throw new InternalError(e);
        }
    }

    /**
     *以正确的顺序（从第一个到最后一个元素）返回一个包含此列表中所有元素的数组。 
     *返回的数组将是“安全的”，因为该列表不保留对它的引用。 （换句话说，这个方法必须分配一个新的数组）。
     *因此，调用者可以自由地修改返回的数组。 此方法充当基于阵列和基于集合的API之间的桥梁。
     */
    public Object[] toArray() {
        return Arrays.copyOf(elementData, size);
    }

    /**
     * 以正确的顺序返回一个包含此列表中所有元素的数组（从第一个到最后一个元素）; 
     *返回的数组的运行时类型是指定数组的运行时类型。 如果列表适合指定的数组，则返回其中。 
     *否则，将为指定数组的运行时类型和此列表的大小分配一个新数组。 
     *如果列表适用于指定的数组，其余空间（即数组的列表数量多于此元素），则紧跟在集合结束后的数组中的元素设置为null 。
     *（这仅在调用者知道列表不包含任何空元素的情况下才能确定列表的长度。） 
     */
    @SuppressWarnings("unchecked")
    public <T> T[] toArray(T[] a) {
        if (a.length < size)
            // 新建一个运行时类型的数组，但是ArrayList数组的内容
            return (T[]) Arrays.copyOf(elementData, size, a.getClass());
            //调用System提供的arraycopy()方法实现数组之间的复制
        System.arraycopy(elementData, 0, a, 0, size);
        if (a.length > size)
            a[size] = null;
        return a;
    }

    // Positional Access Operations

    @SuppressWarnings("unchecked")
    E elementData(int index) {
        return (E) elementData[index];
    }

    /**
     * 返回此列表中指定位置的元素。
     */
    public E get(int index) {
        rangeCheck(index);

        return elementData(index);
    }

    /**
     * 用指定的元素替换此列表中指定位置的元素。 
     */
    public E set(int index, E element) {
        //对index进行界限检查
        rangeCheck(index);

        E oldValue = elementData(index);
        elementData[index] = element;
        //返回原来在这个位置的元素
        return oldValue;
    }

    /**
     * 将指定的元素追加到此列表的末尾。 
     */
    public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        //这里看到ArrayList添加元素的实质就相当于为数组赋值
        elementData[size++] = e;
        return true;
    }

    /**
     * 在此列表中的指定位置插入指定的元素。 
     *先调用 rangeCheckForAdd 对index进行界限检查；然后调用 ensureCapacityInternal 方法保证capacity足够大；
     *再将从index开始之后的所有成员后移一个位置；将element插入index位置；最后size加1。
     */
    public void add(int index, E element) {
        rangeCheckForAdd(index);

        ensureCapacityInternal(size + 1);  // Increments modCount!!
        //arraycopy()这个实现数组之间复制的方法一定要看一下，下面就用到了arraycopy()方法实现数组自己复制自己
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);
        elementData[index] = element;
        size++;
    }

    /**
     * 删除该列表中指定位置的元素。 将任何后续元素移动到左侧（从其索引中减去一个元素）。 
     */
    public E remove(int index) {
        rangeCheck(index);

        modCount++;
        E oldValue = elementData(index);

        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
      //从列表中删除的元素 
        return oldValue;
    }

    /**
     * 从列表中删除指定元素的第一个出现（如果存在）。 如果列表不包含该元素，则它不会更改。
     *返回true，如果此列表包含指定的元素
     */
    public boolean remove(Object o) {
        if (o == null) {
            for (int index = 0; index < size; index++)
                if (elementData[index] == null) {
                    fastRemove(index);
                    return true;
                }
        } else {
            for (int index = 0; index < size; index++)
                if (o.equals(elementData[index])) {
                    fastRemove(index);
                    return true;
                }
        }
        return false;
    }

    /*
     * Private remove method that skips bounds checking and does not
     * return the value removed.
     */
    private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
    }

    /**
     * 从列表中删除所有元素。 
     */
    public void clear() {
        modCount++;

        // 把数组中所有的元素的值设为null
        for (int i = 0; i < size; i++)
            elementData[i] = null;

        size = 0;
    }

    /**
     * 按指定集合的Iterator返回的顺序将指定集合中的所有元素追加到此列表的末尾。
     */
    public boolean addAll(Collection<? extends E> c) {
        Object[] a = c.toArray();
        int numNew = a.length;
        ensureCapacityInternal(size + numNew);  // Increments modCount
        System.arraycopy(a, 0, elementData, size, numNew);
        size += numNew;
        return numNew != 0;
    }

    /**
     * 将指定集合中的所有元素插入到此列表中，从指定的位置开始。
     */
    public boolean addAll(int index, Collection<? extends E> c) {
        rangeCheckForAdd(index);

        Object[] a = c.toArray();
        int numNew = a.length;
        ensureCapacityInternal(size + numNew);  // Increments modCount

        int numMoved = size - index;
        if (numMoved > 0)
            System.arraycopy(elementData, index, elementData, index + numNew,
                             numMoved);

        System.arraycopy(a, 0, elementData, index, numNew);
        size += numNew;
        return numNew != 0;
    }

    /**
     * 从此列表中删除所有索引为fromIndex （含）和toIndex之间的元素。
     *将任何后续元素移动到左侧（减少其索引）。
     */
    protected void removeRange(int fromIndex, int toIndex) {
        modCount++;
        int numMoved = size - toIndex;
        System.arraycopy(elementData, toIndex, elementData, fromIndex,
                         numMoved);

        // clear to let GC do its work
        int newSize = size - (toIndex-fromIndex);
        for (int i = newSize; i < size; i++) {
            elementData[i] = null;
        }
        size = newSize;
    }

    /**
     * 检查给定的索引是否在范围内。
     */
    private void rangeCheck(int index) {
        if (index >= size)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    /**
     * add和addAll使用的rangeCheck的一个版本
     */
    private void rangeCheckForAdd(int index) {
        if (index > size || index < 0)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    /**
     * 返回IndexOutOfBoundsException细节信息
     */
    private String outOfBoundsMsg(int index) {
        return "Index: "+index+", Size: "+size;
    }

    /**
     * 从此列表中删除指定集合中包含的所有元素。 
     */
    public boolean removeAll(Collection<?> c) {
        Objects.requireNonNull(c);
        //如果此列表被修改则返回true
        return batchRemove(c, false);
    }

    /**
     * 仅保留此列表中包含在指定集合中的元素。
     *换句话说，从此列表中删除其中不包含在指定集合中的所有元素。 
     */
    public boolean retainAll(Collection<?> c) {
        Objects.requireNonNull(c);
        return batchRemove(c, true);
    }


    /**
     * 从列表中的指定位置开始，返回列表中的元素（按正确顺序）的列表迭代器。
     *指定的索引表示初始调用将返回的第一个元素为next 。 初始调用previous将返回指定索引减1的元素。 
     *返回的列表迭代器是fail-fast 。 
     */
    public ListIterator<E> listIterator(int index) {
        if (index < 0 || index > size)
            throw new IndexOutOfBoundsException("Index: "+index);
        return new ListItr(index);
    }

    /**
     *返回列表中的列表迭代器（按适当的顺序）。 
     *返回的列表迭代器是fail-fast 。
     */
    public ListIterator<E> listIterator() {
        return new ListItr(0);
    }

    /**
     *以正确的顺序返回该列表中的元素的迭代器。 
     *返回的迭代器是fail-fast 。 
     */
    public Iterator<E> iterator() {
        return new Itr();
    }

 }
```

# LinkedList

## 简单实现LinkedList

```java
import static org.hamcrest.CoreMatchers.nullValue;

public class MyLinkedListTest {
	public static void main(String[] args) {
		MyLinkedList2 mll = new MyLinkedList2();
		//顺序添加
		mll.add("L");
		mll.add("H");
		mll.add("F");
		mll.add("Z");
		mll.add("Q");
		
		//指定下标添加
		mll.add(5,"J");
		
		//遍历数组
		for(int i = 0; i < mll.size(); i++){
			System.out.print(mll.get(i)+"\t");
		}
		System.out.println();
		
		//设置指定位置元素
		mll.set(4, "H");
		//获取指定位置元素
		System.out.println(mll.get(0));
		
		mll.remove(4);//删除指定位置元素
		for(int i = 0; i < mll.size(); i++){
			System.out.print(mll.get(i)+"\t");
		}
		System.out.println();
		
		//判断元素出现的首下标
		System.out.println(mll.indexOf("H"));
		System.out.println(mll.indexOf("Q"));
		
		//判断元素是否存在
		System.out.println(mll.contains("H"));
		System.out.println(mll.contains("Q"));
	}
}
class MyLinkedList{
	//链表中是以节点连接的，所以先创建一个节点类
	//为了使用方法。定义为静态成员内部类、
	private static class Node{
		//创建一个Object对象，保存数据
		Object data;
		Node next;//保存下一个节点的地址
		
		//公开的构造方法
		public Node(Object data){
			this.data=data;
		}

		@Override
		public String toString() {
			return "Node [data=" + data + ", next=" + next + "]";
		}
		
	}
	
	Node head;//代表首节点
	int size;//代表有效元素个数
	
	//顺序添加
	public void add(Object data){
		//创建一个新节点对象
		Node newNode=new Node(data);
		//如果是首次添加
		if(head==null){
			head=newNode;
		}else {
			//不是首次添加，要找到末尾节点
			Node p=head;
			while (p.next!=null) {
				//将下一个的节点的地址赋值给p，p指向下一个节点
				p=p.next;
			}
			//循环结束，p指向尾部节点
			p.next=newNode;
			
		}
		size++;
		
	}
	
	//返回index处节点
	public Node node(int index){
		int count=0;//计数器
		Node p=head;
		//使用while循环，找到index处的节点
		while (count<index) {
			//将下一个节点的地址赋值给p，p指向下一个节点
			p=p.next;
			count++;
		}
		return p;
	}
	
	//指定下标添加
	public void add(int index,Object data){
		//创建一个新节点
		Node newNode=new Node(data);
		//如果是添加到头部
		if(index==0){
			newNode.next=head;
			head=newNode;
		}else {
			//获取index-1处节点p
			Node p=node(index-1);
			//获取index处的节点q
			Node q=p.next;
			//将p指向newNode，将newNode指向q
			p.next=newNode;
			newNode.next=q;
		}
		size++;
	}
	
	//指定下标删除
	public void remove(int index){
		//如果是删除0下标的元素
		if (index==0) {
			Node p=head;
			head=p.next;
			p.next=null;
		}else {
//			获取index-1和index节点
			Node p=node(index-1);
			Node k=p.next;
			//获取index+1处的节点
			Node q=k.next;
			
			//p指向p。断开k和q的联系
			//把q的地址赋值给p.next
			p.next=q;
			//p.next原来存的是k的地址，下面的式子只是把k的地址赋值给q，p和q并没有产生联系
			//q=p.next;
			k.next=null;
		}
		size--;
	}
	
	//更新指定下标元素
	public void set(int index,Object data){
		node(index).data=data;
	}
	
	//获取指定下标元素
	public Object get(int index){
		return node(index).data;
	}
	
	//获取有效元素数量
	public int size(){
		return size;
	}
	
	//获取元素首次出现的下标
	public int indexOf(Object data){
		int count=0;
		//定义p为head元素
		Node p=head;
		//如果p不为null，一直循环
		while (p!=null) {
			if(p.data.equals(data))
				return count;
			//p是一个引用，并没有实际地址
			p=p.next;
			count++;
		}
		return -1;
	}
	
	//判断是否包含一个元素
	public boolean contains(Object data){
		return indexOf(data)>=0;
	}
}
```



