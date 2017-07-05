---
layout: post
title: "ios runloop的介绍"
date: 2017-05-31 10:31:00
categories: ios
author: justinytang
tags: runloop
---

* content
{:toc}

| 导语 一道题引出的对runloop的认知。

        最近做到一道有关 runloop 的选择题，题目大概是这样的：

        关于 runloop 的说法中，哪些是正确的？（不定项选择）
<!--more-->

a - 每个线程都会对应一个 runloop

b - 只有主线程才有 runloop

c - 手动创建一个线程，系统会默认生成 runloop

d - runloop 只能选择一个 mode 启动，如果当前mode中没有任何
source(sources0、sources1)、timer，那么就直接退出runloop

        比较有意思的是，多线程是我们在 ios 开发过程中比较常用的一个方式，但是可能大部分人并没有关注到 runloop ，那runloop
到底是什么呢？这篇文章将介绍 runloop 的世界，相信介绍完你就会知道上面这道题的答案了。

## runloop 的概念

        大家在平时使用 iphone 中的 app 的时候会发现，当你静止不进行任何操作的时候，好像 app
休眠了，但是当你点击按钮的时候，就会立即触发一个事件，仿佛 app 一直在待命，等你执行任何操作，这里的实现就是通过 runloop 来实现的。

    
    
    int main(int argc, char * argv[]) {
        @autoreleasepool {
            return uiapplicationmain(argc, argv, nil, nsstringfromclass([yourappdelegate class]));
        }
    }

        上面一段代码，每个app启动时都会执行的，主线程也随之开始运行。runloop 做为主线程的一部分也同时被启动。
uiapplicationmain() 方法在这里不仅完成了初始化我们的程序并设置程序 delegate 的任务，而且随之开启了主线程的 runloop
,开始接受处理事件。

        runloop
本质和它的意思一样是运行着的循环，更确切的说是线程中的循环。它用来接受循环中的事件和安排线程工作，并在没有工作时，让线程进入睡眠状态。

        下图展示了run loop的模型 :

           ![run
loop](/image/ios_runloop_de_jie_shao/efe7108fdcf3f4fde86503006ef07eb7ebe61fb857b34a8bfb476d274b5ba94c)

       从图中可以看出，runloop 是线程中的一个循环，并对接收到的事件进行处理。我们的代码可以通过提供 while 或者 for 循环来驱动
runloop 。在循环中，runloop 对象来负责事件处理代码（接收事件并且调用事件处理方法）。

        runloop 从两个不同的事件源中接收消息:

  * input source 用来投递异步消息，通常消息来自另外的线程或者程序。在接收到消息并调用程序指定方法时，线程中对应的 nsrunloop 对象会通过执行 rununtildate: 方法来退出。
  * timer source 用来投递 timer 事件（ schedule 或者 repeat ）中的同步消息。在处理消息时，并不会退出 run loop 。
  * run loop 还有一个观察者 observer 的概念，可以往 run loop 中加入自己的观察者以便监控 run loop 的运行过程。

        runloop
实际上就是一个对象，这个对象管理了其需要处理的事件和消息，并提供了一个入口函数来执行事件循环的逻辑。线程执行了这个函数后，就会一直处于这个函数内部
"接受消息->等待->处理" 的循环中，直到这个循环结束（比如传入 quit 的消息），函数返回。

        osx/ios 系统中，提供了两个这样的对象：nsrunloop 和 cfrunloopref 。

  * cfrunloopref 是在 corefoundation 框架内的，它提供了纯 c 函数的 api ，所有这些 api 都是线程安全的。
  * nsrunloop 是基于 cfrunloopref 的封装，提供了面向对象的 api ，但是这些 api 不是线程安全的。

## **runloop ****与线程的关系**

        首先，ios开发中能遇到两个线程对象: pthread_t 和 nsthread
