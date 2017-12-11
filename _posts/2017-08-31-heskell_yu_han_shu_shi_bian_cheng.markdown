---
layout: post
title: "Heskell与函数式编程"
date: 2017-08-31 23:46:00 +0800
categories: android
author: siriushe
tags: haskell 函数式编程
---

* content
{:toc}

| 导语 这个系列打算分为三部分，由浅入深地介绍所谓的函数式编程 1）Haskell入门 2）Monad介绍 3）函数式编程的思想

# Haskell简介

Haskell诞生于1990年，是一门纯函数式编程语言，和我们经常使用的JAVA不一样，JAVA是一门命令式编程语言。函数式编程和命令式编程有本质上的区别，命令式编程是基于冯诺依曼体系的抽象，通俗点来说就是像电脑运作般思考，而函数式编程更多是数学抽象上函数的概念，也就是输入和输出的映射关系。
<!--more-->

我们来举个简单里例子，一个价格的集合，大于20块的打9折，然后相加。

下面是JAVA的示例：

![](/image/heskell_yu_han_shu_shi_bian_cheng/82f3b67bb24cc3c69adeb54117d1344a5e62d5f746fe4aef339bcaeedf9a5d02)

这里的写法非常清晰明了，循环价格的集合，找出其中大于20的价钱，打九折，然后加到价格总数里面，实际上计算器内部使用寄存器和跳转指令执行的流程也是相差无几，这就是用计算机执行的思维去写代码。

然后看下Haskell对这个问题的处理：

![](/image/heskell_yu_han_shu_shi_bian_cheng/1d2490746a11ae277b15819b03e4ae7ed3dd97949843801d1e5323ba02d0cfca)

就一行代码，涉及了三个函数

1）filter ：从价格集合中筛选出大于20的价格，形成新的集合

2）map：对1中产生的新集合进行变换处理，这里的处理是每个元素*0.9，也就是打九折

3）sum：对2中产生集合进行求和处理

从这里可以看到，Haskell的基本处理单位是函数（函数是一等公民），一个函数可以成为另外一个函数的输入，函数和数学范畴的映射是一样的。

因此掌握Haskell对理解函数式编程具有很大的作用。

# 编写第一个Haskell

编写Haskell之前需要把Haskell
Platform下载下来（<https://www.haskell.org/platform/>），安装后使用ghci就可以进行Haskell编程了。

我的电脑是Windows，在Windows下打开cmd，输入ghci，就能进入编程界面，在这个界面能够进行简单的编码，比如下面：

![](/image/heskell_yu_han_shu_shi_bian_cheng/ed5bbbdbb02e02e90ac1838bfe2d5372ab50db23c64e74881b32eb453e0a4923)

这里简单的进行了一次 3+5的求和操作。

但是我们更加习惯于用编辑器进行编码，下面使用文本编辑器来写一段代码。

![](/image/heskell_yu_han_shu_shi_bian_cheng/cc4d08129702ea1eb3306d3ee954361d2423850706a63b576c64c253a88a7f60)

这段代码定义了一个函数findMax，输入两个数字x和y，输出x和y的最大值，这里要注意下haskell内if
else语句else是不可或缺的，不像JAVA可以只写if不写else。

写完保存成文件（这里保存为cal.hs），以.hs作为后缀，在对应目录的命令行下面输入 :l 文件名

![](/image/heskell_yu_han_shu_shi_bian_cheng/0c64c49a47be383fd5c1ab8e7c94952d853a176c5b2db59dc1d762f4e3d74ee0)

调用自定义的函数findMax，输入参数1 3，然后就能够看到输出最大值3了。

# 类型和函数

Haskell是静态类型，也就是编译器在编译过程中就能够明确每个值的类型，当发现类型不匹配的时候，在编译过程中就会报错。比如输入这样一个函数：

![](/image/heskell_yu_han_shu_shi_bian_cheng/1807b7c8e26fb63f93fc785ab5a92df90d86ea1723b7fd7d23457556ee6d3231)

== 是个表达式，编译的时候会进行1和"2“的类型判断，1是Int类型，”2“是[Char]类型，因此会报编译错误。

![](/image/heskell_yu_han_shu_shi_bian_cheng/7ab8db689a78b33f143dc0c6b6585fcf595db311a017aff1a5fa5aef5933d561)

Haskell 可以使用 :t 命令来查看数值的类型，下面来看下一些常见的类型。

![](/image/heskell_yu_han_shu_shi_bian_cheng/d9f61c5bc4f0cd976ff2dec1dd03079dce0a3a2eab770505a72ba8abda20823a)

可以看到一些基础的类型

True ，Char，[Char]

然后对于  :t 0 的理解   （ 0 :: Num a => a ），表明
0是一种Num类族(typeclass)的a，Num类族这里可以先简单理解为JAVA的interface，Integer，Double等都是它的”实现“，和在之后的篇章再详细介绍到typeclass的概念。

我们先看下函数的类型是怎么样的，之前我们定义过一个函数findMax，这里看下![](/image/heskell_yu_han_shu_shi_bian_cheng/661816989648bdd79b5a3e4dacde4efd00cfb97851de01a9bb80ff7d93dd961e)

这里Ord也是一个typeclass，一个他的实例的类型能够使用>来比较大小，然后后面跟着三个a，这里简单做下括号就能够区分了。

( a -> a ) -> a ，最后一个参数输出，前面两个a是入参，用文字来描述就是：

输入两个Ord类族的参数，输出一个Ord类族的输出。

这里对findMax对下简单的变形，让它更能突显问题：

![](/image/heskell_yu_han_shu_shi_bian_cheng/e8a8f5a04d971e92412c357a302034c109e15c1a32e65c9b84ab1520a81c7ada)

这里看下type

![](/image/heskell_yu_han_shu_shi_bian_cheng/44ccbf9714f3249f8e582708cb796d652d69ddcaf659defb07109334974edb91)

用文字来表述：

入参是（Ord , Ord , (Eq , Fractional)
）类族的三个参数，出参是一个Boolean值，其中z具有Eq和Fractional两个特性，Eq的作用是能够做==比较，Fractional表示z能够被分解为分数。

未完待续

