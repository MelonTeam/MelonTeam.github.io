---
layout: post
title: "老司机用神经网络带您安全驾驶"
date: 2017-04-24 16:06:00
categories: android
author: richardcliu
tag: 深度学习 神经网络
---

* content
{:toc}


# 0 概述

> 

随着今年深度学习的热潮的来临，神经网络已经被应用在越来越多的应用中。而在印象中对于神经网络进行训练的往往需要借助大量的计算资源与数据。其实通过一定的方法，配合预训练好的网络，我们完全可以在自己的pc上训练出一个准确率较高、实用性也非常不错的网络。下面我就以kaggle上的一个竞赛为例，带领各位司机训练一个对<strong>驾驶行为</strong>进行分类的网络。


<!--more-->


首先我们了解一下需要解决的问题: 我们有一位老司机，可惜开车时不太专心，一会儿`喝饮料`一会儿`打电话`又或是在`玩手机`， 并在驾驶过程中不断的变化着自己的姿势。碰到这样的老司机，我们有没有办法提醒他安全驾驶呢？

设想如果我们能在他的汽车上装上一枚摄像头，并通过实时图片采集他的行为。最终通过<strong>神经网络分析他的动作行为</strong>，善意的提醒他安全驾驶的姿势。

这看起来是不是很酷~~ 装上摄像头的汽车采集到的数据，就像下图这样:<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/32b329f20a8dce7a2aad6c51039d682e8ade5ce3554a53fa9e1a4c40f6c05f8f"/><br/>接着这一问题转换成了神经网络，即对10种类型的图片进行分类预测的问题，这10种行为分别是:

```
'0.正常开车' '1.右手玩手机' '2.右手打电话' '3.左手玩手机' '4.左手打电话' 

'5.操作收音机' '6.喝东西' '7.向后伸手' '8.化妆', '9.说话'
```

 <img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/dc7002c3e0e90b49196626951d03202b9b69aa20fc1bb81830b398249eb8a3de"/>

