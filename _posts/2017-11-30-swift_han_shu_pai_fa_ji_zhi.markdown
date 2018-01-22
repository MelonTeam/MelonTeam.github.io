---
layout: post
title: "Swift 函数派发机制"
date: 2017-11-30 18:38:00 +0800
categories: 未分类
author: jackzkzhang
tags: Swift 函数派发
---

* content
{:toc}

| 导语 作为苹果为开发者极力推荐的一种语言，swift 的使用已经越来越广泛，而且swift 4.0 已经发布了，这意味着swift
日趋稳定。之前已经写过一篇关于swift 基本语法的介绍，今天要谈的比较深入一点，主要是介绍swift的函数派发机制。

### 一  常见的函数派发机制

<!--more-->
首先，我们先来了解下编译型语言常见的三种派发方式：直接派发，函数表派发和消息机制派发。

1.直接派发 （direct dispatch）

  直接派发是最快的，因为编译器需要调用的指令集更少，而且还能有较大的优化空间，比如函数内联等，c语言的函数调用，以及c++的非虚函数
都是使用这种派发机制。

2.函数表派发 （table dispatch）

  是编译型语言实现动态性最常见的方式，一般是使用数组来存储类声明的每一个函数指针，常见的使用有 c++虚函数表，swift witness table
等。

  下面的例子 阐述了函数表派发机制

![](/image/swift_han_shu_pai_fa_ji_zhi/3a3149964c4e7bb207a54c02c1c1f0a76e77d16743f2b5d24e490d37e37a378a)

3\. 消息机制派发（message dispatch）

 这个写object-c 的同学相信就非常熟悉了，oc的动态性实现，比如kvo,swizzling 都是使用这种机制。

 还是用例子来 大概阐述下这个机制：

![](/image/swift_han_shu_pai_fa_ji_zhi/0a1914958d6ebe42c658893e5326e2577522b980eae7b60346a49d752683c9e3)

![](/image/swift_han_shu_pai_fa_ji_zhi/52f851eeffbc79538b10dcfe6c5caaacbd29d291583eca7b4d7950885dba22de)

常见的几种编译型语言中：java 默认使用函数表派发，但可以通过final修饰符改成直接派发；

c++默认使用直接派发，但可以通过加上virtual 修饰符改成函数表派发；

object-c 使用消息机制派发；

而 swift 则以上三种派发方式都有用到。

### 二  swift 的函数派发机制

上面说到，swift的函数派发 用到了**直接派发**，**函数表派发**和**消息机制派发**三种。而swift 的函数选择哪一种，于下面几个因素有关：

1\. 声明的位置

![](/image/swift_han_shu_pai_fa_ji_zhi/8567dad22082d5075fe5692e6017d7266b406f1559a34b6d53df41a0857d8e90)

关于 上面四种类型，这里简单介绍一下：

 value type 和 class：值类型和类类型。swift里面，枚举和结构体属于值类型，类则属于类类型。而
dictionary,array等常见集合在swift里面都是结构体。

 protocol：协议，和object-c的相同

 nsobject subclass：指的是 swift里面 实现nsobject协议的类，这些类常用于 于object-c交互。

 extension：拓展 ，和object-c的相同

也就是说，如果函数

  定义在值类型 以及 它的拓展中，使用的是直接派发；

  定义在协议里，使用的是函数表派发；定义在协议的拓展里，使用的是直接派发

  定义在类类型里，使用的是函数表派发；定义在类类型的拓展里，使用的是直接派发

  定义在实现了nsobject协议的类里，使用的是函数表派发；定义在它的拓展里，使用的是消息机制派发

2\. 代码中指定派发方式

final 修饰符

final 允许类里面的函数使用直接派发，这个修饰符会让函数失去动态性，任何函数都可以使用final 修饰符

dynamic

dynamic 可以让类 以及 其协议里面的函数 使用消息机制派发，任何实现了nsobject协议的类和swift原生类里面的函数都可以 使用这个修饰符。

@objc & @nonobjc

@objc 和 @nonobjc 显示地声明一个函数能否被object-c 运行时捕获到。swift函数默认 添加@objc（起码在swift
4.0上尝试如此）。而@nonobjc 可以用来禁止消息机制派发这个函数，不让这个函数注册到object-c的运行时里。

final & @objc

可以在标记为final的同时，也使用@objc 来让函数可以使用消息机制派发。这么做的结果就是，调用函数的时候会使用直接派发，但也会在object-c
的运行时里注册相应的selector。函数可以响应perform(selector：) 以及别的object-c 特性。

用下面一张图来表示各种修饰符对应的派发方式：

![](/image/swift_han_shu_pai_fa_ji_zhi/9c6789bc0d69c56a3f72673df6ab89e9fab5f82fcc7609fe145e2faf836c343b)

3\. 显示的优化

  swift 底层会尽最大的努力去优化 函数派发的方式。例如：如果你类类型里面 定义了一个函数，但该函数从来没有被override，swift
就会检测并且在可能的情况下 使用直接派发。

 在swift 文档里有这样一段例子说明：

Applying the private keyword to a declaration restricts the visibility of the
declaration to the current file. This allows the compiler to find all
potentially overriding declarations. The absence of any such overriding
declarations enables the compiler to infer the final keyword automatically and
remove indirect calls for methods and property accesses.

翻译成中文就是：在函数前面加上private 关键字可以把函数的可见范围限制在当前文件里面。这就允许编译器去尝试找到所有 对这个函数的override 。
如果这个函数没有被override，那么编译器就能自动的在函数前面插入final 关键字，从而使得这个函数可以被直接派发。

![](/image/swift_han_shu_pai_fa_ji_zhi/74d46e2b1480f87ea94f603d93a0825ea4ea919132f91a3ce02df4d05eae6bba)

综上所述，swift的函数派发
用到了直**接派发**，**函数表派发**和**消息机制派发**三种。具体使用哪一种，主要看函数**声明的位置**和**代码中指定的派发方式**，除此之外，还要考虑
是否会受编译器**显示优化**的影响。

