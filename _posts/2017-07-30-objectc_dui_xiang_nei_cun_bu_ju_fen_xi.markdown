---
layout: post
title: "ObjectC对象内存布局分析"
date: 2017-07-30 18:12:00 +0800
categories: ios
author: stackhuang
tags: Runtimeclass iOS
---

* content
{:toc}

| 导语
C语言包括C++对象的内存分布都相当简单，几乎就是一个struct，但OC有Class和MetaClass的设计，本身的内存布局就不太清晰，若要回答一个问题，一个OC对象究竟占用了多少内存？还真没有好好分析过。之前看过一些文章说OC对象内存也是一个struct，然后简单的调试了下，发现并不是这样，更加激发了兴趣，于是抽时间研究了下，由于时间原因，这里的分析还不算太深入，后续再深入分析下。

## 分析

<!--more-->
C++对象的内存布局很简单，比如：

    
    
    class CMemObject
    {
        int value;
        char* pstr;
    }
    

在32bit的模式下，内存直接就是8字节的一个struct，拿到CMemObject的指针以后，可以直接通过相对于this的偏移地址来访问，简单直接。  
之前看过一些Runtime的资料，觉得模式不会太复杂，尝试手动猜测和分析，后面才发现想法完全是错的。  
网上关于OC的内存分布，大多只停留在这样的资料

    
    
    struct objc_class {  
        Class isa  OBJC_ISA_AVAILABILITY;
    #if !__OBJC2__
        Class super_class;
        const char *name;
        long version;
        long info;
        long instance_size;
        struct objc_ivar_list *ivars;
        struct objc_method_list *methodLists;
        struct objc_cache *cache;
        struct objc_protocol_list *protocols;
    #endif
    };
    

很少有对新的结构做分析的。我尝试了用clang编译成c++文件，类似这样

    
    
    clang -framework Foundation -rewrite-objc MemObject.m
    

结果得到的是这样的结构

    
    
    struct _class_t {
        struct _class_t *isa;
        struct _class_t *superclass;
        void *cache;
        void *vtable;
        struct _class_ro_t *ro;
    };
    

里面还有几个关于结构体的定义，但一下看不出头绪。然后我尝试手动分析内存，分析内存在lldb里面主要使用 x 命令。  
比如 x/16xg obj  
意思是，x显示内存，g表示按8字节读取，x表示按16进制显示，16表示读取16个，所以这里会读取16*8个数据，例子

    
    
    (lldb) x/16xg obj
    0x60800001e430: 0x000000010faafe50 0x0000000000000000
    0x60800001e440: 0x0000608000283020 0x0000000000000000
    0x60800001e450: 0x00006080002815e0 0x0000000000000000
    0x60800001e460: 0xbadd907d96eebead 0x000060800001e470
    0x60800001e470: 0xbadd907d96eebead 0x0000000000000000
    0x60800001e480: 0x00007fa04b504930 0x00007fa04b709c50
    0x60800001e490: 0x40383a3040343276 0x0000000000003631
    0x60800001e4a0: 0x00000001108dcfb0 0x0000600000057af0
    

这里走了一些弯路，开始觉得既然分析OC，那么Mac和iOS应该差不多，于是尝试手动在Mac下面分析OC对象的内存结构，遇到了很大的问题，有的数据长得像地址但就是无法访问。光猜是不行的，然后就老老实实按标准流程开始分析。

## 实践

我实现了一个MemObject的Class

    
    
    @interface MemObject : NSObject
    @property(nonatomic, assign) int intValue;
    - (void)function;
    @end
    

有一个属性和一个方法。调用的代码长这样

    
    
    - (void)memoryAnalyse
    {
        MemObject* mem = [[MemObject alloc] init];
        [mem function];
    }
    

调试，直接查看mem的内存

    
    
    (lldb) x/8xg mem
    0x60800001e430: 0x000000010faafe50 0x0000000000000000
    0x60800001e440: 0x0000608000283020 0x0000000000000000
    0x60800001e450: 0x00006080002815e0 0x0000000000000000
    0x60800001e460: 0xbadd907d96eebead 0x000060800001e470
    

