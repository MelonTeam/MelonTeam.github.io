---
layout: post
title: "KVO实现原理"
date: 2017-08-29 19:11:00 +0800
categories: ios
author: berniwang
tags: iOS kvo isa混写
---

* content
{:toc}



**概览**  
本文分为两个大的方面。一、kvo的简单使用场景。二、kvo的来龙去脉，讲讲苹果的实现。

<!--more-->
**KVO 使用方法，和常用场景。**

Key-value observing is a mechanism that allows objects to be notified of
changes to specified properties of other objects.

— Key-Value Observing Programming Guide

简而言之，kvo就是允许一个对象去监听其他对象(可以自己)指定属性的值的变化。但是一般涉及的类比较复杂的时候，我们应该该使用Notification或者delegate，b不然太过分散，bug不容易查找，当然delegate，通知也需要统一处理.现在使用属性监听的场景还是比较少了，我们这里主要是探究一下苹果的实现原理。

使用方法分3步：

    
    
    1.  注册观察者 addObserver:forKeyPath:options:context:
    2.  观察者中实现
        observeValueForKeyPath:ofObject:change:context:
    3.  移除观察者： removeObserver:forKeyPath:
    

注意：

  * 注册与移除必须成对出现，否则会crash掉。
  * 观察者实现的方法，change字典里存放的数据与你注册观察者时  
的options相关，NSKeyValueObservingOptionNew表现为  
改变后的值，键为@”new”;NSKeyValueObservingOptionOld,  
同理键为@”old”,根据自己的需要选择。

* * *

**kvo实现原理**
    
    
    1.  runtime生成被监控类的子类NSKVONotifying_xx实例对
        象，被监控对象的isa指针指向子类，真正的起作用的类就成了
        子类。
    
    2. 一旦被监控类的某个属性改变，就会在子类中重写相应的set方
       法，在set方法中调用NSObject的- willChangeValueForKey:
       和- didChangeValueForKey:通知观察者。自己可以测试在被
       监控的类中自己重写这两个方法中的一个，可以看到观察者就
       收不到
       －observeValueForKeyPath:ofObject:change:context:消息
       了，说明截断了消息，使得kvo机制不起作用了。
    
    3. 子类中还重写了－ class方法，返回父类的 class，欲盖弥彰，
       就好像没有这个子类一样。
    
    4.删除观察者后一切照旧，对象的isa指针重新指向父类。
    

下面通过代码来验证：

自定义Person类，有age和height两个属性。自己时被监控对象，为了简单起见，也是观察者。

    
    
    #import 
    #import 
    
    @interface Person : NSObject
    
    @property(nonatomic,assign) int age;
    @property(nonatomic,assign) float height;
    
    @end
    
    @implementation Person
    /**
     *  如果重写，这两个方法，kvo就失效了。
     */
    //- (void)willChangeValueForKey:(NSString *)key{
    //    NSLog(@"willChangeValueForKey");
    //}
    
    //- (void)didChangeValueForKey:(NSString *)key{
    //    NSLog(@"didChangeValueForKey");
    //}
    //options属性改变change的值，这个是观察者要实现的方法。
    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
        if ([keyPath isEqualToString:@"age"]) {
            NSLog(@"%@",change);
        }
    
    }
    @end
    

获取一个类实现的所有selector(不包括父类的方法)

    
    
    static NSArray* classMethodsName(Class c){
        NSMutableArray* array = [NSMutableArray new];
        uint count = 0;
        Method* methods = class_copyMethodList(c, &count);
        for(int i=0; iNSStringFromSelector(
                          method_getName(methods[i])
                          )
            ];
        }
        return array;
    }
    
    static void PrintDescription(NSString *name, id obj)
    {
        //重点关注，对象的类型，runtime的类型。
        NSString *str = [NSString stringWithFormat:
                         @"%@: %@\n\tNSObject class %@\n\tlibobjc class %@\n\timplements methods ",
                         name,
                         obj,
                         [obj class],
                         object_getClass(obj),
                         [                          
                         classMethodsName(
                         object_getClass(obj)
                         ) 
                         componentsJoinedByString:@","]
                         ];
    
        printf("%s\n", [str UTF8String]); 
    }
    

