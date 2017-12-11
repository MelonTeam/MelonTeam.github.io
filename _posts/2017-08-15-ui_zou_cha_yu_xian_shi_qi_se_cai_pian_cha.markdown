---
layout: post
title: "UI走查与显示器色彩偏差"
date: 2017-08-15 23:24:00 +0800
categories: ios
author: stackhuang
tags: 显示器 色彩
---

* content
{:toc}



UI提了一个UI走查问题，说一个按钮的底色不对。

![](/image/ui_zou_cha_yu_xian_shi_qi_se_cai_pian_cha/eaeecaa51ed442d9ec26ee758fae93703b33af20f17f6aec756bf6c8ed4f792a)
<!--more-->

标明色值为0xff3b30。

我一看代码，看见

![](/image/ui_zou_cha_yu_xian_shi_qi_se_cai_pian_cha/2070c4d6e322742e866cb21243d232b09aaa4b0d45259824e8d4fbf9ba4a6f7d)

没有问题啊，然后在模拟器上取色值，发现，还真的不对，屏幕取色为 0xfa3f39，奇怪了，难道这个上面还有一个View？结论是没有。

然后在XCode里面看View的结构，发现，这个里面的色值正是0xff3b30，很奇怪。

猜测是显示器的色彩配置，我之前以为无论如何配置，仅仅影响视觉感受，色彩的值不会变的，然而，我想错了。显示器的配置确实会影响屏幕取色的准确值。

这个东西

![](/image/ui_zou_cha_yu_xian_shi_qi_se_cai_pian_cha/09b9b0a17824136685d0446539c7c4be2668ab106ad51e2a1eae5fe65014a461)



当选择不同的描述文件的时候，从屏幕上取的色值是不一样的，可能会差别很大。

最终我选择如图所示的描述文件时，我获取的色值刚好是0xff3b30。

还发现一个神奇的事情，任何描述文件下，XCode展示UI层次图的时候，色彩都是正常的（给定值与屏幕取色值相同），应该是3D渲染相关。

回想起来，之前在设计稿上直接屏幕取色值，有可能是不准确的，所以UI会提出走查问题。

所以，如何UI跟你的色值有异议的时候，你可以问，你的显示器校准了么？

