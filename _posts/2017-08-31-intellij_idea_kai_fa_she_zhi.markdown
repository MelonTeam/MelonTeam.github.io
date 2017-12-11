---
layout: post
title: "IntelliJ IDEA开发设置"
date: 2017-08-31 23:37:00 +0800
categories: android
author: limingzhang
tags: IntelliJ idea Android java
---

* content
{:toc}

| 导语 介绍一些IntelliJ IDEA使用过程中可以提高工作效率和改善心情的开发设置

# 一、设置参数，优化开发体验

Help -> Edit Custom VM Options，创建一份vmoptions文件。  
<!--more-->
默认64位操作系统 + 16G内存  
建议修改参数：

    
    
    -Xms2g  
    -Xmx4g  
    -XX:+UseConcMarkSweepGC  
    -XX:+UseParNewGC  
    -Xverify:none

-Xms 设置初始的内存大小，可以提高Java程序的启动速度

-Xmx 设置最大的内存大小，ide默认的只有几百兆，导致开发过程中载入很大的类时使用起来十分卡顿，提高改值，可以减少垃圾回收频率，提升IDE性能

-XX:UseConcMarkSweepGC 设置年老代为并发收集垃圾

-XX:UseParNewGC 设置年轻代为并发收集垃圾

-Xverify：none 关闭Java字节码验证，可以加快类的装入速度，提高IDE启动速度

# 二、防止导包时在代码中出现import*

File --> Settings -->Editor --> Code Style --> Java-->Imports

![](/image/intellij_idea_kai_fa_she_zhi/fbee7baec9e10e04c2fed2d5e232c45cf19b9eba5f3089b4cd4ebf76344203a7)、

为了避免在代码中出现import*的情况， 把需要使用import*时的包数量提高到1000。

# 三、正确地使用Tab键

如果工程中要避免使用Tab，该设置可以让你使用tab键的同时仍然以空格的方式输入

![](/image/intellij_idea_kai_fa_she_zhi/284da8bbf94b81af9e9c3b4c915f639e9b9db5c27d77ef6ed41b754729c70bb3)  
分别对：Java和xml选项进行配置  
1\. 取消对Use tab character的勾选  
2\. 让indent改为4个空格。

# 四．开启Android高版本API错误警告

如果你的IDE缺少了高版本api错误提示，看下这里是不是没有设置好：  
File -->Setting -->Inspections-->Android Lint --> Calling new
methods on older versions

![](/image/intellij_idea_kai_fa_she_zhi/5048d6e888288221b544ee719d081d2dbdd1a117d1f3f93d75d325cce74e7eb1)

# 五、代码提示不区分大小写

![](/image/intellij_idea_kai_fa_she_zhi/be5e34d1ac3932cb5ef7f5e1e12edfdc1938665e98f6a9cc3aad6f7a6fbabd5a)

把 case sensitive completion 设置为None，因为IDE本身默认是区分大小写，
这样我们用到代码提示功能时还要记住字母是大小还是小写，很麻烦。

# 六、左侧类名下面显示类成员

![](/image/intellij_idea_kai_fa_she_zhi/aa52d2852c09ad19886c2ddd775225d58539a60142319f4c88df63f04ea7cd7c)

这样子可以很方便的查看该类的成员。

# 七、给IDE设置背景

![](/image/intellij_idea_kai_fa_she_zhi/4eff98e0457ba80e56248f4b995c4b6a63b00ecaef27b3f8eaf9f5b682c912d2)

按下Ctrl+Shift+A，输入Set Background Image，点击结果跳转，
弹出一个窗口，按照提示操作即可，如果你把IDE设置为老婆的背景，每天对着老婆写代码，是不是充满干劲呢（认真脸）？

