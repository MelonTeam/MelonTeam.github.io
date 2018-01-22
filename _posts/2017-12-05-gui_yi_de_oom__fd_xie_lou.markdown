---
layout: post
title: "诡异的oom---fd泄漏"
date: 2017-12-05 16:43:00 +0800
categories: 未分类
author: henrikwu
tags: 泄漏 fd 线程 OOM OutOfMemoryError
---

* content
{:toc}

| 导语 oom一定是因为内存不足吗？未必！

   最近组件更新，三方反馈一个诡异问题outofmemoryerror.

    
<!--more-->
    
    java.lang.OutOfMemoryError: Could not allocate JNI Env
    java.lang.Thread.nativeCreate(Native Method)
    java.lang.Thread.start(Thread.java:729)
    com.tencent.mobileqq.msf.sdk.k.d(MsfServiceProxy.java:197)
    com.tencent.mobileqq.msf.sdk.x.onServiceConnected(RemoteServiceProxy.java:59)
    android.app.LoadedApk$ServiceDispatcher.doConnected(LoadedApk.java:1475)
    android.app.LoadedApk$ServiceDispatcher$RunConnection.run(LoadedApk.java:1492)
    android.os.Handler.handleCallback(Handler.java:754)
    android.os.Handler.dispatchMessage(Handler.java:95)
    android.os.Looper.loop(Looper.java:163)
    android.app.ActivityThread.main(ActivityThread.java:6337)
    java.lang.reflect.Method.invoke(Native Method)
    com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:880)
    com.android.internal.os.ZygoteInit.main(ZygoteInit.java:770)

单看这个异常堆栈，发现是在创建线程时oom。这就很奇怪了，因为这个是发生在daemon进程，这只是一个守护进程并没有高内存的操作，并且打出内存信息发现确实内存还很足。那发生oom就是一个超出我们理解的事情了。

    不明白是为什么。之后三方给了我一个链接<https://mp.weixin.qq.com/s/AjtzDxwJzyqC95FXgDPS1g>

发现了新大陆，原来fd(文件描述符)超出限制也会导致linux系统抛oom.

![](/image/gui_yi_de_oom__fd_xie_lou/93cbae14b171934ef34b78f8450d3817b2e20588bf6ad4bc4a212d385eff920c)

再分析我们的组件代码,发现在异常情况下，我们确实会打开大量fd而没有关闭进而导致创建新线程时发现fd不足，进而系统抛出oom.

结论：

    打开的fd一定要及时关闭。

