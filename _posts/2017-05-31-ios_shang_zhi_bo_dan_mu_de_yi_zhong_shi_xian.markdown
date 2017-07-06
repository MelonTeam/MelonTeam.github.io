---
layout: post
title: "iOS上直播弹幕的一种实现"
date: 2017-05-31 11:57:00
categories: ios
author: nicema
tags: 弹幕实现 iOS
---

* content
{:toc}



### **一、弹幕简介**

所谓弹幕，就是评论的一种表现形式，更能吸引用户眼球，增强用户体验，增加用户参与感和使用粘度。用户可以在观看内容（视频为主）的同时查看其他人对这个视频的评论，而不需要找到对应的评论区查看。现在视频网站基本都已经实现了弹幕，深受年轻用户的追捧和喜爱。
<!--more-->

弹幕分类有很多种，PC上比较常见的一种弹幕是从屏幕右侧进入并从屏幕左侧飞出，全屏弹幕能造成一种比较“震撼”的感觉。在手机上，有很多产品和场景也采用相同方式。但是受屏幕大小限制，可能另一种弹幕方式更常见常见，例如过重直播软件中，弹幕通常出现在弹幕的左下角的固定区域，从下往上出现。

        日迹播放场景中，视频评论也是以弹幕的方式在视频的左下角出现，其形式更像是将评论逐一展示出来。下面详细分析下日迹场景弹幕的实现方式。

### **二、弹幕分析**

         日迹弹幕总体可以划分成三个部分：评论数据、展现形式、滚动方式。

评论数据模块，包括拉取逻辑，这个部分跟业务比较相关。评论的数据，来自用户对日迹的评论，目前来看，评论数据是纯文本，比较简单。拉取逻辑也相对比较简单，就不详细说明。

日迹弹幕的展现形式比较简单，只是展示纯文本，没有比较复杂的展现形式的动画。当然，设计弹幕方案的时候，考虑到产品形态的变更，后期弹幕展示需要变得丰富，或者展示图片之类的，现在设计的系统也要能够支持快速变更和迭代。

日迹的滚动经过了两个版本的调整，第一个版本匀速滚动，第二个版本是评论逐条滚动，滚动到最后一条，停止滚动，然后动画渐隐消失。整体来讲，也只是调整滚动速度等。

弹幕开始滚动的前提是已经拉到评论数据，因此，弹幕的启动是由数据来驱动的。弹幕这里的整体设计思想，想使整套实现能够实现定制化。因此，这三个部分需要以一种比较灵活的方式组合在一起。

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/1cfe1a180560e57cddfcc6f8c886e79f89602765f92200a80945771ebd659618)

上图是整体设计思路，将滚动方式、展示形式和数据模块分成三个部分。

1、QAutoRollTableView本质是个tableview，这个类本身只关注滚动逻辑，比方说滚动频率，幅度等，还有一个功能就是提供一套接口控制滚动的启动和暂停，供调用方式用。其tableview的DataSource由QAutoRollDataSource来提供。

2、QAutoRollDataSource作为tableview的数据源，可以指定每个cell的展示样式。这个类本身可以被各个业务继承过去，然后根据业务需要指定cell样式。其内部还会持有维护一个很重要的类，QAutoRollDataModel
，由这个model提供弹幕需要展示的数据。

3、弹幕数据由QAutoRollDataModel提供，这个model目前来讲，只是提供一些接口，各个业务可以自己继承过去，做业务自己的逻辑。dataModel拉取到数据后，通过delegate反向驱动tableView开始刷新滚动。

### **三、弹幕实现**

       1、QAutoRollTableView 下图给的就是滚动弹幕的tableview接口，接口作用如图中注释。

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/3dd723e29de19e83d8e92822126be72b6ee629ef7878189ec12967ede0c2d548)

        2、QAutoRollDataSource
初始化需要制定一个dataModel,由dataModel来提供弹幕数据，和驱动力。这个对象本身需要只需要制定每个cell的样式和展示逻辑即可。

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/d299b2aad05322c49a17b5d3f8cbc3b16865257e5f89b9b5109f23541cc330ba)

3、dataModel本身就相对简单，只需要关注业务本身的拉取逻辑即可。准备好数据后，需要通过delegate通知到tableview，开始滚动

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/436d9481426611c56b8da8831b09d478eb3477819c38c15ac6621915b4ea2c3f)

     日迹的弹幕提供了一个通用的显示纯文本的弹幕控件，下图中cellForRow方法由
QAutoRollTableTextDataSource提供，指定纯文本显示。

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/82fc31c036853fff3de6394df429162e60378ff82b014ce75b7cee2425cda2b8)

![](/image/ios_shang_zhi_bo_dan_mu_de_yi_zhong_shi_xian/d002c9d69dbc657bf06b84bef15e6545036bd1fa3093b90eb68f3a622f9c90c3)

以上是我在做日迹需求中实现弹幕的一套方案，写的比较仓促，接口设计上，可能不是很友好，希望大家批评指正。

