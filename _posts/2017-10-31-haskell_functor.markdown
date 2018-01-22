---
layout: post
title: "Haskell Functor"
date: 2017-10-31 21:15:00 +0800
categories: android
author: siriushe
tags: haskell
---

* content
{:toc}



### **范畴**

要想了解Haskell的Functor，首先先简单了解下“范畴论”里面的“范畴”的概念，下面先看下wiki的定义：
<!--more-->

![](/image/haskell_functor/9abcf825fa07562b9f268ffa37bf4d5c495938e0f294b518f86aad211b1ff3df)

范畴有三个要点：

1）一系列的object，这里的object标识一类有共同属性的物体，可以用编程语言的class来理解。

2）一个态射，可以理解为我们常说的映射。

3）态射间满足结合律和单位态射。结合律即 h.(g.f) = (h.g).f。范畴内单位态射必须存在，也就是结构里面的每个object
a，都存在一个态射使得 a -> a。

Haskell本质上也属于范畴。

Haskell是强类型的，也有typeClass的概念，因此1条件满足。

Haskell是函数式变成，Function本质上也是一种映射，比如一个最简单的例子

![](/image/haskell_functor/8973936c800a3cdfd082223666d1e2f85a4a5a80833d4005af6b359789cd56d9)

就是将满足（Eq ,Num） typeclass的 x 映射到Bool 。

### 函子

如果我们把范畴看作是更高层范畴的对象，那么范畴之间的态射就是所谓的函子（Functor）。我们定义函子F，则 F
把范畴A中的对象映射给范畴B，并且将范畴A中的态射映射到范畴B的态射。

也就是 F： A -> B ，F使得A中的任意一个元素Ax映射到Bx，其中Bx属于B范畴，同时范畴A的态射Af 也映射到B的态射 Bf。

我们可以看下Haskell里面Functor的定义：

![](/image/haskell_functor/41e9a5410abdf4431cd57d9f46a94c99dc53c9c9778c874ab37c422846448cd4)

Functor定义了一个操作fmap，里面实现了两个态射的态射，也就是将态射(a -> b) 映射到态射 f a里面去，生成态射f b。

借用网上的一个图表示一下![](/image/haskell_functor/35f4aa7565190275ffa1bad1fe63f26d1a532fcc6e2dbd1df81877517a5f1cce)

假设有两个范畴C1和C2，C1有类型Int和String，C2有类型List[Int]和List[String]。C1和C2间有Functor
F，则F使Intc1 映射到List[Intc2]，Stringc1 映射到List[Stringc2]，  C1有态射Intc1 ->
Stringc2，则C2中也会存在List[Intc1] -> List[Stringc2] 的态射。

### 举个栗子

Haskell里面List是Functor的一个实例，List 里面的map操作既是fmap

![](/image/haskell_functor/1b48e2cd02bf6377dcad2467aaaa6e3e37f39e83e4ab602ae4f4c177c5a5332e)

看下这波操作，fmap 将 （+1） 这个态射给映射到[1 , 2 ,3] 这个List里面，结果是生成了一个新的List[2,3,4]
,他的过程就是将态射(+1)作用到List的每个元素上面，生成新的List。

### 总结

总的来说，在Haskell里面Functor就是任何能用fmap操作的数据类型。