。过去苹果有份[文档](http://www.fenestrated.net/~macman/mirrors/apple%20technotes%20\(as%20of%202002\)/tn/tn2028.html)标明了
nsthread 只是 pthread_t 的封装，但那份文档已经失效了，现在它们也有可能都是直接包装自最底层的 mach thread
。苹果并没有提供这两个对象相互转换的接口，但不管怎么样，可以肯定的是 pthread_t 和 nsthread 是一一对应的。比如，你可以通过
pthread_main_thread_np() 或 [nsthread mainthread] 来获取主线程；也可以通过 pthread_self() 或
[nsthread currentthread] 来获取当前线程。cfrunloop 是基于 pthread 来管理的。

        苹果不允许直接创建 runloop，它只提供了两个自动获取的函数：cfrunloopgetmain() 和
cfrunloopgetcurrent()。 这两个函数内部的逻辑大概是下面这样:

    
    
    /// 全局的dictionary，key 是 pthread_t， value 是 cfrunloopref
    static cfmutabledictionaryref loopsdic;
    /// 访问 loopsdic 时的锁
    static cfspinlock_t loopslock;
     
    /// 获取一个 pthread 对应的 runloop。
    cfrunloopref _cfrunloopget(pthread_t thread) {
        osspinlocklock(&loopslock);
        
        if (!loopsdic) {
            // 第一次进入时，初始化全局dic，并先为主线程创建一个 runloop。
            loopsdic = cfdictionarycreatemutable();
            cfrunloopref mainloop = _cfrunloopcreate();
            cfdictionarysetvalue(loopsdic, pthread_main_thread_np(), mainloop);
        }
        
        /// 直接从 dictionary 里获取。
        cfrunloopref loop = cfdictionarygetvalue(loopsdic, thread));
        
        if (!loop) {
            /// 取不到时，创建一个
            loop = _cfrunloopcreate();
            cfdictionarysetvalue(loopsdic, thread, loop);
            /// 注册一个回调，当线程销毁时，顺便也销毁其对应的 runloop。
            _cfsettsd(..., thread, loop, __cffinalizerunloop);
        }
        
        osspinlockunlock(&loopslock);
        return loop;
    }
    cfrunloopref cfrunloopgetmain() {
        return _cfrunloopget(pthread_main_thread_np());
    }
    cfrunloopref cfrunloopgetcurrent() {
        return _cfrunloopget(pthread_self());
    }

         从上面的代码可以看出，线程和 runloop 之间是一一对应的，其关系是保存在一个全局的 dictionary 里。线程刚创建时并没有
runloop，如果你不主动获取，那它一直都不会有。runloop 的创建是发生在第一次获取时，runloop
的销毁是发生在线程结束时。你只能在一个线程的内部获取其 runloop（主线程除外），这样就解释了文章开头那道选择题的a答案。

## **runloop****对外的接口**

        在 corefoundation 里面关于 runloop 有5个类:

        cfrunloopref  
        cfrunloopmoderef  
        cfrunloopsourceref  
        cfrunlooptimerref  
        cfrunloopobserverref

        其中cfrunloopmoderef类并没有对外暴露，只是通过 cfrunloopref 的接口进行了封装。他们的关系如下:

![runloop_0](/image/ios_runloop_de_jie_shao/6f09f9aef920675b51be0073e766dd1ebf77a9200db701ac5a719aab90039a30)

        一个 runloop 包含若干个 mode，每个 mode 又包含若干个 source/timer/observer。每次调用
runloop 的主函数时，只能指定其中一个 mode，这个mode被称作 currentmode。如果需要切换 mode，只能退出
loop，再重新指定一个 mode 进入。这样做主要是为了分隔开不同组的 source/timer/observer，让其互不影响。

  * **cfrunloopsourceref** 是事件产生的地方。source有两个版本：source0 和 source1：source0 只包含了一个回调（函数指针），它并不能主动触发事件。使用时，你需要先调用 cfrunloopsourcesignal(source)，将这个 source 标记为待处理，然后手动调用 cfrunloopwakeup(runloop) 来唤醒 runloop，让其处理这个事件。source1 包含了一个 mach_port 和一个回调（函数指针），被用于通过内核和其他线程相互发送消息。这种 source 能主动唤醒 runloop 的线程，其原理在下面会讲到。

  * **cfrunlooptimerref** 是基于时间的触发器，它和 nstimer 是toll-free bridged 的，可以混用。其包含一个时间长度和一个回调（函数指针）。当其加入到 runloop 时，runloop会注册对应的时间点，当时间点到时，runloop会被唤醒以执行那个回调。

  * **cfrunloopobserverref** 是观察者，每个 observer 都包含了一个回调（函数指针），当 runloop 的状态发生变化时，观察者就能通过回调接受到这个变化。可以观测的时间点有以下几个：

    
    
    typedef cf_options(cfoptionflags, cfrunloopactivity) {
        kcfrunloopentry         = (1ul << 0), // 即将进入loop
        kcfrunloopbeforetimers  = (1ul << 1), // 即将处理 timer
        kcfrunloopbeforesources = (1ul << 2), // 即将处理 source
        kcfrunloopbeforewaiting = (1ul << 5), // 即将进入休眠
        kcfrunloopafterwaiting  = (1ul << 6), // 刚从休眠中唤醒
        kcfrunloopexit          = (1ul << 7), // 即将退出loop
    };

        上面的 source/timer/observer 被统称为 **mode item**，一个 item 可以被同时加入多个
