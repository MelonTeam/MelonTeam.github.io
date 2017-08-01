---
layout: post
title: "Objective-C内存管理原理探究（一）"
date: 2017-07-10 14:05:00 +0800
categories: android
author: chaodong
tags: OC原理 内存管理 引用计数
---

* content
{:toc}

| 导语 让我们通过源代码了解OC内存管理的机制。

# 前言

相信每个人在开发iOS的过程中都有过OC是如何管理内存的疑问，虽然大家都知道是基于引用计数的，但retain，release究竟做了什么，只是简单的将引用计数加减1吗？Autorelease又究竟做了什么？Weak又是怎样实现的？等等跟内存相关的问题~本系列文章就从源代码级别来探究下OC究竟是怎么管理内存的~计划分为三篇  
<!--more-->
1.基础引用计数方法探究  
2.ARC内存管理探究  
3.Autorelease实现探究  
本文是第一篇~

>
本文使用的源代码是[objc4-709](https://opensource.apple.com/tarballs/objc4/objc4-709.tar.gz)

# 一、引用计数

说起OC的内存管理必须要先说下引用计数：  
1.我们创建一个新对象时，该对像引用计数为1；  
2.有一个新的指针关联到该对象时，他的引用计数就加1；  
3.对象关联的某个指针不再指向他时，他的引用计数就减1；  
4.对象的引用计数为0时，说明此对象不再被任何指针指向，这时我们就可以将对象销毁。  
这便是引用计数。

![](/image/objective_c_nei_cun_guan_li_yuan_li_tan_jiu__yi_/c5fd84955f4a273dc0d80501f86533d0fe5dee23a4af55c1a4a26f84d8d842e0)

# 二、alloc、init、retain，release实现

## alloc实现

OC中声明一个NSObjec是总是会先调用下`alloc`，但这个`alloc`究竟是做了什么呢？

在NSObject.mm中可以找到`alloc`的实现

    
    
    + (id)alloc {
        return _objc_rootAlloc(self);
    }
    
    id
    _objc_rootAlloc(Class cls)
    {
        return callAlloc(cls, false/*checkNil*/, true/*allocWithZone*/);
    }
    
    static ALWAYS_INLINE id
    callAlloc(Class cls, bool checkNil, bool allocWithZone=false)
    {
        if (slowpath(checkNil && !cls)) return nil;
    
    #if __OBJC2__
        if (fastpath(!cls->ISA()->hasCustomAWZ())) {
            // No alloc/allocWithZone implementation. Go straight to the allocator.
            // fixme store hasCustomAWZ in the non-meta class and 
            // add it to canAllocFast's summary
            if (fastpath(cls->canAllocFast())) {
                // No ctors, raw isa, etc. Go straight to the metal.
                bool dtor = cls->hasCxxDtor();
                id obj = (id)calloc(1, cls->bits.fastInstanceSize());
                if (slowpath(!obj)) return callBadAllocHandler(cls);
                obj->initInstanceIsa(cls, dtor);
                return obj;
            }
            else {
                // Has ctor or raw isa or something. Use the slower path.
                id obj = class_createInstance(cls, 0);
                if (slowpath(!obj)) return callBadAllocHandler(cls);
                return obj;
            }
        }
    #endif
    
        // No shortcuts available.
        if (allocWithZone) return [cls allocWithZone:nil];
        return [cls alloc];
    }
    

大概流程如下:  
1）`slowpath(checkNil && !cls)`

看下`slowpath`和`fastpath`的定义

    
    
    #define fastpath(x) (__builtin_expect(bool(x), 1))
    #define slowpath(x) (__builtin_expect(bool(x), 0))
    

> `__builtin_expect`起的是优化性能的作用  
> `__builtin_expect((x),1)` 表示 x 的值为真的可能性更大；  
> `__builtin_expect((x),0)` 表示 x 的值为假的可能性更大。

从宏的定义中可以看出`slowpath(checkNil &&
!cls)`是对cls进行nil判断，但这里cls大概率不为nil所以这里使用`slowpath`。

2）通过`hasCustomAWZ`，判断是否有自定义allocWithZone实现

    
    
        bool hasCustomAWZ() {
            return ! bits.hasDefaultAWZ();
        }
    
    
    
    #if FAST_HAS_DEFAULT_AWZ
        bool hasDefaultAWZ() {
            return getBit(FAST_HAS_DEFAULT_AWZ);
        }
        void setHasDefaultAWZ() {
            setBits(FAST_HAS_DEFAULT_AWZ);
        }
        void setHasCustomAWZ() {
            clearBits(FAST_HAS_DEFAULT_AWZ);
        }
    #else
        bool hasDefaultAWZ() {
            return data()->flags & RW_HAS_DEFAULT_AWZ;
        }
        void setHasDefaultAWZ() {
            data()->setFlags(RW_HAS_DEFAULT_AWZ);
        }
        void setHasCustomAWZ() {
            data()->clearFlags(RW_HAS_DEFAULT_AWZ);
        }
    #endif
    

`hasCustomAWZ`用来判断是否有自定义的的allocWithZone方法，如果为YES则说明有自定义实现，则不能走默认逻辑。  
`hasCustomAWZ`为YES时直接调用allocWithZone方法。

    
    
    // Replaced by ObjectAlloc
    + (id)allocWithZone:(struct _NSZone *)zone {
        return _objc_rootAllocWithZone(self, (malloc_zone_t *)zone);
    }
    
    id
    _objc_rootAllocWithZone(Class cls, malloc_zone_t *zone)
    {
        id obj;
    
    #if __OBJC2__
        // allocWithZone under __OBJC2__ ignores the zone parameter
        (void)zone;
        obj = class_createInstance(cls, 0);
    #else
        if (!zone) {
            obj = class_createInstance(cls, 0);
        }
        else {
            obj = class_createInstanceFromZone(cls, 0, zone);
        }
    #endif
    
        if (slowpath(!obj)) obj = callBadAllocHandler(cls);
        return obj;
    }
    

可以看出allocWithZone实际上调用的也是`class_createInstanceFromZone`。

3）`hasCustomAWZ`为NO时，还需要再次判断当前的class是否支持快速alloc。如果支持，直接调用calloc函数，申请bits.fastInstanceSize()大小的内存空间，如果创建失败，会调用`callBadAllocHandler`函数，如果不支持快速alloc则调用`class_createInstance`

我们再看看定义FAST_ALLOC的地方

    
    
    #if !__LP64__
    
    ...
    
    #elif 1
    // Leaks-compatible version that steals low bits only.
    
    // class or superclass has .cxx_construct implementation
    #define RW_HAS_CXX_CTOR       (1<<18)
    // class or superclass has .cxx_destruct implementation
    #define RW_HAS_CXX_DTOR       (1<<17)
    // class or superclass has default alloc/allocWithZone: implementation
    // Note this is is stored in the metaclass.
    #define RW_HAS_DEFAULT_AWZ    (1<<16)
    
    // class is a Swift class
    #define FAST_IS_SWIFT           (1UL<<0)
    // class or superclass has default retain/release/autorelease/retainCount/
    //   _tryRetain/_isDeallocating/retainWeakReference/allowsWeakReference
    #define FAST_HAS_DEFAULT_RR     (1UL<<1)
    // class's instances requires raw isa
    #define FAST_REQUIRES_RAW_ISA   (1UL<<2)
    // data pointer
    #define FAST_DATA_MASK          0x00007ffffffffff8UL
    
    #else
    ..
    #define FAST_ALLOC              (1UL<<50)
    // instance size in units of 16 bytes
    //   or 0 if the instance size is too big in this field
    //   This field must be LAST
    #define FAST_SHIFTED_SIZE_SHIFT 51
    

这里有个#elif 1，所以现在其实FAST_ALLOC 是没有定义的，所以一定会调用`class_createInstance`创建对象。  
在`objc-runtime-new.mm`中可以找到`class_createInstance`方法

    
    
    id 
    class_createInstance(Class cls, size_t extraBytes)
    {
        return _class_createInstanceFromZone(cls, extraBytes, nil);
    }
    
    static __attribute__((always_inline)) 
    id
    _class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone, 
                                  bool cxxConstruct = true, 
                                  size_t *outAllocatedSize = nil)
    {
        if (!cls) return nil;
    
        assert(cls->isRealized());
    
        // Read class's info bits all at once for performance
        bool hasCxxCtor = cls->hasCxxCtor();
        bool hasCxxDtor = cls->hasCxxDtor();
        bool fast = cls->canAllocNonpointer();
    
        size_t size = cls->instanceSize(extraBytes);
        if (outAllocatedSize) *outAllocatedSize = size;
    
        id obj;
        if (!zone  &&  fast) {
            obj = (id)calloc(1, size);
            if (!obj) return nil;
            obj->initInstanceIsa(cls, hasCxxDtor);
        } 
        else {
            if (zone) {
                obj = (id)malloc_zone_calloc ((malloc_zone_t *)zone, 1, size);
            } else {
                obj = (id)calloc(1, size);
            }
            if (!obj) return nil;
    
            // Use raw pointer isa on the assumption that they might be 
            // doing something weird with the zone or RR.
            obj->initIsa(cls);
        }
    
        if (cxxConstruct && hasCxxCtor) {
            obj = _objc_constructOrFree(obj, cls);
        }
    
        return obj;
    }
    

