---
layout: post
title: "iOS 11 兼容引起的UI问题记录"
date: 2017-09-29 13:17:00 +0800
categories: ios
author: doreencao
tags: iOS iOS11
---

* content
{:toc}



1，NavigationBar的变化

       在iOS
<!--more-->
11之前，导航栏的title添加于UINavigationItemView上，navigationBarButton直接添加于navigationBar上。如果设置了titleView，titleView也是直接添加于navigationBar。

        iOS
11对NavigationBar的图层进行了调整，UINavigationBar有两个子视图，分别是UIBarBackground和UINavigationBarContentView。从下图可以看出，左右navigationBarButton和titileView均被添加于新增的UINavigationBarContentView上。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/9c51964faad603bdacabba803b3a9328767980d6ebb0ec2244a3890838cb189d)

对于navigationBarButton，在它与UINavigationBarContentView之间还有一层_UIButtonBarStackView，navigationBarButton被添加于_UIButtonBarStackView上。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/23ad57a0dc0a780317c4606908660c568ed2559af2d3ed79d3ce01242ae05fac)

       iOS11对导航栏里的item边距也做了调整[1]：

（1）如果只是设置了titleView，没有设置barbutton，把titleview的宽度设置为屏幕宽度，则titleview距离屏幕的边距，iOS11之前，在iPhone6p上是20p，在iPhone6p之前是16p；iOS11之后，在iPhone6p上是12p，在iPhone6p之前是8p。

（2）如果只是设置了barbutton，没有设置titleview，则在iOS11里，barButton距离屏幕的边距是20p和16p；在iOS11之前，barButton距离屏幕的边距也是20p和16p。

（3）如果同时设置了titleView和barButton，则在iOS11之前，titleview和barbutton之间的间距是6p，在iOS11上titleview和barbutton之间无间距。

2，NavigationBar的titleView的宽度适配

由于NavigationBar图层的变化，在navigatioBar上的使用自定义的titleView（如searchBar、segmentControl），iOS
11下可能会出现宽度异常，如下图。

iOS 11：

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/ab20174530857942b74abdd4f6508c93366213db10c07da5bf8dbf0bd3f79192)

理想情况：

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/915bdb0d31946bd18552047bd22c278a7256f678cc2bfa950bd1b475a4199856)

以截图的场景为例，解决这个问题的方案是在自定义的titleView中重写intrinsicContentSize属性get函数，视具体情况返回size值。

3，从二级页面返回后searchBar背景色设置失效

       如下图所示，点击“更多精华话题”，进入二级页面后返回，底色变为灰色。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/c6ba8d23d1e1f61e77e8f864d4e888e15f8231aa4c52b2fca82d8645f9de2ce0)
![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/13437e8957a298ecc406e6394053cbebcd708aadfc11b0db1f17f1ffc18b985d)

在这里searchBar是作为rightBarButtonItem展示在navigationBar中，如下图所示，searchBar添加于图层_UITAMICAdaptorView上，这也是iOS
11的新特性。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/c3178e300b99c1e39319214c89c2134282a237cdc6ef46c8aa52fe37d5abc479)

图(1)

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/37388f0af916fbf66af5da3d332191cd71c5f46399fa635371fea6ddda5ac454)

图(2)

上图(1)是第一次进入搜索页面展示的正常UI，图(2)对应着从二级页面返回后的视图结构。可以看出UI异常是由于原本隐藏的UISearchBarBackground图层又展示出来。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/d807a51cf25b1862976880469963cb3094165b651e548e7c9eea3a740ce5a223)

UISearchBarBackground用于设置背景效果，解决这个问题最简单的方法是在初始化searchBar时将UISearchBarBackground对象从父视图中移除。

![](/image/ios_11_jian_rong_yin_qi_de_ui_wen_ti_ji_lu/8f35dec13adf390556a3d29122f560856c73c559cc01b1235807645ca992bd86)

参考文章：

[1][App界面适配iOS11](http://www.jianshu.com/p/352f101d6df1)

[2][iOS11适配之：0代码实现导航栏UIBarButtonItem间距调整](https://ioslittlewhite.github.io/2017/09/21/iOS11适配之：0代码实现导航栏UIBarButtonItem间距调整/)

[3][What's new in iOS 11 -
部分iOS11新特性整理](http://www.jianshu.com/p/d4a17c32abdf)