mode。但一个 item 被重复加入同一个 mode 时是不会有效果的。如果一个 mode 中一个 item 都没有，则 runloop
会直接退出，不进入循环。

## **runloop ****的 ****mode**

        cfrunloopmode 和 cfrunloop 的结构大致如下：

    
    
    struct __cfrunloopmode {
        cfstringref _name;            // mode name, 例如 @"kcfrunloopdefaultmode"
        cfmutablesetref _sources0;    // set
        cfmutablesetref _sources1;    // set
        cfmutablearrayref _observers; // array
        cfmutablearrayref _timers;    // array
        ...
    };

        cfrunloop 对外暴露的管理 mode 接口只有下面2个:

    
    
    cfrunloopaddcommonmode(cfrunloopref runloop, cfstringref modename);
    cfrunloopruninmode(cfstringref modename, ...); 

        mode 暴露的管理 mode item 的接口有下面几个：

    
    
    cfrunloopaddsource(cfrunloopref rl, cfrunloopsourceref source, cfstringref modename);
    cfrunloopaddobserver(cfrunloopref rl, cfrunloopobserverref observer, cfstringref modename);
    cfrunloopaddtimer(cfrunloopref rl, cfrunlooptimerref timer, cfstringref mode);
    cfrunloopremovesource(cfrunloopref rl, cfrunloopsourceref source, cfstringref modename);
    cfrunloopremoveobserver(cfrunloopref rl, cfrunloopobserverref observer, cfstringref modename);
    cfrunloopremovetimer(cfrunloopref rl, cfrunlooptimerref timer, cfstringref mode);

在你的代码中，你通过name来识别模式。ios中定义一个默认的模式和几种常用的模式，可通过字符串name来指定模式。你也可以自定义模式，只需要一个自定义字符串name指定模式名称。尽管你指定到自定义模式的名字是任意的，这些模式的内容不是任意的。你必须添加一个或多个输入源，计时器或运行循环观察者到任何你创建的模式，以确保它们有用。

        下表列出了苹果定义的标准模式以及描述。

预定义的 runloop 模式：

模式

|

名称

|

说明  
  
---|---|---  
  
默认

|

[nsdefaultrunloopmode](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid/_self)(cocoa)

[kcfrunloopdefaultmode](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid/_self)
(core foundation)

|

默认模式用于大多数操作。大多数情况下，你使用该模式来启动你的 runloop 并配置你的输入源。  
  
连接

|

nsconnectionreplymode(cocoa)

|

cocoa结合nsconnection 对象使用该模式来监控回答。你自己应该很少需要使用这个模式。  
  
模态

|

nsmodalpanelrunloopmode(cocoa)

|

cocoa使用该模式来识别用于模态面板的事件。  
  
事件跟踪

|

nseventtrackingrunloopmode(cocoa)

|

cocoa使用该模式在鼠标拖动期间来限制传入的事件和其他类型用户界面跟踪循环。  
  
常见模式

|

[nsrunloopcommonmodes](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid/_self)(cocoa)

[kcfrunloopcommonmodes](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid/_self)
(core foundation)

|

只是一个常用模式的可配置组。将输入源与这种模式结合也将它与组中其他模式结合。对于cocoa引用，这组默认包括默认、模态和时间跟踪模式。核心基础包括的只是默认模式。你可以使用
[cfrunloopaddcommonmode](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid/_self)
函数添加自定义模式。

  
  
            注意：kcfrunloopdefaultmode 和 uitrackingrunloopmode。这两个 mode
都已经被标记为"common"属性。defaultmode 是 app 平时所处的状态，trackingrunloopmode 是追踪 scrollview
滑动时的状态。当你创建一个 timer 并加到 defaultmode 时，timer 会得到重复回调，但此时滑动一个tableview时，runloop
会将 mode 切换为 trackingrunloopmode，这时 timer 就不会被回调，并且也不会影响到滑动操作。 有时你需要一个
timer，在两个 mode 中都能得到回调，一种办法就是将这个 timer 分别加入这两个 mode。还有一种方式，就是将 timer 加入到顶层的
runloop 的 "commonmodeitems" 中。"commonmodeitems" 被 runloop 自动更新到所有具有"common"属性的
mode 里去。

        注意：mode
区分基于事件的来源而非事件的类型。例如，你不会使用模式来匹配鼠标单击事件或键盘事件。你可以使用模式来监听一组不同的端口，暂时暂停计时器，或以其他方式改变来源和当前监控的
runloop 观察者。

