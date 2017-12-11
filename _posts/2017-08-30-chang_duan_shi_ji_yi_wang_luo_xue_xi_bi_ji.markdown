---
layout: post
title: "长短时记忆网络学习笔记"
date: 2017-08-30 20:23:00 +0800
categories: ai
author: yellowye
tags: 神经网络
---

* content
{:toc}

| 导语  一个机器学习算法包含两个主要部分  （1）模型从输入特征x预测输入y的函数f（x）； （2）目标函数
目标函数取最小(最大)值时所对应的参数值，就是模型的参数的最优值。我们往往只能获得目标函数的局部最小(最大)值，因此也只能得到模型参数的局部最优值，而常见求最优解的算法是梯度下降/上升算法。
而神经网络算法是实现机器学习的其中一种方法，为了适应不同的输入特征应用场景，神经网络算法也有很多种变形，这里只是简单的介绍下长短时记忆网络，做个笔记。


<!--more-->

    
    
    背景

全连接神经网络和卷积神经网络的特点是只能单独的取处理一个个的输入，前一个输入和后一个输入是完全没有关系的，而循环神经网络就可以处理序列性较强的信息，即前后输入有依赖关系的场景，但是其误差项沿时间反向传播的公式容易产生梯度消失的问题；

什么叫梯度消失？

假设某次训练中，各个时刻的梯度之和如下（盗图）：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/85d4651d5dd576ebb54b0b83ce84d893b6b8d496da3db1795f471774f12ffc2a)

而权重数组**W**的最终梯度是各个时刻的梯度之和：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/b3151473e065abd95bd6f8b48573354d144d94af37077e86065ef7e6a277d740)

从图中可以看到在t-3时刻，梯度开始接近为0了，再向前走的时刻中也几乎为0，所以安照反向传播更新的思想，t-3及其之前接近0的时刻都不会对权重w有更新
，也就相当于网络忽略了t-3时刻之前的状态，这就是梯度消失导致的原始循环神经网络无法处理较长距离依赖的原因。

  
长短时记忆网络也是一种循环神经网络，它的产生背景是为了解决原始循环神经网络误差项沿时间反向传播的公式容易产生梯度消失的问题。

    
    
    什么是长短时记忆网络

如下图所示，该网络由长短时记忆层堆砌而成，可用于提取时序视频帧中的时空特征。

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/5d30d07e4a66d28ef7a80f9cc399d26a0e74e96d76a8ea887fb9bbf2c683975e)

每个长短时记忆单元包括1个输入门、1个输出门、1个忘记门和1个记忆元组；具体来讲，输入门用于对输入进行预处理，输出门用于对输出做后处理，忘记门用于控制记忆元组，对记忆元组记录的内容进行自适应地遗忘。更具体的公式表示如下。

输入门：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/65967d000ec5b8f5a65d9b6fe89ec2d1745a86ede420014c1b6d36f6d407c7a5)

遗忘门：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/a2288a178ce25e4d2c80e4b1b2404d0e6d15d63337a71bc6a894b9c531f6810b)

记忆元组：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cb351ce948b1a59f9a3b24ce847a41422d8c3596e079eb2085190b3c20d073d8)

输出门：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/fc64217dd116bc161997ecd737bc21cac4030f1ffb439a9f5c5b9426a0c6d926)

输出：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/374b5e79e4608fe34699a0d47ca18f0e2c2fababd8fee2674cf1d0aac531daa6)

