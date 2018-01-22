---
layout: post
title: "Android圆形图片组件RotateCircleImageView简介"
date: 2017-12-27 19:27:00 +0800
categories: 未分类
author: vincanyang
tags: 圆形图片组件
---

* content
{:toc}



## 介绍

Android开发中经常会需要展示圆形图片尤其是头像，但是SDK并没有直接支持，需要开发者自行实现。RotateCircleImageView正是这样一个圆形图片UI组件，使用它不仅可以快速简单实现圆形图片，还有多种展示风格可以选择：
<!--more-->

1.圆形头像，默认

2.圆形头像，且带有边框

3.圆形头像，且带有分段边框（适合区分数据状态场景）

4.圆形头像，且带有转圈的边框（适合展示加载数据场景）

目前代码已开源至github，详见[这里](https://github.com/yangwencan2002/RotateCircleImageView)。  

![](/image/android_yuan_xing_tu_pian_zu_jian_rotatecircleimageview_jian_jie/bd090a794e1621d5fa8fe58d6b8144a9b068d53a66c5a4b5ffbb8373c159258a)  

[ RotateCircleImageView ]

## 使用方法

## 代码引用（gradle）

    
    
    dependencies {
        ...
        compile 'com.vincan:rotatecircleimageview:1.0.0'
    }
    

## 代码使用

XML

    
    
    <com.vincan.rotatecircleimageview.RotateCircleImageView
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:src="@drawable/penguin"
        app:rciv_border_width="2dp"
        app:rciv_border_padding="2dp"
        app:rciv_border_colors="@array/border_colors"
        app:rciv_border_style="rotate"/>
    

Java

    
    
    rotateCircleImageView.setBorderWidth(2);//设置边框宽度
    rotateCircleImageView.setBorderPadding(2);//设置边框和头像的间距
    rotateCircleImageView.setBorderColors(new int[]{Color.BLUE, Color.LTGRAY});//设置边框颜色，多个颜色值表示分段边框的颜色，且起点为12点钟顺时针方向
    rotateCircleImageView.setBorderStyle(BorderStyle.ROTATE);//设置边框风格，BorderStyle.ROTATE表示旋转，BorderStyle.STILL表示静态，即非旋转状态
    

## 源码及DEMO

参见[github](https://github.com/yangwencan2002/RotateCircleImageView)

## 已应用App

#### 手Q

![](/image/android_yuan_xing_tu_pian_zu_jian_rotatecircleimageview_jian_jie/105d377f3422186c6a25bc9b9802b2327a131445829630d8324732c87bdbc894)  

[ 手Q ]

## 版本发布

[bintray.com](https://bintray.com/yangwencan2002/maven/RotateCircleImageView)

## 源码解读

待补充

