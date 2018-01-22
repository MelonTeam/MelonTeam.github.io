---
layout: post
title: "单变量线性回归模型介绍"
date: 2017-12-28 22:56:00 +0800
categories: deep learning
author: zehongliu
tags: ml 线性回归
---

* content
{:toc}

| 导语 本文介绍机器学习中的一种入门级模型：单变量线性回归模型。总结于吴恩达的机器学习课程，ppt已经上传到文档列表中。

单变量线性回归模型介绍

一、模型分类
<!--more-->

在机器学习领域，学习的方式可以简单地被分为两类：有监督学习和无监督学习。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/1dc682412dddb6fae81446f82c731763a5f2b914763e6c0bc80d3d6ee043e395)

有监督学习指对分类结果有明确预判的问题，比如我们针对一个患有肿瘤的病人，根据其肿瘤大小来判断肿瘤的性质属于恶性还是良性。由于我们已知预测结果只有恶性和良性两种可能，所以此行为属于有监督学习。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/af2769b8c7bc9b3b5985f3b67ec26f984b442f17167d50087c14e20db5a07f29)

无监督学习指对预测结果没有预判的问题，比如在GOOGLE新闻网页中，GOOGLE官方会将每天发生的新闻按照类别自动聚合。由于每天产生的新闻无法预判，所以这种聚类的方式属于无监督学习。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/c3e811c845e550def7874b4d592513211c292b1ae7b23c89f174485433afd6f0)

在有监督学习中，主要又可以分为具有连续结果的回归模型，和具有离散结果的分类模型。之前提到的肿瘤预测良性恶性属于分类模型，因为分类结果非黑即白，属于离散结果。举一个预测房价的例子，如果我们通过房屋面积预测房屋价格，会得到下图所示的一条曲线。这种拥有连续结果的预测模型属于回归模型。

单变量线性回归模型是回归模型的一种最简单的呈现方式。由于其只有一个变量，且假设函数是线性的，十分易于理解。

二、 单变量线性回归模型

1\. 代价函数

我们使用之前通过房屋面积预测房屋价格的例子，假设房屋的价格面积对应关系如下表所示。表中的每一行数据都是一个输入样本和一个输出样本的集合，也称作训练集。所有样本的数量用小写m表示，输入样本用x表示，输出样本用y表示。x和y的对应关系称作假设函数h。我们要做的就是通过训练集找到假设函数h，确定了假设函数之后就可以进行预测了。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/5e5cc0d152816e24a2fa07ffd8ea905449cc52e2cac089bee2f1de48cb11aeaa)![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/07689ec61e85aa5228184ecb8f58d4d50b8583c4601101befb734b0eae96b685)

假设函数h：

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/19b63a931600b62ad508f2735d125654d1d03769ec28dbcf850d6770bcac9f6d)

    通过假设函数h我们可以在训练集的坐标轴上画出一条线。由于是单变量线性回归，这条假设函数线是一条直线，它会尽可能多的靠近训练集样本点。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/9b97fc6f7c99911d61ccd02da94d2d1f90547abd6df70201d98b7836bda61729)

那么，如何评价一个假设函数是否准确呢？或者说如何衡量这条直线是否贴近了足够多的训练集样本点呢？我们使用代价函数来评价假设函数的优劣。代价函数用J表示，描述了假设函数上取每一个输入样本点，和输出样本做差后再求平方和。可以理解为假设函数上每个点到真实样本之间的距离。显然，总距离越近，J越小，假设函数就越合理。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/06f84f21f91d3793c48bff4a5aa033560f9d8a6d71ed6e6dc56da4a95632407f)

我们的目的是得到最小的代价函数J：

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/89bd778b2b809e1d15196b5139a37ea420bcfbef1666678f0b70d94b1486b031)

从下面的3D图中可以看到，代价函数J呈一个碗状，在碗底的最低点，就是最佳的系数取值点，从此确定假设函数h。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/46eb9ac0a5b9ca24006621e80f46f1ebaa28981d537adb265528ae71af5718ca)

2\. 梯度下降

接上文，我们如何确定这个碗的碗底在哪里呢？显然遍历所有的系数θ取值点不是一个可行的好办法。一般会采取一些下降算法，最普遍的就是梯度下降法。

梯度下降法的做法是，针对一个假设函数h，对其系数θ随机找到两个初始点，然后同步地、持续地改变系数θ的值，直到获得最小的代价函数J。可以理解为从碗的任意一点出发，逐步地向碗底进发。一般来说，每一步前进的方向是代价函数J对系数θ自身的偏导数，用这个偏导数乘上学习速率α就是每一步的大小。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/4e45903ec484524644ed88d7207f6bdd7881dd01c0cb9357924f656a4d0b08bd)

注意，梯度是一个向量，由两个偏导数一起合成出来，所以要同步改变两个系数的值，左下图是正确的。右下图先改变了一个系数，另一个系数是在其基础上改变的，不属于同步改变，在编程中值得注意。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/b37e3a8d88259511b0b8c828f12929a5e1805b4c93235eb35015f9c3859ce7dd)![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/59d025d4a15e520feae8d770dad3b965bbea69d7bb2789d41323785e8aed6fae)

另外，注意区别全局最优和局部最优，下图中一个是全局最优，一个是局部最优，在机器学习中，陷入局部最优解是一个很常见且很难排查的一种情况，需要留意分析。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/13732e372f70aaf2c23f960abab551bbb08c5d97cf7f6c9e99e3ff3ee6096db1)

局部最优

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/f6152e7df3d49ea69878b593e3eaddcc3569b77630f67bee6df3277aec28a099)

全局最优

学习速率α是一个描述步长的人工设定的参数，学习速率越大，每次梯度下降的幅度越大，反之越小。在下面四个图中，上方两个图分别描述了学习速率过大和过小的情况。如果学习速率过大，有可能跳过最低点，反而无法收敛。如果学习速率过小，收敛过于缓慢，无法适应大规模问题。左下图表示，当到达最低点时，代价函数将不会再发生移动，达到收敛状态。右下图表示，只要最初定好学习速率，不用中途随时调整，因为随着下降的过程，下降的曲线会变缓，步长会变小，不需要调整学习速率以免跳过最低点。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/dce5649a27cf5b825ba9d7a0edd3c77eaa3f8b72c502b04c3bbe741f6b4beb25)

综合上文中所描述的假设函数h、代价函数J以及梯度下降算法中系数的下降函数，可以得到单变量线性回归模型中假设函数系数的回归模型。

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/ed1ea1e1cdd355f9bce551656543900616e73335e6fe1397f82bfe5dfd24ee36)

![](/image/dan_bian_liang_xian_xing_hui_gui_mo_xing_jie_shao/2b0d08ef67afe218864853b01b64c1fffd84809a41de308e5ddd0f6cd3998597)

本文简单描述了机器学习中一类入门模型：单变量线性回归模型。图片素材来自吴恩达机器学习视频课程。PPT已上传文档。

