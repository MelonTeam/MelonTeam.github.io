---
layout: post
title: "一个创建自定义事件源的例子"
date: 2017-05-31 19:57:00
categories: ios
author: justinytang
tags: 线程 runloop
---

* content
{:toc}



上一篇文章我们介绍了RunLoop的相关知识，但是毕竟我们实际开发中很少应用，今天我们就通过介绍RunLoop在iOS系统中的应用，来实现一个小小的demo，启发我们在开发过程中设计代码架构时的思路。

## **RunLoop 的适用场景**
<!--more-->

       回顾一下上一篇文章的介绍，只有当你为你的应用创建子线程时，才可能需要显式的运行一个 RunLoop 。而主线程的 RunLoop
是自动启动循环。对于子线程，当线程有更多交互的情况。例如：

  * 使用端口或自定义输入源来与其他线程通信。
  * 在线程上使用计时器。
  * 在程序中使用任何performSelector方法。
  * 使线程执行周期任务

则你需要启动一个 RunLoop 。

## **RunLoop 的使用**

        RunLoop 对象为主要界面提供添加输入源、计时器和 RunLoop 观察者到你的 RunLoop 并运行之。每个线程都有一个单独的
RunLoop 对象与之相关联。在Cocoa，这个对象是 NSRunLoop 类的一个实例。在底层应用中，它是一个指向 CFRunLoopRef
不透明类型的指针。

### **获取 RunLoop 对象**

        为了获取当前线程的 RunLoop ，你可以使用下列方法之一：

  * 使用 NSRunLoop 的 CurrentRunLoop 类方法来获取一个 NSRunLoop 对象。
  * 使用 CFRunLoopGetCurrent 函数。

        当需要时，你可以从 NSRunLoop 对象获取一个 CFRunLoopRef 不透明类型指针。NSRunLoop 类定义了一个
GetCFRunLoop 方法，返回一个 CFRunLoopRef 类型，你可以传递到核心基础程序。因为两个对象引用相同 NSRunLoop
，如果需要你可以混合调用 NSRunLoop 对象和 CFRunLoopRef 不透明类型。

### **配置运行循环**

        在子线程运行一个 RunLoop 之前，你必须添加至少一个输入源或计时器到 RunLoop 上。如果一个 RunLoop
没有任何来源要监控，当你试图运行它时，它会立即退出。

        除了增加来源，你可以增加 RunLoop 观察者并使用它们来监测 RunLoop 的不同执行阶段。为了增加一个 RunLoop
