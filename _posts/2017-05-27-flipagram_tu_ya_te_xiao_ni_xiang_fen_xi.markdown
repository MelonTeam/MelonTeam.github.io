---
layout: post
title: "Flipagram 涂鸦特效逆向分析"
date: 2017-05-27 15:56:00 +0800
categories: ios
author: qingduan
tags: 涂鸦粒子效果
---

* content
{:toc}



  * 背景
  * Flipagram特效
  * 仿涂鸦特效
<!--more-->
    * IOS粒子效果
    * Flipagram特效参数分析
  * 逆向分析
    * UI层级分析
    * 相关类
    * 小结
  * 后续工作

## 背景

Flipagram是美国一款非常火爆的短视频应用，一度登顶美国appstore榜首。前段时间又被今日头条重金收购，被当做今日头条发展海外短视频、提升国际影响力的发力点。本着好奇的心情体验了一下这款APP，印象最深的是视频编辑能力比较强，特别是动态涂鸦效果感觉非常惊艳，打算好好研究一下，优化改进一下手Q现有的涂鸦效果。

## Flipagram特效

![Untitled](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/a658c5552ff00982a62844332c5ebb83852d4e45677ad42d5f984767987e6e2f)

## 仿涂鸦特效

初步推测：系统自带的粒子效果+手势，在手指移动的过程中创建不同效果的粒子发射机，粒子发射机发射不同效果的粒子。

### IOS粒子效果

系统自带的粒子效果实现主要的类是：`CAEmitterBehavior`、`CAEmitterLayer`、`CAEmitterCell`他们的作用分别是，定义粒子发射机的行为、设置发射机的特征、设置粒子的具体特效。

使用比较简单：

    
    
        //Create the root layer
        rootLayer = [CALayer layer];
    
        //Set the root layer's attributes
        rootLayer.bounds = CGRectMake(0, 0, 640, 480);
        CGColorRef color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1);
        rootLayer.backgroundColor = color;
        CGColorRelease(color);
    
        //Load the spark image for the particle
        NSImage *image = [NSImage imageNamed:@"tspark"];
        CGImageRef img = [image CGImageForProposedRect:nil context:nil hints:nil];
    
        mortor = [CAEmitterLayer layer];
        mortor.emitterPosition = CGPointMake(320, 0);
        mortor.renderMode = kCAEmitterLayerAdditive;
    
        //Invisible particle representing the rocket before the explosion
        CAEmitterCell *rocket = [CAEmitterCell emitterCell];
        rocket.emissionLongitude = M_PI / 2;
        rocket.emissionLatitude = 0;
        rocket.lifetime = 1.6;
        rocket.birthRate = 1;
        rocket.velocity = 400;
        rocket.velocityRange = 100;
        rocket.yAcceleration = -250;
        rocket.emissionRange = M_PI / 4;
        color = CGColorCreateGenericRGB(0.5, 0.5, 0.5, 0.5);
        rocket.color = color;
        CGColorRelease(color);
        rocket.redRange = 0.5;
        rocket.greenRange = 0.5;
        rocket.blueRange = 0.5;
    
        //Name the cell so that it can be animated later using keypath
        rocket.name = @"rocket";
    
        //Flare particles emitted from the rocket as it flys
        CAEmitterCell *flare = [CAEmitterCell emitterCell];
        flare.contents = (__bridge id)img;
        flare.emissionLongitude = (4 * M_PI) / 2;
        flare.scale = 0.4;
        flare.velocity = 100;
        flare.birthRate = 45;
        flare.lifetime = 1.5;
        flare.yAcceleration = -350;
        flare.emissionRange = M_PI / 7;
        flare.alphaSpeed = -0.7;
        flare.scaleSpeed = -0.1;
        flare.scaleRange = 0.1;
        flare.beginTime = 0.01;
        flare.duration = 0.7;
    
        //The particles that make up the explosion
        CAEmitterCell *firework = [CAEmitterCell emitterCell];
        firework.contents = (__bridge id)img;
        firework.birthRate = 9999;
        firework.scale = 0.6;
        firework.velocity = 130;
        firework.lifetime = 2;
        firework.alphaSpeed = -0.2;
        firework.yAcceleration = -80;
        firework.beginTime = 1.5;
        firework.duration = 0.1;
        firework.emissionRange = 2 * M_PI;
        firework.scaleSpeed = -0.1;
        firework.spin = 2;
    
        //Name the cell so that it can be animated later using keypath
        firework.name = @"firework";
    
        //preSpark is an invisible particle used to later emit the spark
        CAEmitterCell *preSpark = [CAEmitterCell emitterCell];
        preSpark.birthRate = 80;
        preSpark.velocity = firework.velocity * 0.70;
        preSpark.lifetime = 1.7;
        preSpark.yAcceleration = firework.yAcceleration * 0.85;
        preSpark.beginTime = firework.beginTime - 0.2;
        preSpark.emissionRange = firework.emissionRange;
        preSpark.greenSpeed = 100;
        preSpark.blueSpeed = 100;
        preSpark.redSpeed = 100;
    
        //Name the cell so that it can be animated later using keypath
        preSpark.name = @"preSpark";
    
        //The 'sparkle' at the end of a firework
        CAEmitterCell *spark = [CAEmitterCell emitterCell];
        spark.contents = (__bridge id)img;
        spark.lifetime = 0.05;
        spark.yAcceleration = -250;
        spark.beginTime = 0.8;
        spark.scale = 0.4;
        spark.birthRate = 10;
    
        preSpark.emitterCells = @[spark];
        rocket.emitterCells = @[flare, firework, preSpark];
        mortor.emitterCells = @[rocket];
        [rootLayer addSublayer:mortor];
    
        //Set the view's layer to the base layer
        theView.layer = rootLayer;
        [theView setWantsLayer:YES];
    
        //Force the view to update
        [theView setNeedsDisplay:YES];
    

