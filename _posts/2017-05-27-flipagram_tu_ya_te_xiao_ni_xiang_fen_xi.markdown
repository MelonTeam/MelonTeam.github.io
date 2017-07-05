---
layout: post
title: "flipagram 涂鸦特效逆向分析"
date: 2017-05-27 15:56:00
categories: ios
author: qingduan
tags: 涂鸦粒子...
---

* content
{:toc}



  * 背景
  * flipagram特效
  * 仿涂鸦特效
<!--more-->
    * ios粒子效果
    * flipagram特效参数分析
  * 逆向分析
    * ui层级分析
    * 相关类
    * 小结
  * 后续工作

## 背景

flipagram是美国一款非常火爆的短视频应用，一度登顶美国appstore榜首。前段时间又被今日头条重金收购，被当做今日头条发展海外短视频、提升国际影响力的发力点。本着好奇的心情体验了一下这款app，印象最深的是视频编辑能力比较强，特别是动态涂鸦效果感觉非常惊艳，打算好好研究一下，优化改进一下手q现有的涂鸦效果。

## flipagram特效

![untitled](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/3811bde633bcb0a35390dedea415cca7642b53746ffe82e4004004f189a07899)

## 仿涂鸦特效

初步推测：系统自带的粒子效果+手势，在手指移动的过程中创建不同效果的粒子发射机，粒子发射机发射不同效果的粒子。

### ios粒子效果

系统自带的粒子效果实现主要的类是：`caemitterbehavior`、`caemitterlayer`、`caemittercell`他们的作用分别是，定义粒子发射机的行为、设置发射机的特征、设置粒子的具体特效。

使用比较简单：

    
    
        //create the root layer
        rootlayer = [calayer layer];
    
        //set the root layer's attributes
        rootlayer.bounds = cgrectmake(0, 0, 640, 480);
        cgcolorref color = cgcolorcreategenericrgb(0.0, 0.0, 0.0, 1);
        rootlayer.backgroundcolor = color;
        cgcolorrelease(color);
    
        //load the spark image for the particle
        nsimage *image = [nsimage imagenamed:@"tspark"];
        cgimageref img = [image cgimageforproposedrect:nil context:nil hints:nil];
    
        mortor = [caemitterlayer layer];
        mortor.emitterposition = cgpointmake(320, 0);
        mortor.rendermode = kcaemitterlayeradditive;
    
        //invisible particle representing the rocket before the explosion
        caemittercell *rocket = [caemittercell emittercell];
        rocket.emissionlongitude = m_pi / 2;
        rocket.emissionlatitude = 0;
        rocket.lifetime = 1.6;
        rocket.birthrate = 1;
        rocket.velocity = 400;
        rocket.velocityrange = 100;
        rocket.yacceleration = -250;
        rocket.emissionrange = m_pi / 4;
        color = cgcolorcreategenericrgb(0.5, 0.5, 0.5, 0.5);
        rocket.color = color;
        cgcolorrelease(color);
        rocket.redrange = 0.5;
        rocket.greenrange = 0.5;
        rocket.bluerange = 0.5;
    
        //name the cell so that it can be animated later using keypath
        rocket.name = @"rocket";
    
        //flare particles emitted from the rocket as it flys
        caemittercell *flare = [caemittercell emittercell];
        flare.contents = (__bridge id)img;
        flare.emissionlongitude = (4 * m_pi) / 2;
        flare.scale = 0.4;
        flare.velocity = 100;
        flare.birthrate = 45;
        flare.lifetime = 1.5;
        flare.yacceleration = -350;
        flare.emissionrange = m_pi / 7;
        flare.alphaspeed = -0.7;
        flare.scalespeed = -0.1;
        flare.scalerange = 0.1;
        flare.begintime = 0.01;
        flare.duration = 0.7;
    
        //the particles that make up the explosion
        caemittercell *firework = [caemittercell emittercell];
        firework.contents = (__bridge id)img;
        firework.birthrate = 9999;
        firework.scale = 0.6;
        firework.velocity = 130;
        firework.lifetime = 2;
        firework.alphaspeed = -0.2;
        firework.yacceleration = -80;
        firework.begintime = 1.5;
        firework.duration = 0.1;
        firework.emissionrange = 2 * m_pi;
        firework.scalespeed = -0.1;
        firework.spin = 2;
    
        //name the cell so that it can be animated later using keypath
        firework.name = @"firework";
    
        //prespark is an invisible particle used to later emit the spark
        caemittercell *prespark = [caemittercell emittercell];
        prespark.birthrate = 80;
        prespark.velocity = firework.velocity * 0.70;
        prespark.lifetime = 1.7;
        prespark.yacceleration = firework.yacceleration * 0.85;
        prespark.begintime = firework.begintime - 0.2;
        prespark.emissionrange = firework.emissionrange;
        prespark.greenspeed = 100;
        prespark.bluespeed = 100;
        prespark.redspeed = 100;
    
        //name the cell so that it can be animated later using keypath
        prespark.name = @"prespark";
    
        //the 'sparkle' at the end of a firework
        caemittercell *spark = [caemittercell emittercell];
        spark.contents = (__bridge id)img;
        spark.lifetime = 0.05;
        spark.yacceleration = -250;
        spark.begintime = 0.8;
        spark.scale = 0.4;
        spark.birthrate = 10;
    
        prespark.emittercells = @[spark];
        rocket.emittercells = @[flare, firework, prespark];
        mortor.emittercells = @[rocket];
        [rootlayer addsublayer:mortor];
    
        //set the view's layer to the base layer
        theview.layer = rootlayer;
        [theview setwantslayer:yes];
    
        //force the view to update
        [theview setneedsdisplay:yes];
    

