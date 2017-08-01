---
layout: post
title: "ARKit浅析V1.0"
date: 2017-07-29 17:59:00 +0800
categories: ar/vr
author: nicema
tags: iOS ARKit
---

* content
{:toc}



## 一、**ARKit**介绍****

苹果公司在WWDC2017 上发布了ARKit,开发者可以使用这套框架在iPhone和iPad上创建属于自己的AR体验。
<!--more-->

增强现实技术（Augmented Reality，简称
AR），是一种实时地计算摄影机影像的位置及角度并加上相应图像、视频、3D模型的技术，这种技术的目标是在屏幕上把虚拟世界套在现实世界并进行互动。

ARKit框架提供了两种AR技术，一种是基于3D场景(SceneKit)实现的增强现实，一种是基于2D场景(SpriktKit)实现的增强现实。

需要注意的是，ARKit虽说是iOS11提供的框架，但是并非升级到iOS11都能使用。必须要A9以及以上的处理器才能使用。以下是ARKit 开发环境：

1.Xcode版本：Xcode9及以上

2.iOS系统:iOS11及以上

3.iOS设备：处理器A9及以上（6S机型及以上）

4.MacOS系统：10.12.4及以上（安装Xcode9对Mac系统版本有要求）

## 二、**ARKit**工作原理和流程****

首先需要说明的是，ARKit并不是一个能够独立运行的框架，其依赖SceneKit框架。简单点说，ARKit框架主要提供相机相关的工作，主要负责捕捉和分析现实世界。而展示虚拟物体部分，则是依赖SceneKit提供的能力。如果没有SceneKit，那ARKit只是一个相机而已。（SceneKit是苹果在iOS8中集成的一套3D引擎框架）

下图是ARKit中主要类的关系图：

![](/image/arkit_qian_xi_v1_0/706dc5f2b4055e3678343f073d3ac55be3b8258a446c151a865dcc1a6d350872)

上图中，ARSCNView可以认为是一个容器，代表的就是看到的现实世界。其作用有两个：

1、如上图右边部分：管理ARSession，在这里简单认为ARSession是管理ARKit世界的上下文，其管理者相机的属性设置，也负责向ARSCNView输出捕捉到的显示世界。

2、如上图左边部分：显示我们添加进去的AR物体，这里可以是一个3D物体，也可以是一个2D物体。这里从继承关系来看，ARSCNView、SCNScene、SCNNode等类是从SceneKit中继承过来的。

从上图可以简单的看出ARKit的工作原理，ARKit框架提供相机能力，在手机上捕捉并构建现实世界。SceneKit提供模型能力，在手机的“现实世界”中添加虚拟物体。

以下是一段代码，可以简单的展示一个虚拟物体:

1）首先需要为ARSession 配置运行参数，参数其实挺简单。

![](/image/arkit_qian_xi_v1_0/845d223ac8393d7de482bec192523b53dd93a70d53f009a48c4fc504fd1bff12)

2）使用SCNScene加载3D模型，然后设置成主场景。

![](/image/arkit_qian_xi_v1_0/a85fa7203628e634d9c458e6edbe95c95db75ac775adf9bf2696f9ce281e0798)

3）上面使用的是简答的设置主场景的方式，还可以通过addChildNode的方式加载

![](/image/arkit_qian_xi_v1_0/f0b43bcefdeac48e6d8228da03325e42a821ee81212276030ab07945e4ec88e9)

从上述代码中可以看到，使用ARKit显示一个3D的虚拟物体 其实很简单。这得益于苹果对于技术细节的高度封装，开发者只需要关注自己的产品逻辑即可。

## 三、**ARKit API**介绍****

ARKit框架的API其实并不多。下图就是整个ARKit框架提供的类。下面就这几个主要的类（介绍主要的属性）做一个简单的说明。

![](/image/arkit_qian_xi_v1_0/1008ef67e40e336347ba3c9e4f1386eb351cdb3a60d25803cc2125ed250d7346)

1 ARSCNView

之前介绍过，ARKit支持3D和2D场景，ARSCNView是3D的AR场景视图，是从SceneKit框架中的SCNView继承过来的，其内部最重要的属性是

    
    
    @property (nonatomic, weak, nullable) id delegate;
    @property (nonatomic, strong) ARSession *session;

其中session 主要负责管理ARSession，前面介绍过，这个类主要是管理整个ARKit的上下文，可以理解成管理整个AR世界的捕捉和创建

ARSCNViewDelegate 代理则是负责回调虚拟节点创建移除的一些关键事件回调，如下图所示，从名字上就可以看出其作用，这里就不再一一赘述其作用了

![](/image/arkit_qian_xi_v1_0/d651334e169e206ce067a547844e165d1873cd8282cb4aa7cd9aaa77b9ec51bc)

2 ARSession

ARSession是一个连接底层与AR视图之间的桥梁。ARSession可以偶去相机的一些关键数据，主要有两种方式：一、通过delegate，可以不断的获知相机位置；二、通过ARSession的CurrentFrame属性来获取；

其内部最重要的属性是：

    
    
    // 代理
    @property (nonatomic, weak) id  delegate;
    // 获取当前的相机参数，包括位置等
    @property (nonatomic, copy, nullable, readonly) ARFrame *currentFrame;
    // 管理会话追踪参数
    @property (nonatomic, copy, nullable, readonly) ARSessionConfiguration *configuration;

 最重要的是一些代理方法

    
    
    //session KVO观察者
    @protocol ARSessionObserver <NSObject>
    @optional
    /**
     session失败
     */
    - (void)session:(ARSession *)session didFailWithError:(NSError *)error;
    /**
    相机改变追踪状态
     */
    - (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera;
    /**
     session意外断开（如果开启ARSession之后，APP退到后台就有可能导致会话断开）
     */
    - (void)sessionWasInterrupted:(ARSession *)session;
    /**
    session会话断开恢复（短时间退到后台再进入APP会自动恢复）
     */
    - (void)sessionInterruptionEnded:(ARSession *)session;
    @end
    #pragma mark - ARSessionDelegate
    @protocol ARSessionDelegate <ARSessionObserver>
    @optional
    /**
     相机当前状态（ARFrame：空间位置，图像帧等）更新
     */
    - (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame;
    /**
    添加锚点
     */
    - (void)session:(ARSession *)session didAddAnchors:(NSArray*)anchors;
    /**
    刷新锚点
     */
    - (void)session:(ARSession *)session didUpdateAnchors:(NSArray*)anchors;
    /**
    移除锚点
     */
    - (void)session:(ARSession *)session didRemoveAnchors:(NSArray*)anchors;
    @end

 3 ARSessionConfiguration

ARSessionConfiguration会话追踪配置，主要就是追踪相机的配置

4 ARAnchor

ARAnchor表示一个物体在3D空间的位置和方向。

5 ARCamera

记录相机的一些参数。一般情况下，我们并不需要设置这个类，系统会帮我们配置好

6 ARFrame

ARFrame主要是追踪相机当前的状态，这个状态不仅仅只是位置，还有图像帧及时间等参数

7 ARHitTestResult

点击回调结果，这个类主要用于虚拟增强现实技术（AR技术）中现实世界与3D场景中虚拟物体的交互。
比如我们在相机中移动。拖拽3D虚拟物体，都可以通过这个类来获取ARKit

所捕捉的结果

上文主要参考官方文档和网络博客：<http://blog.csdn.net/u013263917/article/details/72903174>

