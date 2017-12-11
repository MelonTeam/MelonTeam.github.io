---
layout: post
title: "ArrayList源码完全分析"
date: 2017-08-31 16:44:00 +0800
categories: android
author: baobaowang
tags: ArrayList
---

* content
{:toc}

| 导语 这里分析的ArrayList是使用的JDK1.8里面的类，AndroidSDK里面的ArrayList基本和这个一样。
分析的方式是逐个API进行解析 关键的内容都在代码的注释以及代码下边的分析中

### 1、数组构造与扩容

<!--more-->
涉及的API如下：

    
    
    public ArrayList(int initialCapacity) {
        if (initialCapacity > 0) {
            this.elementData = new Object[initialCapacity];
        } else if (initialCapacity == 0) {
            this.elementData = EMPTY_ELEMENTDATA;
        } else {
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        }
    }
    
    public ArrayList() {
        this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
    }
    
     public void ensureCapacity(int minCapacity) {
        //如果构造方法没有指定初始容量，那么调用ensureCapacity时，会将容量设置为DEFAULT_CAPACITY=10
        int minExpand = (elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
            ? 0: DEFAULT_CAPACITY;
    
        if (minCapacity > minExpand) {
            ensureExplicitCapacity(minCapacity);
        }
    }
    
    //这个方法会在类内部调用，它会保证如果列表没有指定初始值，则设置为10
     private void ensureCapacityInternal(int minCapacity) {
        if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
            minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
        }
    
        ensureExplicitCapacity(minCapacity);
    }
    
    private void ensureExplicitCapacity(int minCapacity) {
        //这里注意到这个modCount，它指的是对列表元素的修改次数。每次的修改包括添加，删除，都会加1 
        modCount++;
    
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
    
    private void grow(int minCapacity) {        
        int oldCapacity = elementData.length;
        //一次扩容后到原来容量的1.5倍
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        //如果1.5倍容量不够，则直接扩充到minCapacity值
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        //这行代码会创以newCapacity大小创建一个新数组，并将数组复制到新数组中
        elementData = Arrays.copyOf(elementData, newCapacity);
    }



这里可以看到，构造时，即使没有指定初始容量，也不会立即将数组设置为10大小。一直要等到有add操作，或者其他会调用ensureCapacityInternal方法的操作才会设置为10大小。所以如果能确定你的列表是比10小的，可以自己指定这个容量，节省一定的空间。

### 2、空判断

    
    
    //所以我们判断一个列表是否为空，也可以  !list.isEmpty()
    public boolean isEmpty() {
        return size == 0;
    }



### 3、检查一个项是否在列表中存在

    
    
    public boolean contains(Object o) {
        return indexOf(o) >= 0;
    }
    
     public int indexOf(Object o) {
        if (o == null) {
            for (int i = 0; i < size; i++)
                if (elementData[i]==null)
                    return i;
        } else {
            for (int i = 0; i < size; i++)
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
    }



这里可以看出，要查一个项是否在列表中，可以使用contains。而contains使用的方法是从头到尾遍历整个列表，使用equals来判断。所以我们只需要重写类的equals方法即可(如果这个类需要用作hash类的键，记得重写hashcode())。这里要注意到遍历方式为顺序遍历，如果列表很大，是会有性能问题的。所以如果有需求是要判断一个值是否存在，或者设置一些标志位，并且不需要保持顺序，可以使用HashSet之类的集合来处理，而不是使用ArrayList。

### 4、添加元素

    
    
    public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }
    
     public void add(int index, E element) {
        rangeCheckForAdd(index);
    
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);
        elementData[index] = element;
        size++;
    }



这里可以看到ensureCapacityInternal方法会使modCount++。而modCount会和迭代器的预期modCount比较，如果不同会抛出也会导致ConcurrentModificationException，下面的这块的说明。

另外这两个add方法，一个是在元素末尾，一个是在中间。在元素末尾添加的不会有元素移动，所以效率更高。