具体效果：  
![untitled1](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/dd892091c4c0d2d508f464cb91746bc4f53fb2e040ab93ad5cf3aa184fe64e53)

### flipagram特效参数分析

粒子效果的参数非常多，要实现和flipagram一样的效果，设置参数是一件非常繁琐的事情，借用粒子效果的工具分析了一种类似效果的具体参数，主要包含4个方面的参数：发射机、粒子、色彩、纹理  
16个发射机参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.28](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/5fdceb6c5888ff91a17f68a587749e0045b85982ec56918bb72e93b996c4c8d9)

10个粒子参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.39](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/453134d07a5a9bf0c70b0f494d2184b2bc725df47909f431b25d1469554da0a1)

12个色彩参数(截取部分显示)：  
![屏幕快照 2017-04-28
下午2.05.46](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/930b8b3f6ac2a81f3cfe4583765a10072694e8a21fa4ab902174218c7f82ccd1)

纹理设置：  
![屏幕快照 2017-04-28
下午2.05.53](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/e91dc92d57a0d6e7f730d9894af2c226d0437874a10b3e6dcdbcaf09d8ad5ab6)

**小结：通过类似粒子效果的参数分析，发现系统接口的参数比较少，根本实现不了这种稍微复杂一点的效果。**

## 逆向分析

### ui层级分析

通过分析flipagram的涂鸦页面的ui层级，发现和涂鸦渲染层的类是`fgdrawcontrolsview`  
![708ff504-d266-4c76-a31a-
e75094aae585](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/42472930a5dd1c25ebba733d1d3a0465503fbe4e6c9c65c9a638e31d0ef127d4)

### 相关类

通过反汇编分析了和渲染层`fgdrawcontrolsview`相关的主要类：`fgdrawenginepathfactory`、`fgdrawenginepath`、`fgdrawengine`  
![056c8ff2-d711-4faa-ba7f-
8451a4c8966d](/image/flipagram_tu_ya_te_xiao_ni_xiang_fen_xi/100e7193c51c9bfa5c2dc4b37ffde86ac43bb537e7edd0cdf8cf27f3a646b725)

`fgdrawenginepathfactory`是一个负责创建具体特效路径的工厂类，比如：烟花效果的路径、不同画刷的路径、表情效果的路径、沙子效果的路径等等。
`fgdrawenginepath`设置粒子发射机的特性和粒子特效参数，比如：颜色、画刷参数、弧度等，同时维护了一条路径的矢量点阵信息。
`fgdrawengine`内部利用了opengl把发射机参数、粒子效果参数、色彩参数、纹理参数的具体效果渲染出来。

### 小结

`ios`自带的粒子效果使用比较简单，但是效果也比较单一，很难实现酷炫的效果。`flipagram`的涂鸦特效实现是在手指移动的过程中创建不同效果的粒子发射机，粒子发射机发射不同效果的粒子。其中`fgdrawenginepath`主要负责管理路径和特效信息，`fgdrawengine`负责渲染具体的效果。

## 后续工作

继续分析`fgdrawengine`的内部接口，利用`opengl`实现一个粒子特效引擎，最终实现`flipagram`的涂鸦特效。