## **runloop****的内部逻辑**

        每次你运行，线程的 runloop 处理等待事件并生成通知附加观察者。顺序如下：

  * 通知观察者已进入 runloop 。
  * 通知观察者任何准备的计时器将要触发。
  * 通知观察者任何不基于端口的输入源将要触发。
  * 触发任何不基于端口准备触发的输入源。
  * 如果基于端口输入源准备就绪等待触发，立即处理事件。跳转到第9步。
  * 通知观察者线程将要休眠。
  * 让线程休眠直到以下事件发生：
    * 一个事件到达基于端口的输入源。
    * 计时器触发。
    * 为 runloop 到期设置的超时值。
    * runloop 显式的唤醒
  * 通知观察者线程唤醒
  * 处理等待事件
    * 如果一个用户定义的计时器触发，处理计时器事件并重新启动循环。跳转到步骤2.
    * 如果一个输入源触发，交付事件。
    * 如果 runloop 显式的唤醒但尚未超时，重新启动循环，跳转到步骤2.
  * 通知观察者 runloop 已退出。

因为计时器和输入源的观察者通知在事件发生前被通知，可能通知时间与实际发生的时间有差距。如果这些事件间的时间至关重要，你可以使用休眠和从休眠到唤醒的通知来帮助你关联实际事件间的时间。

        因为计时器和其他定期事件在你运行 runloop
时被通知，注意循环会破坏这些事件的通知。例如你通过输入一个循环并向应用多次请求事件来实现一个鼠标跟踪程序时，会发生这种行为。因为你的代码直接抓住事件，而非让
app 正常调度这些事件，活动的计时器可能无法被触发直到你的鼠标跟踪程序退出并返回让 app 控制。

        一个 runloop 可以用 runloop 对象显式的唤醒。其他活动也可能导致 runloop
被唤醒。例如添加另一个非基于端口的输入源source0来唤醒 runloop ，这样可以立即处理输入源，而不是等到其他事件发生。

下面是一个示意图:

![runloop_1](/image/ios_runloop_de_jie_shao/7c43b3265d71ab773db3014c50ea015e78d03a0cfcb726c87fd284b125c06d11)

        其内部代码整理如下：

    
    
    /// 用defaultmode启动
    void cfrunlooprun(void) {
        cfrunlooprunspecific(cfrunloopgetcurrent(), kcfrunloopdefaultmode, 1.0e10, false);
    }
    /// 用指定的mode启动，允许设置runloop超时时间
    int cfrunloopruninmode(cfstringref modename, cftimeinterval seconds, boolean stopafterhandle) {
        return cfrunlooprunspecific(cfrunloopgetcurrent(), modename, seconds, returnaftersourcehandled);
    }
    /// runloop的实现
    int cfrunlooprunspecific(runloop, modename, seconds, stopafterhandle) {
        /// 首先根据modename找到对应mode
        cfrunloopmoderef currentmode = __cfrunloopfindmode(runloop, modename, false);
        /// 如果mode里没有source/timer/observer, 直接返回。
        if (__cfrunloopmodeisempty(currentmode)) return;
        /// 1. 通知 observers: runloop 即将进入 loop。
        __cfrunloopdoobservers(runloop, currentmode, kcfrunloopentry);
        /// 内部函数，进入loop
        __cfrunlooprun(runloop, currentmode, seconds, returnaftersourcehandled) {
            boolean sourcehandledthisloop = no;
            int retval = 0;
            do {
                /// 2. 通知 observers: runloop 即将触发 timer 回调。
                __cfrunloopdoobservers(runloop, currentmode, kcfrunloopbeforetimers);
                /// 3. 通知 observers: runloop 即将触发 source0 (非port) 回调。
                __cfrunloopdoobservers(runloop, currentmode, kcfrunloopbeforesources);
                /// 执行被加入的block
                __cfrunloopdoblocks(runloop, currentmode);
                /// 4. runloop 触发 source0 (非port) 回调。
                sourcehandledthisloop = __cfrunloopdosources0(runloop, currentmode, stopafterhandle);
                /// 执行被加入的block
                __cfrunloopdoblocks(runloop, currentmode);
                /// 5. 如果有 source1 (基于port) 处于 ready 状态，直接处理这个 source1 然后跳转去处理消息。
                if (__source0diddispatchportlasttime) {
                    boolean hasmsg = __cfrunloopservicemachport(dispatchport, &msg)
                    if (hasmsg) goto handle_msg;
                }
                /// 通知 observers: runloop 的线程即将进入休眠(sleep)。
                if (!sourcehandledthisloop) {
                    __cfrunloopdoobservers(runloop, currentmode, kcfrunloopbeforewaiting);
                }
                /// 7. 调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
                /// • 一个基于 port 的source 的事件。
                /// • 一个 timer 到时间了
                /// • runloop 自身的超时时间到了
                /// • 被其他什么调用者手动唤醒
                __cfrunloopservicemachport(waitset, &msg, sizeof(msg_buffer), &liveport) {
                    mach_msg(msg, mach_rcv_msg, port); // thread wait for receive msg
                }
                /// 8. 通知 observers: runloop 的线程刚刚被唤醒了。
                __cfrunloopdoobservers(runloop, currentmode, kcfrunloopafterwaiting);
                /// 收到消息，处理消息。
                handle_msg:
                /// 9.1 如果一个 timer 到时间了，触发这个timer的回调。
                if (msg_is_timer) {
                    __cfrunloopdotimers(runloop, currentmode, mach_absolute_time())
                } 
                /// 9.2 如果有dispatch到main_queue的block，执行block。
                else if (msg_is_dispatch) {
                    __cfrunloop_is_servicing_the_main_dispatch_queue__(msg);
                } 
                /// 9.3 如果一个 source1 (基于port) 发出事件了，处理这个事件
                else {
                    cfrunloopsourceref source1 = __cfrunloopmodefindsourceformachport(runloop, currentmode, liveport);
                    sourcehandledthisloop = __cfrunloopdosource1(runloop, currentmode, source1, msg);
                    if (sourcehandledthisloop) {
                        mach_msg(reply, mach_send_msg, reply);
                    }
                }
                /// 执行加入到loop的block
                __cfrunloopdoblocks(runloop, currentmode);
                if (sourcehandledthisloop && stopafterhandle) {
                    /// 进入loop时参数说处理完事件就返回。
                    retval = kcfrunlooprunhandledsource;
                } else if (timeout) {
                    /// 超出传入参数标记的超时时间了
                    retval = kcfrunloopruntimedout;
                } else if (__cfrunloopisstopped(runloop)) {
                    /// 被外部调用者强制停止了
                    retval = kcfrunlooprunstopped;
                } else if (__cfrunloopmodeisempty(runloop, currentmode)) {
                    /// source/timer/observer一个都没有了
                    retval = kcfrunlooprunfinished;
                }
                /// 如果没超时，mode里没空，loop也没被停止，那继续loop。
            } while (retval == 0);
        }
        /// 10. 通知 observers: runloop 即将退出。
        __cfrunloopdoobservers(rl, currentmode, kcfrunloopexit);
    }

        可以看到，实际上 runloop 就是这样一个函数，其内部是一个 do-while 循环。当你调用 cfrunlooprun()
时，线程就会一直停留在这个循环里；直到超时或被手动停止，该函数才会返回。

## **runloop 的适用场景**

        当你为你的应用创建子线程时，才可能需要显式的运行一个 runloop 。主线程的 runloop 是一个重要的基础能力。因此，app
提供代码来运行 main runloop 并自动启动循环。ios中 uiapplication 的 run 方法（或者osx中的 nsapplication
）启动一个应用的 main runloop 作为正常启动序列的一部分，你不应该显式的调用

        对于子线程，你需要决定 runloop 是否必要的，如果是，你自己配置并启用它。你不需要在所有情况下启动一个线程的 runloop
。例如，如果你使用一个线程来执行一些长期和预定的任务，你就能避免启动 runloop 。 runloop
用于你想与线程有更多交互的情况。例如，你需要启动一个 runloop 如果你计划做以下事情：

  * 使用端口或自定义输入源来与其他线程通信。
  * 在线程上使用计时器。
  * 在程序中使用任何performselector方法。
  * 使线程执行周期任务

        如果你选择使用 runloop
，配置和设置是很简单的。与所有线程编程一样，你应该有个计划在适当的情况下退出子线程。让它退出比强迫它终止可以更好的更干净的结束线程。如何配置信息和退出运行循环的信息参见使用运行循环对象（
[using run loop
objects](http://write.blog.csdn.net/postedit/43404181#//apple_ref/doc/uid
/10000057i-ch16-sw5)）。

## 结语

通过上面对runloop的介绍，现在应该可以轻松答出最开始的题目的答案，就是ad。当然通过介绍，我们虽然已经对runloop有了初步的认识，但是认识它有什么好处呢？好像平时编程中也没用到它。其实不然，下一篇文章，我们将介绍ios中runloop的具体应用场景，尝试利用runloop的特性来实现一个类似的例子，给我们以后的开发和代码设计提供思路。