从源码可以看出其实真正调用的是`_class_createInstanceFromZone`

`_class_createInstanceFromZone`函数过程如下：  
1、对 cls 判断 nil，如果 cls 是 nil 的话就直接返回 nil。

2、`assert(cls->isRealized());`判断该类是否已经做过realize，关于realize的详请可以参考[这篇](http://www.jianshu.com/p/68e7a40376dc)和[这篇](http://www.cocoachina.com/ios/20160518/16322.html)，realize主要是一些数据的拷贝和整理对齐。

3、判断是否支持`hasCxxCtor` 和 `hasCxxDtor`还有`canAllocNonpointer`，`hasCxxCtor` 和
`hasCxxDtor`是对 Objective-C++ 的支持，表示这个类是否有 C++
类构造函数和析构函数，如果有的话，需要进行额外的工作。`canAllocNonpointer`我们不用太关心，这里OC 2.0以上基本上返回的都是true。

4、通过`instanceSize`获取该对像的大小

    
    
        // May be unaligned depending on class's ivars.
        uint32_t unalignedInstanceSize() {
            assert(isRealized());
            return data()->ro->instanceSize;
        }
    
        // Class's ivar size rounded up to a pointer-size boundary.
        uint32_t alignedInstanceSize() {
            return word_align(unalignedInstanceSize());
        }
    
        size_t instanceSize(size_t extraBytes) {
            size_t size = alignedInstanceSize() + extraBytes;
            // CF requires all objects be at least 16 bytes.
            if (size < 16) size = 16;
            return size;
        }
    

通过代码我们可以看出来OC中的对象最小大小是16字节。

5、一般zone都是为false（NSZone 已经弃用），fast都是true，所以最后都是调用`initInstanceIsa`进行初始化

### 总结

最后我们用一张图概括下alloc的流程  
![](/image/objective_c_nei_cun_guan_li_yuan_li_tan_jiu__yi_/22edd31a0af2652724288ee0ee9da009f9925fe15c37091194e091a3a75a1ca5)

# init实现

    
    
    - (id)init {
        return _objc_rootInit(self);
    }
    
    id
    _objc_rootInit(id obj)
    {
        // In practice, it will be hard to rely on this function.
        // Many classes do not properly chain -init calls.
        return obj;
    }
    

我们发现init其实什么也没做，只是返回了对象本身。这里还有段注释说很多类可能没有调用[super inti]，所以这个init其实作用并不是特别大。

## SideTable介绍

在介绍retain的实现之前我们先介绍一个跟引用计数相关的数据结构SideTable

    
    
    struct SideTable {
        spinlock_t slock;
        RefcountMap refcnts;
        weak_table_t weak_table;
    
        SideTable() {
            memset(&weak_table, 0, sizeof(weak_table));
        }
    
        ~SideTable() {
            _objc_fatal("Do not delete SideTable.");
        }
    
        void lock() { slock.lock(); }
        void unlock() { slock.unlock(); }
        void forceReset() { slock.forceReset(); }
    
        // Address-ordered lock discipline for a pair of side tables.
    
        template
        static void lockTwo(SideTable *lock1, SideTable *lock2);
        template
        static void unlockTwo(SideTable *lock1, SideTable *lock2);
    };
    

其中`RefcountMap refcnts`存放的就是引用计数，`slock`是同步锁，`weak_table`是weak
table跟ARC的weak实现相关。

引用计数器定义了几个重要的宏，用来存储一些跟引用计数相关的标志位。

    
    
    // The order of these bits is important.
    #ifdef __LP64__
    #   define WORD_BITS 64
    #else
    #   define WORD_BITS 32
    #endif
    
    #define SIDE_TABLE_WEAKLY_REFERENCED (1UL<<0)
    #define SIDE_TABLE_DEALLOCATING      (1UL<<1)  // MSB-ward of weak bit
    #define SIDE_TABLE_RC_ONE            (1UL<<2)  // MSB-ward of deallocating bit
    #define SIDE_TABLE_RC_PINNED         (1UL<WORD_BITS-1))
    
    #define SIDE_TABLE_RC_SHIFT 2
    #define SIDE_TABLE_FLAG_MASK (SIDE_TABLE_RC_ONE-1)
    

每个retainCount都是size_t，是无符号整形  
所以根据上面的宏定义，一个retainCount的位区域划分如下图  
![](/image/objective_c_nei_cun_guan_li_yuan_li_tan_jiu__yi_/ffbc4ae37cc9cee1a93b300959a11f0feca767e9727c7e6a6cab45803b7aa706)  
`SIDE_TABLE_WEAKLY_REFERENCED` （内存的第 1位）标识该对象是否有过 weak 对象；  
`SIDE_TABLE_DEALLOCATING`（内存的第 2 位），标识该对象是否正在 dealloc。  
`SIDE_TABLE_RC_ONE` （内存的第 3 位），存放引用计数数值（三位之后都用来存放引用计数数值）。  
所以每次我们引用计数加一时，真正加的是4,在取出真正的引用计数时需要右移两位

# retain实现

    
    
    // Equivalent to calling [this retain], with shortcuts if there is no override
    // Replaced by ObjectAlloc
    - (id)retain {
        return ((id)self)->rootRetain();
    }
    
    inline id 
    objc_object::rootRetain()
    {
        if (isTaggedPointer()) return (id)this;
        return sidetable_retain();
    }
    

retain 函数只是直接调用了`rootRetain`，`rootRetain`首先判断是否为TaggedPointer，之后对 isa 中是否有自定义
retain 和 release，如果没有自定义的实现，则进入`sidetable_retain` 函数，否则的话直接向对象发送 retain 消息。  
判断是否为TaggedPointer，是因为针对TaggedPointer会做一些优化。本文就不详细叙述~我们在下一讲中在进行介绍。

    
    
    id
    objc_object::sidetable_retain()
    {
    #if SUPPORT_NONPOINTER_ISA
        assert(!isa.nonpointer);
    #endif
        SideTable& table = SideTables()[this];
    
        table.lock();
        size_t& refcntStorage = table.refcnts[this];
        if (! (refcntStorage & SIDE_TABLE_RC_PINNED)) {
            refcntStorage += SIDE_TABLE_RC_ONE;
        }
        table.unlock();
    
        return (id)this;
    }
    

`sidetable_retain`先从SideTables中取出SideTable，然后从table.refcnts中取出自己的retainCount存储区域，refcntStorage
+=
SIDE_TABLE_RC_ONE，而且这里有上锁，所以retain是线程安全的。之所以有SideTables，是为了减小锁的粒度，如果直接存放在一个SideTable中，那这个SideTable就是全局上锁了势必性能不好。

### 总结

  * SideTable包含着一个自旋锁slock来防止操作时可能出现的多线程读取问题、一个弱引用表weak_table以及引用计数表refcnts。
  * RefcountMap 通过Map的结构存储了对象持有者的地址以及引用计数
  * SideTables中存放SideTable，SideTable中存放refcnts，是两层嵌套。
  * 由于bitMask的使用，每次retain引用计数的值实际上增加了(1 << 2) = 4而不是1

# release实现

    
    
    - (oneway void)release {
        ((id)self)->rootRelease();
    }
    
    inline bool 
    objc_object::rootRelease()
    {
        if (isTaggedPointer()) return false;
        return sidetable_release(true);
    }
    
    // rdar://20206767
    // return uintptr_t instead of bool so that the various raw-isa 
    // -release paths all return zero in eax
    uintptr_t
    objc_object::sidetable_release(bool performDealloc)
    {
    #if SUPPORT_NONPOINTER_ISA
        assert(!isa.nonpointer);
    #endif
        SideTable& table = SideTables()[this];
    
        bool do_dealloc = false;
    
        table.lock();
        RefcountMap::iterator it = table.refcnts.find(this);
        if (it == table.refcnts.end()) {
            do_dealloc = true;
            table.refcnts[this] = SIDE_TABLE_DEALLOCATING;
        } else if (it->second < SIDE_TABLE_DEALLOCATING) {
            // SIDE_TABLE_WEAKLY_REFERENCED may be set. Don't change it.
            do_dealloc = true;
            it->second |= SIDE_TABLE_DEALLOCATING;
        } else if (! (it->second & SIDE_TABLE_RC_PINNED)) {
            it->second -= SIDE_TABLE_RC_ONE;
        }
        table.unlock();
        if (do_dealloc  &&  performDealloc) {
            ((void(*)(objc_object *, SEL))objc_msgSend)(this, SEL_dealloc);
        }
        return do_dealloc;
    }
    

release需要判断最终是否需要调用dealloc，所以会复杂些，流程如下：  
1）先遍历 table.refcnts，寻找是否有对应对象的retainCount，如果不存在do_dealloc = true  
2）如果存在再判断标志位是否小于SIDE_TABLE_DEALLOCATING（引用计数是否为0，可以发现这个时候我们还没有减1，但已经跟0进行判断了，所以可以发现表中存的引用计数实际上存的是真实的引用计数-1），如果小于do_dealloc
= true  
3）否则就减去一个SIDE_TABLE_RC_ONE（引用计数-1）  
4）最后看do_dealloc是否需要调用dealloc。

# 三、retainCount、dealloc的实现

## retainCount实现

    
    
    - (NSUInteger)retainCount {
        return ((id)self)->rootRetainCount();
    }
    
    inline uintptr_t 
    objc_object::rootRetainCount()
    {
        if (isTaggedPointer()) return (uintptr_t)this;
        return sidetable_retainCount();
    }
    
    uintptr_t
    objc_object::sidetable_retainCount()
    {
        SideTable& table = SideTables()[this];
    
        size_t refcnt_result = 1;
    
        table.lock();
        RefcountMap::iterator it = table.refcnts.find(this);
        if (it != table.refcnts.end()) {
            // this is valid for SIDE_TABLE_RC_PINNED too
            refcnt_result += it->second >> SIDE_TABLE_RC_SHIFT;
        }
        table.unlock();
        return refcnt_result;
    }
    

流程如下：  
1）声明refcnt_result并且在初始化的时候设为1（用来+1）  
2）从SideTables找出对应对象的SideTable。  
3）判断refcnts中是否存该对象，如果存在，先将值>> SIDE_TABLE_RC_SHIFT得到真实的引用计数值，然后返回引用计数+1

至于>> SIDE_TABLE_RC_SHIFT和加1是因为我们上面有提到，数据结构的后两位用了做了别的用途，所以有>>
SIDE_TABLE_RC_SHIFT。而表中存的值实际上真实的引用计数值-1。

## dealloc的实现

    
    
    - (void)dealloc {
        _objc_rootDealloc(self);
    }
    
    void
    _objc_rootDealloc(id obj)
    {
        assert(obj);
    
        obj->rootDealloc();
    }
    
    inline void
    objc_object::rootDealloc()
    {
        if (isTaggedPointer()) return;
        object_dispose((id)this);
    }
    
    id 
    object_dispose(id obj)
    {
        if (!obj) return nil;
    
        objc_destructInstance(obj);    
        free(obj);
    
        return nil;
    }
    
    void *objc_destructInstance(id obj) 
    {
        if (obj) {
            // Read all of the flags at once for performance.
            bool cxx = obj->hasCxxDtor();
            bool assoc = obj->hasAssociatedObjects();
    
            // This order is important.
            if (cxx) object_cxxDestruct(obj);
            if (assoc) _object_remove_assocations(obj);
            obj->clearDeallocating();
        }
    
        return obj;
    }
    

可以发现，dealloc主要是调用`objc_destructInstance`方法，`objc_destructInstance`中做了很多事情，清理关联对象，ARC下释放成员变量等等，这里我们留到下一讲再详细叙述。

# 参考目录

  * <https://opensource.apple.com/tarballs/objc4/>
  * <https://github.com/Draveness/Analyze>
  * <http://www.jianshu.com/p/bb384657f65a>

