---
layout: post
title: "ios runtime方法调用与消息转发"
date: 2017-05-31 11:04:00
categories: ios
author: monawang
tags: 运行时 ios
---

* content
{:toc}

| 导语 ios
runtime为开发者提供了很多灵活便捷的方法，使得在运行时也可以改变类的结构。这篇文章主要是从方法调用作为切入点，来学习&记录runtime的理论知识。

### 一、方法调用

<!--more-->
      在oc中，运行时贯穿了整个工程的运行过程，每一个方法的调用都离不开运行时的工作。

      在讨论oc时，我们经常说 向对象“发消息”
而不是“调用”，原因就在于在整个程序运行过程中，每一次实际上所调用的方法并不是已经完全绑定好的，编译器会把oc方法的调用，转换成objc_msgsend函数，这个函数会动态的寻找下一步要执行的方法。也正是这个函数，完成了动态绑定的整个过程。

     objc_msgsend的大致运行流程如下图，其中需要重点关注的是“寻找方法实现”这一步。

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/d515fc633024d8f4dd248537f2a8362fa68e82564207a02fe9108e58e289a3d6)

寻找方法实现可以概括为以下几步：

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/49d65bf7c25d01679631572571ba47035cc6ddd790eaae7950b4c32b405703e0)

### 二、消息转发

    当oc找不到代码中调用的方法时，在crash之前我们还有机会通过重写以下nsobject的四个方法来进行处理:

    
    
    //当调用一个不存在的类方法时调用
    + (bool)resolveclassmethod:(sel)sel;
    
    //当调用一个不存在的实例方法时调用
    + (bool)resolveinstancemethod:(sel)sel;
    
    //将这个不存在的方法重定向到其它类处理，需要返回一个实例
    - (id)forwardingtargetforselector:(sel)aselector;
    
    //将这个不存在的方法打包成nsinvocation丢进来。需要调用invokewithtarget:给某个能够执行方法的实例
    - (void)forwardinvocation:(nsinvocation *)aninvocation;
    
    
    整个流程如下图所示：

·首先调用resolveinstancemethod(以调用实例方法来举例)

·如果返回no，那么调用forwardingtargetforselector

·如果返回nil，那么调用forwardinvocation

![](/image/ios_runtime_fang_fa_diao_yong_yu_xiao_xi_zhuan_fa/e61d9fea2a32c69da6ab6876f3a26add0dfcf4e231ccd171d2ff36e92d99fbe7)

我们现在来动手动态的添加一个方法。首先，在viewdidload里调用一个不存在的方法：

    
    
    testclass *tstobj = [[testclass alloc]init];
    [tstobj performselector:@selector(lalaland)];

再在testclass.m中添加以下代码：

    
    
    void addmethod(id self, sel _cmd){
        nslog(@"addmethod complete.");
    }
    
    + (bool)resolveinstancemethod:(sel)sel{
        //给本类动态添加一个方法
        class_addmethod(self, sel, (imp)addmethod, "v@:*");
        nslog(@"resolveinstancemethod return.");
        return yes;
    }
    
    - (id)forwardingtargetforselector:(sel)aselector
    {
        nslog(@"forwardingtargetforselector complete.");
        return nil;
    }
    
    - (void)forwardinvocation:(nsinvocation *)aninvocation
    {
        nslog(@"forwardinvocation complete.");
    }

打印log:

    
    
    2017-02-28 16:26:12.992 normaltrytry[12628:28082853] resolveinstancemethod return.
    2017-02-28 16:26:25.348 normaltrytry[12628:28082853] addmethod complete.

上面的代码实际上只运行到了resolveinstancemethod就成功返回，因为在这个方法中我们已经给到了系统一个方法实现，并返回了tes，这时候系统就不会再向两个forward抛出消息了。

简单说来，这四个方法都是用来添加未处理方法的。区别在于，resolveinstancemethod是在本类中添加方法，并告诉系统该方法是否执行；forwardingtargetforselector
是自己处理不了，转给其它实例做处理；如果经过以上几步还是处理不了，那么就走到了forwardinvocation中，系统会把这个方法的所有信息都打包给我们，做最后的处理。

消息转发有很多灵活的应用，对于crash防崩溃、lua-wax都是很重要的技术点~