main函数里，定义了三个人，one,two,three,one观察了自己的age属性，two观察了自己height属性，three作为对比。

    
    
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            Person* one = [Person new];
            Person* two = [Person new];
            Person* three = [Person new];
    
            printf("注册观察者之前\n");
            PrintDescription(@"one", one);
            PrintDescription(@"two", two);
            PrintDescription(@"three", three);
            /**
             *  在注册观察者之前
             */
           //breakpint 1
            [one addObserver:one forKeyPath:@"age" 
                 options:NSKeyValueObservingOptionNew 
                 context:nil];
            [two addObserver:two forKeyPath:@"height" 
                 options:NSKeyValueObservingOptionNew 
                 context:nil];
    
            printf("注册观察者之后\n");        
            PrintDescription(@"one", one);
            PrintDescription(@"two", two);
            PrintDescription(@"three", three);
    
            //查看类的方法实现(函数指针)的地址。
            printf("\none own method setAge:%p  libSubcluss 
                   method setAge:%p\n",
                   class_getMethodImplementation(
                      [one class], @selector(setAge:)
                   ),
                   class_getMethodImplementation(
                     object_getClass(one), 
                     @selector(setAge:)
                     )
            );
            printf("two own method setHeight:%p
                    libSubcluss method setHeight:%p\n"
                   ,class_getMethodImplementation(
                      [two class], @selector(setHeight:)
                    ),
                   class_getMethodImplementation(
                     object_getClass(two), 
                     @selector(setHeight:)
                   )
            );
            printf("three own method setHeight:%p  
                three libSubcluss method setHeight:%p\n\n",
                class_getMethodImplementation(
                  [three class], @selector(setHeight:)
                ),
                class_getMethodImplementation(
                  object_getClass(three), 
                  @selector(setHeight:)
                  )
             );
             //        one.age = 14;
            //        two.height = 5.5;
            /**
             *  注册观察者之后
             */      
           //breakpoint 2
            [one removeObserver:one forKeyPath:@"age"];
            [two removeObserver:two forKeyPath:@"height"];
    
            printf("删除观察者之后\n");
            PrintDescription(@"one", one);
            PrintDescription(@"two", two);
            PrintDescription(@"three", three);
            //breakpoint 3
    
        }
        return 0;
    }
    

breakpint 1

    
    
    one: <Person: 0x1006001c0>
        NSObject class Person
        libobjc class Person
        implements methods   
        setAge:,observeValueForKeyPath:ofObject:change
            :context:,height,setHeight:>
    two: <Person: 0x100600220>
        NSObject class Person
        libobjc class Person
        implements methods 
        setAge:,observeValueForKeyPath:ofObject:change
            :context:,height,setHeight:>
    three: <Person: 0x100600230>
        NSObject class Person
        libobjc class Person
        implements methods 
        setAge:,observeValueForKeyPath:ofObject:change
            :context:,height,setHeight:>
    

**结果1：**
    
    
    在未添加观察者之前，运行时的类和对象本身的类是一样的。
    

breakpoint2

    
    
    one: 0x1006001c0>
        NSObject class Person
        libobjc class NSKVONotifying_Person
        implements methods 
        class,dealloc,_isKVOA>
    two: 0x100600220>
        NSObject class Person
        libobjc class NSKVONotifying_Person
        implements methods 
        class,dealloc,_isKVOA>
    three: 0x100600230>
        NSObject class Person
        libobjc class Person
        implements methods 
        
    
    one own method setAge:0x1000015b0  libSubcluss method     
                   setAge:0x7fff8a5a1a81
    two own method setHeight:0x100001600  libSubcluss 
            method setHeight:0x7fff8a5a1ba9
    three own method   setHeight:0x100001600  three  
    libSubcluss method setHeight:0x100001600
    

**结果2**
    
    
    1.  监听过的属性值都会在NSKVONotifying_XX(本例是Person)
        生成对应的set方法。
    2. 重写了class方法，目的在于隐藏子类，依然返回父类的class,
        伪装自己。
    3.  one的setAge方法，two的setHeight方法，居然有两个实
         现，说明运行时至少是该方法重写了。而没有监听属性的
         three一切正常。
    至此，应该算是比较明白runtime干了一件什么样的事了，还不会，那我们看看，删除监听的后效果。
    

breakpoint3

    
    
    one: <Person: 0x1006001c0>
        NSObject class Person
        libobjc class Person
        implements methods
        setAge:,observeValueForKeyPath:ofObject:change
        :context:,height,setHeight:>
    two: <Person: 0x100600220>
        NSObject class Person
        libobjc class Person
        implements methods 
       setAge:,observeValueForKeyPath:ofObject:change:
          context:,height,setHeight:>
    three: <Person: 0x100600230>
        NSObject class Person
        libobjc class Person
        implements methods      
        setAge:,observeValueForKeyPath:ofObject:
        change:context:,height,setHeight:>
    

一切都是原来的的样子，runtime的magic。

**结论**

只要监听了属性的改变，父类就通过isa-
swizzle(isa混写)，指向了子类，而狡猾的子类不仅完成了该有的set方法的重写，而且重写class方法，返回父类的类对象。然而runtime之下，无所隐藏.

