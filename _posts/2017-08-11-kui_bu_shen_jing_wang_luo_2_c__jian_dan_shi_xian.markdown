---
layout: post
title: "跬步神经网络2-C++简单实现"
date: 2017-08-11 16:22:00 +0800
categories: 未分类
author: yanjun
tags: 神经网络 AI
---

* content
{:toc}

| 导语 不考虑性能，用c++简单实现NN网络，通过训练预测 XOR、AND、OR

目录  
[跬步神经网络1-基本模型解析](
"跬步神经网络1-基本模型解析" )  
<!--more-->
跬步神经网络2-C++简单实现  
[跬步神经网络3-MNIST手写库初步识别](
"跬步神经网络3-MNIST手写库初步识别" )

* * *



跬步1 了解了bp神经网络的原理，这次动手实践。

代码在这里： <https://git.coding.net/yj_3000/SimpleNN.git>  
                      xcode工程，需要设置一下开发者账号  
                      windows是vs2012的工程

**代码大致结构：  
**主要包括3个类，Session、Layer 和 Unit。  
Session 代表一套NN网络，可以配置激活函数、损失函数、数据填充方法等  
Layer 代表网络中的一层，包含一个或者多个Unit  
Unit 代表神经元，实现了  UpdateO(更新输出值)    UpdateE(更新Error)  
                                          UpdateB(更新Bias)        UpdateW(更新权重)

**简单训练方法：**  
1\. 设置 input 所有 unit的 输出值 和 output 所有 unit 的目标值  
2\. 正向依次调用所有 unit 的 updateO  
3\. 反向依次调用所有 unit 的 updateE updateB updateW  
4\. 重复 epochs 次

目前实现了3种激活函数： logistic、tanh、relu  
![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/1d9355fcaf0282b2364a7fe6ec1977fcbb0798896754b10a97305e972f3f94f8)

测试1 - (LogicFitting::run) :  
1\. 建立 2,2,1的网络，随机填充  
2\. 使用相同的网络、相同的参数（lr=0.013），设置不同的激活函数，开始训练 XOR  
3\. 退出条件  
         1）训练次数达到上限  
         2）预测结果与目标值的距离小于 0.01  
结果如下图，  
1） lr=0.013时， relu 表现最好  
![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/d408a6e8702ee890b47cf650bf1b4aef59557ceee90821f64d63031202613a42)

2）lr=0.3时，
relu训练次数以内，没有达到要求![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/655119e2fcbf9ca5492911061216f19bedb71652a04422993360f60e2be1ce07)

3）lr=0.9时， relu和tanh训练次数以内，都没有达到要求  
![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/82b8ac745b2ffe15bd7687638109e8c89fe94c46af49577f0ceade2236684f25)

测试2 - (LogicFitting::run1) :  
1\. 使用相同的网络， 调整 lr，看结果,  
    relu 在 lr > 0.33 之后就再也没有成功过，  
    尝试设置 lr = 0.31 ，然后多次随机填充网络，都会失败，无法成功  
    relu 太容易 die 了  
    这也引出另外一个问题，如何动态调整 lr  
![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/ba26375af8135a10111486d67ce54cdec07dd1a70398985d56848b49add909c3)

下一步打算使用 mnist 上的手写数字数据库，做识别手写数字的联系，  
如果训练性能跟不上，尝试把一般的网络优化方式都实现，看看效果

这里借一张图：  
[https://www.youtube.com/watch?v=yKKNr-
QKz2Q&index=3&list=PLJV_el3uVTsPy9oCRY30oBPNLCo89yu49](https://www.youtube.com/watch?v
=yKKNr-QKz2Q&index=3&list=PLJV_el3uVTsPy9oCRY30oBPNLCo89yu49)  
![](/image/kui_bu_shen_jing_wang_luo_2_c__jian_dan_shi_xian/87fb25f0cc597a7b227720dc648d40108675cacffe0e450855320581231de84e)  
蓝色线，表示 lr 太小，导致梯度下降很慢，有生之年系列  
红色刚刚好  
绿色比较尴尬，出现循环，  
        栗子（y=x*x  y'=2x   想通过梯度下降求极小值， lr=1   x初始值是1，x1=1-1*y'(1)=-1）  
        x会一直在 -1 和 1之间摇摆  
黄色是lr设置太大，直接越过最低点