观察者，创建一个 CFRunLoopObserverRef 不透明类型并使用 CFRunLoopAddObserver 函数来添加到你的 RunLoop
上。

        下面的代码向你展示如何创建 RunLoop 观察者，因此代码简单的设置了一个 RunLoop 来监视所有 RunLoop 活动。

    
    
    - (void)threadMain
    {
        // The application uses garbage collection, so no autorelease pool is needed.
        NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
        // Create a run loop observer and attach it to the run loop.
        CFRunLoopObserverContext  context = {0, self, NULL, NULL, NULL};
        CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
        if (observer)
        {
            CFRunLoopRef    cfLoop = [myRunLoop getCFRunLoop];
            CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
        }
        // Create and schedule the timer.
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                    selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
        NSInteger    loopCount = 10;
        do
        {
            // Run the run loop 10 times to let the timer fire.
            [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            loopCount--;
        }
        while (loopCount);
    }

        当为一个长期线程配置 RunLoop ，最好添加至少一个输入源来接收消息。尽管你可以仅添加一个计时器来进入 RunLoop
，一旦计时器触发后，它通常是无效的，这将导致 RunLoop 退出。附加一个重复的计时器可以保持 RunLoop
运行一段较长的时间，但会涉及到周期性的触发计时器唤醒你的线程，这实际上是另一种形式的轮询。相比之下，一个输入源等待事件发生，保持你的线程休眠直到它完成。

### **启动运行循环**

        只有子线程才需要启动 RunLoop 。一个 RunLoop 必须至少有一个输入源或计时器用于监控。如果没有，运行循环将立即退出。

        有以下几种方法来启动 RunLoop ：

  * 无条件的：

        无条件的进入你的 RunLoop 是最简单的选择，但也是最不可取的。无条件的运行你的 RunLoop 将线程放置到一个永久循环，你对
RunLoop 本身只有很少的控制。你可以添加和删除输入源和计时器，但停止 RunLoop 的唯一方法是杀死它。也没办法在自定义模式下运行 RunLoop
。

  * 设置时间限制：

        相比无条件的运行一个 RunLoop ，运行一个有超时值的 RunLoop 是更好的。当你使用一个超时值时，RunLoop
持续运行直到一个事件到达或者分配的时间过期。如果一个事件到达，该事件被分配到一个处理程序来处理，RunLoop 退出。你的代码可以重新启动 RunLoop
来处理下一个事件。如果分配的时间过期，你可以简单的重启 RunLoop。

  * 在一个特定的模式：

        除了设置超时时间，你也可以使用特定模式来运行你的 RunLoop 。模式和超时时间并不互斥，在启动 RunLoop 时都可以使用。

        下面一段代码展示了子线程主入口该怎么设计。这个例子的关键部分展示了 RunLoop 的基本结构。从本质上说，你添加输入源和计时器到
RunLoop ，然后反复调用程序来启动 RunLoop 。每次 RunLoop 程序返回，检查是否出现任何条件批准线程退出。

    
    
    - (void)skeletonThreadMain
    {
        // Set up an autorelease pool here if not using garbage collection.
        BOOL done = NO;
        // Add your sources or timers to the run loop and do any other setup.
        do
        {
            // Start the run loop but return after each source is handled.
            SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);
            // If a source explicitly stopped the run loop, or if there are no
            // sources or timers, go ahead and exit.
            if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
                done = YES;
            // Check for any other exit conditions here and set the
            // done variable as needed.
        }
        while (!done);
        // Clean up code here. Be sure to release any allocated autorelease pools.
    }

        可以递归的运行一个 RunLoop 。换句话说，你可以调用 CFRunLoopRun, CFRunLoopRunInMode 或任何
NSRunLoop 方法来启动 RunLoop ，但其中必须有输入源或计时器的处理模块。当这样做时，你可以使用任何你想要的方式来运行嵌套的 RunLoop
，包括在 RunLoop 外使用的模式。

### **退出运行循环**

        有两种方法可以使 RunLoop 在处理事件前退出：

  * 配置 RunLoop 一个超时值：

        使用一个超时值当然是首选，如果你可以管理它。指定一个超时值，让 RunLoop 完成所有正常进程，包括在退出前通知 RunLoop 观察者。

  * 告知 RunLoop 停止：

        显式的使用 CFRunLoopStop 函数停止 RunLoop 产生的结果类似于超时。 RunLoop 发送任何剩余 RunLoop
通知然后退出。不同的是你可以在无条件启动 RunLoop 时使用此方法。

        注意：尽管删除 RunLoop 的输入源和计时器也可能导致 RunLoop 退出，但这并不是常规的方式。某些时候一些系统程序会注入输入源到
RunLoop 来处理事件，你无法了解到是否有系统添加的输入源，这将阻止 RunLoop 退出。

## RunLoop 在iOS中的应用

### AutoreleasePool

     App启动后，苹果在主线程 RunLoop 里注册了两个 Observer，其回调都是
_wrapRunLoopWithAutoreleasePoolHandler()。

     第一个 Observer 监视的事件是 Entry(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush()
创建自动释放池。其 order 是-2147483647，优先级最高，保证创建释放池发生在其他所有回调之前。

     第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠) 时调用_objc_autoreleasePoolPop()
和 _objc_autoreleasePoolPush() 释放旧的池并创建新池；Exit(即将退出Loop) 时调用
_objc_autoreleasePoolPop() 来释放自动释放池。这个 Observer 的 order 是
2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。

     在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop 创建好的 AutoreleasePool
环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。

### 事件响应

    苹果注册了一个 Source1 (基于 mach port 的) 用来接收系统事件，其回调函数为
__IOHIDEventSystemClientQueueCallback()。

    当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 IOKit.framework 生成一个 IOHIDEvent 事件并由 SpringBoard
