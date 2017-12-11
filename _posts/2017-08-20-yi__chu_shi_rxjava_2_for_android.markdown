---
layout: post
title: "[译]初识RxJava 2 for Android"
date: 2017-08-20 20:24:00 +0800
categories: android
author: leoyxwang
tags: RxJava 响应式 ReactiveX 异步
---

* content
{:toc}

| 导语 关于响应式编程在手Q中的应用，目前本人了解到至少有以下两种： （1）手Q部落实现的一套Stream框架。 （2）Qzone引入的RxJava
1.1.2。 为了知其然，知其所以然，下面从入门开始对最受欢迎的响应式框架RxJava进行研究。

原文作者：Jessica Thornsby (Mar 6th, 2017)

<!--more-->
<https://code.tutsplus.com/tutorials/getting-started-with-rxjava-20-for-
android--cms-28345>

* * *



如果你是Android开发人员，你一定听说过 **RxJava **——它是将响应式引入JVM的ReactiveX库的开源实现。

虽然 **RxJava **对“数据”的定义十分广泛，但 **RxJava **的设计目的是为了解决异步数据流的痛点。**RxJava**
兼容JVM，能够在各种平台上使用。本文将简单展示如何使用 **RxJava 2 **进行Android开发。

在本系列文章最后你将会掌握所有 **RxJava 2
**的要素，然后你就可以开始编写高度响应式的App，可以处理各种同步和异步数据。所有这些更加简洁和可管理的代码都能使用Java实现。

本系列文章不止为 **RxJava** 新手提供指导，如果你是 **RxJava 1** 的老司机并希望与时俱进地转到 **RxJava 2**
，那么本文会使你转换的过程更加顺利。虽然升级到最新版本的库可能听起来没那么复杂，但 **RxJava 2 **并不是简单的update，而是
**RxJava **的完整重写。因此伴随着巨大的变化，会带来很多困惑。所以从初学者的角度来看需要一些时间来熟悉 **RxJava 2
**，长远来看可以节省大量时间和踩坑的过程。

本文将介绍什么是 **RxJava **，以及它为Android开发人员带来的主要优点。我们也将深入了解任意 **RxJava **工程的核心组件：
**Observers** 和 **Observables** 和 **Subscriptions**
。在本文最后你就可以创建一个包括所有这些组件的简单"Hello World"式App。

![](/image/yi__chu_shi_rxjava_2_for_android/548d23e0b67282ef1014f7bb1c6cf708328a8eeaaf2ac1561ae63fb7762e3eb1)

## 一、什么是RxJava？

**RxJava **是一个能让你使用响应式编程风格创建App的第三方库。它的核心是响应式变成提供了简洁高效的方式来处理和响应包括具有动态数据在内的实时数据流。

这些数据流不一定必须是传统数据类型的形式，因为 **RxJava
**把所有的一切（如变量、属性、缓存甚至用户输入包括点击和滑动）都当做数据流(**Stream**)。

每个 Stream
发射的数据可以是一个值（必选）、一个错误（可选）或者一个“完成”的信号（可选）。创建数据发射流后，将它们与消费这条流的响应式对象组合起来，然后根据流发射的内容对
Stream 的数据执行不同的操作。**RxJava **包括很多有用的操作符配合 Stream
一起工作，这使得过滤(filter)、映射(map)、延时(delay)、计数(count)等操作更容易执行。

![](/image/yi__chu_shi_rxjava_2_for_android/ad742c4b0995f683dd9c2d7cf65ef056a0626990e5dc9526f201b34801e61c76)

为创建这种数据流的工作流和响应它们的对象，**RxJava **扩展了 **Observer** 设计模式（观察者模式）。本质上，在 **RxJava**
中由 **Observable** 对象发射数据流然后终止，由 **Observer **对象订阅 **Observable** 。**Observer**
在所订阅的 **Observable** 发射一个值、错误、完成信号时会接收到通知。

所以概括地来说，**RxJava **就是：

  * 创建 **Observable** 。
  * 为 **Observable** 设置发射的数据。
  * 创建 **Observer **。
  * 把 **Observable** 指定 **Observer**。
  * 为 **Observer** 设置任务，用于在收到指定的 **Observable** 发射的数据时执行。

##

## 二、什么使用RxJava？

学习任何新技术都需要时间和精力，而作为面向数据的库，**RxJava** 并不是最容易掌握的API。

为了帮助决定是否值得初步投资学习 **RxJava** ，接下来我们来探索一些在Android项目中引入 **RxJava **库的主要优点。

