---
layout: post
title: "IOS控件动画的一种通用方法"
date: 2017-07-31 20:45:00 +0800
categories: ios
author: houlvezhou
tags: iOS 动画
---

* content
{:toc}



# IOS控件动画的一种通用方法

> 最近在做一个垂直弹幕控件 , 在做控件动画时费了不少心思, 这里分享一些心得.
<!--more-->

## 前言

关于动画, 我们一般使用UIKit提供的动画来实现.

UIView动画可以设置的动画属性有:

  * 大小变化(frame)
  * 拉伸变化(bounds)
  * 中心位置(center)
  * 矩阵(transform)
  * 透明度(alpha)
  * 背景颜色(backgroundColor)
  * 拉伸内容(contentStretch)

这里主要介绍transform这个属性.

**CGAffineTransform**  
transform的类型是CGAffineTransform , 这是一个2D矩阵.

## 矩阵的基本知识

    
    
    struct CGAffineTransform
    {
      CGFloat a, b, c, d;
      CGFloat tx, ty;
    };
    CGAffineTransform CGAffineTransformMake (CGFloat a,CGFloat b,CGFloat c,CGFloat d,CGFloat tx,CGFloat ty);
    

为了把二维图形的变化统一在一个坐标系里，引入了齐次坐标的概念，即把一个图形用一个三维矩阵表示，其中第三列总是(0,0,1)，用来作为坐标系的标准。所以所有的变化都由前两列完成。  
以上参数在矩阵中的表示为：

![1](/image/ios_kong_jian_dong_hua_de_yi_zhong_tong_yong_fang_fa/44e68d4700c1529266d0a5a62cddbc0b4af2b251983f2b5602da9be106b599d2)  

[ 1 ]

  
运算原理：原坐标设为（X,Y,1）;  

![2](/image/ios_kong_jian_dong_hua_de_yi_zhong_tong_yong_fang_fa/45c301df9d8f74bdc1125d11a318b20f34025016cff750151993f3258b5dc5a7)  

[ 2 ]

通过矩阵运算后的坐标[aX + cY + tx bX + dY + ty 1]，我们对比一下可知：  
**第一种**：  
设a=d=1, b=c=0.  
[aX + cY + tx bX + dY + ty 1] = [X + tx Y + ty 1];  
可见，这个时候，坐标是按照向量（tx，ty）进行平移，  
其实这也就是函数

    
    
    CGAffineTransform CGAffineMakeTranslation(CGFloat tx,CGFloat ty)
    

的计算原理。

**第二种**：

设b=c=tx=ty=0.  
[aX + cY + tx bX + dY + ty 1] = [aX dY 1];  
可见，这个时候，坐标X按照a进行缩放，Y按照d进行缩放，a，d就是X，Y的比例系数，其实这也就是函数

    
    
    CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy)
    

的计算原理。a对应于sx，d对应于sy。

**第三种**：设tx=ty=0，a=cosɵ，b=sinɵ，c=-sinɵ，d=cosɵ。  
[aX + cY + tx bX + dY + ty 1] = [Xcosɵ - Ysinɵ Xsinɵ + Ycosɵ 1] ;  
可见，这个时候，ɵ就是旋转的角度，逆时针为正，顺时针为负。其实这也就是函数

    
    
    CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle)
    

的计算原理。angle即ɵ的弧度表示。

总体来说, 记住下面这个结论就好.

>  
对于CGAffineTransformMake(a,b,c,d,tx,ty)  
**ad缩放bc旋转tx,ty位移**

## 应用

如何做一个 指定锚点的缩放动画.

分析:  
缩放动画 只需要改变b , d 的值即可. 但是此时控件的锚点是在中心点.  
把当前中心点移动到你想要的点即可 , 例如, 把锚点放在相对控件原点(0,0)

    
    
    //设置开始状态
    CGFloat offsetX = 0 - view.size.width/2;
    CGFloat offsetY = 0 - view.size.height/2;
    //0.1 , 0.1 缩放到原来大小的0.1倍, 把原点放到(0,0)
    view.transform = CGAffineTransformMake(0.1, 0, 0, 0.01, offsetX, offsetY);
    [UIView animateWithDuration:0.5 delay:0.7 
    options:UIViewAnimationOptionCurveLinear 
    animations:^{
       //放大到1倍, 位移到原点
         view.transform = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
            } completion:^(BOOL finished){}];
    

可以看到. 只使用一次变换就完成了一次位移和缩放的动画.