对下面的几个地址尝试分析了下，完全没有头绪。只能拿Objc的源码了  
OC的源码地址是 <https://opensource.apple.com/tarballs/objc4/>  
直接下载最新的就可以。  
Class的定义非常简单（抛开类方法的定义，只看属性）：

    
    
    //objc-private.h
    struct objc_object {
    private:
        isa_t isa;
    }
    

仅有一个isa属性，继续看这个isa

    
    
    union isa_t 
    {
        Class cls;
        uintptr_t bits;
        # if __arm64__
    #   define ISA_MASK        0x0000000ffffffff8ULL
    #   define ISA_MAGIC_MASK  0x000003f000000001ULL
    #   define ISA_MAGIC_VALUE 0x000001a000000001ULL
        struct {
            uintptr_t nonpointer        : 1;
            uintptr_t has_assoc         : 1;
            uintptr_t has_cxx_dtor      : 1;
            uintptr_t shiftcls          : 33; // MACH_VM_MAX_ADDRESS 0x1000000000
            uintptr_t magic             : 6;
            uintptr_t weakly_referenced : 1;
            uintptr_t deallocating      : 1;
            uintptr_t has_sidetable_rc  : 1;
            uintptr_t extra_rc          : 19;
    #       define RC_ONE   (1ULL<<45)
    #       define RC_HALF  (1ULL<<18)
        };
    

这是一个union，最后面的struct在不同的CPU下面定义还不一样，这个也是为什么我开始在Mac上看到的数据不太像地址的原因。在iOS上面，这个isa属性就直接是Class的地址。参考上面的调试结果，这个Class地址就是
0x000000010faafe50，继续。

    
    
    (lldb) x/16xg 0x000000010faafe50
    0x10faafe50: 0x000000010faafe28 0x000000011044be58
    0x10faafe60: 0x0000608000282e40 0x0000000100000003
    0x10faafe70: 0x0000608000263c42 0x000000010faafea0
    0x10faafe80: 0x0000000111bedec8 0x00007fa04c010a00
    0x10faafe90: 0x000000320000007f 0x0000608000262540
    0x10faafea0: 0x000000011044be08 0x0000000111bedef0
    0x10faafeb0: 0x00006080001184b0 0x0000000500000007
    0x10faafec0: 0x0000608000262580 0x000000011044be08
    

直觉猜第一个和第二个应该是两个Class的地址，果然

    
    
    (lldb) po (Class)0x000000010faafe28
    MemObject
    (lldb) po (Class)0x000000011044be58
    NSObject
    

看源码

    
    
    typedef struct objc_class *Class;
    typedef struct objc_object *id;
    

我们平时用的id时一个objc_object, 而Class是 objc_class，继续看objc_class的定义

    
    
    struct objc_object {
    private:
        isa_t isa;
    }
    
    //objc-runtime-new.h
    struct objc_class : objc_object {
        // Class ISA;
        Class superclass;
        cache_t cache;             // formerly cache pointer and vtable
        class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
    }
    

在OC源码里面，还有一个objc-runtime-old.h，这个是之前的格式，网上大部分都是这种格式。继续看cache_t

    
    
    struct bucket_t {
    private:
        cache_key_t _key;
        IMP _imp;
    }
    
    #if __LP64__
    typedef uint32_t mask_t;  // x86_64 & arm64 asm are less efficient with 16-bits
    #else
    typedef uint16_t mask_t;
    #endif
    typedef uintptr_t cache_key_t;
    
    struct cache_t {
        struct bucket_t *_buckets;
        mask_t _mask;
        mask_t _occupied;
    }
    

这里是有关方法查找的缓存的，有机会分析下，这里大致可以看出，bucket就是一个key
Value的缓存数据存储的地方，而后面两个mask，我们只需要知道数据长度就OK。下面继续看class_data_bits_t，这里也是用掩码来作了一些操作，跟isa的方法类似。

    
    
    struct class_data_bits_t {
        // Values are the FAST_ flags above.
        uintptr_t bits;
    public:
        class_rw_t* data() {
            return (class_rw_t *)(bits & FAST_DATA_MASK);
        }
    

看下现在的情况：

    
    
    (lldb) x/16xg 0x000000010faafe50
    0x10faafe50: 0x000000010faafe28 0x000000011044be58
                 Class              Super Class
    0x10faafe60: 0x0000608000282e40 0x0000000100000003
                 cache_t.bucket_t*  mask
    0x10faafe70: 0x0000608000263c42 0x000000010faafea0
                 class_rw_t*
    

继续看 class_rw_t 的定义

    
    
    struct class_rw_t {
        // Be warned that Symbolication knows the layout of this structure.
        uint32_t flags;
        uint32_t version;
    
        const class_ro_t *ro;
    
        method_array_t methods;
        property_array_t properties;
        protocol_array_t protocols;
    
        Class firstSubclass;
        Class nextSiblingClass;
    
        char *demangledName;
    
    #if SUPPORT_INDEXED_ISA
        uint32_t index;
    #endif
    }
    
    struct class_ro_t {
        uint32_t flags;
        uint32_t instanceStart;
        uint32_t instanceSize;
    #ifdef __LP64__
        uint32_t reserved;
    #endif
    
        const uint8_t * ivarLayout;
        
        const char * name;
        method_list_t * baseMethodList;
        protocol_list_t * baseProtocols;
        const ivar_list_t * ivars;
    
        const uint8_t * weakIvarLayout;
        property_list_t *baseProperties;
    };
    
    

终于接近核心了，有两个很重要的类，class_rw_t 和 class_ro_t，从字面意思可以猜，一个是Read & Write，一个是Read
Only，显然，因为OC是动态语言，如果要增加属性或者方法，应该是在RW这个类上面添加。我们一步步来验证下。

    
    
    (lldb) x/32xg 0x608000263c40    //class_rw_t*
    0x608000263c40: 0x0000000080080000 0x000000010faaf188
                    version   flags    class_ro_t*
    0x608000263c50: 0x000000010faaf0f8 0x000000010faaf170
                    method_array_t     property_array_t
    0x608000263c60: 0x0000000000000000 0x0000000000000000
                    protocol_array_t   firstSubclass
    0x608000263c70: 0x0000000111c13268 0x0000000000000000
                    nextSiblingClass   demangledName
    
    (lldb) x/32xg 0x000000010faaf188 //class_ro_t*
    0x10faaf188: 0x0000000800000080 0x000000000000000c
                 Start    flags     reserved instanceSize 
    0x10faaf198: 0x0000000000000000 0x000000010faadcd8
                 ivarLayout         name
    0x10faaf1a8: 0x000000010faaf0f8 0x0000000000000000
                 baseMethodList     baseProtocols
    0x10faaf1b8: 0x000000010faaf148 0x0000000000000000
                 ivars              weakIvarLayout
    0x10faaf1c8: 0x000000010faaf170 0x0000002800000081
                 baseProperties
    
    

很明显，RW的 method_array_t 跟 RO 的 baseMethodList 的地址是同样的，RW的 property_array_t 跟 RO
的 baseProperties 也是一致的。我们可以验证一些东西了

    
    
    (lldb) x/32cb 0x000000010faadcd8 //ClassName
    0x10faadcd8: MemObject\0ViewController\0AppDele
    //证明ClassName = “MemObject”
    
    struct method_t {
        SEL name;
        const char *types;
        IMP imp;
    }
    
    struct property_t {
        const char *name;
        const char *attributes;
    };
    
    (lldb) x/32xg 0x000000010faaf0f8
    0x10faaf0f8: 0x000000030000001a 0x000000010faadd30
                 count              "setIntValue"
    0x10faaf108: 0x000000010faae783 0x000000010faad760
                 type: v20@0:8i16   [MemObject setIntValue:]
    0x10faaf118: 0x000000010fdc3a92 0x000000010faae773
                 “function”
    0x10faaf128: 0x000000010faad710 0x000000011088efad
                                    "intValue"
    0x10faaf138: 0x000000010faae77b 0x000000010faad740
    
    (lldb) b 0x000000010faad760
    Breakpoint 2: where = MemObj`-[MemObject setIntValue:] at MemObject.h, address = 0x000000010faad760
    //要确定一个地址是否是一个方法的入口，发现最简单的办法就是下个断点，还可以这样，通过反汇编来确认是不是一个方法入口
    (lldb) x/32ig 0x000000010faae783
        0x10faae783: 76 32              jbe    0x10faae7b7               ; "2@0:8@16@24"
        0x10faae785: 30 40 30           xorb   %al, 0x30(%rax)
        0x10faae788: 3a 38              cmpb   (%rax), %bh
        0x10faae78a: 69 31 36 00 69 00  imull  $0x690036, (%rcx), %esi   ; imm = 0x690036 
        0x10faae790: 76 32              jbe    0x10faae7c4               ; "32@0:8@"UIApplication"16@"NSDictionary"24"
        0x10faae792: 34 40              xorb   $0x40, %al
        
    (lldb) x/32xg 0x000000010faaf170  //property_array_t
    0x10faaf170: 0x0000000100000010 0x000000010faadc45
                 count = 1          name="intValue"
    0x10faaf180: 0x000000010faadc4e 0x0000000800000080
                 attr="Ti,N,V_intValue"
                 
    还剩下一个感兴趣的字段 
    
    struct ivar_t {
        int32_t *offset;
        const char *name;
        const char *type;
        // alignment is sometimes -1; use alignment() instead
        uint32_t alignment_raw;
        uint32_t size;
    };
    
    
    (lldb) x/32xg 0x000000010faaf148    //ivars
    0x10faaf148: 0x0000000100000020 0x000000010faafe18
                                    8
    0x10faaf158: 0x000000010faadd3d 0x000000010faae78e      
                 "_intValue"        "i"
    0x10faaf168: 0x0000000400000002 0x0000000100000010
                 sz   alignment_raw  
    

我很早之前一直疑惑一个问题，就是OC的变量是怎么存的，当看到ivars的结构的时候，恍然大悟，其实跟C++也类似，猜测为这样，可以简单验证下。

MemObject  
---  
isa(8byte)  
_intValue(4byte)  
      
    
    //如果预想得没错，那么如果对intValue赋值，则会直接修改 mem + 8 的值
    (lldb) x/16xg mem  
    0x60800001e430: 0x000000010faafe50 0x0000000000000000
    0x60800001e440: 0x0000608000283020 0x0000000000000000
    
    (lldb) po mem.intValue = 5
    5
    (lldb) x/16xg mem
    0x60800001e430: 0x000000010faafe50 0x0000000000000005
    0x60800001e440: 0x0000608000283020 0x0000000000000000
    //成功
    

在 class_ro_t 里面有一个字段 instanceSize
，这里的值是0xc(12),也就是一个8byte的isa指针加一个4byte的int。完全符合设想。

到这里，一个类里面的方法，属性是如何描述的，都已经清楚了，一个类自己所占用的内存，也很清楚了，其实跟C++类似，也是跟属性的定义直接相关。

现在可以画出OC对象的内存布局了。

接下来，还有1个问题：如果动态修改Class的方法或者属性，RW和RO类会如何变化？  
修改了下代码

    
    
    //MemObject.h
    #import 
    
    @interface MemObject : NSObject
    
    @property(nonatomic, assign) int intValue;
    @property(nonatomic, strong) NSString* strValue;
    
    - (void)function;
    
    @end
    
    //MemObject.m
    #import "MemObject.h"
    
    @interface MemObject()
    {
        NSString* _privateStr;
    }
    @end
    
    @implementation MemObject
    
    - (void)function
    {
        NSLog(@"function @ memObject");
        self.strValue = @"property";
        _privateStr = @"privateStr";
    }
    
    - (void)privateFunction
    {
         NSLog(@"function @ privateFunction");
    }
    
    
    - (void)memoryAnalyse
    {
        Class clsMemObject = objc_getClass("MemObject");
        int objSize = class_getInstanceSize(clsMemObject);
        
        MemObject* mem1 = [[MemObject alloc] init];
        mem1.intValue = 1;
        [mem1 function];
        
        MemObject* mem2 = [[MemObject alloc] init];
        mem2.intValue = 2;
        [mem2 function];
        
        MemObject* mem3 = [[MemObject alloc] init];
        mem3.intValue = 3;
        [mem3 function];
        
        class_addMethod(clsMemObject, @selector(addValue), (IMP)addedMethod, "v@");
        [mem1 performSelector:@selector(addValue)];
        
        NSString* strAttr = @"strAttr";
        objc_setAssociatedObject(mem1, "attr", (id)strAttr, OBJC_ASSOCIATION_ASSIGN);
    }
    
    void addedMethod(id self, SEL _cmd)
    {
        NSLog(@"from addedMethod");
    }
    
    

改动主要为：  
1\. 添加了私有属性 _privateStr  
2\. 添加了私有方法 privateFunction  
3\. 新增加一个属性 strValue  
4\. 动态添加方法addedMethod  
5\. 关联一个attr属性

由于调试代码太多，这里仅列出关键的调试步骤。  
可以使用class_getInstanceSize获取一个类实例的内存占用大小，这里是 4 * 8=32Byte。  
可以直接看见内存布局。

    
    
    (lldb) x/16xg mem1
    0x600000038d80: 0x0000000101c76f50 0x0000000101c760a8
                    isa                "privateStr"
    0x600000038d90: 0x0000000000000001 0x0000000101c76088
                    intValue           "property"
    

然后分析了下RW类，可以给出内存中实际的布局。

methodList: 7  
---  
setStrValue:  
privateFunction  
setIntValue:  
strValue  
function  
.cxx_destruct  
intValue  
propertyList: 2  
---  
intValue  
strValue  
ivarl: 3  
---  
_privateStr  
_intValue  
_strValue  
  
在添加方法以后，发现RW的 method_array_t 发生了变化。而且也只有这个发生了变化。随便看了下，比较简单，一下就猜出来了。

    
    
    (lldb) x/16xg 0x60800003d8c0  //新的method_array_t
    0x60800003d8c0: 0x0000000000000002 0x000060800003bb40
                    count=2            新添加的方法
    0x60800003d8d0: 0x000000010f91a1c0 0x000202030a06060b
                    旧的method_array_t指针
    (lldb) x/16xg 0x000060800003bb40
    0x60800003bb40: 0x000000010000001a 0x000000010f918d39
                                       “addValue”
    0x60800003bb50: 0x000000010f918bee 0x000000010f918710
    

RW 的 method_array_t
变成了两个array，array里面是两个methodList,一个指向新添加的Method，一个指向原来的MethodList。  
还有就是关联对象的问题，查看了ivarl没有变化，那么这个 AssociatedObject
又到哪里去了呢？查看了OC的源码，_object_set_associative_reference，原来，OC维护了一个全局的map，维护了对象和关联对象的对应关系，有一个AssociationsManager，还有一个AssociationsHashMap。

## OC对象内存布局

到现在为止，我们已经可以比较明确的画出OC的对象内存布局了。

![](/image/objectc_dui_xiang_nei_cun_bu_ju_fen_xi/76c79bcecd57845cf6ab45662d37b9447448923ca1397e49b6bf9d38094d86f8)  
当添加一个Method的时候，变化为

![](/image/objectc_dui_xiang_nei_cun_bu_ju_fen_xi/bc8eb0434db0aadb00b5c5e4e630ce20c0f4445f1bbf0184caefd0b6fa15fdb7)