### 2.1 更简洁，更易读的代码

复杂、冗长和难以阅读的代码总是令人烦躁。凌乱的代码更容易出Bug并降低开发效率，如果发生任何错误，跟踪这些问题会花费大量的时间。

即使项目可以顺利构建，复杂的代码仍有很大的隐患，特别是需要在几个月内对app发布更新、启动项目，然后马上就遇到了很多纠结混乱的代码！

**RxJava **简化了处理数据和事件所需的代码，方法是允许开发者描述想实现的内容，而不是写一份指令列表。**RxJava **也提供了一个标准的工作流程，可以用来处理App中所有的数据和事件——创建 **Observable** ，创建 **Observer** ，把 **Observable** 分配给 **Observer** ，清理和重复。这个公式化的方法使得代码变得非常直接和人性化。

###

### 2.2 多线程简单易用

现在Android应用需要支持多任务。至少在App在后台执行某些工作（如管理网络链接、下载文件或播放音乐）时，用户能够继续与UI交互。那么问题来了，Android默认情况下是单线程的，所以如果App需要执行多任务就需要创建一些额外的线程。

因此，Android确实提供了许多方法来创建其他线程，例如Service和IntentService，但是这些解决方案都不是特别容易实现的，并且可能很容易导致复杂和冗长的代码出错。

**RxJava **旨在通过特殊的调度方式和操作符来解决多线程App的痛点。 **RxJava** 提供了更简单的方法指定任务应该被执行的线程和任务结果应该被发布到的线程。**RxJava 2 **默认提供了一些调度，包括**Schedulers.newThread **,它在创建新线程时特别有用。

要更改执行工作的线程，只需使用 **subscribeOn **操作符更改 **Observer** 观察 **Observable**
的位置（线程）。例如，我们可以创建一个新线程并指定任务在这个新线程上执行：

    
    
    observable.subscribeOn(Schedulers.newThread())

Android上多线程另一个长期以来的问题是，只能在主线程更新UI。通常无论何时都需要把一些后台任务的结果从发送到UI中，必须创建一个专用的Handler。

再者，**RxJava** 有一个更直接的解决方案。可以使用 **observeOn** 操作符来指定 **Observable**
通过包括主线程在内的不同 **Scheduler** 发送通知。

这就是说只要两行代码就可以创建一个新线程并把此线程上任务的结果发送到UI线程。

    
    
    .subscribeOn(Schedulers.newThread())
    .observeOn(AndroidSchedulers.mainThread())

其实在技术上这里有一些超前，因为 **AndroidSchedulers.mainThread**
只有在RxAndroid库中才可以使用。不过该实例可以瞥见 **RxJava** 和 **RxAndroid**
简化过于复杂的Android开发领域的能力。

###

### 2.3 提高灵活性

**Observable **以完全隐藏创建数据的方式发出数据。由于观察者无法观察到数据是怎样创建的，可以随意定制 **Observable** 来创建数据。

一旦实现了 **Observable** ，**RxJava **提供了强大的操作符可以用来过滤、合并和变换由这些**Observable
**发射出的数据。甚至可以把越来越多的操作符链接在一起，直到准确创建了App需要的数据流。

例如，可以组合来自多个流的数据，过滤新合并的流，然后用生成的数据作为后续数据流的输入。记住在 **RxJava**
中几乎所有内容都被视为数据流，因此甚至可以把这些操作符用于非传统的“数据”，例如点击事件。

### 2.4 创建响应式App

App展示loading页面并等待用户点击“下一步”的时代已经过去。如今的主流移动App需要能够对日益增长的各种事件和数据做出响应，最好是实时的。例如，主流社交网络App需要不断监听输入的点赞、评论和好友请求，同时在后台管理网络连接，并在用户点击或滑动屏幕时立即响应。

**RxJava** 旨在能够同时且实时管理大量数据和事件，是创建快速响应的App的强大工具。

## 三、将RxJava添加到Android Studio（略）

任何含有rx包名的代码都是 **RxJava 1 **代码，与 **RxJava 2** 不兼容。

## 四、RxJava的组成

目前为止，我们只是在很高的层次上看过 **RxJava** 。是时候具体并深入了解在 **RxJava**
工作期间再次出现的两个最重要的组件：**Observer** 和 **Observable** 。

在本节结束之前，我们不仅可以对这两个核心组件有一个深刻的了解，而且将会创建一个功能齐全的App，其中包含一个发出数据的 **Observable**
和做出响应的 **Observer** 。

