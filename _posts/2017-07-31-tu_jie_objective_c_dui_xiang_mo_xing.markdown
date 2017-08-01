---
layout: post
title: "图解Objective-C对象模型"
date: 2017-07-31 20:13:00 +0800
categories: ios
author: berniwang
tags: iOS对象模型 对象模型 objectivec
---

* content
{:toc}



**目录**：  
**1.这就是Objective-C对象模型吗？**  
**2.Objective-C对象结构**  
<!--more-->
**3.Meta Class(元类)**  
**4.代码验证**  
**5.推荐文章**

### 1.这就是Objective-C对象模型吗？

![一张来自官方文档的对象结构图](/image/tu_jie_objective_c_dui_xiang_mo_xing/8a4e01d4df0416d77c5654ea5f92f48065c94d69f7a1f9132e09be41c0493f98)  

[ 一张来自官方文档的对象结构图 ]

这个图也大致涵盖了Objetive-C对象的主要内容，这里出现了实例变量，指向对象类结构的isa指针，类结构中的selector（运行时将
转变为IMP（方法实现）），指向父类的superclass指针,一切都是多么的完美。

真的就是这只有这么多了吗?苹果可是经常“善意的欺骗“码农，KVO的实现不就如此，明明牺牲了那么多，却要用个isa混写，深藏功与名（此处应为苹果鼓掌）。好吧，先提个问题，我们项目中经常提供两个方法，分别提供一个实例方法和对应的类方法。比如字典转模型，以我的大Person为例:

    
    
     [Person personWithDic:dic];
     [[Person alloc]initWithDic:dic];
    

什么，你还没有看出来有什么端倪？T_ _T ,我感觉第一个感觉比第二好用，对头，我也是这么认为的。毕竟现在还不了解Objetive-
C对象模型，消息发送机制，这个直观的感觉很正常。但是苹果到底为你做了多少了？先看本文中时常用到的几个名词。

**必须搞清楚的几个术语**(`有不同意见清轻喷T_T`)

  * 对象(又跟码农谈Object。。。天台)，一个类的实例对象。
  * 类/类结构，也经常叫作类对象(ClassObject)，元类的对象。
  * 元类（metaClass），你的图上都咩有，现在说个＊＊＊。

### 2.Objective-C对象结构

下面的代码在`objc/obj.h和objc/Object.h`

    
    
    /// An opaque type that represents an Objective-C class.
    typedef struct objc_class *Class;
    
    /// Represents an instance of a class.
    struct objc_object {
        Class isa  OBJC_ISA_AVAILABILITY;
    };
    //再补充一个几乎所有对象的基类NSObject类定义
    @interface Object
    {
        Class isa;    /* A pointer to the instance's class structure */
    }
    

以上几行代码，想要表达的无非就是，Objetive-C对象是C语言的的结构体，每个对象的内存开头的地址都是Class类型的isa。就酱
，一条Objetive-C中的铁律就产生了。

**如果结构体中第一个变量的类型是Class,就可以当作是Objetive-C对象**。之后讲block的实质的时候就会看到其本质就是Objective-C对象。

那么我们再来看看struct
objc_class的结构体，这个结构体定义在`objc/runtime.h`中，这个就是我们真正的类结构体了，描述了对象所属类的性质。

    
    
    struct objc_class {
        Class isa                    OBJC_ISA_AVAILABILITY;
    
    #if !__OBJC2__
       Class super_class                           
                                      OBJC2_UNAVAILABLE;
        const char *name                                         
                                      OBJC2_UNAVAILABLE;
        long version                                             
                                      OBJC2_UNAVAILABLE;
        long info                 
                                      OBJC2_UNAVAILABLE;
        long instance_size                                       
                                      OBJC2_UNAVAILABLE;
        struct objc_ivar_list *ivars   
                                      OBJC2_UNAVAILABLE;
        struct objc_method_list **methodLists                    
                                      OBJC2_UNAVAILABLE;
        struct objc_cache *cache      
                                      OBJC2_UNAVAILABLE;
        struct objc_protocol_list *protocols                     
                                      OBJC2_UNAVAILABLE;
    #endif
    
    } OBJC2_UNAVAILABLE;
    

看到这个，是不是有点熟悉了，这些东西好像我们平常在定义个类的时候都用到过，类的名字，实例变量，方法，遵守的协议等。然而聪明的童鞋可能开始疑惑了，妈蛋，这结构体里面怎么又有一个Class了，那按照铁律这个也是对象啰，那它的类又是在哪里？那这个Class又指到哪里去了，小伙子，你骨骼精奇呀。，那类的延伸不是没完没了，最基本的类在哪里了？就是元类了，比如，我们的NSString虽然是一个类，也就是我们普通意义上的类，但同时也是类对像。既然说到这里，先介绍两个函数,代码验证时要用到(源码之下，无所隐藏，23333)。

    
    
    //Returns the class object for the receiver’s class.
    //返回一个消息接收者的 *类对象*
    - (Class)class
    //Returns the class of an object
    //返回一个对象的类，注意，不是类对象哦
    Class object_getClass(id object)
    

