---
layout: post
title: "runloop解读"
date: 2017-05-21 15:40:00
categories: ios
author: jackzkzhang
tags: ios runloop
---

* content
{:toc}


    runloop 是ios/osx 应用程序运行的基础，它使我们的程序能够不断处在一个循环中，有效地接受事件并处理事件，可以说，它为整个程序的运行搭建了一个框架。不过，在平时上层的开发中，nsrunloop/cfrunloopref 暴露的接口使用的并不多，使得我们忽略了对它原理和机制的探究，而这篇文章的目的就是对runloop机制进行一次解读，加深了解。

<!--more-->

   首先，runloop是跟线程挂钩的，一个线程只能有唯一对应的runloop，当然根runloop 可以嵌套子runloop，不过这种情况使用的并不多。如果一个线程没有创建对应的runloop，那么运行完一次后就退出了。要想使线程能够在要处理的事件到来时，及时地处理反馈，就要为线程创建一个特定的“循环机制”，使程序在没有事件处理时挂起休息，节省资源；在事件到来时又能够被及时地唤醒工作。这就是runloop运行最基本的原理。

  苹果系统提供了两个关于runloop的对象：nsrunloop 和 cfrunloopref。cfrunloopref是在corefoundation框架内的，是c函数的api，线程安全；而nsrunloop是对cfrunloopref的封装，面向对象，但是线程不安全。这篇文章主要基于cfrunloopref进行阐述，每个接口在nsrunloop基本都可以找到对应的封装。

 前面说到，runloop和线程是一一对应的。为了更好的理解，我们看下cfrunloopref这部分相关的代码：

<img src="/image/runloop_jie_du/b8b21a96e23995de41b17bf24a596b30c276ca34ddcc2c1f01129abf14abfcf3"/>

系统不允许我们直接创建runloop，只提供了cfrunloopgetmain( ) 获取主线程的runloop 和 cfrunloopgetcurrent() 获取当前线程的runloop。可以看到，runloop和thread的关系保存在一个全局字典里，第一次获取时创建。当我们创建一个线程时，默认是不会帮我们获取runloop的，而主线程的runloop是在启动时系统帮我们创建的。

下面将会从<strong>runloop的基本构造</strong>，<strong>runloop的运行逻辑</strong> 以及 <strong>与runloop相关的一些应用场景</strong> 三个方面介绍runloop。

## <strong>runloop的基本构造</strong>

<img src="/image/runloop_jie_du/ea054caf23d725dee731e4a33d10a1c3d02d3d1159198fa3d510cb4ba381a1e1" width="422" height="325"/>

一个runloop包含至少一个mode，每个mode由source/observer/timer的集合构成。每次runloop运行在其中一种模式(mode)下，如果想切换另一种模式，必须退出当前runloop，再重新进入，也就是说mode与mode之间是相互隔离的。

```
// 添加mode

cfrunloopaddcommonmode(cfrunloopref runloop, cfstringref modename);
```

当添加一个新的mode时，系统就自动帮我们创建该mode。但是，mode 只能添加不能删除。

mode有以下5中类型：

<img src="/image/runloop_jie_du/75bbbcd1896a55ebcc2e4b6720a745b1fc0bb5d1ae9bcc6bd05015d516aa996f"/>

而 source/observe/timer 统称mode item。一个mode必须有mode item，runloop才能在该mode下运行。下面介绍下这三种mode item：

