---
layout: post
title: "Android JNI堆栈分析工具简介"
date: 2017-06-23 17:01:00 +0800
categories: android
author: stevcao
tags: JNI堆栈 ndk-stack
---

* content
{:toc}

| 导语
从事Android开发的同事如果在碰到JNI的bug一般都是比较头疼的，因为JNI出错的日志信息比较少，不像Java层的堆栈那样，可以直接看到出错的信息（异常信息）以及出错的类和行数。最近有在分析项目中一个JNI
crash，查了一些JNI堆栈分析的方法，涉及到ndk的几个工具的使用，跟大家分享一下。

## 一、JNI堆栈
<!--more-->

为了查看JNI的异常堆栈，我这里模拟了一个出错的代码：

![image](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/7f23d66391878bb7de757b542b48437b1e79365851dcbadeaf7b498ae0403094)

这段代码在testException的13行会有空指针的问题，我们实际运行的时候会碰到这样的堆栈异常：

    
    
    1. 06-23 15:02:26.772: W/(299): stopped -- fatal signal, send SIGSTOP to process, request.pid:14173
    2. 06-23 15:02:26.772: I/DEBUG(299): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
    3. 06-23 15:02:26.772: I/DEBUG(299): Build fingerprint: 'OPPO/A33m/A33:5.1.1/LMY47V/1390465867:user/release-keys'
    4. 06-23 15:02:26.772: I/DEBUG(299): Revision: '0'
    5. 06-23 15:02:26.772: I/DEBUG(299): ABI: 'arm'
    6. 06-23 15:02:26.772: I/DEBUG(299): pid: 14173, tid: 14173, name: xample.hellojni  >>> com.example.hellojni <<<
    7. 06-23 15:02:26.772: I/DEBUG(299): signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
    8. 06-23 15:02:26.782: I/DEBUG(299):     r0 ab0173d0  r1 fff7690c  r2 00000001  r3 00000000
    9. 06-23 15:02:26.782: I/DEBUG(299):     r4 ab0173d0  r5 73f18f38  r6 12c1a190  r7 12c79000
    10. 06-23 15:02:26.782: I/DEBUG(299):     r8 00000000  r9 ab016e00  sl 00000000  fp 12c5b1c0
    11. 06-23 15:02:26.782: I/DEBUG(299):     ip 66127bf9  sp fff768f8  lr 66127c01  pc 66127bf4  cpsr 200b0030
    12. 06-23 15:02:26.782: I/DEBUG(299): backtrace:
    13. 06-23 15:02:26.782: I/DEBUG(299):     #00 pc 00000bf4  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (testException+3)
    14. 06-23 15:02:26.782: I/DEBUG(299):     #01 pc 00000bfd  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (Java_com_example_hellojni_HelloJni_stringFromJNI+4)
    15. 06-23 15:02:26.782: I/DEBUG(299):     #02 pc 000001df  /data/dalvik-cache/arm/data@app@com.example.hellojni-1@base.apk@classes.dex
    

这样一堆东西我们是看不出是哪里发生了错误，注意到这里：

    
    
    #00 pc 00000bf4  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (testException+3)
    #01 pc 00000bfd  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (Java_com_example_hellojni_HelloJni_stringFromJNI+4)
    #02 pc 000001df  /data/dalvik-cache/arm/data@app@com.example.hellojni-1@base.apk@classes.dex
    

从上面的片段中我们能看到arm汇编代码调用命令的地址，头两行是我们自己的so文件相关的（libhello-
jni.so），分别是0bfd->0bf4，出错的地方是0bf4，能通过这些调用信息找到对应的代码行数吗？答案肯定是可以的，当然前提是我们有Native的源码，以下的工具都是我们有源码的前提。

# 从JNI堆栈分析代码对应的调用栈

NDK提供了一个工具帮助我们定位汇编命令对应的代码文件以及行数：arm-linux-androideabi-addr2line,工具的位置如下：

![](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/f74291e17fc95573ab785ab0baa6bce389d0b1931184d542d64611cc2cf72f1c)

输入如下命令：

    
    
    arm-linux-androideabi-addr2line -e F:\hello-jni\obj\local\armeabi\libhello-jni.so 0bf4 0bfd
    

-e是jni编译过程中obj目录下的中间so文件，这里要注意下，不能用libs目录下的so文件。  
后面跟上地址信息，这里需要知道两个地址对应的行数，所以就有两个，如果堆栈比较深，可以跟多个地址信息；

结果如下：

![](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/77c659659119c8d69a607027151058e7cfcd7ded42e1811c0e274a371a96f923)

从结果我们可以看到，出错的地方是hello-jni.cpp的第13行，确实就是我们出现空指针的地方；

## 二、获取汇编代码

上面的例子中，我们在日志中看到了出错的汇编代码位置，但是我们是不知道对应的汇编代码，以及函数的，下面的一个工具能够帮助我们反编译so获取汇编代码：

    
    
    arm-linux-androideabi-objdump -S -D F:\hello-jni\libs\armeabi\libhello-jni.so > C:\Users\stevcao\Desktop\jni2.txt
    

这里的so文件可以libs目录下的，也可以是obj目录下的；生成的反编译文件会有所不一样，obj目录的信息会详细点，包括源文件的代码对应的汇编代码以及注释都会有；libs目录下的so文件会只有汇编代码。下面分别贴出：

## obj目录下so dump结果

![](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/6f51d93716c1657e517a2db9fdedeef8df10a166438cf510df3131cd47b585a4)

## libs目录下的so dump结果

![](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/904e438c134fc2f2a907d2df5734db44b7ef31534f5bac5e6b894d4fca66adf4)

## 三、ndk-stack工具

工具位置：  
![](/image/android_jni_dui_zhan_fen_xi_gong_ju_jian_jie/58a78ae83cf89a27a288cabaa2698b84b238f18cc1d225a384e11bacc5ed4813)

ndk-stack可以直接从日志中分析出堆栈的错误信息，能够直接帮助我们定位到错误的位置，一步到位；

我们可以直接把logcat中的错误信息输入给ndk-stack，也可以使用ndk-stack来分析crash的日志（比如平台上报的crash数据）；

    
    
    ndk-stack -sym F:\hello-jni\obj\local\armeabi\
    

或者：

    
    
    ndk-stack -sym F:\hello-jni\obj\local\armeabi\ -dump crash.log
    

用ndk-stack对本文中出现的日志分析，输入如下信息，和用addr2line工具得到的结果是一样的：

    
    
    ********** Crash dump: **********
    Build fingerprint: 'OPPO/A33m/A33:5.1.1/LMY47V/1390465867:user/release-keys'
    pid: 14173, tid: 14173, name: xample.hellojni  >>> com.example.hellojni <<<
    signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
    Stack frame 06-23 15:02:26.782: I/DEBUG(299):     #00 pc 00000bf4  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (testException+3): Routine testException at F:/hello-jni//jni/hello-jni.cpp:13
    Stack frame 06-23 15:02:26.782: I/DEBUG(299):     #01 pc 00000bfd  /data/app/com.example.hellojni-1/lib/arm/libhello-jni.so (Java_com_example_hellojni_HelloJni_stringFromJNI+4): Routine Java_com_example_hellojni_HelloJni_stringFromJNI at F:/hello-jni//jni/hello-jni.cpp:20
    Stack frame 06-23 15:02:26.782: I/DEBUG(299):     #02 pc 000001df  /data/dalvik-cache/arm/data@app@com.example.hellojni-1@base.apk@classes.dex
    

