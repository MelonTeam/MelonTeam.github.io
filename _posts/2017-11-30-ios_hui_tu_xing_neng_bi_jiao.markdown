---
layout: post
title: "iOS 绘图性能比较"
date: 2017-11-30 18:01:00 +0800
categories: ios
author: louisysshen
tags: iOS绘图 性能优化 iOS
---

* content
{:toc}



在iOS中绘制UI一般有两种方法：一种是通过UIImageView或者UILabel建立相关图片和文字对象，然后添加到对应的父View中作为其SubView来实现；另外一种方法是直接在UIView中通过Core
Graphics框架进行绘制。在一般情况下，这两种方法的性能孰优孰劣呢？  

<!--more-->
![](/image/ios_hui_tu_xing_neng_bi_jiao/332ec0fa1d55899bdbfc3eabf6b213e47710a41178a573590cabfc6085c730bc)  

[ 直接添加SubView实现UI绘制 ]

  

![](/image/ios_hui_tu_xing_neng_bi_jiao/3fd62a7bd5d4b6175b7aa11991168cc43f8490f22495bf73054cf99c287c80b3)  

[ 通过Core graphics实现UI绘制 ]

  
毛主席说过，实践是检验真理的唯一标准，为了得到一个令人信服的答案，up主做了一个简单的测试，通过实验验证两种方法的性能。测试程序生成了几十到上千张数量不等的图片，并分别通过上述两种方式绘制在相同的UIView上，利用Instruments监控时间和内存的消耗，实验结果如下所示。为了叙述方便，在下文中两种方法分别被称为添加法和绘制法。

## 实验结果分析

### 图片平铺时

当图片的排列方式为不重叠的平铺在父View上时，两种方式的时间消耗如下图所示。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/8f10bb5fcafc76aeaad13f890c5dcdb5ac7e9cf3fcdf40a13f4ae55e7f206bb9)  

[ 图片平铺时的时间开销 ]

  
从时间开销上来看，两者差距不大。进一步分析两种方式时间开销的来源可以看到，两种方式的时间开销来源并不相同，  

![](/image/ios_hui_tu_xing_neng_bi_jiao/66e51a36fc11443281fa822db5a6345c07a112a6493ae9446360065db0a2f741)  

[ 添加法时间开销来源 ]

  

![](/image/ios_hui_tu_xing_neng_bi_jiao/0e543159458dceee32f59f73c9976fe28c47b12878f7f305b8344e613a2b93e9)  

[ 绘制法时间开销来源 ]

  
对于添加法来说，主要的时间开销来自三部分：UIImage对象的初始化，UIimageView对象的初始化，以及将UIimageView添加到父View上展示的渲染时间。而对于绘制法来说，相比添加法省去了初始化UIimageView对象的时间，但是在渲染的性能上差了一些。原因是Core
Graphics调用了CPU进行绘制，相对来说性能会有一定的损失。综合起来看，**时间开销**上两种方式的差距不大。

另一方面，从内存占用情况看，两者的差距比较明显。添加法的内存占用随着图片数量的增长上升很快，而绘制的的内存占用则与图片数量的关系不大。原因也很好解释，添加法的额外内存开销就是对UIImageView对象的初始化。当图片数量增多时，iOS在这里似乎并没有重用的机制（即便所有UIImageView对象对应的是同一张图片），导致内存占用显著上升。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/13d726d614714b0bf4878893e1d992102f5baa48bfb5c41721b35e1a1bff89f9)  

[ 图片平铺时的内存开销 ]

### 图片重叠时

当图片的排列方式为层层重叠在父View上时，两种方式的性能与平铺时的情况有所不同。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/0f8076d5e3d69676f25f133a5545508d07bcc31d30e29cd4d2fa52ccdf724507)  

[ 图片覆盖时的时间开销 ]

  
在图片以覆盖的方式展示时，添加法的性能与平铺时相比并没有太大的变化，但是绘制法的性能出现了严重的问题。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/083bd2e3669e769a560a19ecb32b0e388225b0c3a4b883621e5efe2880b10190)  

[ 图片重叠时绘制法时间开销来源 ]

  
从Time
Profiler的分析结果来看，绘制法的时间开销主要来自UIimage的`drawInRect`方法的调用。这个方法有两个参数`blendMode`和`alpha`。`alpha`是up主熟知的透明度。`blendMode`则是图片的混合模式，该属性的默认值为`kCGBlendModeNormal`，即前景图的颜色会覆盖背景图，有趣的是，即便在这种情况下，在图片渲染时似乎仍对混合后的图片颜色进行了计算，而非像alpha值一样在不透明时直接不做计算，采用顶层图片的透明度。推测这里可能是导致性能下降的关键原因。

### 图层持有动画时

当对应的父View持有动画时，两种方式会对动画的性能产生影响吗？从测试的结果看，在图片数量增多时，采用添加法会导致动画的帧数明显下降，而绘制法则不会对动画性能产生影响。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/a9a0454a1c1dab9d8b5d7b66cf68011aad028eeb5046b7fe865ddab092b7901a)  

[ 动画性能比较 ]

  
显然，当图层数量较多时，动画的性能会受到明显的影响。绘制法的好处是把绘制后的结果合成为一个图层，从而提升了动画的性能。

## 总结

综合上面的分析，两种方法的优缺点就很明显了。添加法的优点是通过GPU的渲染使得渲染速度较快，缺点则是会生成较多图层，内存占用高，且会影响动画性能；绘制法的优点是只生成一个图层，占用内存少，动画性能好，缺点是CPU渲染，速度慢，且在图片重叠时性能很差。那么，有没有两全齐美的方法呢？答案是有的，在《iOS核心动画高级技巧中》有这样的一段话：

> 使用CALayer renderInContext方法，你可以将图层及其子图层快照进一个Core
Graphics上下文然后得到一个图片，它可以直接显示在UIImageView中，或者作为另一个图层的contents。

具体来说。可以先通过添加法绘制图层，然后通过父View的renderInContext方法将所有图层合成为一张图片，这样就兼顾了两种方法的性能优势。  

![](/image/ios_hui_tu_xing_neng_bi_jiao/e075e0b9bcae9e43287c95036e24386c7ce736627d2a458095a1955048451eb2)  

[ 两全齐美的方法 ]