接收。这个过程的详细情况可以参考[这里](http://iphonedevwiki.net/index.php/IOHIDFamily)。SpringBoard
只接收按键(锁屏/静音等)，触摸，加速，接近传感器等几种 Event，随后用 mach port 转发给需要的App进程。随后苹果注册的那个 Source1
就会触发回调，并调用 _UIApplicationHandleEventQueue() 进行应用内部的分发。

     _UIApplicationHandleEventQueue() 会把 IOHIDEvent 处理并包装成 UIEvent
进行处理或分发，其中包括识别 UIGesture/处理屏幕旋转/发送给 UIWindow 等。通常事件比如 UIButton
点击、touchesBegin/Move/End/Cancel 事件都是在这个回调中完成的。

### 手势识别

     当上面的 _UIApplicationHandleEventQueue() 识别了一个手势时，其首先会调用 Cancel 将当前的
touchesBegin/Move/End 系列回调打断。随后系统将对应的 UIGestureRecognizer 标记为待处理。

     苹果注册了一个 Observer 监测 BeforeWaiting (Loop即将进入休眠) 事件，这个Observer的回调函数是
_UIGestureRecognizerUpdateObserver()，其内部会获取所有刚被标记为待处理的
GestureRecognizer，并执行GestureRecognizer的回调。

    当有 UIGestureRecognizer 的变化(创建/销毁/状态改变)时，这个回调都会进行相应处理。

### 界面更新

     当在操作 UI 时，比如改变了 Frame、更新了 UIView/CALayer 的层次时，或者手动调用了 UIView/CALayer 的
setNeedsLayout/setNeedsDisplay方法后，这个 UIView/CALayer 就被标记为待处理，并被提交到一个全局的容器去。

     苹果注册了一个 Observer 监听 BeforeWaiting(即将进入休眠) 和 Exit (即将退出Loop)
事件，回调去执行一个很长的函数：  
_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()。这个函数里会遍历所有待处理的
UIView/CAlayer 以执行实际的绘制和调整，并更新 UI 界面。

     这个函数内部的调用栈大概是这样的：

    
    
    _ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()
        QuartzCore:CA::Transaction::observer_callback:
            CA::Transaction::commit();
                CA::Context::commit_transaction();
                    CA::Layer::layout_and_display_if_needed();
                        CA::Layer::layout_if_needed();
                            [CALayer layoutSublayers];
                                [UIView layoutSubviews];
                        CA::Layer::display_if_needed();
                            [CALayer display];
                                [UIView drawRect];

### 网络请求

     iOS 中，关于网络请求的接口自下至上有如下几层:

    
    
    CFSocket
    CFNetwork       ->ASIHttpRequest
    NSURLConnection ->AFNetworking
    NSURLSession    ->AFNetworking2, Alamofire

• CFSocket 是最底层的接口，只负责 socket 通信。  
• CFNetwork 是基于 CFSocket 等接口的上层封装，ASIHttpRequest 工作于这一层。  
• NSURLConnection 是基于 CFNetwork 的更高层的封装，提供面向对象的接口，AFNetworking 工作于这一层。  
• NSURLSession 是 iOS7 中新增的接口，表面上是和 NSURLConnection 并列的，但底层仍然用到了
NSURLConnection 的部分功能 (比如 com.apple.NSURLConnectionLoader 线程)，AFNetworking2 和
Alamofire 工作于这一层。

     通常使用 NSURLConnection 时，你会传入一个 Delegate，当调用了 [connection start] 后，这个
Delegate 就会不停收到事件回调。实际上，start 这个函数的内部会会获取 CurrentRunLoop，然后在其中的 DefaultMode
添加了4个 Source0 (即需要手动触发的Source)。CFMultiplexerSource 是负责各种 Delegate
回调的，CFHTTPCookieStorage 是处理各种 Cookie 的。

     当开始网络传输时，我们可以看到 NSURLConnection 创建了两个新线程：com.apple.NSURLConnectionLoader
和 com.apple.CFSocket.private。其中 CFSocket 线程是处理底层 socket
连接的。NSURLConnectionLoader 这个线程内部会使用 RunLoop 来接收底层 socket 的事件，并通过之前添加的 Source0
通知到上层的 Delegate。

![](/image/yi_ge_chuang_jian_zi_ding_yi_shi_jian_yuan_de_li_zi/31b90899e7a07d66751bfacd23d3f4f1a56a54f394ecaa6e17eb4bc1e1fd178f)

     NSURLConnectionLoader 中的 RunLoop 通过一些基于 mach port 的 Source 接收来自底层
CFSocket 的通知。当收到通知后，其会在合适的时机向 CFMultiplexerSource 等 Source0 发送通知，同时唤醒 Delegate
线程的 RunLoop 来让其处理这些通知。CFMultiplexerSource 会在 Delegate 线程的 RunLoop 对 Delegate
执行实际的回调。

## 一个Demo

          根据上面对NSURLConnection的介绍，我们模拟一个类似的设计来实现通过RunLoop来等待和处理事件。

### 第一步：创建任务线程

          创建子线程，用于初始化一个接收自定义事件源。该子线程主函数入口设计如下：

    
    
    - (void)main
    {
        @autoreleasepool {
            NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
            //自定义的输入事件源Source1，可以通过delegate回调，出发子线程处理方法
            self.customInputSource = [[CustomInputSource alloc] init];
            self.customInputSource.delegate = self;
            [self.customInputSource addToCurrentRunLoop];
            while (!self.cancelled) {
                //runloop结束前完成其他任务
                [self finishOtherTask];
                [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
    }

 主函数初始化自定义的事件源，通过delegate的方式回调回来。并将事件源加入到当前的RunLoop中。

### 第二步：设计自定义事件源

       自定义事件源包括初始化，添加事件源到指定RunLoop，从指定RunLoop中删除事件源等方法。而初始化方法中包含了Run Loop
Source Context的三个回调方法，具体代码如下：

    
    
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            /*RunLoopSourceContext的三个回调方法:
             runLoopSourceScheduleRoutine():把当前的Run Loop Source添加到Run Loop中时，会回调这个方法。  
             假如主线程管理该Input source，可以使用performSelectorOnMainThread通知主线程。主线程和当前线程的通信使用CCRunLoopContext对象来完成。
             runLoopSourcePerformRoutine():当前Input source被告知需要处理事件.
             runLoopSourceCancelRoutine():如果使用CFRunLoopSourceInvalidate函数把输入源从Run Loop里面移除的话,系统会回调该方法。  
             我们在该方法中移除了主线程对当前Input source context的引用。
             */
            CFRunLoopSourceContext context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL,
                &runLoopSourceScheduleRoutine,
                &runLoopSourceCancelRoutine,
                &runLoopSourcePerformRoutine};
            _runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
        }
        return self;
    }
    
    - (void)addToCurrentRunLoop
    {
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
    }
    
    - (void)invalidate
    {
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFRunLoopRemoveSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
    } 

        注意：通过上述代码可以看出，自定义的事件源的实例是触发子线程工作的钥匙，所以这个实例对象，需要被与子线程相关联的线程所hold住。

       而触发自定义事件源的方法如下：

    
    
    - (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runLoop
    {
        CFRunLoopSourceSignal(_runLoopSource);
        CFRunLoopWakeUp(runLoop);
    }

### 第三步：设计触发事件源的函数

        这一步顾名思义，在其他数据准备好的时候，通过自定义事件源触发子线程的工作。

### 第四步：退出子线程RunLoop

        退出RunLoop的方式也很简单，只需要将当前子线程的runLoop实例停止就可以了，代码如下：

    
    
    - (void)stopThreadAndRunLoop:(CFRunLoopRef)runLoop
    {
        CFRunLoopStop(runLoop);
        [_customInputSourceThread cancel];
    }

经过上面四个步骤，你就已经设计了一个属于你自己的自定义事件源，这个事件会根据你数据的准备情况来主动唤醒子线程的RunLoop来处理具体事件，这样的好处不言而喻，充分利用了RunLoop的特性，非常适合类似网络请求这样的异步等待事件。