具体效果：  
![Untitled1](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/92e77db926e37e4048d8d52e9e340ea5f0a840b874a371e2b016a5f53ef85ba9)

### Flipagram特效参数分析

粒子效果的参数非常多，要实现和Flipagram一样的效果，设置参数是一件非常繁琐的事情，借用粒子效果的工具分析了一种类似效果的具体参数，主要包含4个方面的参数：发射机、粒子、色彩、纹理  
16个发射机参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.28](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/2fe6c2862e10ae1f4c1a9eebfbbe85db8fb321bd2dfbf6c7534c0a22e2f58f9d)

10个粒子参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.39](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/472680555b4c18e282bdb26fe5458ee6b8836c878ebcb5314ba5bd47b8b2be01)

12个色彩参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.46](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/b8008c75a6fc39919a88daac1a678a9b06281c5000babb29abaa26429f2754a9)

纹理设置：  
![屏幕快照 2017-04-28
下午2.05.53](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/d65415b4f3fa5a956b979931f29259456344a9383c027e54dbf816daa55e6e40)

**小结：通过类似粒子效果的参数分析，发现系统接口的参数比较少，根本实现不了这种稍微复杂一点的效果。**

## 逆向分析

### UI层级分析

通过分析Flipagram的涂鸦页面的UI层级，发现和涂鸦渲染层的类是`FGDrawControlsView`  
![708FF504-D266-4C76-A31A-
E75094AAE585](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/39a67b431717fbf92b7b7f943c689f422eb6f782eeedb2c5ad7b23f955c3b6bc)

### 相关类

通过反汇编分析了和渲染层`FGDrawControlsView`相关的主要类：`FGDrawEnginePathFactory`、`FGDrawEnginePath`、`FGDrawEngine`  
![056C8FF2-D711-4FAA-BA7F-
8451A4C8966D](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/c59271ab58e5f8f9934b2b7a817602d27e87ee1c8ddd2a65eab9a973c6251f1d)

`FGDrawEnginePathFactory`是一个负责创建具体特效路径的工厂类，比如：烟花效果的路径、不同画刷的路径、表情效果的路径、沙子效果的路径等等。
`FGDrawEnginePath`设置粒子发射机的特性和粒子特效参数，比如：颜色、画刷参数、弧度等，同时维护了一条路径的矢量点阵信息。
`FGDrawEngine`内部利用了OpenGL把发射机参数、粒子效果参数、色彩参数、纹理参数的具体效果渲染出来。

### 小结

`IOS`自带的粒子效果使用比较简单，但是效果也比较单一，很难实现酷炫的效果。`Flipagram`的涂鸦特效实现是在手指移动的过程中创建不同效果的粒子发射机，粒子发射机发射不同效果的粒子。其中`FGDrawEnginePath`主要负责管理路径和特效信息，`FGDrawEngine`负责渲染具体的效果。

## 后续工作

继续分析`FGDrawEngine`的内部接口，利用`OpenGL`实现一个粒子特效引擎，最终实现`Flipagram`的涂鸦特效。

