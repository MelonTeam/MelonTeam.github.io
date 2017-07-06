---
layout: post
title: "RunLoop解读"
date: 2017-05-21 15:40:00
categories: ios
author: jackzkzhang
tags: iOS runloop
---

* content
{:toc}



    RunLoop 是ios/osx
应用程序运行的基础，它使我们的程序能够不断处在一个循环中，有效地接受事件并处理事件，可以说，它为整个程序的运行搭建了一个框架。不过，在平时上层的开发中，NSRunLoop/CFRunLoopRef
暴露的接口使用的并不多，使得我们忽略了对它原理和机制的探究，而这篇文章的目的就是对Runloop机制进行一次解读，加深了解。
<!--more-->

   首先，Runloop是跟线程挂钩的，一个线程只能有唯一对应的Runloop，当然根Runloop
可以嵌套子Runloop，不过这种情况使用的并不多。如果一个线程没有创建对应的Runloop，那么运行完一次后就退出了。要想使线程能够在要处理的事件到来时，及时地处理反馈，就要为线程创建一个特定的“循环机制”，使程序在没有事件处理时挂起休息，节省资源；在事件到来时又能够被及时地唤醒工作。这就是Runloop运行最基本的原理。

  苹果系统提供了两个关于Runloop的对象：NSRunloop 和
CFRunloopRef。CFRunloopRef是在CoreFoundation框架内的，是c函数的api，线程安全；而NSRunloop是对CFRunloopRef的封装，面向对象，但是线程不安全。这篇文章主要基于CFRunloopRef进行阐述，每个接口在NSRunloop基本都可以找到对应的封装。

 前面说到，Runloop和线程是一一对应的。为了更好的理解，我们看下CFRunloopRef这部分相关的代码：

![](/image/runloop_jie_du/b8b21a96e23995de41b17bf24a596b30c276ca34ddcc2c1f01129abf14abfcf3)

系统不允许我们直接创建Runloop，只提供了CFRunLoopGetMain( ) 获取主线程的Runloop 和
CFRunloopGetCurrent()
获取当前线程的Runloop。可以看到，Runloop和Thread的关系保存在一个全局字典里，第一次获取时创建。当我们创建一个线程时，默认是不会帮我们获取Runloop的，而主线程的Runloop是在启动时系统帮我们创建的。

下面将会从**Runloop的基本构造**，**Runloop的运行逻辑** 以及 **与Runloop相关的一些应用场景** 三个方面介绍Runloop。

## **Runloop的基本构造**

![](/image/runloop_jie_du/ea054caf23d725dee731e4a33d10a1c3d02d3d1159198fa3d510cb4ba381a1e1)

一个Runloop包含至少一个mode，每个mode由source/observer/timer的集合构成。每次Runloop运行在其中一种模式(mode)下，如果想切换另一种模式，必须退出当前Runloop，再重新进入，也就是说mode与mode之间是相互隔离的。

    
    
    // 添加mode
    CFRunLoopAddCommonMode(CFRunLoopRef runloop, CFStringRef modeName);

当添加一个新的mode时，系统就自动帮我们创建该mode。但是，mode 只能添加不能删除。

mode有以下5中类型：

![](/image/runloop_jie_du/75bbbcd1896a55ebcc2e4b6720a745b1fc0bb5d1ae9bcc6bd05015d516aa996f)

而 source/observe/timer 统称mode item。一个mode必须有mode
item，runloop才能在该mode下运行。下面介绍下这三种mode item：

### 1.CFRunloopSourceRef：事件来源，包含两种：

  1) source0:   CFRunLoopSource {order =..., {callout =... }}
