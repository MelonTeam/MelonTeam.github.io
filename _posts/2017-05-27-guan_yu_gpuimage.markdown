---
layout: post
title: "关于GPUImage"
date: 2017-05-27 17:55:00
categories: ios
author: doreencao
tags: 滤镜
---

* content
{:toc}



本文内容参考自以下文章：KM文章[一张图教你看懂GPUImage](http://km.oa.com/group/22128/articles/show/272905?kmref=search&from_page=1&no=1)、[iOS
图像处理系列 -
GPUImage源码解读（一）](http://km.oa.com/group/29501/articles/show/284686?kmref=author_post)，博文[GPUImage文集](http://www.jianshu.com/nb/4268718)。文中不再详细标注引用来源。
<!--more-->

# ****

## 关于GPUImage

GPUImage框架是一个开源iOS类库，基于OpenGL进行图像和视频处理，借助GPU加速实现各种滤镜效果，并支持摄像头拍摄实时渲染。

它具有以下特性：

·             对OpenGL资源创建和滤镜做统一封装，接口简单易用，内置cache模块进行framebuffer管理。

·             框架设计灵活，支持上下级滤镜的串联、并联，以实现复杂的滤镜响应链。

·             有丰富的输入、输出组件及封装好的内置滤镜，可满足大多数场景的应用。

·             可继承GPUImageFilter实现自定义滤镜效果，扩展非常方便。

## GPUImage框架

GPUImage功能的实现依赖四个部分：资源管理、Sources、Filters、Outputs。核心架构用下图概括：

**![](/image/guan_yu_gpuimage/c8ea0275608836eb3387c2965cb05c96510a9ab57fc47d0a12c789d6f0853774)**

**1.     ****资源管理**

**      ![](/image/guan_yu_gpuimage/5f3a90fe2b66fa08a16e62fbc9bde6dc18c3de82aab39c04749bd4220ca34daa)**

GLProgram是GPUImage对OpenGL
ES中的program的封装，可用vertexShader和fragmentShader创建GLProgram对象，实现自定义滤镜效果。

GPUImageContext是GPUImage对OpenGL
ES上下文的封装，并添加GPUImge相关的上下文，如上下文队列(contextQueue，解决OpenGLContext不是多线程安全的问题)、CV纹理缓存(coreVideoTexttureCache)、framebuffer缓存、program使用的缓存等。

GPUImageFramebuffer是管理纹理缓存格式、帧缓存的buffer，完成缓存创建、指定渲染目标、调整视口、解锁等。其中，newCGImageFromFramebufferContents函数从缓存中获取图像数据，创建CGImageRef并返回。

GPUImageFramebufferCache是GPUImageFramebuffer的管理类。

**2.     ****Sources**

**      ![](/image/guan_yu_gpuimage/8056ee83b90903e331566f2b229eac4d805b378918401c85c76762c42ce3b46a)**

Sources目录结构如上图所示。GPUImageOutput是其他输入源的基类，输入组件将图像或视频帧数据转换成OpenGL纹理传递给滤镜组件。下面以滤镜视频拍摄这一场景下使用的GPUImageVideoCamera为例进行介绍。

GUPImagVideoCamera利用AVCaptureSession从AV输入设备采集数据。

**![](/image/guan_yu_gpuimage/c8f82220908cfbb1fa1621b1e049fbf13114186fd789d2db0dd58bd989feff62)**

**![](/image/guan_yu_gpuimage/ba311537f13d9dce5b4513052a9aafa5951bb12ce797885bfbb6fd57215834d8)**

      流程概述如下：

1)
找到摄像头设备_inoutCamera、麦克风_microphone，创建摄像头输入videoInput和麦克风输入audioInput，设置为_captureSession的输入。

2)
创建摄像头输出videoOutput和麦克风输出audioOutput，设置为_captureSession的输出，设置二者的输出delegate。

3)     调用[_captureSessionstartRunning]开始获取音视频数据。

4)      音频数据到达后发送给设置的audioEncordingTarget处理。

5)     视频数据到达后利用下面的函数处理回调：

**![](/image/guan_yu_gpuimage/9a60edb80c1a2f374fe49e48ec620edb9db5f16b32a202676d7be81108fcd4f8)**

摄像头默认采样格式为YUV420，Y通道数据和UV通道数据分别存放在两个plane中，processVideoSampleBuffer:函数将两个plane的数据取出，处理后在convertYUVToRGBOutput函数中通过颜色转换的shader，得到了RGB格式的GPU纹理提供给下一级滤镜组件，完成数据输入工作。

**![](/image/guan_yu_gpuimage/8381c98223f110b43ed6177c1c810f0981362cddaac3ed807c533ef23046fa86)**

**3.     ****Filters**

**      ![](/image/guan_yu_gpuimage/b3dde7cc9e3e7a94cc8b9e514c874cff7f11c1096425aec4d4d70f7f70d20489)**

GPUImageFilter是各滤镜类的基类。它实现了GPUImageInput协议，可以作为输出对象。GPUImageInput定义了组件作为响应链中的target(上一级组件的输出对象)需要实现的接口。

**![](/image/guan_yu_gpuimage/78e60c622c1f03a9fff09a0427dc9d4bab84e99f25cbef519f4335346b3b1506)**

另一方面GPUImageFilter继承自Sources中的GPUImageOutput，因此一个滤镜组件也可以作为输入对象。基于这种设计，输入组件、滤镜组件、输出组件可以链式串联起来，推动输入数据的处理与传递。

GPUImageFilter及子类接受一个或多个输入，调用关联的GLProgram进行渲染，将结果输出到targets属性保存的对象列表中的每一个对象。输入、输出的纹理由GPUImageFrameBuffer管理。