### 3.Meta Class(元类)

先上图，再说话。我想下面这张图，你默默的看个几分钟，就能解之前的疑惑了，心中的草泥马终于可以释怀了。

![Objective-
C对象结构图](/image/tu_jie_objective_c_dui_xiang_mo_xing/ad9acc55b8bb6f2e8aa78fdd18bff344d4a1f7c68677390c9880e5d358a2f1a0)  

[ Objective-C对象结构图 ]

从这张图上，我们来做一个总结：

  1. 对象的isa指向了一个类对象(ClassObject)。
  2. 类对象里包含了一个SuperClass指向父类，isa 指向了自己的  
元类（MetaClass）.

  3. 元类和普通的类也是一样，有自己的继承层次，有自己的父类。
  4. 元类也是一个对象，所有元类都有一个共同的基元  
类（Root MetaClass），基元类的元类就是它自己啦。

  5. 万物归宗， NSObject是基元类的父类，所以NSObject 基本是  
万物之首（NSProxy并不是继承自NSObject的，原因在讲消息机制时再说吧）。

可是，你讲了这么久，元类到底做什么的了？也只是大致了解一些啦，苹果并没有没给源代码。还记得开头提的一个问题，字典转模型一个类方法和实例方法？这个就是元类的作用了。

**类对象中有你定义的实例方法的引用，而元类中有对类方法的引用，使得你可以对类对象（ClassObject）发消息。**

这里出两道题，来自sunny的博客。挑两道较好的，刚好与类的对象模型相关。  
[神经病院objc runtime入院考试](http://blog.sunnyxx.com/2014/11/06/runtime-nuts/)

    
    
    //1.下面的答案是什么
    BOOL res1 = [(id)[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res2 = [(id)[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res3 = [(id)[Sark class] isKindOfClass:[Sark class]];
    BOOL res4 = [(id)[Sark class] isMemberOfClass:[Sark class]];
    
    //2.下面的代码会？Compile Error / Runtime Crash / NSLog…?
    @interface NSObject (Sark)
    + (void)foo;
    @end
    @implementation NSObject (Sark)
    - (void)foo {
        NSLog(@"IMP: -[NSObject (Sark) foo]");
    }
    @end
    // 测试代码
    [NSObject foo];
    [[NSObject new] foo];
    
    //答案不能自行解决？你还不会，额，2333，继续看看上面的图。
    

### 4.代码验证

我就简单粗暴的用之前的两个方法把NSString当一次靶子，打印一下，类对象，元类，基元类，NSObject和它的元类的地址。

    
    
            Class baseMeta = 
            object_getClass(object_getClass([NSString class]));
            Class metaOfBaseMeta = object_getClass(baseMeta);
            Class fatherOfbaseMeta = [baseMeta superclass];
    
            printf("NSString,类的地址:%@\n",[NSString class]);
            printf("metaClass,元类的地
                址:%p\n",object_getClass([NSString class]));
            printf("baseMeta，基元类的地址:%p\n",baseMeta);
            printf("metaOfBaseMeta,基元类的元类地
                址:%p\n",metaOfBaseMeta);
            printf("fatherOfbaseMeta,基元类的父类地
                址:%p\n",fatherOfbaseMeta);
            printf("NSObject类对象地址:%p\n",[NSObject class]);
            printf("NSObject元类地
                址:%p\n",object_getClass([NSObject class]));
    

答案在此，我就不解析了，欢迎评论区拍砖。

`NSString,类对象的地址:0x7fff7626ce28 metaClass,元类的地址:0x7fff7626ce50
baseMeta，基元类的地址:0x7fff78bcb118 metaOfBaseMeta,基元类的元类地址:0x7fff78bcb118
fatherOfbaseMeta,基元类的父类地址:0x7fff78bcb0f0 NSObject类对象地址:0x7fff78bcb0f0
NSObject元类地址:0x7fff78bcb118`

### 5.推荐文章

[1.What is a meta-class in Objective-C cocoawithlove matt大神  
写的，里面还有很多很多很多（重要的事情强调三遍）很好的东  
西](http://www.cocoawithlove.com/2010/01/what-is-meta-class-in-
objective-c.html)

[2.这个是上一篇文章的翻译，博主并没有看，还是看看原版的](http://blog.csdn.net/windyitian/article/details/19810875)