第_t_帧输入门、忘记门和输出门分别由![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/34cd8326a6810a3d1d0ae596c6ca9cea69b8f0b42a034ff56d8663e3a0118bd3)、![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/fe3a253ebb0bb6d037b160100cc997218f043ebe7b0c9bd6b59115904e809e31)、![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/88dd1914f7124662f839700307c350b110c087e6861b3345bcf695d530cc9dd6)表示，记忆单元![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/dd57265d91abb407347b1c9d6892d64f5dbb589651b47a2d26723c3b73d7ab42)（时序上不同时间的记忆单元状态不同，![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/40c1bbf8901d1b973ea59ca8f0a8f1759e44df352812cfaa49eb140c0f25c24a)和![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/332e442727603919b853ea2c2fa3943c38e456aebe25f195bbfe9c45ac23a657
)分别表示在t和t-
1时刻的记忆元组状态）。![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cec58c0157e366319c20673a84aa574d940409d63c5d65d4123d69146fd3a664)表示在t时刻的输入特征（可以为中间特征图或原图像），![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cc895ce713ea36956f6f427570143dd24de847980f07378b703b4c69dac8a2cb)表示门的偏置（![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cce6f12d01c44ba8d3bb2c4b046dc988519be284ad18b82c4e2940825d88eea2)依次表示输入门、忘记门和输出门的偏置），![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/1442c01f72c74780a898c56dcf9ac65821dc02fa52101cbb5cc45658d85f183a)表示门的权重（![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/fa861d0ab4e0ab589c694a4d7599e6a351ad5b23e43b6a9d0fe68a2bd4b7dc29)依次表示输入门、忘记门和输出门的权重），σ表示sigmoid激活函数，tanh表示tanh函数，*和∘分别表示矩阵乘法操作和点乘操作，![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/f68a2eeba95116f10579fb3f76258ea75d8b77af96b6090486924afa55c66b51)和![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/f373c5573b0d603eba7011fc0ca47591df7e333d20fe0897e8fdb6fe2c432bde
)分别表示在t和t-
1时刻的输出特征。在进行前向传播的时候，输入包括t时刻的输入特征![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cec58c0157e366319c20673a84aa574d940409d63c5d65d4123d69146fd3a664
)和t-
1时刻的输出特征![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/f373c5573b0d603eba7011fc0ca47591df7e333d20fe0897e8fdb6fe2c432bde)，从而通过计算得到![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/f68a2eeba95116f10579fb3f76258ea75d8b77af96b6090486924afa55c66b51)。

注意：这里的门是指常规的矩阵乘法操作，直接作用与输入的特征图![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/cec58c0157e366319c20673a84aa574d940409d63c5d65d4123d69146fd3a664)，不能够很好的保留数据的二维空间结构信息，只能有限地对时序信息进行表达。为解决这一难题，Shi
[2]
提出了长短时记忆卷积层，即用卷积操作来替代矩阵乘法操作，以能够保留数据的二维空间结构信息，结合记忆元组对时序信息的建模，能够有效地学习出二维时序与空间结构特征（时空特征）。



**应用示例：周期性三维人体姿势机 (CVPR 2017)**

姿态估计是计算机视觉研究的一个重要领域，其主要任务是让计算机能够自动地感知场景中的人“在哪里”和判断人在“干什么”，它的应用包括智能监控、病人监护和一些涉及人机交互的系统。人体姿势的目标是希望能够自动地从未知的视频中（例如，一段图像帧）中推测人体各个部分的姿态参数（例如，关节点坐标）。通过这些姿态参数可以在三维空间中重建人体的动作，为整个场景的语义理解奠定基础。

为解决这一问题，Lin [3] 提出了周期性三维人体姿势机。

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/5a830668704595e73806befb70b7fab1a87039beb63f98a3f9bc9b2d5b1f3412)

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/a7a37b97aaec315958c0f446b9c01c6b47d2ffc729bb0ee079450f744ab7f0b6)

如上图所示，该姿势机由互相串联的卷积神经网络和长短时记忆网络构成，整体来看分为三个阶段，渐进式地修正预测出的三维姿势。每个阶段可分为二维姿势、特征适配和三维姿势周期等三个模块。二维姿势模块使用全卷积神经网络对视频数据进行逐帧处理，提取二维图像中人物的二维人体关节点特征；特征适配模块将二维图像中人物的二维人体关节点特征转化到三维人体关节点坐标相关的特征空间；
三维姿势周期模块使用长短时记忆网络结合当前帧及其之前的连续多帧二维图像的特征信息，预测出当前帧二维图像的三维人体关节点坐标。
单个阶段的模块详细结构如下图所示：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/ec37fa1ff745e40f1f5d2a5bc03d1a41ec958861bc764c5731acb178dc089de9)



    
    
    其中，网络结构的参数如下：

**序号**

|

**1**

|

**2**

|

**3**

|

**4**

|

**5**

|

**6**

|

**7**

|

**8**

|

**9**  
  
---|---|---|---|---|---|---|---|---|---  
  
**名称**

|

**conv1_1**

|

**conv1_1**

|

**pool_1**

|

**conv2_1**

|

**conv2_2**

|

**pool_2**

|

**conv3_1**

|

**conv3_2**

|

**conv3_3**  
  
**通道数**

**(****核大小****-****步长****)**

|

**64(3-1)**

|

**64(3-1)**

|

**64(2-2)**

|

**128(3-1)**

|

**128(3-1)**

|

**128(2-2)**

|

**256(3-1)**