输入数据通过setInputFramebuffer:接口传入，由响应链中的上一级组件调用。

**![](/image/guan_yu_gpuimage/a81b1956b2a23503dd574ceaedcb3319b4bbf6b82e932f98850f6d9f84dfcfa4)**

读入输入数据后，下图接口实现了渲染和数据向下级组件的传递。

**![](/image/guan_yu_gpuimage/5fd475627e83e96aae5dd1b60706ea57748966f4a3b40f45f9b9ed65b1b156f4)**

其中，renderToTextureWithVertices:函数实现滤镜渲染，将渲染结果输出到outputframebuffer指定的缓存。

**![](/image/guan_yu_gpuimage/be20f959ec6dfe987ea119df757b16075a0d57a009584b3df579fc1e6092fc89)**

informTargetsAboutNewFrameAtTime:将自己获得的渲染结果数据传递给下一级组件，并推动其处理数据。

**![](/image/guan_yu_gpuimage/7a45f6f1c2cabf1b90a3342a5a777d2638ff5e3481a9a5675237d8e3d988eab5)**

**4.     ****Outputs**

      **![](/image/guan_yu_gpuimage/bd3ab902f9a309202566bea33885394e2f4ad378061df55a81c37df98e11b812)**

Outputs组件是响应链的终点，负责将处理结果输出。这组组件同样实现GPUImageInput协议，处理上一级组件的输出结果。GPUImageView是UIView的子类，用于实时将滤波结果显示在屏幕上，GPUImageMovieWriter将滤镜视频保存在本地，GPUImageTextureOutput输出GPU纹理，GPUImageRawDataOutput提供输出完成的delegate回调和读区像素数据的接口。录制滤镜视频时需要用到GPUImageView和GPUImageMovieWriter。

GPUImageMovieWriter将视频输出到磁盘，通过设置、使用AVAssetWriter，在newFrameReadyAtTime:中实现功能。

**![](/image/guan_yu_gpuimage/9471d357ca2ed47b97a0b947eb91753643b3f68381ea05365961c1689ec1c9f2)**

GPUImageView内部将自己的CALayer申明为CAEAGLayer，在初始化后调用createDisplayFramebuffer方法：

**![](/image/guan_yu_gpuimage/67628b1e8e9cee0494aa37e1f8d15b1e77d46ad8298d20b07187c46490e040a2)**

将renderBuffer和CALayer关联，newFrameReadyAtTime:渲染后图像会输出至CALayer上。

**![](/image/guan_yu_gpuimage/a07c4d718ee9adc3feb43a7bef1d9052617307be0ab3af0e0e762415a695b5ed)**

## 录制滤镜视频

下面的例子利用GPUImage录制视频、实现实时的滤镜效果渲染并将视频文件保存到本地。

通过GPUImageVideoCamera采集视频和音频数据，音频直接传递至GPUImageMovieWriter；视频传入滤镜链，经过滤镜处理后，输出的渲染结果传递给GPUImageMovieWriter准备写入本地文件，并通过GPUImageView显示在屏幕上。

**![](/image/guan_yu_gpuimage/18c7c342dc4a39ba245d86a634e0b193e2f7edd234a26ba2f683f1abc9094063)**

下图是视频录制页面，使用内置滤镜GPUImageSwirlFilter，屏幕下方滑动条可以调整滤波核参数，实时的改变滤镜渲染的效果(本例表现为螺旋形的角度)。点击左上方按钮启动/结束录制，结束录制后视频文件保存在本地相册。

**![](/image/guan_yu_gpuimage/8a9dbd303def459c253263de67db282f8609ab0f296bfd5347d4acdbfba9f120)**

录制界面

设置响应链：

**![](/image/guan_yu_gpuimage/1671843d6cf2c36399d33792a635214e0988303bd3dead6ad7f859f440991ab9)**

点击录制按钮开始录制视频，用NSURL及尺寸初始化_movieWriter：

**![](/image/guan_yu_gpuimage/1233b5fd1eb748beaa2955db5f3dabfeda453d82a5a525ff691fe5162aaef024)**

结束录制：

**![](/image/guan_yu_gpuimage/c4b902377ecfb2589b1b4c8735c53da518bdba2d9c2c878e7cf50b83cf9aff38)**

其他滤镜效果：

**![](/image/guan_yu_gpuimage/e7b599863b6a5c014d823deb120d97b39b533f16d3ea52549648b007a8bf545d)**    **![](/image/guan_yu_gpuimage/bef686b06f6a0e0d7bd8038f6081ea9a3e877451dc2803d29fdbb9ede0f48741)**

玻璃球                                       阴影边框

**![](/image/guan_yu_gpuimage/0cd89b4d678e393b979733fb98d4615accea2f5e662e163e8d1b1d05ed11b0c2)**    **![](/image/guan_yu_gpuimage/94afb797cfde4d0c9d714e8b9b22b6b4dfddf9b8a84a15ba85150c284591a03c)**

                         泊松图像融合                            左图中的水印原图

**![](/image/guan_yu_gpuimage/303b1951fa8bd4825fdc84027b11e65f9bdae9fa3138a250aed9a435b630c0f3)**    **![](/image/guan_yu_gpuimage/48bdadec4faf0e9b5c4b19875370e28fd7e7273390fac1b98a181388ead429cc)**

  形态学开运算                               形态学闭运算

**![](/image/guan_yu_gpuimage/bcff472568eebe2cbd4cf68b8d08b17027aef5b77218225a39a343f025b4c66f)**    **![](/image/guan_yu_gpuimage/eed52fbc401bd958c1641a65731bcf208c24e40ab5b0386b2ea36deeac3fefa6)**

                        风格化之素描画                                卡通

__

##

