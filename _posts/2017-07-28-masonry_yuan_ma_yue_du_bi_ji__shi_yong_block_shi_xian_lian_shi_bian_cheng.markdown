---
layout: post
title: "Masonry源码阅读笔记——使用Block实现链式编程"
date: 2017-07-28 00:01:00 +0800
categories: ios
author: jakchen
tags: masonry block 链式编程 iOS
---

* content
{:toc}

| 导语 前段时间在阅读Masonry源码时，看到其内部使用了链式编程，比较有趣，这里简单分享一下；

在OC中实现链式编程并不难，最常用的实现是使用Block，具体包括以下几个要点：

1）对于要实现链式编程的函数，使用Block作为其返回值；
<!--more-->

2）作为返回值的Block，需在执行后Return自身；

这里看起来似乎不太好理解，下面通过一个例子来说明：

    
    
    @interface Box : NSObject
    
    - (Box *(^)(CGFloat width))setWidth;
    - (Box *(^)(CGFloat height))setHeight;
    - (Box *(^)())setProperty;
    - (Box *(^)())build;
    
    @end
    
    @implementation Box
    
    - (Box *(^)(CGFloat width))setWidth {
        return ^(CGFloat width){
            NSLog(@"Set width : %f.", width);
            return self;
        };
    }
    
    - (Box *(^)(CGFloat height))setHeight {
        return ^(CGFloat height){
            NSLog(@"Set height : %f.", height);
            return self;
        };
    }
    
    - (Box *(^)())setProperty {
        return ^{
            NSLog(@"Set other property.");
            return self;
        };
    }
    
    - (Box *(^)())build {
        return ^{
            NSLog(@"A box is built.");
            return self;
        };
    }
    
    @end
    
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            Box *box = [Box new];
            box.setWidth(10.f).setHeight(10.f).setProperty().build();
        }
        return 0;
    }

 在对象通过点语法调用函数时，返回了一个Block，在执行Block后，又返回了对象本身，这样就能将多个函数调用串联起来，实现链式的效果；

代码执行后为：

![](/image/masonry_yuan_ma_yue_du_bi_ji__shi_yong_block_shi_xian_lian_shi_bian_cheng/2539d7c85c85658cd418ea411532cde94090cac9fa3e6a8a0ea842f888c399da)

当然，链式编程很多时候并没有实际意义，例如上面的Demo，完全可以采用下面的实现：

    
    
    @interface Box : NSObject
    
    - (Box *)setWidth:(CGFloat)width;
    - (Box *)setHeight:(CGFloat)height;
    - (Box *)build;
    
    @end
    
    @implementation Box
    
    - (Box *)setWidth:(CGFloat)width {
        NSLog(@"Set width : %f.", width);
        return self;
    }
    
    - (Box *)setHeight:(CGFloat)height {
        NSLog(@"Set height : %f.", height);
        return self;
    }
    
    - (Box *)build {
        NSLog(@"A box is built.");
        return self;
    }
    
    @end
    
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            Box *box = [Box new];
            [[[box setWidth:10.f] setHeight:10.f] build];
        }
        return 0;
    }

但这样写一开始还能接受，链条一长时就会出现一堆恶心的中括号，这也是OC一直让人诟病的点；使用Block，形式上会美观许多；

当然，一般情况下还是不推荐链式编程的，因为这么写除了美观外毫无意义（个人愚见）；但对于一些特殊的情况，例如使用Bulider模式，这么写可以使代码可读性更好，所以说，具体做法还是要视情况而定；