### 5、删除操作

    
    
     private void rangeCheck(int index) {
        if (index >= size)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }
    
    public E remove(int index) {
        //边界检测
        rangeCheck(index);
    
        modCount++;
        E oldValue = elementData(index);
    
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        //注意这里的赋值，以便GC可以回收这里的引用
        elementData[--size] = null; 
    
        return oldValue;
    }
    
    //和contains一样，也是遍历整个表来remove掉某个元素，效率不高
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
    
    //仅仅少了边界检测
     private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
    }



### 6、批量删除

    
    
    public boolean removeAll(Collection> c) {
        Objects.requireNonNull(c);
        return batchRemove(c, false);
    }
    
    //与removeAll是相反的作用
     public boolean retainAll(Collection> c) {
        Objects.requireNonNull(c);
        return batchRemove(c, true);
    }
    
    private boolean batchRemove(Collection> c, boolean complement) {
        final Object[] elementData = this.elementData;
        int r = 0, w = 0;
        boolean modified = false;
        try {
            for (; r < size; r++)
                //这里也是通过contains来判断，这里总共遍历了两个列表，所以如果两个列表很大，效率不好。
                if (c.contains(elementData[r]) == complement)
                    elementData[w++] = elementData[r];
        } finally {            
            if (r != size) {
                System.arraycopy(elementData, r,
                                 elementData, w,
                                 size - r);
                w += size - r;
            }
            if (w != size) {                
                for (int i = w; i < size; i++)
                    elementData[i] = null;
                modCount += size - w;
                size = w;
                modified = true;
            }
        }
        return modified;
    }



可以看出对ArrayList的添加删除操作效率是不高的，而随机访问效率很高

### 7、迭代器

    
    
    public Iterator iterator() {
        return new ArrayListIterator();
    }
    
    private class Itr implements Iterator<E> {
        int cursor;       // index of next element to return
        int lastRet = -1; // index of last element returned; -1 if no such
        int expectedModCount = modCount;
    
    final void checkForComodification() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
        }



从成员变量中可以看到expectedModCount，这个变量和我们平时遇到的ConcurrentModificationException有关。这里变量的赋值说明在调用iterator()方法后，这个值就确定下来了。checkForComodification()方法会在迭代器的next(),remove()等方法中调用。对比modCount和expectedModCount是否相同，不相同会抛出ConcurrentModificationException异常。前面
说过modCount是ArrayList的成员变量，而expectedModCount是迭代器的成员变量。modCount会在ArrayList的add,remove,removeAll等方法中调用。所以如果在一个迭代器的使用过程中，有add,remove等操作，会导致ConcurrentModificationException异常。而且这个异常不一定是发生在多线程当中，只要满足这个情况就能发生。典型的情景如下：

    
    
    ArrayList test = new ArrayList<>(100);
        for(int i=0;i<100;i++){
            test.add(i+"");
        }
        for(String str:test){
            if(str.equals("10")){
                test.remove(str);
            }
        }



或：

    
    
    Iterator it = test.iterator();
        while (it.hasNext()){
            String str = it.next();
            if(str.equals("10")){
                test.remove(str);
            }
        }



这里会导致ConcurrentModificationException异常

    
    
    public E next() {
            //这里对比了modCount和expectedModCount
            checkForComodification();
            int i = cursor;
            if (i >= size)
                throw new NoSuchElementException();
            Object[] elementData = ArrayList.this.elementData;
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i + 1;
            return (E) elementData[lastRet = i];
        }
    
    public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();
            checkForComodification();
    
            try {
                ArrayList.this.remove(lastRet);
                cursor = lastRet;
                lastRet = -1;
                //同步两个值
                expectedModCount = modCount;
            } catch (IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }



在迭代器的remove方法中可以看到，执行完remove操作后，会同步expectedModCount =
modCount的值，所以在上面抛异常的示例中，如果使用迭代器的remove方法，则不会有这个异常。