|

**256(3-1)**

|

**256(3-1)**  
  
**序号**

|

**10**

|

**11**

|

**12**

|

**13**

|

**14**

|

**15**

|

**16**

|

**17**

|

**18**  
  
** **

|

** **

|

** **

|

** **

|

** **

|

** **

|

** **

|

** **

|

** **

|

** **  
  
**通道数**

**(****核大小****-****步长****)**

|

**256(3-1)**

|

**256(2-2)**

|

**512(3-1)**

|

**256(3-1)**

|

**256(3-1)**

|

**256(3-1)**

|

**256(3-1)**

|

**256(3-1)**

|

**128(3-1)**  
  
**序号**

|

**19**

|

**20**

|

**21**

|

**22**

|

**23**

|

**24**

|

**25**

|  |  
  
**名称**

|

**conv5_1**

|

**conv5_2**

|

**conv6_1**

|

**conv6_2**

|

**fc_1**

|

**lstm**

|

**fc_2**

|  |  
  
**通道数**

**(****核大小****-****步长****)**

|

**128(3-1)**

|

**128(3-1)**

|

**128(5-2)**

|

**128(5-2)**

|

**1024**

|

**1024**

|

**51**

|  |  
      
    
     
    
    
    **训练目标**

计算训练样本中真实的三维人体关节点坐标与预测的三维人体关节点坐标的误差；采用时序反向传播算法求长短时记忆网络中各个参数的偏导数；根据长短时记忆网络传入的残差，通过反向传播算法求卷积神经网络中各个参数的偏导数；根据计算结果更新模型参数并重复迭代计算。

具体地，先求解训练样本中真实的三维人体关节点坐标与预测的三维人体关节点坐标之间的损失函数![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/a50d77730a676da42dd3d9b2a5155802cc53c0a455795422dacc11e20e921c5d)，然后求得其对于参数![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/20af08b109cf5c3a88ab2b0c6d27280c665efec5344dbefc786f61c5451895bb)的梯度，采用Adam算法更新![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/9100318e1520aa063bcb473db92c9d44316e8073437daa236622e35200aefb30)，总的损失函数![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/a50d77730a676da42dd3d9b2a5155802cc53c0a455795422dacc11e20e921c5d)定义为：

![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/3be5a8a8adb845282cf9e4e1e68999c7f405d72f37f2adfaa4eaea5ad2c6b8a1)

    
    
    其中，![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/36650221bd0bc9489878ae8ac1ac5b71c88935c4f56a39beafa1e8333e88b31a)为输入深度模型的连续帧数目，K为关节点数目，![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/910763cd9520f4bb695e81c647a67767cca9d7a50aadbb071362de832f2281a2)为前向传播算法预测的三维人体关节点坐标，![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/726bc8f330d49df02f89ea342e65f0c8d29ec0af41eb7e3a3bc81226cb3045c5)为训练样本中真实的三维人体关节点坐标。
    
    
     
    
    
    **实验结果**
    
    
    在大规模数据集Human3.6M上实验验证如下，该方法超越了现有最先进的方法，三维姿势预测误差小到了73.10，比现有最好的方法提升了21.52%。![](/image/chang_duan_shi_ji_yi_wang_luo_xue_xi_bi_ji/c62a602df24a762dbeb95a389a137c95707d3a39f7554405281dd48fbd9c19fb)
    
    
    根据作者的实验，仅舍弃长短时记忆网络后，三维姿势预测误差才为81.12。即长短时记忆网络提升了10%的性能。
    
    
    ** **
    
    
    **引用**
    
    
    [1]                      S. _Hochreiter_ and J. _Schmidhuber_, Long short-term memory, Neural Computation, vol. 9, no. 8, pp. 1735--1780, 1997.
    
    
    [2]                      X. Shi, Z. Chen, H. Wang, D.-Y. _Yeung_, W.-k. Wong and W.-c. WOO, Convolutional lstm network: A machine learning approach for precipitation nowcasting, in Advances in Neural Information Processing Systems (NIPS), pp. 802—810, 2015.
    
    
    [3]                        Mude Lin, Liang Lin, Xiaodan Liang, Keze Wang, Hui Cheng. Recurrent 3D Pose Sequence Machines, CVPR 2017.  
    [](https://zybuluo.com/hanbingtao/note/581764)
    
    
    [4]                       零基础入门深度学习(6) - 长短时记忆网络(LSTM)<https://zybuluo.com/hanbingtao/note/581764>
    
    
     



