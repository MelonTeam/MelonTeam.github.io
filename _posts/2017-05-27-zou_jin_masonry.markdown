---
layout: post
title: "走进 masonry"
date: 2017-05-27 19:58:00
categories: ios
author: pikachuqiu
tags: autolayo... masonry
---

* content
{:toc}

| 导语 masonry 源码阅读

在阅读这篇文章之前，你需要对两块东西有明确的了解

1、autolayout, 至少能够知道并使用过
<!--more-->

    
    
    /* create constraints explicitly.  constraints are of the form "view1.attr1 = view2.attr2 * multiplier + constant" 
     if your equation does not have a second view and attribute, use nil and nslayoutattributenotanattribute.
     */
    +(instancetype)constraintwithitem:(id)view1 attribute:(nslayoutattribute)attr1 relatedby:(nslayoutrelation)relation toitem:(nullable id)view2 attribute:(nslayoutattribute)attr2 multiplier:(cgfloat)multiplier constant:(cgfloat)c;
    

这个 api, 因为 `masonry` 本质最后调用的就是这个

2、设计模式
[composite](https://en.wikipedia.org/wiki/composite_pattern)，如果你还不清楚该设计模式，你需要
google 看看对应的文章

—————————————————— 回归正题 ——————————————————

首先简单看一下 masonry 主要的设计以及 class 结构方法，这是一个经典的 `composite` 设计模式

![](/image/zou_jin_masonry/8c6e704af29919c593cdd467aefaadbf8bd41d6d4d8488133b637ecd3e1aac6c)

另外还有一个辅助的 class `masconstraintmaker`

![](/image/zou_jin_masonry/4ec3e1d2e9b91a075aaccc989655b251bed470c0bfa7a2eb634b8d2f603ed6b8)

其中 `left`、`right` 等方法分别被定义在了 `masconstraint` 和 `masconstraintmaker`
中，具体的内部实现稍微不同

看完了上面类设计图，我们开始跟踪程序

`masonry` 开始于这样的代码结构

    
    
    - (void)viewdidload {
        [super viewdidload];
    
        uiview *aview = [[uiview alloc] init];
        [self.view addsubview:aview];
    
        [aview mas_makeconstraints:^(masconstraintmaker *make) {
            make.top.equalto(self.view);
            make.left.right.equalto(@0);
        }];
    }
    

其中， `mas_makeconstraints` 方法在 `view+masadditions`(由于还有 macos 平台，所以 这里的view
被定义为 `nsview` 或者 `uiview`) 被定义

    
    
    - (nsarray *)mas_makeconstraints:(void(^)(masconstraintmaker *))block {
        self.translatesautoresizingmaskintoconstraints = no;
        masconstraintmaker *constraintmaker = [[masconstraintmaker alloc] initwithview:self];
        block(constraintmaker);
        return [constraintmaker install];
    }
    

代码的第一行关闭 autoresizingmask， 相当于让 autolayout 开始生效

第二行创建了一个 `masconstraintmaker`(`masconstraintmaker` 与 `masconstraint` 一样 定义了
`left` `right` 等方法) 对象，也就进行链式操作`make.left.right.equalto` 的开始，创建了所谓的 `maker`.

第三行执行代码 `block(constraintmaker)`， 也就是执行我们写的 `make.left.right.equalto` 的代码

下面开始解析这一段链式代码(``make.left.right.equalto`)

`masconstraintmaker` 内部有一个 `nsmutablearray *constraints` 对象， `constraints`
保存了每一条 make 出来的信息，比如如果你写这样的代码

    
    
    make.top.equalto(self.view);
    make.left.right.equalto(@0);
    make.bottom.equalto(self.view)
    

`constraints` 将会保存 3 个对象，第一个对象记录了 `make.top.equalto(self.view)` 的所有信息，第二个对象记录了
`make.left.right.equalto([@0](https://github.com/0 "@0" ))` 的所有信息，第三个对象记录了
`make.bottom.equalto(self.view)`，而对象的数据结构就是上图中的 `masviewconstraint` 和
`mascompositeconstraint`

接下来，我们开始解析 `masviewconstraint` 和
`mascompositeconstraint`这两个对象，也就是一个`mascompositeconstraint` 或者 一个
`masviewconstraint`
是如何存储一个类似于`make.left.right.equalto([@0](https://github.com/0 "@0"
));`这样一条链式信息的 ：

先看第一个层级：

    
    
    make.top
    

调用顺序如下：

    
    
    - (masconstraint *)top {
        return [self addconstraintwithlayoutattribute:nslayoutattributetop];
    }
    
    
    
    - (masconstraint *)addconstraintwithlayoutattribute:(nslayoutattribute)layoutattribute {
        return [self constraint:nil addconstraintwithlayoutattribute:layoutattribute];
    }
    
    
    
    - (masconstraint *)constraint:(masconstraint *)constraint addconstraintwithlayoutattribute:(nslayoutattribute)layoutattribute {
        masviewattribute *viewattribute = [[masviewattribute alloc] initwithview:self.view layoutattribute:layoutattribute];
        masviewconstraint *newconstraint = [[masviewconstraint alloc] initwithfirstviewattribute:viewattribute];
    //    if ([constraint iskindofclass:masviewconstraint.class]) {
    //        //replace with composite constraint
    //        nsarray *children = @[constraint, newconstraint];
    //        mascompositeconstraint *compositeconstraint = [[mascompositeconstraint alloc] initwithchildren:children];
    //        compositeconstraint.delegate = self;
    //        [self constraint:constraint shouldbereplacedwithconstraint:compositeconstraint];
    //        return compositeconstraint;
    //    }
        if (!constraint) {
            newconstraint.delegate = self;
            [self.constraints addobject:newconstraint];
        }
        return newconstraint;
    }
    

其中上面注释的代码是本次调用不会运行的，后面会讲到注释掉的代码的作用

介绍一下 `masviewattribute`

`masviewattribute` 的 class 结构如下图

![](/image/zou_jin_masonry/7ba4c05c76f16fe4040a8a60313017ac935c820739eca6fd0bc1c1d676d3915e)

上面的 item 字段，`masonry` 上给的是 `id` 字段，因为 还有 `uiviewcontroller` 的 `toplayoutguide`
属性，这里 为了方便理解，可以把`item`直接直接看作 `uiview`

剩余的代码很简单，只是根据 top 这个属性，新建你一个 `masviewconstraint` 的对象，然后为 `masviewconstraint`
创建 `firstviewattribute` (这里还没有生成 `secondviewattribute`)

相当于下面的代码：

    
    
    //self  是外部的 [aview mas_makeconstraints] 的 aview
    masviewconstraint *newconstraint.firstviewattribute.item = self.view //外部调用 make.top 的 aview
    newconstraint.firstviewattribute.layoutconstraint = nslayoutattributetop
    

最后 把 这个 `newconstraint` 加入到 `masconstraintmaker(make)` 的 `constraints` 对象中

这样 完成了 `make.top` 的操作 （`.equalto` 的操作稍后介绍），也就是让`constraints`对象保存了所有 `make.top`
的信息

接着，我们看第二句（和 `make.top` 的区别在于这句话有 2 个链式结构构成）

    
    
    make.left.right
    

其中，前面半句 `make.left` 和上面的步骤是一样的，不同的地方在于后面 `.right`

首先，前半句 `make.left` 返回了 `masattribute(masviewconstraint)`对象。注意，这里返回的已经不是
`masconstraintmaker(make)` 对象了。所以 我们需要看看 `masviewconstraint` 的 `left`
方法做了那些事情。

调用顺序如下：

    
    
    - (masconstraint *)left {
        return [self addconstraintwithlayoutattribute:nslayoutattributeleft];
    }
    
    
    
    - (masconstraint *)addconstraintwithlayoutattribute:(nslayoutattribute)layoutattribute {
        nsassert(!self.haslayoutrelation, @"attributes should be chained before defining the constraint relation");
    
        return [self.delegate constraint:self addconstraintwithlayoutattribute:layoutattribute];    //这里 delegate 指向了刚刚的 `masconstraintmaker(make)` 对象
    }
    
    
    
    - (masconstraint *)constraint:(masconstraint *)constraint addconstraintwithlayoutattribute:(nslayoutattribute)layoutattribute {
        masviewattribute *viewattribute = [[masviewattribute alloc] initwithview:self.view layoutattribute:layoutattribute];
        masviewconstraint *newconstraint = [[masviewconstraint alloc] initwithfirstviewattribute:viewattribute];
        if ([constraint iskindofclass:masviewconstraint.class]) {
            //replace with composite constraint
            nsarray *children = @[constraint, newconstraint];
            mascompositeconstraint *compositeconstraint = [[mascompositeconstraint alloc] initwithchildren:children];
            compositeconstraint.delegate = self;
            [self constraint:constraint shouldbereplacedwithconstraint:compositeconstraint];
            return compositeconstraint;
        }
    //    if (!constraint) {
    //        newconstraint.delegate = self;
    //        [self.constraints addobject:newconstraint];
    //    }
        return newconstraint;
    }
    

方法通过某个协议以及 `delegate` 重新调用回到了 `masconstraintmaker(make)` 的

    
    
    - (masconstraint *)constraint:(masconstraint *)constraint addconstraintwithlayoutattribute:(nslayoutattribute)layoutattribute
    

方法。但是，这一次最后这个函数的执行了上阶段注释的代码，这段代码和之前的代码相同，也是先创建了一个 `masviewconstraint` 的对象。
不同之处在于这次组成了一个 `mascompositeconstraint`，`mascompositeconstraint` 的
`childconstraints` 放了上次的 `make.left` 的信息和这次 `make.right` 的信息，并且 用
`mascompositeconstraint` 替换了原来的 `masviewconstraint`。 (这里希望你理解 `composite`
设计模式的精髓, 因为 类似这种`make.left.right.top`三连以上的链式句式 `mascompositeconstraint`
里面放的是两个`mascompositeconstraint`)

这里不太好理解，可以这么想：一个 `masviewconstraint` 就是一个文件(文件系统的文件)，一个
`mascompositeconstraint` 就是一个文件夹，每一个 `.left`、`.right` 这样的 layout
就是一个文件。于是，`make.left`, 创建了一个文件 fileleft，`make.left.right` 在创建 fileleft 的基础上了一个
文件 fileright（代表着 `right`），之后又创建了一个文件夹叫做 folderleftright, 这个文件夹里面放了 fileleft 与
fileright。当链式变成更多之后，比如 `make.left.right.bottom`, 就会创建一个 folderleftrightbottom
这样的文件夹，里面放了一个文件夹 folderleftright 和一个文件 filebottom, folderleftright 里面有 2 个文件夹
fileleft 和 fileright。接下来，如果更多的链式也保持一样的道理，再添加一个文件夹而已，模型大致是这样

![](/image/zou_jin_masonry/7bd1c3a86d6d0d52d38a63c0562dc558ef292f7593f47d49d53e74060310a122)

箭头表示这个 `masconstraint` 在哪一个 `mascompositeconstraint` 的
`childconstraints`，而最终被保存的数据结构，就是 root 所代表的那个 `mascompositeconstraint`
（如果只有一层，则是 `masviewconstraint`，因为他们同时继承自 `masconstraint`）

最后是 `equalto` 的语法

先看一下 `equalto` 的定义

    
    
    - (masconstraint * (^)(id attr))equalto
    

划重点了：`equalto` 是一个 返回 `masconstraint *` 里面包括一个参数 `attr` 名为 `equalto` 的 block

之所以是 `attr` 被定义为 `id` 是因为 我们可以写出这样的代码

    
    
    make.left.equalto(self.view) 或者 make.left.equalto(@0)
    

整个 equalto 的调用顺序如下（`self` 是 `masconstraint`对象）

    
    
    - (masconstraint * (^)(id))equalto {
        return ^id(id attribute) {
            return self.equaltowithrelation(attribute, nslayoutrelationequal);
        };
    }
    
    
    
    - (masconstraint * (^)(id, nslayoutrelation))equaltowithrelation {
        return ^id(id attribute, nslayoutrelation relation) {
    //        if ([attribute iskindofclass:nsarray.class]) {
    //            nsassert(!self.haslayoutrelation, @"redefinition of constraint relation");
    //            nsmutablearray *children = nsmutablearray.new;
    //            for (id attr in attribute) {
    //                masviewconstraint *viewconstraint = [self copy];
    //                viewconstraint.layoutrelation = relation;
    //                viewconstraint.secondviewattribute = attr;
    //                [children addobject:viewconstraint];
    //            }
    //            mascompositeconstraint *compositeconstraint = [[mascompositeconstraint alloc] initwithchildren:children];
    //            compositeconstraint.delegate = self.delegate;
    //            [self.delegate constraint:self shouldbereplacedwithconstraint:compositeconstraint];
    //            return compositeconstraint;
    //        } else {
                nsassert(!self.haslayoutrelation || self.layoutrelation == relation && [attribute iskindofclass:nsvalue.class], @"redefinition of constraint relation");
                self.layoutrelation = relation;
                self.secondviewattribute = attribute;
                return self;
    //        }
        };
    }
    

这里 我只列举出了 `masviewconstraint` 的 `equaltowithrelation`， 因为 `composite`
模式中`mascompositeconstraint` 的 `equaltowithrelation` 其实就是让所有的子类依次去执行
`equaltowithrelation`，最终也就是让 `masviewconstraint` 去执行
`equaltowithrelation`的。就像我们算文件和文件夹的 filesize 道理一样，文件夹占用固定的
4k（举个:chestnut:），文件夹真正的大小就是算他下面的每一个文件大小，遇到文件夹，继续递归下去计算。

另外，看一下 `masviewconstraint` 的 `secondviewattribute` 被定义

    
    
    - (void)setsecondviewattribute:(id)secondviewattribute {
        if ([secondviewattribute iskindofclass:nsvalue.class]) {
            [self setlayoutconstantwithvalue:secondviewattribute];
        } else if ([secondviewattribute iskindofclass:mas_view.class]) {
            _secondviewattribute = [[masviewattribute alloc] initwithview:secondviewattribute layoutattribute:self.firstviewattribute.layoutattribute];
        } else if ([secondviewattribute iskindofclass:masviewattribute.class]) {
            _secondviewattribute = secondviewattribute;
        } else {
            nsassert(no, @"attempting to add unsupported attribute: %@", secondviewattribute);
        }
    }
    

这也是为什么我们能够让`equalto` 后面可以接 `nsnumber` 和 `uiview` 甚至是 `nsvalue`

    
    
    make.left.equalto(@0) // make.left.equalto(self.view)
    

好了，到此为止，所有的链式代码已经解读完毕，至于 类似的 `offset` 道理都一样，相对简单，这里不再做过多的陈述。

最后是 `[constraintmaker install]` 的代码

调用函数如下(`self` 是 `masconstraintmaker`)：

    
    
    - (nsarray *)install {
        if (self.removeexisting) {
            nsarray *installedconstraints = [masviewconstraint installedconstraintsforview:self.view];
            for (masconstraint *constraint in installedconstraints) {
                [constraint uninstall];
            }
        }
        nsarray *constraints = self.constraints.copy;   
        for (masconstraint *constraint in constraints) {
            constraint.updateexisting = self.updateexisting;
            [constraint install];
        }
        [self.constraints removeallobjects];
        return constraints;
    }
    

上面的代码 `removeexisting` 是 `mas_remakeconstraints` 做的事情， `masonry` 用一个
`mutableset` 记录了所有通过 `masonry` 创建的 constraint， 这个 `set` 被定义在了
`masconstraints.m` 里面

    
    
    #define mas_view uiview
    
    @interface mas_view (masconstraints)
    
    @property (nonatomic, readonly) nsmutableset *mas_installedconstraints;
    
    @end
    
    @implementation mas_view (masconstraints)
    
    static char kinstalledconstraintskey;
    
    - (nsmutableset *)mas_installedconstraints {
        nsmutableset *constraints = objc_getassociatedobject(self, &kinstalledconstraintskey);
        if (!constraints) {
            constraints = [nsmutableset set];
            objc_setassociatedobject(self, &kinstalledconstraintskey, constraints, objc_association_retain_nonatomic);
        }
        return constraints;
    }
    
    @end
    

每次通过 `masonry` 添加最后添加成功的 `constraint` 都会被加入到这个 `set` 里面

函数的最后把所有添加到 `masconstraintmaker` 的 `constraints` 的数组清空（因为所有的 `constraint`
都已经被加入到了 `view` 里），这里也不是什么重点，可以直接跳过。

最后 我们看看 `install` 的代码

    
    
    nsarray *constraints = self.constraints.copy;   //这里为什么用 copy 我也不是很清楚作者是怎么想的，可能是出于线程安全的考虑
    for (masconstraint *constraint in constraints) {
        constraint.updateexisting = self.updateexisting;
        [constraint install];
    }
    

`[constraint install]` 也是利用了 `composite` 设计模式的特性（希望你能真正理解 `composite` ）

`masviewconstraint` 的 install 实现：

    
    
    - (void)install {
        if (self.hasbeeninstalled) {
            return;
        }
    
        if ([self supportsactiveproperty] && self.layoutconstraint) {
            self.layoutconstraint.active = yes;
            [self.firstviewattribute.view.mas_installedconstraints addobject:self];
            return;
        }
    
        mas_view *firstlayoutitem = self.firstviewattribute.item;
        nslayoutattribute firstlayoutattribute = self.firstviewattribute.layoutattribute;
        mas_view *secondlayoutitem = self.secondviewattribute.item;
        nslayoutattribute secondlayoutattribute = self.secondviewattribute.layoutattribute;
    
        // alignment attributes must have a secondviewattribute
        // therefore we assume that is refering to superview
        // eg make.left.equalto(@10)
        if (!self.firstviewattribute.issizeattribute && !self.secondviewattribute) {
            secondlayoutitem = self.firstviewattribute.view.superview;      
            secondlayoutattribute = firstlayoutattribute;
        }
        ////---------截止这里的代码都很好理解 就是在配好 nslayoutconstraint 的所有 item 和 attribute， 而这些东西在之前的 make 链式语法都组装好了---------////
    
        ////---------其中 masonry 自己的注释也写明白了 为什么 make.left.equalto(@10) 这样的代码能够被组装成 nslayoutconstraint---------////     
        //maslayoutconstraint 可以简单的认为就是 nslayoutconstraint
        maslayoutconstraint *layoutconstraint
            = [maslayoutconstraint constraintwithitem:firstlayoutitem
                                            attribute:firstlayoutattribute
                                            relatedby:self.layoutrelation
                                               toitem:secondlayoutitem
                                            attribute:secondlayoutattribute
                                           multiplier:self.layoutmultiplier
                                             constant:self.layoutconstant];
    
        layoutconstraint.priority = self.layoutpriority;
        layoutconstraint.mas_key = self.mas_key;
    
        if (self.secondviewattribute.view) {
            mas_view *closestcommonsuperview = [self.firstviewattribute.view mas_closestcommonsuperview:self.secondviewattribute.view];
            nsassert(closestcommonsuperview,
                     @"couldn't find a common superview for %@ and %@",
                     self.firstviewattribute.view, self.secondviewattribute.view);
            self.installedview = closestcommonsuperview;
        } else if (self.firstviewattribute.issizeattribute) {
            self.installedview = self.firstviewattribute.view;
        } else {
            self.installedview = self.firstviewattribute.view.superview;
        }
    
    
        maslayoutconstraint *existingconstraint = nil;
        if (self.updateexisting) {
            existingconstraint = [self layoutconstraintsimilarto:layoutconstraint];
        }
        if (existingconstraint) {
            // just update the constant
            existingconstraint.constant = layoutconstraint.constant;
            self.layoutconstraint = existingconstraint;
        } else {
            [self.installedview addconstraint:layoutconstraint];
            self.layoutconstraint = layoutconstraint;
            [firstlayoutitem.mas_installedconstraints addobject:self];
        }
    }
    

这段代码是 install 的最后一个步骤，整体来说比较简单，就是把 `masviewconstraint` 变成 `nslayoutconstraint`
加入到具体的 `uiview` 当中，如果你还不清楚怎么用系统的 api 写 `autolayout` 的话，需要去了解一下。

其中 `mas_closestcommonsuperview` 是找 `firstviewattribute.view` 和
`secondviewattribute.view` 的共同公共的父 `view`, 这里的算法很简单，只是单纯的遍历

    
    
    - (instancetype)mas_closestcommonsuperview:(mas_view *)view {
        mas_view *closestcommonsuperview = nil;
    
        mas_view *secondviewsuperview = view;
        while (!closestcommonsuperview && secondviewsuperview) {
            mas_view *firstviewsuperview = self;
            while (!closestcommonsuperview && firstviewsuperview) {
                if (secondviewsuperview == firstviewsuperview) {
                    closestcommonsuperview = secondviewsuperview;
                }
                firstviewsuperview = firstviewsuperview.superview;
            }
            secondviewsuperview = secondviewsuperview.superview;
        }
        return closestcommonsuperview;
    }
    

截止为止，`masonry` 的 `mas_makeconstraints` 的整个过程全部分析完毕，对于剩下的
`mas_remakeconstraints` 和 `mas_updateconstraints` 大同小异，这里不再做更多陈述