### 4.1 创建Observable

**Observable **类似 **Iterable ，**给定一个序列，它将遍历该序列并发射出每个Item，但是 **Observable** 只有当 **Observer** 订阅时才会开始发射数据。

每次 **Observable** 发射一个Item时会使用 **onNext() **方法通知它的 **Observer** 。一旦
**Observable** 传送完了所有的数据，会调用以下任意一个方法终止发射：

  * **onComplete() **: 操作成功。
  * **onError()** : 抛出Exception。

我们来看一个例子。这里我们创建一个 **Observable** 来发射数字1,2,3,4然后终止。

    
    
    Observable observable = Observable.create(new ObservableOnSubscribe() {
      @Override
     
      public void subscribe(ObservableEmitter e) throws Exception {
          //Use onNext to emit each item in the stream//
          e.onNext(1);
          e.onNext(2);
          e.onNext(3);
          e.onNext(4);
     
          //Once the Observable has emitted all items in the sequence, call onComplete//
          e.onComplete();
      }
     }
    );



### 4.2 创建Observer

**Observer** 是使用 **subscribe() **方法分配给 **Observable** 的对象。一旦完成订阅，它会在 **Observable** 发出以下之一时做出响应：

  * **onNext()** : **Observable** 已经发出了一个值。
  * **onError()** : 发生了错误。
  * **onComplete()** : **Observable** 发射完成了所有值。

我们创建一个 **Observer** 订阅1,2,3,4的 **Observable** 。为了简单，这个 **Observer **会响应
**onNext** , **onError **, **onComplete **并在Logcat中打印相关信息。

    
    
    Observer observer = new Observer() {
      @Override
      public void onSubscribe(Disposable d) {
          Log.e(TAG, "onSubscribe: ");
      }
     
      @Override
      public void onNext(Integer value) {
          Log.e(TAG, "onNext: " + value);
      }
     
      @Override
      public void onError(Throwable e) {
          Log.e(TAG, "onError: ");
      }
     
      @Override
      public void onComplete() {
          Log.e(TAG, "onComplete: All Done!");
      }
    };
     
    //Create our subscription//
    observable.subscribe(observer);

Logcat结果如下：

![](/image/yi__chu_shi_rxjava_2_for_android/1bb42dd7b9450cc752ae59542f6edca7e7a2caf97d97ea3c44efc5dad01ecb0c)

### 4.3 用更少的代码创建Observable

虽然我们的项目正在成功地发布数据，但我们使用的代码并不完全简洁，特别是用来创建 **Observable** 的代码。

幸运的是，**RxJava** 提供了一些便捷的方法，允许使用更少的代码创建 **Observable** 。

**1\. Observable.just()**

可以使用 **.just() **操作符将任何对象转换为 **Observable** ，最终的 **Observable** 将发射出原始对象并完成。

例如，这里我们创建一个 **Observable** ，发射一个字符串给 **Observer** 。

    
    
    Observable observable = Observable.just("Hello World!");

**2\. Observable.from()**

**.from() **允许将对象的集合转换成可观察的数据流。可以使用 **Observable.fromArray** 把数组转换成 **Observable **，使用 **Observable.fromCallable** 把 **Callable** 转换成 **Observable** ，以及 **Observable.fromIterable** 把 **Iterable** 转换成 **Observable** 。

**3\. Observable.range()**

可以使用 **.range()** 操作符发射一个序列的整数。第一个整数是初始值，第二个是要发出的整数数量。例如：

    
    
    Observable observable = Observable.range(0, 5);

4\. **Observable.interval()**

该操作符创建了一个发射无限递增序列整数的 **Observable** ，每次发射间隔时间是可配置的。例如：

    
    
    Observable observable = Observable.interval(1, TimeUnit.SECONDS)

5\. **Observable.empty()**

这个操作符创建了一个不发射Item但正常终止的 **Observable** ，在需要快速创建测试用的 **Observable** 时较为有用。

    
    
    Observable observable = Observable.empty();



## 五、结论

本文介绍了 **RxJava** 的基本组件。

至此我们知道如何创建并使用 **Observer** 和 **Observable** 工作了，并且知道怎样创建订阅，这样 **Observable**
就可以开始发射数据。我们还简要地看了一些用于使用更少的代码创建不同 **Observable** 的操作符。

然而，操作符不仅仅是减少代码量的方便之选。创建一个Observer和Observable很简单，但操作符是真正使 **RxJava** 出现无限可能的地方。

