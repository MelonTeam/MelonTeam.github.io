---
layout: post
title: "iOS runtime方法调用与消息转发"
date: 2017-05-31 11:04:00
categories: ios
author: monawang
tags: 运行时 iOS
---

* content
{:toc}

| 导语 iOS
runtime为开发者提供了很多灵活便捷的方法，使得在运行时也可以改变类的结构。这篇文章主要是从方法调用作为切入点，来学习&记录runtime的理论知识。

### 一、方法调用

<!--more-->
      在OC中，运行时贯穿了整个工程的运行过程，每一个方法的调用都离不开运行时的工作。

      在讨论OC时，我们经常说 向对象“发消息”
而不是“调用”，原因就在于在整个程序运行过程中，每一次实际上所调用的方法并不是已经完全绑定好的，编译器会把OC方法的调用，转换成objc_msgsend函数，这个函数会动态的寻找下一步要执行的方法。也正是这个函数，完成了动态绑定的整个过程。

     objc_msgsend的大致运行流程如下图，其中需要重点关注的是“寻找方法实现”这一步。

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/d515fc633024d8f4dd248537f2a8362fa68e82564207a02fe9108e58e289a3d6)

寻找方法实现可以概括为以下几步：

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/49d65bf7c25d01679631572571ba47035cc6ddd790eaae7950b4c32b405703e0)

### 二、消息转发

    当OC找不到代码中调用的方法时，在crash之前我们还有机会通过重写以下NSObject的四个方法来进行处理:

    
    
    //当调用一个不存在的类方法时调用
    + (BOOL)resolveClassMethod:(SEL)sel;
    
    //当调用一个不存在的实例方法时调用
    + (BOOL)resolveInstanceMethod:(SEL)sel;
    
    //将这个不存在的方法重定向到其它类处理，需要返回一个实例
    - (id)forwardingTargetForSelector:(SEL)aSelector;
    
    //将这个不存在的方法打包成NSInvocation丢进来。需要调用invokeWithTarget:给某个能够执行方法的实例
    - (void)forwardInvocation:(NSInvocation *)anInvocation;
    
    
    整个流程如下图所示：

·首先调用resolveInstanceMethod(以调用实例方法来举例)

·如果返回NO，那么调用forwardingTargetForSelector

·如果返回nil，那么调用forwardInvocation

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/e61d9fea2a32c69da6ab6876f3a26add0dfcf4e231ccd171d2ff36e92d99fbe7)

我们现在来动手动态的添加一个方法。首先，在viewdidload里调用一个不存在的方法：

    
    
    TestClass *tstObj = [[TestClass alloc]init];
    [tstObj performSelector:@selector(lalaLand)];

再在TestClass.m中添加以下代码：

    
    
    void addMethod(id self, SEL _cmd){
        NSLog(@"addMethod complete.");
    }
    
    + (BOOL)resolveInstanceMethod:(SEL)sel{
        //给本类动态添加一个方法
        class_addMethod(self, sel, (IMP)addMethod, "v@:*");
        NSLog(@"resolveInstanceMethod return.");
        return YES;
    }
    
    - (id)forwardingTargetForSelector:(SEL)aSelector
    {
        NSLog(@"forwardingTargetForSelector complete.");
        return nil;
    }
    
    - (void)forwardInvocation:(NSInvocation *)anInvocation
    {
        NSLog(@"forwardInvocation complete.");
    }

打印log:

    
    
    2017-02-28 16:26:12.992 NormalTryTry[12628:28082853] resolveInstanceMethod return.
    2017-02-28 16:26:25.348 NormalTryTry[12628:28082853] addMethod complete.

上面的代码实际上只运行到了resolveInstanceMethod就成功返回，因为在这个方法中我们已经给到了系统一个方法实现，并返回了TES，这时候系统就不会再向两个forward抛出消息了。

简单说来，这四个方法都是用来添加未处理方法的。区别在于，resolveInstanceMethod是在本类中添加方法，并告诉系统该方法是否执行；forwardingTargetForSelector
是自己处理不了，转给其它实例做处理；如果经过以上几步还是处理不了，那么就走到了forwardInvocation中，系统会把这个方法的所有信息都打包给我们，做最后的处理。

消息转发有很多灵活的应用，对于crash防崩溃、lua-wax都是很重要的技术点~

