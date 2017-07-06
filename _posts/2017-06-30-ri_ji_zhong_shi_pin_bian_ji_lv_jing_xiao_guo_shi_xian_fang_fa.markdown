---
layout: post
title: "日迹中视频编辑滤镜效果实现方法"
date: 2017-06-30 22:10:00 +0800
categories: android
author: berylzhao
tags: 滤镜实现
---

* content
{:toc}

| 导语 本文简要分析，日迹视频解码流程以及视频滤镜的实现原理

需求背景：日迹需要的编辑滤镜效果预览图

![](/image/ri_ji_zhong_shi_pin_bian_ji_lv_jing_xiao_guo_shi_xian_fang_fa/c192aef86cafe072b54ce3ce9510e8b54f77a1cc25e52123383e2219ab680807)
<!--more-->

图1：日迹滤镜效果



要实现产品想要的滤镜效果，首先我们需要把录制的视频mp4文件，用mediacodec解码出来，然后对解码出来的每一帧图像进行滤镜渲染，最后绘制到屏幕或者输出到文件。



我们先来了解mediacodec解码的流程。

![](/image/ri_ji_zhong_shi_pin_bian_ji_lv_jing_xiao_guo_shi_xian_fang_fa/770dd61e00ca1b7521a2357f148041d76dadfa4bf58e0ac98c5c62eb90977ea5)

图2：mediacodec解码流程



MediaExtractor 负责从视频文件中解析每一帧的原始数据；

Mediacodec 负责对音视频数据进行解码，并渲染指定的surface上；

代码示例：

```java
//初始化extractor

MediaExtractor extractor = new MediaExtractor();

extractor.setDataSource(...);

...

//初始化meidacoec

MediaCodec decoder= Mediacodec.createDecodecByType(mine);

decoder.configure(format, surface, null, 0);

decoder.start();

...

//循环处理每一帧

While(notEndFlag){

//把读出来的帧数据交给mediacodec去解析

extractor.readSampleDate(buffer, 0);

decoder.queueInputBuffer(bufferIndex, 0, sampleSize, showTimeus, 0);

//向前移动 准备读取下一帧

extractor.advance();

//把mediacodec解析后的数据交给surface去渲染

decoder.dequeueOutputBuffer(info, 10000);

decoder.releaseOutputBuffer(bufferIndex, isRender);

}
```

走到这里，我们已经可以从Surface上拿到每一帧对应的Texture
（纹理），之后我们就可以利用Opengl的可编程管线，对纹理进行相关的滤镜处理。下面说下opengl的渲染流程。

![](/image/ri_ji_zhong_shi_pin_bian_ji_lv_jing_xiao_guo_shi_xian_fang_fa/29f020e2d6d92c74e67eaeee0d6ee1ce471b2212ec23c66584f7b137714876d1)



图3： opengl 渲染管线简图



CPU
将物体顶点坐标、顶点变换矩阵、纹理坐标、纹理变换矩阵等通过API传给VertexShader（顶点着色器），它针对VBO提供的每个顶点执行一遍顶点着色器，VertexShader通过varying限定符传输易变变量给FragmentShader使用，FrgementShader对光栅化的每个片元进行处理，生成多重的颜色混合效果，最后渲染到屏幕或者写到文件中。



1. 黑白滤镜的实现

我们拍摄出来的每一帧图片都是彩色图片，每个像素的颜色由红、绿、蓝三种值混合而成，红绿蓝的取值由很多种，组合形成各种不同的彩色图片，而灰度图片只有256种颜色。由彩色图片生成灰色图片一般由三种算法:

A. 最大值法：R=G=B=MAX（R,G,B），这种方式亮度值偏高；

B. 平均值法：R=G=B=(R+G+B)/3, 这种方式图片亮度值被平均，图片非常柔和

C. 加权平均法：R=G=B=(R*Wr+G*Wg+B*Wb)，由于人眼对不同颜色的敏感度不一样，所以权重也不同，业界比较常用的权重值是(0.2125,
0.7154, 0.0721)。

我们采用的最后一种加权平均的方式，知道了算法就来实现下吧。要实现GPU实时滤镜，首先要了解这么写Shader，网上有很多shader的文章，这里我就不做叙述。



2. 不同颜色滤镜的实现

想实现不同颜色滤镜的实现，可以把期望加强的颜色通道的颜色值加强到相应的比例即可。

![](/image/ri_ji_zhong_shi_pin_bian_ji_lv_jing_xiao_guo_shi_xian_fang_fa/e532fa9eb1aa87a153050241bb05399d9f9d4cff50b7cc7e920ccaa3fa79997d)

图4：红色值扩大两倍的滤镜效果

3. 暖色冷色滤镜的实现

通过PS调整出目标图片与原图每个通道的偏差规律，并把这种差异生成颜色表，给出最终的滤镜变换查表纹理，FragmentShader处理的时候，不同的RGB颜色值去查表纹理中找到对应的目标颜色值进行替换即可。



4. 马赛克的实现

实现马赛克，首先要确定马赛克单元的块大小，马赛克每个独立的方块上都是纯色的，它的取值一般是原图中对应区域的颜色的平均值。

