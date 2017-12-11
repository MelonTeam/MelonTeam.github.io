---
layout: post
title: "浅析Binder机制"
date: 2017-08-31 12:49:00 +0800
categories: android
author: raymondguo
tags: binder
---

* content
{:toc}



一个老生常谈的话题，但也是在Android学习过程中一定会遇到的一个主题。结合自己的学习历程分享一下我对Binder架构的基本理解吧。

刚开始学习的时候，并没有找到讲binder机制特别清晰的中文资料终于在youtube上找到一个[演讲](https://www.youtube.com/watch?v=Jgampt1DOak)和[slides](http://events.linuxfoundation.org/images/stories/slides/abs2013_gargentas.pdf),以及[这篇](https://www.nds.rub.de/media/attachments/files/2012/03/binder.pdf)资料作为补充，从更全面的角度从头讲解binder机制。本文基本上是在这两份资料的理解上完成的。
<!--more-->

![](/image/qian_xi_binder_ji_zhi/f4711ff7f42bf7c74b4d2ee0cccf2c0f7e137e207e171800fffd0bcade064147)

binder就是Android中实现进程间通信的一种架构。首先看这张把这个过程中最主要的几个部分显示出来的图，可以看到process
A和B的通信稍显曲折，这也是许多binder文章要用到整片”A调用B,B又调用C”的原因。

这里还有一个类之间的调用关系抽象图，同样截取自上面的youtube presentation的slides。

![](/image/qian_xi_binder_ji_zhi/8b3d73b767217760a62ce059cc3d5a7bcc97a77bc47d792b19744db134c5d741)

这里首先有个基本的概念：进程间的通信。在进程A里面用service.invoke(func)，真正的执行主体是在进程B。

## 第一个基础问题，为什么要用cs结构？为什么要用IPC通信?

在安卓系统中client和server的概念还是挺明确的，用户程序常常要使用一些通用的系统服务，gps，alarm，包括开一个activity，task栈是可以跨进程的，维护这个栈也需要系统去维护。

既然这么多需要系统去统一维护的服务，那么就采用c/s结构，上面的各个client都可以向系统请求这些服务，系统也方便管理。

显然，系统服务和用户进程是两个进程，他们之间的通信是IPC。

## 一直在说的binder到底是个什么东西

一般Binder，就是指binder机制，在一些描述中，有的会说把这个binder传给谁。不过在上面两篇里面基本很少这么使用。

先看资料给出几个与Binder有关的定义:

  * IBinder Interface  
A well-defined behavior (i.e. methods) that Binder Objects must implement

  * Binder (Object)  
A generic implementation of the IBinder interface

  * Binder Token  
An abstract 32-bit integer value that uniquely identifies a Binder object
across all processes on the system

主要是binder(object)的解释，就是只要实现了ibinder接口的就是binder！  
再看看上面的图，整个binder框架中会用到的类，就是那么几个，那么这个implement了ibinder接口的类是哪个?

当然详细的关于这几个类的分析在后面，但是现在就可以给出答案,可以看了后面再跳回来看:

下面是一个使用AIDL帮我们生成的类，可以很明确的知道答案

    
    
    package others;
    
    package com.example.app;
    public interface IFooService extends android.os.IInterface {
        public static abstract class Stub extends android.os.Binder implements com.example.app.IFooService {
            ...
            public static com.example.app.IFooService asInterface(
                    android.os.IBinder obj) {
                ...
                return new com.example.app.IFooService.Stub.Proxy(obj);
            }
            ...
            public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int
                    flags) throws android.os.RemoteException { switch (code) {
                ...
                case TRANSACTION_save: {
                    ...
                    com.example.app.Bar _arg0;
                    ...
                    _arg0 = com.example.app.Bar.CREATOR.createFromParcel(data);
                    this.save(_arg0);
                    ...
                }
                ... }
                ... }
            ...
            private static class Proxy implements com.example.app.IFooService {
                private android.os.IBinder mRemote;
                ...
                public void save(com.example.app.Bar bar) throws android.os.RemoteException {
                    ...
                    android.os.Parcel _data = android.os.Parcel.obtain();
                    ...
                    bar.writeToParcel(_data, 0);
                    ...
                    mRemote.transact(Stub.TRANSACTION_save, _data, _reply, 0); ...
                } }
        }
    }
    

没错，就是调用图里面的那个service.stub类，他`extends android.os.Binder` 。这个类算作是要和C++
middleware(上图调用层里面的libbinder)通信的类，是java层面service的最下面的类。他的主要方法是ontrasict()，向这个transic
data里面设置一些值，这些值可能就是返回值，ontransict()就是在他收到C++ middleware的trasiction
的时候的回调函数，他通过执行本地方法，得到结果保存到trancsiction里面并且返回。

另外注意proxy这个类是被client使用的，他手上有stub类的引用，也就是有Binder的引用，所以也可以看到