### 8、subList

    
    
    public List subList(int fromIndex, int toIndex) {
        subListRangeCheck(fromIndex, toIndex, size);
        return new SubList(this, 0, fromIndex, toIndex);
    }
    
    private class SubList extends AbstractList<E> implements RandomAccess {
        private final AbstractList parent;
        private final int parentOffset;
        private final int offset;
        int size;
    
        SubList(AbstractList parent,
                int offset, int fromIndex, int toIndex) {
            this.parent = parent;
            this.parentOffset = fromIndex;
            this.offset = offset + fromIndex;
            this.size = toIndex - fromIndex;
            this.modCount = ArrayList.this.modCount;
        }



从SubList的构造方法可以看出，它其实只是记录了当前列表的一些索引，数组元素是共用的。对subList的所有操作都是对原来ArrayList的操作，只是会加上一个偏移量。

这里要特别提及一个clear()方法，可以看到ArrayList覆盖了AbstractList的clear()，而SubList并没有覆盖。

    
    
    //SubList的clear()方法
    public void clear() {
        removeRange(0, size());
    }
    
    //ArrayList的clear()方法
    public void clear() {
        modCount++;
    
        // clear to let GC do its work
        for (int i = 0; i < size; i++)
            elementData[i] = null;
    
        size = 0;
    }



SubList不能覆盖的原因很明显，因为SubList是ArrayList一个子集，对SubList执行clear()会有元素的移动，而不仅仅赋值为空。

从SubList的clear()方法中可以看到调用了removeRange，比起单个循环remove，这个方法可以提高remove效率，特别是对于很长的列表。

### 9、removeIf,replaceAll,sort

    
    
     public boolean removeIf(Predicate super E> filter) {
        Objects.requireNonNull(filter);
        int removeCount = 0;
        final BitSet removeSet = new BitSet(size);
        final int expectedModCount = modCount;
        final int size = this.size;
        for (int i=0; modCount == expectedModCount && i < size; i++) {
            @SuppressWarnings("unchecked")
            final E element = (E) elementData[i];
            //记录需要移除的元素的位置
            if (filter.test(element)) {
                removeSet.set(i);
                removeCount++;
            }
        }
        if (modCount != expectedModCount) {
            throw new ConcurrentModificationException();
        }
    
        // shift surviving elements left over the spaces left by removed elements
        final boolean anyToRemove = removeCount > 0;
        if (anyToRemove) {
            final int newSize = size - removeCount;
            for (int i=0, j=0; (i < size) && (j < newSize); i++, j++) {
                //当前BitSet对象指定位置或之后第一个设置为false的位的位置，也就是不移除的元素的位置
                i = removeSet.nextClearBit(i);
                //将要保留的元素前移
                elementData[j] = elementData[i];
            }
            for (int k=newSize; k < size; k++) {
                elementData[k] = null;  // Let gc do its work
            }
            this.size = newSize;
            if (modCount != expectedModCount) {
                throw new ConcurrentModificationException();
            }
            modCount++;
        }
    
        return anyToRemove;
    }
    
    public void replaceAll(UnaryOperator operator) {
        Objects.requireNonNull(operator);
        final int expectedModCount = modCount;
        final int size = this.size;
        for (int i=0; modCount == expectedModCount && i < size; i++) {
            elementData[i] = operator.apply((E) elementData[i]);
        }
        if (modCount != expectedModCount) {
            throw new ConcurrentModificationException();
        }
        modCount++;
    }
    
     public void sort(Comparator super E> c) {
        final int expectedModCount = modCount;
        Arrays.sort((E[]) elementData, 0, size, c);
        if (modCount != expectedModCount) {
            throw new ConcurrentModificationException();
        }
        modCount++;
    }



这三个方法中，都有对modCount !=
expectedModCount的检测。这里removeIf有一个值得学习的地方，它removeIf的方式并不是直接remove满足条件的元素，而是批量记录，再通过一次循环移动元素，大量减少了元素的移动次数。

