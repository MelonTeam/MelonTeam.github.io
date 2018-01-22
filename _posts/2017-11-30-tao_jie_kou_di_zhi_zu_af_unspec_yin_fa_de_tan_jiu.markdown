---
layout: post
title: "套接口地址族AF_UNSPEC引发的探究"
date: 2017-11-30 15:55:00 +0800
categories: 后端
author: qiaohuili
tags: 网络编程 TCP/UDP AF_UNSPEC
---

* content
{:toc}

| 导语 网络框架盛行的今天，AF_UNSPEC这个宏估计很多人都没接触过，那我又是如何接触它的呢？

也许很多人，特别是新人的会对对网络编程中AF_UNSPEC这个地址宏的定义感到很陌生，也许大部分人都只记得AF_INET和AF_INET6这两个常用的地址族。然而一个BUG让我首次接触到了这个宏，带着一些疑惑，决定对它研究一下。

首先看下以下简单的示例代码（请忽略无关细节）：
<!--more-->

server demo:

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/cc9131340e37b97fcbc5a356b26de7c8d88ce8c40de8595cce0e1f46a7c851f2)

client demo:

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/bb11f395310d9eb56968cf99563930c6f3a1fb9213006ba01bbfc1287e606faf)

下面是client的运行结果：

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/2b3c4ac60a5a36a333112d9d282c7307dc5344ac1fb7d43b9a7b4313f7196de2)

这个是示例代码，很显然可以看出在client
demo里有一行代码被注释了。没错，这就是导致bug的原因——套接口的地址族没有填充。_**本来问题发现了，改一下就完事**_。可是突然间想到了点小问题，有点想脑补一下的冲动：

1.地址族0值（memset初始化了）什么意义？

2.如果0值是一个不合法的值，为什么connect返回成功，而在send时候出错了？

首先查下第一个问题，查宏定义：

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/ab3ba5c4b84800d676ba61bce29c76e7c84ae931360aa4a6789bcd15535e7d7c)

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/3032a63445d1d0a5025145357b63ed545e6b2d77387a50b412cb2e10a73e60b2)

在第一个图的第一个宏定义中，前面我们提到的AF_UNSPEC出现了，就是我们demo中的地址族值。未指定？那第二个问题来了，为何connect可以成功？以下是connect的api说明（man
2 connect）：

![](/image/tao_jie_kou_di_zhi_zu_af_unspec_yin_fa_de_tan_jiu/226481866632165087fda21decbb5be128fc9de553e9eaabc199c2532a61a104)

大意是：通常基于连接的套接字协议只会成功的调用connection()一次，而基于无连接的套接字协议则可能通过多次调用connect()去改变套接口连结。基于无连接的套接字协议就是可以通过将地址结构中sa_family设置为AF_UNSPEC来解除它们之间的连结。

其实，在TCP中，调用connect()会发起三次握手，建立client和server之间的连接；而在UDP中，调用connect()只是内核把对端的IP/PORT记录下来，所以根据connect()的文档说明，对于UDP调用connect()且地址族指定AF_UNSPEC，就会解除内核中套接口与对端IP/PORT的连结。那UDP将对端IP/PORT绑定有什么好处吗？举个例子：

(1).普通UDP发送两个报文过程：建立连结 => 发送报文1 => 解除连结 => 建立连结 => 发送报文2
=>解除连结。

(2).使用connect()：建立连结 => 发送报文1 => 发送报文2 => 解除连结

这时候可以使用send、recv收发报文。

所以使用connect()的UDP连接的话可以提高性能。