`mRemote.transact(Stub.TRANSACTION_save, _data, _reply, 0)`

他在向binder发送这个transact data.并且这一动作是发生在client端的。

## 如何实现的IPC？

其实所谓IPC，就是你要实现一套通信机制，这边说话那边你要听得懂，听不懂就找个中间人来翻译。同时要保证一个人说一个人听不会乱套，保证两个人不能抢着说。

binder机制中，主要做了一件事情就是prcess
A中`service_local.func(arg)`，这个调用实际上发生在service进程里面，其实是`service_remote.func(arg)`。

这里binder IPC要做的就是我不可能直接告诉你service_remote这个对象在process
B里的真实地址，事实上即使你真的知道这个地址(一串数字)，由于JVM的机制，也不可能调用func去执行这个命令。出于安全的考虑，process之间有天然的隔阂。

这个时候，就要一个中间人，甚至更多的中间人来帮助他们沟通

这里最明显要有一个中间人在知道把这个service_local.func(arg)告诉对应的process
B，并且让他在真实的service对象上进行一些列的操作。

这个把调用信息告诉中间人的方法就是把这个函数调用抽象成一个特定的数据结构(我干脆理解成网络通信里面的通信包似的)

这个数据结构就叫Transmission data,也有叫trasiction：

![](/image/qian_xi_binder_ji_zhi/627f36578f28953e54cdf90bf076e3e010123b7571b6ddb64c04821a540fa9c2)

这个其实就跟网络通信的包一样嘛，几个域规定了几个特定的信息。

这个transmission data就描述了这次调用。包括

  * 是哪个service去调用(target)，这个target真实的情况是一个binder token

binder Token是什么：

> An abstract 32-bit integer value that uniquely identifies a Binder object
across all processes on the system

所以binder token就像是一个process的地址一样，定位远程调用的那个process.  
另外明确一点，这个进行翻译的中间人就是binder drive，如何“翻译”的呢？:

> On every transaction, the binder driver automatically  
> maps local addresses to remote binder handles and remote binder handles to
local addresses

我们确认一下，这个local address就是我们上面说的binder Token吗:

> A binder object reference is one of the following

>

>   * An actual virtual memory address to a binder object in the same process

>   * An abstract 32-bit handle to a binder object in  
> another process

>

![](/image/qian_xi_binder_ji_zhi/c5cb1dad8ba053aa4564e5990aa0a5c9dee8a83b7832f70cf75430f99d50f4e2)

我们这里谈general的情况，所以都是指IPC，所以属于第二种情况。所以，没错！transaciton的target的值就是一个binder
Token,binder driver的作用就是把这个binder Token翻译成指向process B的binder(stub对象)的引用!!

> On every transaction, the binder driver automatically  
> maps local addresses to remote binder handles and remote binder handles to
local addresses

至此，谜团差不多解开了。

整个过程其实就是process A向调B的某个方法，他不能直接调用，把调用信息打包成一个叫trsaction的数据结构，这个结构中主要包括:

  * 哪个service对象去执行(binder token来表示)
  * 这个serivice的哪个方法
  * 进行过数据变换的一些函数参数（parcel）

> Parcel: Container for a message (data and object references) that can be
sent through an IBinder

然后这个trascation会通过Linux ioctl命令(c++ middleware层在做这件事)发送到binder
driver这个内核空间的一块区域，在这里保存着binder token到process B
binder对象（stub对象，即service对象)的引用的映射。由此就找到了真正的service对象他收到transaciton中的调用信息，进行执行，然后把返回值信息设置进一个reply
parcel，然后再调用iotcl把改变过的transaction发送给client里的proxy。

这个过程看上面的调用图应该很明白了。  
这里我之前疑惑的一点是，process
B返回一个parcel而不是trascation也就是不指定地址。返回数据不也是进程间通信吗，为什么这个就可以直接返回数据?

注意这里client把trasaction通过iotcl给binder driver的时候的描述：(结合第二张调用图)

client：

  * 4)submit transaction/data via a blocking ioctl call

service:

  * 5)wake up from a blocking iotcl call and get the transaction data

service设置返回transaction  
service：

  * 13）submit replyParcel via ioctl
  * 14）wake up from a blocking ioctl call and get transaction reply data

再看一段关于procss B 执行完相应方法后的描述:

> Again it is routed through the layers to the binder driver, that transfers
the parcel and wakes up the sleeping client process and delivers the reply
parcel to the proxy object.

也就是说client在等待这个方法的完成.调用的client一直在binder driver的iotcl这个命令中等待，所以binder
driver只需要拿到了返回的parcel，他又通过iotcl把返回parcel穿给这个等待的client就可以了。

所以注意到了目前的描述都是基于阻塞式的调用。当然也可以实现非阻塞式调用，后续会提到。

### binder token 哪里来的

前面讲了这么多，这个binder token到底是什么，它是一个关键。只要client知道了binder
Token并把它装进tracsaction里，binder driver收到后就可以通过映射关系找到真正的binder handler了。

