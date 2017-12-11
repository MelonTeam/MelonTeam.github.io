---
layout: post
title: "关于Android进程，你需要知道的"
date: 2017-08-31 18:43:00 +0800
categories: 未分类
author: henrikwu
tags: native 组件 Android
---

* content
{:toc}

| 导语 Android系统是怎样杀进程的，native进程是怎么管理的？本文为你解密

一、Android进程管理

Android是基于组件工作的，每个组件可以通过android:process节点指定在一个独立进程中执行，所以一个app里面可能会有多个Android进程。系统在强制停止app的时候是怎么干掉这些进程呢？
<!--more-->

                             ActivityManagerService相关逻辑

![](/image/guan_yu_android_jin_cheng__ni_xu_yao_zhi_dao_de/3c35b09907f11ed4060db484abdbc7e0b44a8e27040799bac97b620ee23cba2d)

      这里我们可以看到核心逻辑，首先遍历出来该packageName下的所有Android进程放在procs集合里，接着我们在for循环里分别杀之。

![](/image/guan_yu_android_jin_cheng__ni_xu_yao_zhi_dao_de/daeffd2651a9a05e2c18d6a8009df0ee3951f3db85873aa963c11d7b351f44a6)

    这里我们可以看到调用Process的killProcessQuiet方法去杀进程，实际上最终调用linux进程机制发送-9信号将相关进程杀掉。

这里我们着重看一下killProcessGroup方法，这个逻辑是5.0之后新增的。看名字我们可以大概猜测一下是杀进程组，那Android里面的进程组什么样的呢？什么样的进程会被放在进程组里呢？

二、进程组

    Android进程组借鉴了Linux进程组的机制，实际上就是fork出来的子进程会被和Android进程放到同一个进程组里面。

![](/image/guan_yu_android_jin_cheng__ni_xu_yao_zhi_dao_de/cf0faabfb92efc980c607c701e294674a1dfc11849612305362c04a59ab69ac7)

但是这里面不同的是，Android里面同一个进程组的进程会被记录的/acct/uid_xxx/pid_xxx/cgroup.procs文件下，这样当系统强制停止app的时候，就会从这个文件里面读取进程并杀之。

![](/image/guan_yu_android_jin_cheng__ni_xu_yao_zhi_dao_de/a67fde456851ae2b23a527b4704ac75ad6984f1bbc8331ceb86520c12fc4242a)

这块逻辑是5.0之后新增的。也是为了堵之前不杀native进程的漏洞。因为这个逻辑，所以之前市面上很成熟的native进程守护保活方案失效了。当然这里面还是有可以的做文章的空间，想要保活依然可以做到。不过Android每个版本都由相应的进化，所以需要分析源码来找到突破口。

最后给一张Android进程的分析图：![](/image/guan_yu_android_jin_cheng__ni_xu_yao_zhi_dao_de/a12479a4f223d650e0da75f00c57c97016c78df57d5241e670acb8d88ea07b42)

