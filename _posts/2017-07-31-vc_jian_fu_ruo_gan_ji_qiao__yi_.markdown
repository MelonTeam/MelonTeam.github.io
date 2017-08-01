---
layout: post
title: "VC减负若干技巧（一）"
date: 2017-07-31 18:23:00 +0800
categories: ios
author: lilinli
tags: VC 腐烂
---

* content
{:toc}

| 导语 VC代码的膨胀和臃肿，是业界普遍问题，网上很多文章也都在讨论如何给VC减负，这里总结一下我看过的文章提出的一些减负技巧

随着业务的变更和增加，VC的代码也随着庞大和臃肿，有些一开始设计不好的VC，更是随着时间推移，慢慢变成一场灾难。我的一个感受，某些模块的代码不是万不得已我是不敢点开看的。

为什么会出现这种问题呢？  貌似VC的膨胀和臃肿，确实也是业界普遍问题，网上很多文章也都在讨论如何给VC减负，这里总结一下我看过的文章提出的一些减负技巧。
<!--more-->

1 首先是要有清晰的CodeStyle

我觉得这个真正是最重要的东西。我们知道，基本一个VC的代码都会被不同的开发同学去修改，后面的人一般都会遵循前面的CodeStyle，所以第一个版本的CodeStyle是否够清晰，决定了后续加入的代码是否清晰，往往第一个版本CodeStyle就很糟糕的代码，第二第三个版本只会更糟糕。下面是看到一篇[文章](https://casatwy.com
/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-
an.html)推荐的CodeStyle，个人觉得挺好的，比较清晰，推荐大家借鉴学习。

![](/image/vc_jian_fu_ruo_gan_ji_qiao__yi_/c292d02d3f85fd4a9771179e382695d739342cdc35b61c4eb0180fcf8369a4ec)

2 拆VC

这个也是老生常谈了，关键是要怎么拆，我们天天说mvc，mvc，都知道c是负责协调v和m的，那到底协调是什么？这个概念非常抽象，存DB算不算协调，监听通知算不算协调？因为没有很明确的分界线，所以才不知道这块代码到底应该放在VC内还是VC外。这里我尝试提出一个分界线，VC的责任应该是拿到数据（从model取数据），然后展示数据（在View展示数据）。我们拿这个标准再来看看当前代码，应该如何拆VC。

我以手Q日迹主页这个类来做例子来讲。

![](/image/vc_jian_fu_ruo_gan_ji_qiao__yi_/06dd70c2e81fbf4f88635cb876aa853275df248c81885057a040ca25df31f5f2)

主页代码由一个主文件和若干个category组成,

    
    
    QQStoryViewController 		2874行，
    QQStoryViewController+TableView 2005行
    QQStoryViewController+Notification  849行
    QQStoryViewController+VideoPublish 954行

可以看到，这个类的已经非常庞大了，从名字也大概可以猜出各自的功能。然后我们按照上面的思路来拆分VC，首先QQStoryViewController+VideoPublish，发表视频相关的API，这个跟拉取数据和展示数据关系都不大，所以肯定可以拆出去。

![](/image/vc_jian_fu_ruo_gan_ji_qiao__yi_/bc3b6e0efc13ec15f7680c80f2fd218e6f81142bcf758621741fb72753763203)

打开文件看了一下代码，这块其实已经剥离出去了，但是不知道什么原因文件名字没有改，让人看了疑惑。

继续看QQStoryViewController+Notification，这个category主要处理通知，按照我们上面定义的分界线，处理通知后一般要刷新UI，所以其属于展示数据的一环，是VC的协调职能，理论上应该放在VC内。但其实仔细分析，一般我们响应通知会做下面操作：

1 不带数据的通知，直接刷新整个UI

2 带数据的通知，先转化数据，再局部更新UI

第一种场景可以直接调VC的接口，第二种场景数据需要进行转化，理论上要先经过数据层做处理或者筛选才能到VC这一层来，所以这里建议通知还是移到VC外，不要放进VC。VC通过实现必要的protocol或者提供重刷接口，让通知层来调用。

再看看主页代码里的处理，

![](/image/vc_jian_fu_ruo_gan_ji_qiao__yi_/77cf96c44aac5ca6b2f3c005149331af6df9e7a278ec9635e958954d2fab60e8)

其实这个category的拆分思路，跟上面说的差不多，不过我建议还是拆成独立的类，不要以category的方式来实现。

接着，我们再来看QQStoryViewController+TableView。顾名思义，这里是处理tableview相关逻辑的地方。关于tableview的拆分，这里有篇[文章](https://www.objc.io/issues/1
-view-controllers/lighter-view-
controllers/)大家可以参考一下，其设计思路就是添加一个中间类，把tableviewcell的创建和返回委托出去，我们也可以用工厂来实现。这种方式的一个好处就是，这个中间类的代码是可以复用的，所有用到tableview的地方都能用，可以减少很多代码，然后代码集中一处，也有通用的规范和便于管理。

    
    
    @implementation ArrayDataSource
    
    - (id)itemAtIndexPath:(NSIndexPath*)indexPath {
        return items[(NSUInteger)indexPath.row];
    }
    
    - (NSInteger)tableView:(UITableView*)tableView 
     numberOfRowsInSection:(NSInteger)section {
        return items.count;
    }
    
    - (UITableViewCell*)tableView:(UITableView*)tableView 
            cellForRowAtIndexPath:(NSIndexPath*)indexPath {
        id cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                  forIndexPath:indexPath];
        id item = [self itemAtIndexPath:indexPath];
        configureCellBlock(cell,item);
        return cell;
    }
    
    @end  
    

VC的调用：

    
    
    void (^configureCell)(PhotoCell*, Photo*) = ^(PhotoCell* cell, Photo* photo) {
       cell.label.text = photo.name;
    };
    photosArrayDataSource = [[ArrayDataSource alloc] initWithItems:photos
                                                    cellIdentifier:PhotoCellIdentifier
                                                configureCellBlock:configureCell];
    self.tableView.dataSource = photosArrayDataSource;
    