//order:优先级；callout：回调函数

  只含有回调事件，使用时要标记为待处理，然后手动wakeup Runloop来处理。比如：event事件

  2) source1:   CFRunLoopSource {order = ..., {port = ..., callout =...}
//order:优先级；port：监听的   端口 ; callout：回调函数

  包含mach_port和callout回调，可以通过内核和其他线程进程通信，使用时能主动唤醒Runloop。

###  2. CFRunLoopTimerRef  时间触发器

  CFRunLoopTimer {firing =..., interval = ...,tolerance = ...,next fire date =
...,callout = ...}

  //  tolerance 允许时间误差

  我们熟悉的NSTimer 和 performSelecter:afterdelay:都是基于它实现的。底层是生成这种时间源并加
入到当前Runloop中，当时间点到时，Runloop被主动唤醒执行回调操作。

![](/image/runloop_jie_du/7b980e0457516c16e1401ae3b2511fecf0c4d75fa6a6f946d5d363147fa827c6)

### 3. CFRunLoopObserverRef  监听Runloop状态，接收回调信息

  CFRunLoopObserver {order = ..., activities = ..., callout = ...}  //
order(优先级)，ativity(监听状态)，callout(回调函数)

 监听的状态有以下这几种：

![](/image/runloop_jie_du/1157ef7424617071dc7277fc6809d0aa8801fa05df9cd8f58ae3e3667ae6776c)

  利用监听主线程Runloop的状态，系统做了一系列的工作，比如界面绘制，自动释放池的创建释放等，下面会具体介绍。

Runloop暴露的管理mode item的接口有下面这几个：

![](/image/runloop_jie_du/47ec098699ec06ce0f395b5cc6ab615319f07de88701b8be108a7c3d5968c0f6)

我们来看下 CFRunloop 以及 CFRunloopMode的定义：

![](/image/runloop_jie_du/6b152558a556a2b229d8640807868ffaccec0461570a9a46e97cbb8a31f82eb8)

正如上面介绍的，CFRunloopMode 是由几种mode item的集合构成的，而CFRunloop
又包含若干个CFRunloopMode。CFRunloop中还定义了commonModes 和 commonModeItems 两个集合，这里有个介绍：

可以将一个mode标记为common属性，也就是调用下面这个接口将mode加入到_commonModes中：CFRunLoopAddCommonMode(CFRunLoopRef
runloop, CFStringRef modeName);

而每当 RunLoop 的内容发生变化时，RunLoop 都会自动将 _commonModeItems 里的 Source/Observer/Timer
同步到具有 "Common" 标记的所有Mode里。

就比如上面列出的kCFRunLoopDefaultMode 和 UITrackingRunLoopMode，这两个 Mode
都已经被标记为"Common"属性。DefaultMode 是 App 平时所处的状态，UITrackingRunLoopMode 是追踪
ScrollView 滑动时的状态。当你创建一个 Timer 并加到 DefaultMode 时，Timer
会得到重复回调，但此时滑动一个ScrollView时，RunLoop 会将 mode 切换为 UITrackingRunLoopMode，这时 Timer
就不会被回调，并且也不会影响到滑动操作。

如果想在滑动的过程中也监听timer的回调，可以将这个 Timer 分别加入这两个 Mode；或者 将 Timer 加入到顶层的 RunLoop 的
"commonModeItems" 中。"commonModeItems" 被 RunLoop 自动更新到所有具有"Common"属性的 Mode 里去。

## RunLoop的运行逻辑

了解了Runloop 的基本构造后，我们来看下Runloop 内部的运行逻辑。CFRunloop.c
的源码可以在这里<https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c.auto.html>看到，下面是关键部分的源代码:

![](/image/runloop_jie_du/8dde04e915461576a879e0485619d86c6d7d0b72ed7c1c3a4f180725c986cb5b)

![](/image/runloop_jie_du/c8de487d12755aabec436db4d1b8d6348778b3c9ec3829545185d011ee543ce5)

![](/image/runloop_jie_du/005df877ccdd1b954833c7a0080db331ead6035e5207400872175a6115977e32)

以及根据源码归纳出的来流程简图：

![](/image/runloop_jie_du/8065cfe7fa0f2e0959042975d5f518bceb3115082805862f87a218ecd1c4709b)

![](/image/runloop_jie_du/8fca96ce9087f585742190d04efc5507f416a1c5c2ec5c7263ef4c3c347e0ee3)\

我们在一开始提到，Runloop
运行最基本的原理是：让程序在没有事件处理时挂起休息，节省资源；在事件到来时又能够被及时地唤醒工作，也就是流程图中：休眠，监听特定的端口，等待唤醒。实现这一原理的关键就是mach
port 和 mach_msg()函数。

  首先，需要先了解下基本背景：Mach是XNU的内核，进程、线程和虚拟内存等对象通过端口发消息进行通信，"消息"是 Mach
中最基础的概念，消息在两个端口 (port) 之间传递，这就是 Mach 的 IPC (进程间通信) 的核心。

一条 Mach 消息实际上就是一个二进制数据包 (BLOB)，其头部定义了当前端口 local_port 和目标端口 remote_port。

![](/image/runloop_jie_du/9df003e7ad576e56373b3e366649d48dbb9dd74d51f4184ba6d9e9399da3fe30)

而mach_msg()函数实际上是调用了mach_msg_trap()，然后从用户态切换到内核态。RunLoop
调用这个函数去接收特定端口的消息，如果没有别人发送 port 消息过来，内核会将线程置于等待状态，也就是上面代码中的这部分：

![](/image/runloop_jie_du/6a2ca6698296b74a5f99ba86b4a414dfa2b801a0e6c420249c456b8a24f84b59)

从上面的流程图看，Runloop 运行的两个关键步骤 就是 **休眠监听mach_por**t 以及
**根据特定条件判断是否要继续循环或者退出**。整个Runloop其实就是在循环中按照顺序，执行相关的回调。

![](/image/runloop_jie_du/e1d9100d5afd5070a64699ed99cf4b6cb2126918bf43ca5c2d9a18b46d03514b)

当程序在断点处暂停时，我们可以从调用栈中看到，是从底层那个回调中触发的。

## RunLoop相关的一些应用场景

在知道了Runloop的基本构造以及运行流程之后，我们来了解下与Runloop相关的一些场景：  
  

### AutoreleasePool

App启动后，苹果在主线程 RunLoop 里注册了两个 Observer。

第一个 Observer 监视的事件是 Entry(即将进入Loop)，其回调内会创建自动释放池。它的优先级最高，保证创建释放池发生在其他所有回调之前。

第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠)释放旧的池并创建新池；Exit(即将退出Loop)
时释放自动释放池。它们的优先级最低，保证其释放池子发生在其他所有回调之后。

