---
layout: post
title: "跬步神经网络1-基本模型解析"
date: 2017-08-08 14:06:00 +0800
categories: 未分类
author: yanjun
tags: 神经网络 人工智能 AI
---

* content
{:toc}

| 导语 最近开始看NN，很多疑问。微积分什么的早丢了，边看边查，记录备忘。
本篇主要是针对最基本的网络模型，解释反向传播（backpropagation）原理。

目录  
跬步神经网络1-基本模型解析  
<!--more-->
[跬步神经网络2-C++简单实现]( "跬步神经网络2-C++简单实现" )  
[跬步神经网络3-MNIST手写库初步识别](
"跬步神经网络3-MNIST手写库初步识别" )

* * *

 整个神经网络可以理解成变量是所有 w、b的损失函数 L，L（w1,b1,w2,b2,w3,b3.......）

为求L的极小值，使用梯度下降的方法

对每个变量求偏导，算出 ****Δw、Δb

更新 w = w - lr Δw    b = b - lr Δb     lr 是步长（learning rate）

激活函数、损失函数、网络结构、训练方法、连接方式、填充方式，都有很多选择，每个选择都会影响最终结果，要达到最优需要逐步积累经验

先从最简单的开始。。。。。。

* * *

需要复习的知识点，导数和偏导数、链式法则、梯度下降

**导数**：二维几何场景下，可以理解为曲线上某点的斜率，在求函数极小值的时候，可以根据斜率确定下一步 X 该增大还是减小

**偏导数**：存在多个变量的情况下，x的偏导就是假设其他变量都是常数，然后对x求导

**链式法则**：借一张图

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/679a554c4cf8077d71afbb842a34db1f40de6facad3ead654e3a5275bf58dd84)

**梯度下降：**求导或偏导得到斜率确定变化值，更新变量得到新的值，重复上面的操作，直到斜率为0或小于设置的某个阈值（比如0.000001）

x = x - lrΔx                   y = y - lrΔy          lr 是步长

* * *

**NN网络举个栗子：**

_神经元：_![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/2b3c062e52756a9ecaa5b0aca2d87d155d9d71ceb3c4a7e55cbab25d8461d228)

_激活函数、损失函数：![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/4ec4ae962fadd12e1546387de33a67e139e07ac0888f8d86629582334930868f)_

_网络结构：_

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/51c56e8d795582e85b79cedc2c31a48aa1aa8ee7d9249b0011eb7d54b96fb86f)

根据上面的网络结构以及定义，可以得到：

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/4dd0b9ca6f444635ca0bb3c744de844323c5777e27787c263d58670d5bb99ff5)

为了更新 W24、W25，需要求 E关于W24、W25的偏导：

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/75403f4f5b13892b4f21d9f5ca6bdcb1cbf8672b956eece8e6c79d056603c447)

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/72947d37861daee680a8304e9d5651f7ad77b55b9c9331b904c6f685f3a4b98b)

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/47d181c5f4003c7fdaabcf66bd5b23ff394c308d6136b78538dbb3f8211dd471)

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/e80d18e6571c2fce116e9d784ee7382968ca85b8ec33358a1989a7480ef083a8)

* * *

 计算W12偏导比较麻烦一些

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/d5eed0fb0bc3b8bac4ebc7875db009dfc4d396829758aaa6daf4888e86b61f3e)

* * *

 根据上面的结果，总结下面的公式：

![](/image/kui_bu_shen_jing_wang_luo_1_ji_ben_mo_xing_jie_xi/80b1782fb7f5ed7f0eb5e2dfeef7dd45204c4153961d605cf7a86196098d7987)

* * *

不同的激活函数和损失函数，求导的方程不一样。

上面的例子使用 logistic函数和最小方差。

下一步打算根据上面的公式，用c++写个小程序动手跑一遍，加深理解，尝试解决简单问题，

然后熟悉成熟框架。

