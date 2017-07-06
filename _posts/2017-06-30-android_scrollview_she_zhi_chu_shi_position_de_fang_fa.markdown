---
layout: post
title: "Android ScrollView设置初始position的方法"
date: 2017-06-30 16:03:00 +0800
categories: android
author: freedeng
tags: 反射 初始位置
---

* content
{:toc}



最近接了产品的一个需求，需要在一个拥有标题栏，内容区，图片区的滚动视图中，默认隐藏标题栏，而且支持用户手动下拉出现标题。

刚听到这个需求的时候，觉得这个很简单，直接设置ScrollView的初始滚动值即可。然而，当真正实现的时候却发现，Android压根没有方法可以设置ScrollView的初始滚动值。经过一系列的尝试，最终通过反射，修改成员变量的方法，实现了产品的需求。下面记录一下具体的踩坑过程。
<!--more-->

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/3a5832dc8e74b645359271cf53e31801f71136f1666c5db5b34f161eaf55e843)

这个就是需求的效果图。

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/d2591a465262382394b168bf56c8e25549b540f2a6ae6540bb88050b12904aa8)

这个是产品的要求，第一次进入的时候先展示标题，然后慢慢的向上滚动，最终隐藏。之后进入发表页都默认不展示标题栏，但是要支持用户可以下拉拉出标题栏。

动画的实现方案比较简单，进来之后等待一段时间，然后通过smoothScrollTo方法一点点的滚动ScrollView。然而，实验之后发现这个方法并不好用，没办法控制动画时间。后来改用Animator来实现，具体实现代码如下：

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/d97c4051208501a60aebaf4888f1c04bd173f76cc09c0d37b718e65f3fd14f02)

但是为难的是如何做到初始化ScrollView的默认滚动值。如果在onCreate里面调用scrollTo是无效的，因为这时候ScrollView都没有布局好。如果延时200ms之后再调用scrollTo，则用户会先看到标题然后再看到标题消失，体验不好。看起来似乎无解，难道一定要自己重载ScrollView来提供相关接口吗？

当我看着上面动画的代码发呆的时候，突然注意到了scrollY这个值，为什么Animator能够通过这个值来调整ScrollView的滚动位置呢？难道是通过反射scrollY这个成员变量动态修改它的value？

于是自己动手在onCreate的时候通过反射修改ScrollView的scollY属性。结果调试发现ScrollView压根没有这个属性。为什么呢？

查看了一下Animator的底层实现，发现scrollY并不是一个具体的属性成员

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/8aafd4a04cc50390bd8d038fde2560a7a2c859f76bb0ffccb32b2af4e973dfa2)

Animator建立了一个映射表，scrollY对应的PreHoneycombCompat.SCROLL_Y的具体值如下：

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/6646bda48641f198a5a4c5ab61f19eca748cae6a8ba6f238f7a84c049f0af7a0)

也就是说其实Animator是通过setScollY这个方法来实现动态滚动ScrollView的。而setScrollY的底层其实就是调用scrollTo。

![](/image/android_scrollview_she_zhi_chu_shi_position_de_fang_fa/8fa8cc9b096bfe29e661dab192a89cafb6beee270e858aff04b59fcf739d0472)

到此似乎饶了个大圈子又回到了起点。前面已经尝试scrollTo在onCreate的时候就设置的话是无效的。

当我感到绝望的时候，看到了上图中的view.getScrollX()，既然有getScroolX那一定有getScrollY，既然有getScrollY那么一定有一个属性成员保存这个scrollY。一定！

通过断点和查看源码确认，这个保存ScrollView当前滚动位置的scrollY属性全名叫做mScrollY，而这个mScrollY并不是ScrollView的成员，而是其父类View的属性成员。

发现这个之后，将之前的反射代码直接修改成获取View的mScrollY变量，然后直接反射设置其初始高度。

编包后自测OK。

### **总结**

一个小小的需求，暴露了自己对View的成员的不够了解，记录一下，提醒自己也方便大家。