### 1.cfrunloopsourceref：事件来源，包含两种：

  1) source0:   cfrunloopsource {order =..., {callout =... }} //order:优先级；callout：回调函数

  只含有回调事件，使用时要标记为待处理，然后手动wakeup runloop来处理。比如：event事件

  2) source1:   cfrunloopsource {order = ..., {port = ..., callout =...} //order:优先级；port：监听的   端口 ; callout：回调函数

  包含mach_port和callout回调，可以通过内核和其他线程进程通信，使用时能主动唤醒runloop。

###  2. cfrunlooptimerref  时间触发器

  cfrunlooptimer {firing =..., interval = ...,tolerance = ...,next fire date = ...,callout = ...} 

  //  tolerance 允许时间误差 

  我们熟悉的nstimer 和 performselecter:afterdelay:都是基于它实现的。底层是生成这种时间源并加 入到当前runloop中，当时间点到时，runloop被主动唤醒执行回调操作。

<img src="/image/runloop_jie_du/7b980e0457516c16e1401ae3b2511fecf0c4d75fa6a6f946d5d363147fa827c6"/>

### 3. cfrunloopobserverref  监听runloop状态，接收回调信息

  cfrunloopobserver {order = ..., activities = ..., callout = ...}  // order(优先级)，ativity(监听状态)，callout(回调函数) 

 监听的状态有以下这几种：

<img src="/image/runloop_jie_du/1157ef7424617071dc7277fc6809d0aa8801fa05df9cd8f58ae3e3667ae6776c"/>

  利用监听主线程runloop的状态，系统做了一系列的工作，比如界面绘制，自动释放池的创建释放等，下面会具体介绍。

runloop暴露的管理mode item的接口有下面这几个：

<img src="/image/runloop_jie_du/47ec098699ec06ce0f395b5cc6ab615319f07de88701b8be108a7c3d5968c0f6"/>

我们来看下 cfrunloop 以及 cfrunloopmode的定义：

<img src="/image/runloop_jie_du/6b152558a556a2b229d8640807868ffaccec0461570a9a46e97cbb8a31f82eb8"/>

<font color="#2f2f2f">正如上面介绍的，cfrunloopmode 是由几种mode item的集合构成的，而cfrunloop 又包含若干个cfrunloopmode。cfrunloop中还定义了commonmodes 和 commonmodeitems 两个集合，这里有个介绍：</font>

<font color="#2f2f2f">可以将一个mode标记为common属性，也就是调用下面这个接口将mode加入到_commonmodes中：</font><font color="#2f2f2f">cfrunloopaddcommonmode(cfrunloopref runloop, cfstringref modename);</font>

<font color="#2f2f2f">而每当 runloop 的内容发生变化时，runloop 都会自动将 _commonmodeitems 里的 source/observer/timer 同步到具有 "common" 标记的所有mode里。</font>

<font color="#2f2f2f">就比如上面列出的kcfrunloopdefaultmode 和 uitrackingrunloopmode，这两个 mode 都已经被标记为"common"属性。defaultmode 是 app 平时所处的状态，uitrackingrunloopmode 是追踪 scrollview 滑动时的状态。当你创建一个 timer 并加到 defaultmode 时，timer 会得到重复回调，但此时滑动一个scrollview时，runloop 会将 mode 切换为 uitrackingrunloopmode，这时 timer 就不会被回调，并且也不会影响到滑动操作。</font>

<font color="#2f2f2f">如果想在滑动的过程中也监听timer的回调，可以将这个 timer 分别加入这两个 mode；或者 将 timer 加入到顶层的 runloop 的 "commonmodeitems" 中。"commonmodeitems" 被 runloop 自动更新到所有具有"common"属性的 mode 里去。</font>

## <font color="#2f2f2f">runloop的运行逻辑</font>

<font color="#2f2f2f">了解了runloop 的基本构造后，我们来看下runloop 内部的运行逻辑。cfrunloop.c 的源码可以在这里[https://opensource.apple.com/source/cf/cf-855.17/cfrunloop.c.auto.html](https://opensource.apple.com/source/cf/cf-855.17/cfrunloop.c.auto.html)看到，下面是关键部分的</font><font color="#2f2f2f">源代码:</font>

<font color="#2f2f2f"><img src="/image/runloop_jie_du/8dde04e915461576a879e0485619d86c6d7d0b72ed7c1c3a4f180725c986cb5b"/></font>

<img src="/image/runloop_jie_du/c8de487d12755aabec436db4d1b8d6348778b3c9ec3829545185d011ee543ce5"/>

<img src="/image/runloop_jie_du/005df877ccdd1b954833c7a0080db331ead6035e5207400872175a6115977e32"/>

以及根据源码归纳出的来流程简图：

<img src="/image/runloop_jie_du/8065cfe7fa0f2e0959042975d5f518bceb3115082805862f87a218ecd1c4709b"/>

<img src="/image/runloop_jie_du/8fca96ce9087f585742190d04efc5507f416a1c5c2ec5c7263ef4c3c347e0ee3"/>\

<font color="#2f2f2f">我们在一开始提到，runloop 运行最基本的原理是：让程序在没有事件处理时挂起休息，节省资源；在事件到来时又能够被及时地唤醒工作，也就是流程图中：休眠，监听特定的端口，等待唤醒。实现这一原理的关键就是mach port 和 mach_msg()函数。</font>

<font color="#2f2f2f">  首先，需要先了解下基本背景：mach是xnu的内核，进程、线程和虚拟内存等对象通过端口发消息进行通信，"消息"是 mach 中最基础的概念，消息在两个端口 (port) 之间传递，这就是 mach 的 ipc (进程间通信) 的核心。</font>

<font color="#2f2f2f">一条 mach 消息实际上就是一个二进制数据包 (blob)，其头部定义了当前端口 local_port 和目标端口 remote_port。</font>

<font color="#2f2f2f"><img src="/image/runloop_jie_du/9df003e7ad576e56373b3e366649d48dbb9dd74d51f4184ba6d9e9399da3fe30"/></font>

<font color="#2f2f2f">而mach_msg()函数实际上是调用了mach_msg_trap()，然后从用户态切换到内核态。runloop 调用这个函数去接收特定端口的消息，如果没有别人发送 port 消息过来，内核会将线程置于等待状态，也就是上面代码中的这部分：</font>

<img src="/image/runloop_jie_du/6a2ca6698296b74a5f99ba86b4a414dfa2b801a0e6c420249c456b8a24f84b59"/>

从上面的流程图看，runloop 运行的两个关键步骤 就是 <strong>休眠监听mach_por</strong>t 以及 <strong>根据特定条件判断是否要继续循环或者退出</strong>。整个runloop其实就是在循环中按照顺序，执行相关的回调。

<img src="/image/runloop_jie_du/e1d9100d5afd5070a64699ed99cf4b6cb2126918bf43ca5c2d9a18b46d03514b"/>

当程序在断点处暂停时，我们可以从调用栈中看到，是从底层那个回调中触发的。

## runloop相关的一些应用场景

在知道了runloop的基本构造以及运行流程之后，我们来了解下与runloop相关的一些场景：<br/><br/>

### autoreleasepool

app启动后，苹果在主线程 runloop 里注册了两个 observer。

第一个 observer 监视的事件是 entry(即将进入loop)，其回调内会创建自动释放池。它的优先级最高，保证创建释放池发生在其他所有回调之前。

第二个 observer 监视了两个事件： beforewaiting(准备进入休眠)释放旧的池并创建新池；exit(即将退出loop) 时释放自动释放池。它们的优先级最低，保证其释放池子发生在其他所有回调之后。

在主线程执行的代码，通常是写在诸如事件回调、timer回调内的。这些回调会被 runloop 创建好的 autoreleasepool 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 pool 了。

### 事件响应

苹果注册了一个source1事件源 来接收系统事件，其回调函数为 __iohideventsystemclientqueuecallback()。

当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 iokit.framework 生成一个 iohidevent 事件并由 springboard 接收，随后用mach_port 转发给需要的app进程。随后苹果注册的那个source1就会触发回调__iohideventsystemclientqueuecallback()，在回调中触发source0事件源，source0的回调_uiapplicationhandleeventqueue() 会进行应用内部的分发。

_uiapplicationhandleeventqueue()会把 iohidevent 处理并包装成 uievent 进行处理或分发，其中包括识别 uigesture/处理屏幕旋转/发送给 uiwindow 等。通常事件比如 uibutton 点击、touchesbegin/move/end/cancel 事件都是在这个回调中完成的。

### 界面更新

当在操作 ui 时，比如改变了 frame、更新了 uiview/calayer 的层次时，或者手动调用了 uiview/calayer 的 setneedslayout/setneedsdisplay方法后，这个 uiview/calayer 就被标记为待处理，并被提交到一个全局的容器去。

苹果注册了一个 observer 监听 beforewaiting(即将进入休眠) 和 exit (即将退出loop) 事件，回调中会遍历所有待处理的 uiview/calayer 以执行实际的绘制和调整，并更新 ui 界面。

### performselecter

performselecter分为两种情况：

当调用 nsobject 的 performselecter:afterdelay: 后，实际上其内部会创建一个 timer 事件源并添加到当前线程的 runloop 中。所以如果当前线程没有 runloop，则这个方法会失效。

当只是调用 performselecter：时，内部创建的是一个block，并添加到当前线程的runloop中。也就是上面源码多处出现的__cfrunloopdoblocks(runloop, currentmode)。

### 关于gcd

当调用 dispatch_async(dispatch_get_main_queue(), block) 时，libdispatch 会向主线程的 runloop 发送消息，runloop会被唤醒，并从消息中取得这个 block，然后在回调里执行。runloop只处理主线程的block，dispatch 到其他线程仍然是由 libdispatch 处理的。

从上面的流程图中看到，runloop一次循环中有两个地方有机会处理dispatch_main：如果唤醒runloop 的不是libdispatch发送的消息，那么在下次休眠前，还有一次机会判断当前是否有dispatch_main事件需要处理。



<font color="#2f2f2f">这篇文章从runloop的基本构造，runloop的运行逻辑 以及 与runloop相关的一些应用场景 三个方面入手，对runloop的原理和机制进行了初步的探究，希望对大家了解runloop运行机制方面有一定的帮助。</font>