而训练数据所需要用的数据库，大家可以在kaggle网页上自行下载，这里是网址[kaggle statefarm](https://www.kaggle.com/c/state-farm-distracted-driver-detection)

## 1. 训练准备

### 1.1 下载训练数据

了解了问题之后，我们开始准备我们的训练数据。 第一份数据可以在[kaggle](https://www.kaggle.com/c/state-farm-distracted-driver-detection)网站上下载到。在下面图中的这个页面中，我们只需要下载images.zip这个4gb的文件即可。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/0e6f41d13b0f7e8c77690c06abdb71edc30346dbeac4e46c927877716cdb0a9e"/>

下载完成之后，我们将这个zip包解开，将看到下面这样的目录结构:

```
└── train

    ├──c0

    │   ├── img_1.jpg

    │   ├── img_2.jpg

    │   ├── ...

    ├──c1

    ├──...

    ├──c9    

└── valid

    ├──c0

    ├──c1

    ├──...

    ├──c9
```

稍微解释一下， `train`目录是给我们训练用的目录，里面一共有`c0`到`c9`十个分类，对应我们刚刚列出的 `0.正常开车` `1.右手玩手机` `2.右手打电话` 等十种行为。在这个训练集中一共包含22,286张图片。

而`valid`目录是给我们校验的目录，也同样是`c0`到`c9`十个分类，但它只有115张图片，主要的作用是用对训练好的神经网络进行校验，稍后我们也会用到它。

### 1.2 自己拍摄数据

由于训练数据比较少，加上 <strong>死磕自己，娱乐大家</strong> 的的精神，作为老司机我也上“车”试上一把。:)

纯手工打造一台“汽车”并参与到训练中去并不难，而所需要的东西如下:

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/70cbe276dfd564328ac16d442b12c166b77499aed904a109bf07075e769e4042"/><img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/3db0ea2558f508e7b454a58578ab60dce31ec9c4fbab5a47a48e3cb261bf9d4c"/>

就这样不停的变换姿势，一共拍摄了200张不同姿势的开车照片，并依照不同的类别放置在刚刚的的train目录对应的分类中。同时也放少量的照片到valid目录中，注意要保证train和valid目录中的照片不重复。

### 1.3 产生更多数据

最后，如果数据还觉得不够的话，我们可以对数据再做一次<strong>data augmentation</strong>，这样可以产生更多的训练数据。

比如对<strong>同一张照片</strong>做颜色和角度偏移就可以得到多张不同的照片，如下图所示，这些照片对训练也是相当有帮助的。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/3aec93f73e18a5587ad86b2baee069318b2eb85d3244016efa23e8345f646e3b"/>

好啦~万事俱备，各位老司机坐好了，我们马上准备开车了~

## 2. 开始训练

### 2.1. 迁移学习

终于到了训练的步骤，问题是我们手头上只有一台普通的开发机器:`corei7`, `8g内存`，`gtx660`。比起各大云服务器上动辄几百g+几十个核心的服务器，需要通过这样一台机器训练一个<strong>稍显复杂的网络</strong>真的是有点难堪。

所以这里向各位老司机推荐<strong>迁移学习</strong>中的一个小tricky，名曰 fine-tune。关于fine-tune的更详细的步骤大家可以在这里得到(配有源码):[finetuning alexnet with tensorflow](https://kratzert.github.io/2017/02/24/finetuning-alexnet-with-tensorflow.html)

而这里提到的fine-tune如果总结一下的话，主要原理可以理解成如下三步骤:

`step1`: 首先我们需要获得一个预先训练好的网络，如下图中的vgg16网络。

`step2`: 我们将网络中的后三个全连接层去掉，只留下前面的卷基层和pooling层。

`step3`: 加入新的全连接层， 冻结之前所有层，仅仅训练新加入的全链接层。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/a9ff297c5e6df82661c0ca940284994256bca590f897262fc5aecfc0d8f1f052"/>

了解了基本原理之后，我们开始根据自己的实际做 fine-tune。注意，这里我们要处理的是一个<strong>十分类</strong>问题，也就是说，我们的网络最后要有10个输出。所以我大概做了这样一个包含一个隐藏层的全连接网络，附加到vgg16的末端:

```
(full) (none, 256)   # 上接vgg16  

(full) (none, 256)   # 一个隐藏层

(full) (none, 10)    # 输出10个分类
```

### 2.2. 训练网络

之后我们将vgg16的前面14层冻结，开始训练后面的三层。冻结网络层，其权重值在训练过程中不会发生任何变化。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/4c7f735dcd8bef23ecb0e3aa8cc92490d7d6cdddcd68e73998761ec36715f125"/>

有了之前的工作，这个训练就变得和普通全连接网络的训练过程完全一样了。

在我的nvidia geforce gtx660 上用了<strong>12个小时</strong>， 一共跑了30个epoch，每个epoch将我们准备好的2400张照片作为输入。学习速率我这里设置到<strong>0.0001</strong>这样一个数值，

最终loss函数值稳定在<strong>0.0262</strong>。看到loss函数呈现如下图中基本上不下降了之后，即可以结束训练了。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/526109222552f65a65da9d0e04b2fbc29134a0e2f7cd39073b625718523787df"/>

## 3 检验结果

### 3.1 简单预测

ok~ ，进过漫长的等待。我们终于可以使用这个网络了~ 现在开始使用刚刚数据库中的校验集，也就是valid目录中的图片。先简单的传入10张图片看看网络的预测结果呗。这10张图片的`正确类型`的动作行为编号分别是[1 1 1 2 0 3 3 0 3 2]。而网络输出的结果是[1 1 1 2 0 3 4 0 3 2]。貌似还不错，只是有点小错误。如下是正确结果和预测结果的比较:

```
[1 1 1 2 0 3 4 0 3 2] # predict

[1 1 1 2 0 3 3 0 3 2] # correct
```

 如果将结果用matpilot输出出来的话会更加直观。如下图是输入网络的10个照片，每张图片的<strong>标题是预测结果`</strong>，发现只有<strong>红框</strong>中的那一张出现了预测错误的问题。

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/ada89a589c859fbcce030163fddf985a7a0eded43a1c21ae31ed76f17b7f40f2"/>

我们再尝试对state farm数据库中的照片做一下分类，10张照片中同样发生了一个错误的预测(红框内为错误的预测):

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/45b1f3d6091651b6c0b6213dd3c9ce45bcd6cc16a07e7ae4c7ab6d4e8272a59b"/>

### 3.2 结果分析

那是不是我们可以认为网络的准确率在90%呢？网络最容易出现错误的预测是哪几类图片呢？

对于这两个问题，尝试对所有的校验集数据做一个预测，并将最终的结果打印成一个<strong>confusion_matrix</strong>就会有答案了。在这个矩阵中，用每一行表示神经网络预测的结果，每一列表示正确的结果。输出以后它是这个样子的:

```
#confusion_matrix

     ([[ 49,   0,   0,   0,   0,   0,   0,   0,   0,   0],

       [  0,  76,   0,   0,   0,   0,   0,   0,   0,   0],

       [  0,   0, 106,   0,   0,   0,   0,   0,   0,   0],

       [  1,   0,   0, 114,   0,   0,   0,   0,   0,   0],

       [  0,   0,   0,   5,  93,   0,   0,   0,   0,   0],

       [ 16,   0,   5,   1,   0,  73,   0,   0,   0,   0],

       [  5,  13,  11,   6,   1,   0,  72,   0,   0,   0],

       [  2,   0,   0,   0,   0,   0,   0, 105,   0,   1],

       [ 13,   1,   5,   0,   1,   0,   0,   0,  84,   6],

       [ 38,   0,   2,   0,   0,   0,   0,   0,   0,  65]])
```

<img src="/image/lao_si_ji_yong_shen_jing_wang_luo_dai_nin_an_quan_jia_shi/edbb66bc75e6f6d63e0afae703c7c70ed5b6853cb232796acf9a3d4a9a7e44c1"/>

分析一下， 我们可以将对角线上的所有数据加起来，得到网络的准确率是<strong>86.3%</strong>。

再具体一点，可以看出最难区分清楚的是<strong>' '3.左手玩手机' '4.左手打电话' </strong>，后续如果增加3、4这两个分类的话，那么网络的准确率还有更大的提升。

## 4 结语

通过整个实验过程，我们发现通过神经网络解决复杂图片的分类问题并不复杂，只需要通过一些小的技巧，训练网络的计算资源也并非很大。86.3%的正确率这一结果也还比较理想~

最后我把本文中用到的一些重要的资料再列举一下，原文、源码、数据都在了，各位老司是不是跃跃欲试了~ :)

[finetuning alexnet with tensorflow blog](https://kratzert.github.io/2017/02/24/finetuning-alexnet-with-tensorflow.html)

[finetuning alexnet with tensorflow code](https://github.com/kratzert/finetune_alexnet_with_tensorflow)

[kaggle state farm](https://www.kaggle.com/c/state-farm-distracted-driver-detection)



<p class="md_block">本文发表于[melonteam](http://km.oa.com/group/25894)，转载请联系作者获得授权。
