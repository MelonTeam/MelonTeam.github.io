---
layout: post
title: "浅析android中的threadlocal"
date: 2017-06-30 22:49:00
categories: android
author: limingzhang
tags: threadlo... android
---

* content
{:toc}



threadlocal第一眼很容易让人误以为这是一个thread，其实并不是，它是在jdk
1.2中引入，为每个线程提供一个独立的本地变量副本，用来解决变量并发访问的冲突问题。所有的线程可以共享一个threadlocal对象，但是每一个线程只能访问自己所存储的变量，线程之间互不影响。那为什么标题中说的是android中的threadlocal呢，原因是android中的threadlocal和jdk的threadlocal代码实现上是有一定区别的，虽然最终实现的效果是一样的。

<!--more-->
# 一. looper

threadlocal在业务开发中使用的场景比较少，所以对大家来说会比较陌生，但是它却和我们平时写的每一行代码都息息相关，接下来一起看一段简单的代码：

    
    
        class mythread extends handlerthread {
            public mythread(string name) {
                super(name);
            }
            @override
            public void run() {
                looper.prepare();
                handler = new handler();
                looper.loop();
            }
        }

我们知道，一个线程本身是不存在消息循环的，我们需要手动调用looper.prepare()，然后再调用looper.loop()创建一个消息循环，这样的话这个线程就有了自己的一个消息循环looper，我们可以通过looper.mylooper()获取当前所在线程的looper,
那么这个looper是保存在哪里的呢？我们点进looper.prepare()这个方法一起看一下：

    
    
        public static void prepare() {
            prepare(true);
        }
    
        private static void prepare(boolean quitallowed) {
            if (sthreadlocal.get() != null) {
                throw new runtimeexception("only one looper may be created per thread");
            }
            sthreadlocal.set(new looper(quitallowed));
        }

首先创建了一个looper对象，在looper对象的构造函数中创建了一个消息队列，然后把这个looper对象放在一个静态的成员变量sthreadlocal里头。因此所有支持消息循环的线程都共享一个threadlocal对象，但是同时也可以获取到只属于自己线程的looper，线程之间互不影响。当我们调用handler的post的方法时候，其实就是把消息丢进了创建该handler时所在的线程的消息队列里头，终止被该线程的looper所执行。

# 二.threadlocal源码分析

  
看到这里可能大家就会想，looper在sthreadlocal内部是如何存储呢？我们一起进去看下set方法：

    
    
    /**
         * sets the value of this variable for the current thread. if set to
         * {@code null}, the value will be set to null and the underlying entry will
         * still be present.
         *
         * @param value the new value of the variable for the caller thread.
         */
        public void set(t value) {
            thread currentthread = thread.currentthread();
            values values = values(currentthread);
            if (values == null) {
                values = initializevalues(currentthread);
            }
            values.put(this, value);
        }

 先获取当前的线程 currentthread,
然后取出currentthread的一个成员变量values，这个values其实就在最终存value的数据结构，如果values为空的话通过initializevalues为其创建一个values。我们一起看下这个values类。

    
    
    static class values {
    
            /**
             * size must always be a power of 2.
             */
            private static final int initial_size = 16;
    
            /**
             * placeholder for deleted entries.
             */
            private static final object tombstone = new object();
    
            /**
             * map entries. contains alternating keys (threadlocal) and values.
             * the length is always a power of 2.
             */
            private object[] table;
    
            /** used to turn hashes into indices. */
            private int mask;
    
            /** number of live entries. */
            private int size;
    
            /** number of tombstones. */
            private int tombstones;
    
            /** maximum number of live entries and tombstones. */
            private int maximumload;
    
            /** points to the next cell to clean up. */
            private int clean;

values初始化时的代码如下：

    
    
           values() {
                initializetable(initial_size);
                this.size = 0;
                this.tombstones = 0;
            }
    
           private void initializetable(int capacity) {
                this.table = new object[capacity * 2];
                this.mask = table.length - 1;
                this.clean = 0;
                this.maximumload = capacity * 2 / 3; // 2/3
            }

这个table是用于存储我们用到的数组，但是它不仅仅存储value的值，他会先存储当前value所对应的值threadlocal的弱引用，然后在下一位存储value的值。可知table的长度一定是2的n次方，而mask的值则为2的n次方减一，maximumload这个值则是用来判断是否需要扩充table的数组大小。

初始化完values，我们就需要把value  put进 values中。

    
    
            /**
             * sets entry for given threadlocal to given value, creating an
             * entry if necessary.
             */
            void put(threadlocal> key, object value) {
                cleanup();
    
                // keep track of first tombstone. that's where we want to go back
                // and add an entry if necessary.
                int firsttombstone = -1;
    
                for (int index = key.hash & mask;; index = next(index)) {
                    object k = table[index];
    
                    if (k == key.reference) {
                        // replace existing entry.
                        table[index + 1] = value;
                        return;
                    }
    
                    if (k == null) {
                        if (firsttombstone == -1) {
                            // fill in null slot.
                            table[index] = key.reference;
                            table[index + 1] = value;
                            size++;
                            return;
                        }
    
                        // go back and replace first tombstone.
                        table[firsttombstone] = key.reference;
                        table[firsttombstone + 1] = value;
                        tombstones--;
                        size++;
                        return;
                    }
    
                    // remember first tombstone.
                    if (firsttombstone == -1 && k == tombstone) {
                        firsttombstone = index;
                    }
                }
            }

在开头先调用了cleanup方法，顾名思义就是释放掉当前table数字中已经失效的value值。然后通过一个for循环寻找当前的value值需要存放的位置，这里起始的index使用的是key.hash
& mask，这样做的用意是什么呢? 我们知道mask的值为2的n次方减一，所以它的二进制的值每一位都是1，我们再看下key.hash的值是多少：

    
    
    /**
         * internal hash. we deliberately don't bother with #hashcode().
         * hashes must be even. this ensures that the result of
         * (hash & (table.length - 1)) points to a key and not a value.
         *
         * we increment by doug lea's magic number(tm) (*2 since keys are in
         * every other bucket) to help prevent clustering.
         */
        private final int hash = hashcounter.getandadd(0x61c88647 * 2);

 这是一个神奇的数字0x61c88647，具体为什么取这个值我们暂时不深究，为的是让这个table上值存储不重复，而且分散。最后key.hash &
mask的值会落在table中的某个位置。接下来在for循环中如果我们在table中找到了threadlocal的弱引用，则替换它的下一位的value的值。如果没有找到对应的threadlocal的引用，则在table中存入当前value所对应的threadlocal的弱引用，并在下一位存入value的值。然后我们通过threadlocal的get方法查找时，其实也是先查找到对应的threadlocal的弱引用，然后下一位才是对应的value的值。