那么到底client是怎么获得binder Token 的？

这里看context Manager的描述:

> Each Binder that needs to publish its name due to being a service, submits a
name and its Binder token to the service manager. Relying on that feature, the
client must only know the name of a service and asks the service manager for
the Binder address of the requested service.

这个context Manager有个更常用的名字service Manager

service Manger也是一个service，在单独的进程一直运行着。

他的作用就是把service name映射成binder token,
每个service都需要注册（如在manifest里面）。注册就是发生在这个service Manager里面。生成一条映射记录:servcice name
->binder token.

所以当client 请求其他服务的时候第一件要做的事情就是向service manager做出请求，然后通过Binder机制，得到要请求的服务的binder
token传给proxy，proxy会放到transaction里面。

这里的问题上是，如果必须要通过service manger才能得到binder token (相当于service
binder的地址)，那servicemanger自己的地址我怎么知道呢?

这个已经规定好了，向servicemanager请求服务，binder token 无需查询，就是0！直接用。

### AIDL

好了，Binder机制差不多了吧。这里还是看上图，关键的有两个类，一个是stub类，一个是proxy类，分别是和c++
middleware打交道的属于service process和client process的两个类。

这两个类规定了如何将函数调用相关信息进行parcel。

其中

  * stub类继承了ibinder，他就是常说的binder 对象,这一层是用来和transaction数据打交道的，把从C++ middle ware层收到的parcel参数转化为java 类型供上面的service的真正的实现使用的
  * proxy类拥有stub对象的引用service，也就是binder的引用(实际在放入transaction的时候是binder token)，他负责当client调用service.func的时候把参数进行parcel放入transcation然后传入C++ middleware层

那么AIDL的作用就是:

负责提供一个service的interface，也就是各个函数的声明(指示了参数类型，返回值类型，函数名)。直接拿资料中的例子：

    
    
    package com.marakana.android.fibonaccicommon;
    import com.marakana.android.fibonaccicommon.FibonacciRequest; 
    import com.marakana.android.fibonaccicommon.FibonacciResponse;
    
    interface IFibonacciService {
        long fibJR(in long n);
        long fibJI(in long n);
        long fibNR(in long n);
        long fibNI(in long n);
        FibonacciResponse fib(in FibonacciRequest request);
    }
    

然后AIDL根据这个Interface就自动帮你生成上面的stub和proxy两个类(那两个类确实也只需要这些信息，他们的作用只是为这些类型提供parcel化而已)

所以AIDL的全称叫Android Interface Definition Language。  
确实只是定义了一个interface而已。AIDL进一步相关不做展开。

### 异步 Binder IPC

前面我们分析过了之前讲的全是阻塞式的binder，也是就client要等待service返回，其中ioctl一直会挂起等待。

这里来看看如何生成异步的bidner IPC.

其实最好还是直接看代码,还是上面那个slides讲得不要更清楚。

原理很好理解，结合slides中的例子，其实就是再写一个interface叫IFibonacciServiceResponseListener,也就是说在client端调用service的函数的时候都要传一个这个listener的对象作为参数，这个对象当然是在client端生成并且实现的。

然后等到service执行完函数后，他没有return reuslt这种语句，而是调用listener的onResponse这个回调函数。

看到这里明白了

对!service也在远程调用一个client对象(listener)。

要怎么实现?也用binder啊!!所以解决办法就是用相同的办法去写listener和service的aidl，然后同时生成他俩的各种stub，proxy这些。

所以我们同时要写两个aidl文件:

唯一区别就是要在aidl文件中声明interface的时候要加上关键字oneway：

文件FibonacciCommon/src/com/marakana/android/fibonaccicommon/IFibonacciServiceResponseListener.aidl:

    
    
    oneway interface IFibonacciServiceResponseListener { 
        void onResponse(in FibonacciResponse response);
    }
    

文件FibonacciCommon/src/com/marakana/android/fibonaccicommon/IFibonacciService.aidl:

    
    
    oneway interface IFibonacciService {
        void fib(in FibonacciRequest request, in IFibonacciServiceResponseListener listener);
    }
    

我想这个oneway的作用就是告诉ioctl不用挂起等待吧。一次性结束，当service要调用client的函数的时候他自己会重新开的。

### 总结

我理解的binder架构简单来说就是通过借助一套通信机制与关键的中间进程，把函数调用信息发送给远程进程进行执来实现Android系统中高效安全的进程间通信。其中涉及的更多具体细节与拓展可能需要更进一步的学习。

参考资料：  
[Deep Dive into Android IPC/Binder
Framework](https://www.youtube.com/watch?v=Jgampt1DOak)

[Android Binder Android Interprocess
Communication](https://www.nds.rub.de/media/attachments/files/2012/03/binder.pdf)

[Android 手写Binder
教你理解android中的进程间通信](http://www.cnblogs.com/punkisnotdead/p/5163464.html)

