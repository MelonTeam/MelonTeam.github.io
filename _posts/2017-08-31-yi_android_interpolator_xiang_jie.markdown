---
layout: post
title: "[译]Android Interpolator详解"
date: 2017-08-31 20:39:00 +0800
categories: 未分类
author: freedeng
tags: Android 动画 插值器 Interpolator
---

* content
{:toc}



原文地址：<https://blog.mindorks.com/understanding-interpolators-in-android-
ce4e8d1d71cd>

<!--more-->
![](/image/yi_android_interpolator_xiang_jie/f07031df9e93f1ee6a16905cb2ea51bf930fc00589380d27458e1e69feb83a48)

在学习Android动画的过程中，我们都想知道到底动画插值器是个什么东西，以及到底该如何使用它。我尝试阅读Android文档来了解它，但是似乎并没有太大的帮助。所以我决定通过在一个View上面使用每个默认的动画插值器来看看他们到底是什么效果。

![](/image/yi_android_interpolator_xiang_jie/be897812153c21d939aaaeba3c1b853ef1e2e4a74aebc327fc4dde76df094299)

从左到右移动立方体

 通过观察不同的动画插值器行为的同时，我阅读了他们的具体代码实现，来了解插值器到底是如何定义动画的变化率的。

总所周知，字符串的本子是一个连续的字符序列。同理，动画其实也是一连串的图片序列（或者叫做帧序列）在一定的时间间隔下顺序播放。

![](/image/yi_android_interpolator_xiang_jie/a3ac2c656dba53a2e83b9a96faab68e9a0d4d366adc69f535b2bce0ad23af82f)

每个时间点对应序列里面的一帧。每一帧之间都只是通过不同的一些动画效果（如平移、缩放、旋转、透明度等）产生了些许的差别。

![](/image/yi_android_interpolator_xiang_jie/2a470615ddfb471fe80973de80a344cac14cd03daade916ea00c6700dbd0a2d3)

**插值器的作用就是在改变动画里面帧和时间的对应关系。**

它将特定时间的帧替换成另一帧，替换帧可以来自过去、现在或者将来的任意一帧。具体替换后的帧是哪个取决于不同的插值器类型。

插值器是一个数学工具，它将一个原始时间作为输入，通过特定的数学公式和方程，输出具体的用来替换原来时间对应帧的帧。

为了简单期间，我们举一个线性插值器的例子。

![](/image/yi_android_interpolator_xiang_jie/748156baec0ec1de24714c0ce24c8600bad46023bf6e34bb01e1344f777f9a7e)

通过线性差值器实现的平移立方体

数学方程式为：    f(x) = x

图为：

![](/image/yi_android_interpolator_xiang_jie/e2148a4f8c8a46c6867d3cb27852621c48502d710ae83798e242959ed6ce8fb5)

图表清楚地表明，在输入没有变化的时候，输出保持不变，动画不受影响。

但是，如果我们修改线性方程，并通过向给定输入添加一些常量小数，来定制一个线性插值器的话，动画会发生什么变化呢？

![](/image/yi_android_interpolator_xiang_jie/352883fdb0c62dd4009cfe0f745aa2aff33c8e655b0c995cb89b03b7e5602989)

使用了自定义的线性插值器的平移立方体

它的数学方程：   f（x）= x + 0.1

图为：

![](/image/yi_android_interpolator_xiang_jie/be68c827a97ca308040539f08bc8e4476ab6310f26a510c1f8808e09b1202e4e)

现在，新的动画比原来的动画先开始，并比原来的动画先结束。因为差值器函数修改了时间对应关系。

我们再来看一个有一点点复杂的插值器：**加速插值器。**它使帧的速度从满到快，具有一定的加速度。

![](/image/yi_android_interpolator_xiang_jie/5ac91efb1510abac719027fe441cba28b4c6c06d063a8ded8dad50ea42b7f912)

应用了加速插值器的平移立方体

它的数学方程式是：f（x）= x 2

图是：

![](/image/yi_android_interpolator_xiang_jie/5d37a37e8347953bc929568bcf590725a0fac3ff037794048c196929d0938818)

从图中可以看出，每个相邻点的差异随着时间的推移而增加。因此，它显示加速类型的行为。

现在我们准备根据需要定制我们自己的插值器来模拟弹簧效果。

![](/image/yi_android_interpolator_xiang_jie/9ab3c406761562f59aac8930e8286b64b24205752021e4ea12e3754d067b08df)

自定义弹簧插值器的平移立方体

他的方程式为：

![](/image/yi_android_interpolator_xiang_jie/9c18859557b97c8747b5496ff016845247e9519db1ddc27a3cd2c88cf1868dbf)

图为：

![](/image/yi_android_interpolator_xiang_jie/6bf271a6565759a86cb2336be2639e91bea4d8a6397e478f3f243ba4469d7175)

我希望通过阅读这篇文章你能学到新的东西。

另外，我创建了一个插件项目，其中展示了不同的插值器是如何影响动画的。里面还包括了每个插值器的图形和方程式用来帮助你理解其他插值器，比如变形、过冲、反弹、循环等。

![](/image/yi_android_interpolator_xiang_jie/bbf28086feb5631ad836b5dfbbb2978c45765b2e9ee732136203c04b17b1d4ab)

如果想查看代码：**[这里是Github
repo链接。](https://github.com/geetgobindsingh/AndroidAnimationInterpolator)**

