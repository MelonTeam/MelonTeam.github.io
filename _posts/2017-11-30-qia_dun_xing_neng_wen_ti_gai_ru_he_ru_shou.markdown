---
layout: post
title: "卡顿性能问题该如何入手"
date: 2017-11-30 15:00:00 +0800
categories: 未分类
author: kylewu
tags: 卡顿优化
---

* content
{:toc}



第一眼看到这个标题应该想到的关键字大多都是`Instruments`，确实这是个很强大的工具，但是我今天想介绍的方法不是使用`Instruments`，而是通过另一种方式去找到性能的问题在那，从而计划优化方案解决性能问题。

## 界面卡顿的原因
<!--more-->

App主线程首先在`CPU`中计算需要显示内容，如视图的布局计算、图片解码、文本绘制等。然后再将计算好的内容提交给`GPU`，由`GPU`进行合成、渲染等，之后`GPU`会把渲染好的结果提交到帧缓冲区等待显示信号，由于垂直同步的机制，如果在一个显示信号时间内`GPU`没有完成内容提交，那么这一帧就会被丢弃，而显示屏会保留之前的内容不变。

简单的来说就是主线程要想达到60fps的话，那么就需要在`1/60s ≈ 16.7ms`内把所有的计算任务做完，否则就会出现卡顿。

## 监测

在了解了原因之后，要想解决卡顿问题只需要找到在一个信号时间内谁耗时最长即可。所以我们应该需要做以下几件事：  
1\. 开启子线程利用`Runloop`来监测主线程耗时最长的行为  
2\. 将发生卡顿时的堆栈收集  
3\. 分析出现堆栈最多的函数

### Runloop

主线程的任务都是以Runloop为单位发生的，而Apple提供了一些API去检测Runloop机制，那么我们就可以监听Runloop的行为了。

    
    
    - (void)startMonitoring
    {
        ...
        CFRunLoopObserverContext context = {0, (__bridge void*)self, NULL, NULL};
        _runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                   kCFRunLoopAllActivities,
                                                   YES,
                                                   0,
                                                   &runLoopObserverCallBack,
                                                   &context);
        CFRunLoopAddObserver(CFRunLoopGetMain(),
                             _runLoopObserver,
                             kCFRunLoopCommonModes);
        ...
    }
    
    static void runLoopObserverCallBack(CFRunLoopObserverRef observer,
                                        CFRunLoopActivity activity,
                                        void* info)
    {
        KWFluencyMonitor *appFluencyMonitor = (__bridge KWFluencyMonitor*)info;
        appFluencyMonitor.runLoopActivity = activity;
        dispatch_semaphore_signal(appFluencyMonitor.semaphore);
    }
    
    

主线程已经开始监听了，那么我们只需要另外再启动个子线程来监控丢帧情况既可。

    
    
    - (void)startMonitoring
    {
        ...
        dispatch_async(_monitorQueue, ^{
            while (YES)
            {
                //一个单位Runloop超过了16.7ms就会出现丢帧
                long st = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 16.7*NSEC_PER_MSEC));
                if (st != 0)
                {
                    if (!_runLoopObserver)
                    {
                        _timeoutCount = 0;
                        self.semaphore = 0;
                        self.runLoopActivity = 0;
                        return;
                    }
                    
                    if (self.runLoopActivity == kCFRunLoopBeforeSources ||
                        self.runLoopActivity == kCFRunLoopAfterWaiting)
                    {
                        //这里规定超过丢两帧就打印堆栈信息
                        if (++_timeoutCount < MAX_TIMEOUT_COUNT)
                            continue;
                        
                        [self printfMainStackTracLogs];
                    }
                }
                
                _timeoutCount = 0;
            }
        });
        ...
    }
    

### 堆栈收集