在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop 创建好的 AutoreleasePool
环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。

### 事件响应

苹果注册了一个Source1事件源 来接收系统事件，其回调函数为 __IOHIDEventSystemClientQueueCallback()。

当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 IOKit.framework 生成一个 IOHIDEvent 事件并由 SpringBoard
接收，随后用mach_port
转发给需要的App进程。随后苹果注册的那个Source1就会触发回调__IOHIDEventSystemClientQueueCallback()，在回调中触发source0事件源，source0的回调_UIApplicationHandleEventQueue()
会进行应用内部的分发。

_UIApplicationHandleEventQueue()会把 IOHIDEvent 处理并包装成 UIEvent 进行处理或分发，其中包括识别
UIGesture/处理屏幕旋转/发送给 UIWindow 等。通常事件比如 UIButton
点击、touchesBegin/Move/End/Cancel 事件都是在这个回调中完成的。

### 界面更新

当在操作 UI 时，比如改变了 Frame、更新了 UIView/CALayer 的层次时，或者手动调用了 UIView/CALayer 的
setNeedsLayout/setNeedsDisplay方法后，这个 UIView/CALayer 就被标记为待处理，并被提交到一个全局的容器去。

苹果注册了一个 Observer 监听 BeforeWaiting(即将进入休眠) 和 Exit (即将退出Loop) 事件，回调中会遍历所有待处理的
UIView/CAlayer 以执行实际的绘制和调整，并更新 UI 界面。

### PerformSelecter

performSelecter分为两种情况：

当调用 NSObject 的 performSelecter:afterDelay: 后，实际上其内部会创建一个 Timer 事件源并添加到当前线程的
RunLoop 中。所以如果当前线程没有 RunLoop，则这个方法会失效。

当只是调用
performSelecter：时，内部创建的是一个block，并添加到当前线程的runloop中。也就是上面源码多处出现的__CFRunLoopDoBlocks(runloop,
currentMode)。

### 关于GCD

当调用 dispatch_async(dispatch_get_main_queue(), block) 时，libDispatch 会向主线程的
RunLoop 发送消息，RunLoop会被唤醒，并从消息中取得这个 block，然后在回调里执行。runloop只处理主线程的block，dispatch
到其他线程仍然是由 libDispatch 处理的。

从上面的流程图中看到，runloop一次循环中有两个地方有机会处理dispatch_main：如果唤醒runloop
的不是libDispatch发送的消息，那么在下次休眠前，还有一次机会判断当前是否有dispatch_main事件需要处理。

这篇文章从Runloop的基本构造，Runloop的运行逻辑 以及 与Runloop相关的一些应用场景
三个方面入手，对Runloop的原理和机制进行了初步的探究，希望对大家了解Runloop运行机制方面有一定的帮助。

