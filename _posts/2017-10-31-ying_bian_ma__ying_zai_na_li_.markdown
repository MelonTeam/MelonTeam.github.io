---
layout: post
title: "硬编码，硬在哪里~"
date: 2017-10-31 22:00:00 +0800
categories: android
author: andrewychen
tags: 编码 芯片 硬件
---

* content
{:toc}



硬编码，硬在哪里~

好吧，我承认有点标题党了。开篇前，我们带着下面的疑问：
<!--more-->

  1. 硬编码，这里的硬是硬件，那么是什么硬件了？
  2. 硬编码是怎么回事呢？这里的硬件是指GPU吗？

我的桌面放着一块Android的开发板 ~  
![](/image/ying_bian_ma__ying_zai_na_li_/047fae82a5fd157a1e03800ab3a6b4eda6a5970d66579a77220aeab712ac8aa8)  
那么哪块是这里的硬编码的芯片呢？

我们可以看到，这里最大块的是Allwinnter A64芯片。这块芯片是一片Soc（System on
chip）的芯片，不是我们在PC时代说的CPU。看看这块芯片的模块图：

![](/image/ying_bian_ma__ying_zai_na_li_/18d2394c3b0e65c075714a2352e8a7f1851de3dbfa72e208bbaa970e2863338a)

这个是不是跟我们在台式电脑机箱里面看到的一样

![](/image/ying_bian_ma__ying_zai_na_li_/bfca1ebae99c69f43d3a7285d6685235c0ef75e2d71dee31aa9e72ed7025d3ed)

是的，现在的手机芯片都是SoC，将所有的功能集成在一块芯片里面。这样可以做到体积小，功耗低。不过对芯片的设计和工艺要非常高。不过，为了应对这样复杂的Soc设计，类似软件设计的模块复用，SoC领域的是IP核复用。那么在硬编码模块VPU有哪些的IP呢？  
下面是ARM最新出的视频处理IP

![](/image/ying_bian_ma__ying_zai_na_li_/1a30f27fffba1f1f8151b3b51349627b493398081d2782485574c15cc0ada04d)  
<https://developer.arm.com/products/graphics-and-multimedia/mali-video-
processors/mali-v500-video-processor>  
这里是它的支持特性，我们可以看到它直接支持OpenMax，这个Android的底层驱动要求是一致的。

![](/image/ying_bian_ma__ying_zai_na_li_/5804605aae13ceb813d59cd968d4009efb888778f412ebfcb6cefe74713b46f4)

为了更好的理解硬件编码是如何工作的，我们看看一块专业的视频编解码Soc芯片架构图

![](/image/ying_bian_ma__ying_zai_na_li_/b81f278a34ebf3b90b98e853a8ea91a908d5aa250891759ff45040f8288485ab)

这里数据通讯都是使用AMBA总线进行。整个编解码流程如下：

> 原始图像写入到外存(SDR SDRAM或DDR
SDRAM)中；视频编解码器从外存中读取图像，进行运动估计(帧间预测)、帧内预测、DCT变换、量化、熵编码、IDCT变换、反量化、运动补偿等操作，最后将符合H.264协议的裸码流和编码重构帧(作为下一帧的参考帧)写入到外存中

文章写到这里，相信已经可以回答文章开头的问题了：

  1. 硬编码，到底硬在哪里了   
这里的硬编码，是手机Soc芯片中的一个模块，通常有专业的公司提供。国内的一个Soc芯片厂商比如华为海思，全志，炬力只要做集成设计就行，无需关注这些专业领域的东西。跟我们开发软件一样~
（其实软IP核也是一些代码，只不过这些代码是用来生成芯片后才有功能作用，而不是跑在通用CPU上）

  2. 硬编码是怎么回事呢？这里的硬件是指GPU吗？   
视频编码需要对大量的数据进行相同的处理，而硬编码是利用物理电路的并行处理能力，同时对很多的数据进行并行的处理。GPU也具有通用的特点，所有我们经常听到使用GPU来对软编码进行优化，充分利用GPU的并行处理能力。而CPU设计公司也意识到这类需求比较常见，因此设计了NEON指令集，可以一条指令处理多个数据（SIMD）。FFmpeg的源码了里面充斥了大量这样的优化。

后续，我们根据下面这幅系统的架构，逐步熟悉Android的多媒体面纱。

![](/image/ying_bian_ma__ying_zai_na_li_/32f63774fa4b3dfda27ae280d98f060e6c15712a064ffa136711b58732de8e1e)

参考文献：

  1. 手机芯片大战 主流高端SoC哪家强？<http://ee.ofweek.com/2016-05/ART-8500-2801-29098041.html>
  2. SOC理解<https://www.zhihu.com/question/40421629>
  3. SOC 设计<https://developer.arm.com/soc>
  4. 专业的视频处理器 <https://developer.arm.com/products/graphics-and-multimedia/mali-video-processors/mali-v550-video-processor>
  5. 微信Android视频编码爬过的那些坑<https://github.com/WeMobileDev/article/blob/master/%E5%BE%AE%E4%BF%A1Android%E8%A7%86%E9%A2%91%E7%BC%96%E7%A0%81%E7%88%AC%E8%BF%87%E7%9A%84%E9%82%A3%E4%BA%9B%E5%9D%91.md>
  6. 音频处理芯片 Aqstic <https://www.qualcomm.com/products/features/aqstic>
  7. 全志芯片[http://www.allwinnertech.com/index.php?c=product&a=index&id=9](http://www.allwinnertech.com/index.php?c=product&a=index&id=9)   
<