当发生了两次丢帧之后就会既刻采集主线程的堆栈信息，大概内容如下：

    
    
    **************************************
    Time: 2017-11-29 15:57:26 385
    Device: iPhone 7Plus, 10.3.3
    
    0   libsystem_c.dylib                   0x0000000182c84758 __swrite + 20
    1   libsystem_c.dylib                   0x0000000182c3b678 _swrite + 104
    2   libsystem_c.dylib                   0x0000000182c7ed40 __sflush + 96
    3   libsystem_c.dylib                   0x0000000182ca1f04  + 316
    4   libsystem_c.dylib                   0x0000000182c3b5e4 vfprintf_l + 64
    5   libsystem_c.dylib                   0x0000000182c4a22c printf + 84
    6   QQ                                  0x0000000102651f44 -[QQLogger addOneLogInternal:inFile:inLine:moduleName:actionName:withLogContent:] + 1120
    7   QQ                                  0x0000000102651010 -[QQLogger addOneCLog:inFile:inLine:moduleName:actionName:withLogContent:] + 180
    8   QQ                                  0x0000000101e0fed4 +[TBStoryInteractiveView calcHeightWithEntryType:width:interactiveModel:commentModel:likeModel:] + 1296
    9   QQ                                  0x0000000102eb4488 -[TBStoryMgr generateStoryInteractiveViewModel:] + 1080
    10  QQ                                  0x0000000102eb3f94 -[TBStoryMgr getDisplayFeedListModel720:filterRecommend:] + 1060
    11  QQ                                  0x0000000102eb37a0 -[TBStoryMgr getStoryListFilterRecommend:] + 396
    12  QQ                                  0x0000000102eb29dc -[TBStoryMgr getFeedListCacheFilterRecommend:] + 692
    13  QQ                                  0x0000000102eb2f4c __57-[TBStoryMgr asyncGetFeedListCacheFilterRecommend:block:]_block_invoke_2 + 88
    14  libdispatch.dylib                   0x000000010fc41a50 _dispatch_call_block_and_release + 24
    15  libdispatch.dylib                   0x000000010fc41a10 _dispatch_client_callout + 16
    16  libdispatch.dylib                   0x000000010fc46b78 _dispatch_main_queue_callback_4CF + 1204
    17  CoreFoundation                      0x0000000183cd50c8  + 12
    18  CoreFoundation                      0x0000000183cd2ce4  + 1572
    19  CoreFoundation                      0x0000000183c02da4 CFRunLoopRunSpecific + 424
    20  GraphicsServices                    0x000000018566d074 GSEventRunModal + 100
    21  UIKit                               0x0000000189ebdc9c UIApplicationMain + 208
    22  QQ                                  0x000000010148d1b0 main + 312
    23  libdyld.dylib                       0x0000000182c1159c  + 4
    
    **************************************
    
    **************************************
    Time: 2017-11-29 15:57:26 452
    Device: iPhone 7Plus, 10.3.3
    
    0   CoreFoundation                      0x0000000183c08950  + 88
    1   QQ                                  0x00000001024df308 CZ_StringEqualToString + 44
    2   QQ                                  0x0000000103de1c60 -[TBUIDService isSelfUnionID:] + 200
    3   QQ                                  0x0000000102eb420c -[TBStoryMgr generateStoryInteractiveViewModel:] + 444
    4   QQ                                  0x0000000102eb3f94 -[TBStoryMgr getDisplayFeedListModel720:filterRecommend:] + 1060
    5   QQ                                  0x0000000102eb37a0 -[TBStoryMgr getStoryListFilterRecommend:] + 396
    6   QQ                                  0x0000000102eb29dc -[TBStoryMgr getFeedListCacheFilterRecommend:] + 692
    7   QQ                                  0x0000000102eb2f4c __57-[TBStoryMgr asyncGetFeedListCacheFilterRecommend:block:]_block_invoke_2 + 88
    8   libdispatch.dylib                   0x000000010fc41a50 _dispatch_call_block_and_release + 24
    9   libdispatch.dylib                   0x000000010fc41a10 _dispatch_client_callout + 16
    10  libdispatch.dylib                   0x000000010fc46b78 _dispatch_main_queue_callback_4CF + 1204
    11  CoreFoundation                      0x0000000183cd50c8  + 12
    12  CoreFoundation                      0x0000000183cd2ce4  + 1572
    13  CoreFoundation                      0x0000000183c02da4 CFRunLoopRunSpecific + 424
    14  GraphicsServices                    0x000000018566d074 GSEventRunModal + 100
    15  UIKit                               0x0000000189ebdc9c UIApplicationMain + 208
    16  QQ                                  0x000000010148d1b0 main + 312
    17  libdyld.dylib                       0x0000000182c1159c  + 4
    
    **************************************
    

从堆栈信息可以看得到函数`getDisplayFeedListModel720`的执行花了两个Runloop或者更多，那么我们就应该去细读这个函数的逻辑并且优化才能解决卡顿问题。

### 代码

附件放有监测的代码，使用很方便只需要调用一个接口（堆栈信息放于document目录下KWMonitorLog.txt）

    
    
    [[KWFluencyMonitor sharedInstance] startMonitoring];
    

