---
layout: post
title: "走进 Masonry"
date: 2017-05-27 19:58:00 +0800
categories: ios
author: pikachuqiu
tags: autolayout masonry
---

* content
{:toc}

| 导语 Masonry 源码阅读

在阅读这篇文章之前，你需要对两块东西有明确的了解

1、AutoLayout, 至少能够知道并使用过
<!--more-->

    
    
    /* Create constraints explicitly.  Constraints are of the form "view1.attr1 = view2.attr2 * multiplier + constant" 
     If your equation does not have a second view and attribute, use nil and NSLayoutAttributeNotAnAttribute.
     */
    +(instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1 relatedBy:(NSLayoutRelation)relation toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c;
    

这个 API, 因为 `Masonry` 本质最后调用的就是这个

2、设计模式
[Composite](https://en.wikipedia.org/wiki/Composite_pattern)，如果你还不清楚该设计模式，你需要
Google 看看对应的文章

—————————————————— 回归正题 ——————————————————

首先简单看一下 Masonry 主要的设计以及 Class 结构方法，这是一个经典的 `Composite` 设计模式

![](/image/zou_jin_masonry/8c6e704af29919c593cdd467aefaadbf8bd41d6d4d8488133b637ecd3e1aac6c)

另外还有一个辅助的 Class `MASConstraintMaker`

![](/image/zou_jin_masonry/4ec3e1d2e9b91a075aaccc989655b251bed470c0bfa7a2eb634b8d2f603ed6b8)

其中 `left`、`right` 等方法分别被定义在了 `MASConstraint` 和 `MASConstraintMaker`
中，具体的内部实现稍微不同

看完了上面类设计图，我们开始跟踪程序

`Masonry` 开始于这样的代码结构

    
    
    - (void)viewDidLoad {
        [super viewDidLoad];
    
        UIView *aview = [[UIView alloc] init];
        [self.view addSubview:aview];
    
        [aview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.right.equalTo(@0);
        }];
    }
    

其中， `mas_makeConstraints` 方法在 `View+MASAdditions`(由于还有 macOS 平台，所以 这里的View
被定义为 `NSView` 或者 `UIView`) 被定义

    
    
    - (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *))block {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
        block(constraintMaker);
        return [constraintMaker install];
    }
    

代码的第一行关闭 AutoresizingMask， 相当于让 AutoLayout 开始生效

第二行创建了一个 `MASConstraintMaker`(`MASConstraintMaker` 与 `MASConstraint` 一样 定义了
`left` `right` 等方法) 对象，也就进行链式操作`make.left.right.equalTo` 的开始，创建了所谓的 `maker`.

第三行执行代码 `block(constraintMaker)`， 也就是执行我们写的 `make.left.right.equalTo` 的代码

下面开始解析这一段链式代码(``make.left.right.equalTo`)

`MASConstraintMaker` 内部有一个 `NSMutableArray *constraints` 对象， `constraints`
保存了每一条 make 出来的信息，比如如果你写这样的代码

    
    
    make.top.equalTo(self.view);
    make.left.right.equalTo(@0);
    make.bottom.equalTo(self.view)
    

`constraints` 将会保存 3 个对象，第一个对象记录了 `make.top.equalTo(self.view)` 的所有信息，第二个对象记录了
`make.left.right.equalTo([@0](https://github.com/0 "@0" ))` 的所有信息，第三个对象记录了
`make.bottom.equalTo(self.view)`，而对象的数据结构就是上图中的 `MASViewConstraint` 和
`MASCompositeConstraint`

接下来，我们开始解析 `MASViewConstraint` 和
`MASCompositeConstraint`这两个对象，也就是一个`MASCompositeConstraint` 或者 一个
`MASViewConstraint`
是如何存储一个类似于`make.left.right.equalTo([@0](https://github.com/0 "@0"
));`这样一条链式信息的 ：

先看第一个层级：

    
    
    make.top
    

调用顺序如下：

    
    
    - (MASConstraint *)top {
        return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTop];
    }
    
    
    
    - (MASConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
        return [self constraint:nil addConstraintWithLayoutAttribute:layoutAttribute];
    }
    
    
    
    - (MASConstraint *)constraint:(MASConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
        MASViewAttribute *viewAttribute = [[MASViewAttribute alloc] initWithView:self.view layoutAttribute:layoutAttribute];
        MASViewConstraint *newConstraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
    //    if ([constraint isKindOfClass:MASViewConstraint.class]) {
    //        //replace with composite constraint
    //        NSArray *children = @[constraint, newConstraint];
    //        MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
    //        compositeConstraint.delegate = self;
    //        [self constraint:constraint shouldBeReplacedWithConstraint:compositeConstraint];
    //        return compositeConstraint;
    //    }
        if (!constraint) {
            newConstraint.delegate = self;
            [self.constraints addObject:newConstraint];
        }
        return newConstraint;
    }
    

其中上面注释的代码是本次调用不会运行的，后面会讲到注释掉的代码的作用

介绍一下 `MASViewAttribute`

`MASViewAttribute` 的 Class 结构如下图

![](/image/zou_jin_masonry/7ba4c05c76f16fe4040a8a60313017ac935c820739eca6fd0bc1c1d676d3915e)

上面的 item 字段，`Masonry` 上给的是 `id` 字段，因为 还有 `UIViewController` 的 `topLayoutGuide`
属性，这里 为了方便理解，可以把`item`直接直接看作 `UIView`

剩余的代码很简单，只是根据 top 这个属性，新建你一个 `MASViewConstraint` 的对象，然后为 `MASViewConstraint`
创建 `firstViewAttribute` (这里还没有生成 `secondViewAttribute`)

相当于下面的代码：

    
    
    //self  是外部的 [aView mas_makeConstraints] 的 aView
    MASViewConstraint *newConstraint.firstViewAttribute.item = self.view //外部调用 make.top 的 aview
    newConstraint.firstViewAttribute.layoutConstraint = NSLayoutAttributeTop
    

最后 把 这个 `newConstraint` 加入到 `MASConstraintMaker(make)` 的 `constraints` 对象中

这样 完成了 `make.top` 的操作 （`.equalTo` 的操作稍后介绍），也就是让`constraints`对象保存了所有 `make.top`
的信息

接着，我们看第二句（和 `make.top` 的区别在于这句话有 2 个链式结构构成）

    
    
    make.left.right
    

其中，前面半句 `make.left` 和上面的步骤是一样的，不同的地方在于后面 `.right`

首先，前半句 `make.left` 返回了 `MASAttribute(MASViewConstraint)`对象。注意，这里返回的已经不是
`MASConstraintMaker(make)` 对象了。所以 我们需要看看 `MASViewConstraint` 的 `left`
方法做了那些事情。

调用顺序如下：

    
    
    - (MASConstraint *)left {
        return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeft];
    }
    
    
    
    - (MASConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
        NSAssert(!self.hasLayoutRelation, @"Attributes should be chained before defining the constraint relation");
    
        return [self.delegate constraint:self addConstraintWithLayoutAttribute:layoutAttribute];    //这里 delegate 指向了刚刚的 `MASConstraintMaker(make)` 对象
    }
    
    
    
    - (MASConstraint *)constraint:(MASConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
        MASViewAttribute *viewAttribute = [[MASViewAttribute alloc] initWithView:self.view layoutAttribute:layoutAttribute];
        MASViewConstraint *newConstraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
        if ([constraint isKindOfClass:MASViewConstraint.class]) {
            //replace with composite constraint
            NSArray *children = @[constraint, newConstraint];
            MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
            compositeConstraint.delegate = self;
            [self constraint:constraint shouldBeReplacedWithConstraint:compositeConstraint];
            return compositeConstraint;
        }
    //    if (!constraint) {
    //        newConstraint.delegate = self;
    //        [self.constraints addObject:newConstraint];
    //    }
        return newConstraint;
    }
    

方法通过某个协议以及 `delegate` 重新调用回到了 `MASConstraintMaker(make)` 的

    
    
    - (MASConstraint *)constraint:(MASConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute
    

方法。但是，这一次最后这个函数的执行了上阶段注释的代码，这段代码和之前的代码相同，也是先创建了一个 `MASViewConstraint` 的对象。
不同之处在于这次组成了一个 `MASCompositeConstraint`，`MASCompositeConstraint` 的
`childConstraints` 放了上次的 `make.left` 的信息和这次 `make.right` 的信息，并且 用
`MASCompositeConstraint` 替换了原来的 `MASViewConstraint`。 (这里希望你理解 `Composite`
设计模式的精髓, 因为 类似这种`make.left.right.top`三连以上的链式句式 `MASCompositeConstraint`
里面放的是两个`MASCompositeConstraint`)

这里不太好理解，可以这么想：一个 `MASViewConstraint` 就是一个文件(文件系统的文件)，一个
`MASCompositeConstraint` 就是一个文件夹，每一个 `.left`、`.right` 这样的 layout
就是一个文件。于是，`make.left`, 创建了一个文件 fileLeft，`make.left.right` 在创建 fileLeft 的基础上了一个
文件 fileRight（代表着 `right`），之后又创建了一个文件夹叫做 folderLeftRight, 这个文件夹里面放了 fileLeft 与
fileRight。当链式变成更多之后，比如 `make.left.right.bottom`, 就会创建一个 folderLeftRightBottom
这样的文件夹，里面放了一个文件夹 folderLeftRight 和一个文件 fileBottom, folderLeftRight 里面有 2 个文件夹
fileLeft 和 fileRight。接下来，如果更多的链式也保持一样的道理，再添加一个文件夹而已，模型大致是这样

![](/image/zou_jin_masonry/7bd1c3a86d6d0d52d38a63c0562dc558ef292f7593f47d49d53e74060310a122)

箭头表示这个 `MASConstraint` 在哪一个 `MASCompositeConstraint` 的
`childConstraints`，而最终被保存的数据结构，就是 root 所代表的那个 `MASCompositeConstraint`
（如果只有一层，则是 `MASViewConstraint`，因为他们同时继承自 `MASConstraint`）

最后是 `equalTo` 的语法

先看一下 `equalTo` 的定义

    
    
    - (MASConstraint * (^)(id attr))equalTo
    

划重点了：`equalTo` 是一个 返回 `MASConstraint *` 里面包括一个参数 `attr` 名为 `equalTo` 的 block

之所以是 `attr` 被定义为 `id` 是因为 我们可以写出这样的代码

    
    
    make.left.equalTo(self.view) 或者 make.left.equalTo(@0)
    

整个 equalTo 的调用顺序如下（`self` 是 `MASConstraint`对象）

    
    
    - (MASConstraint * (^)(id))equalTo {
        return ^id(id attribute) {
            return self.equalToWithRelation(attribute, NSLayoutRelationEqual);
        };
    }
    
    
    
    - (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation {
        return ^id(id attribute, NSLayoutRelation relation) {
    //        if ([attribute isKindOfClass:NSArray.class]) {
    //            NSAssert(!self.hasLayoutRelation, @"Redefinition of constraint relation");
    //            NSMutableArray *children = NSMutableArray.new;
    //            for (id attr in attribute) {
    //                MASViewConstraint *viewConstraint = [self copy];
    //                viewConstraint.layoutRelation = relation;
    //                viewConstraint.secondViewAttribute = attr;
    //                [children addObject:viewConstraint];
    //            }
    //            MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
    //            compositeConstraint.delegate = self.delegate;
    //            [self.delegate constraint:self shouldBeReplacedWithConstraint:compositeConstraint];
    //            return compositeConstraint;
    //        } else {
                NSAssert(!self.hasLayoutRelation || self.layoutRelation == relation && [attribute isKindOfClass:NSValue.class], @"Redefinition of constraint relation");
                self.layoutRelation = relation;
                self.secondViewAttribute = attribute;
                return self;
    //        }
        };
    }
    

这里 我只列举出了 `MASViewConstraint` 的 `equalToWithRelation`， 因为 `Composite`
模式中`MASCompositeConstraint` 的 `equalToWithRelation` 其实就是让所有的子类依次去执行
`equalToWithRelation`，最终也就是让 `MASViewConstraint` 去执行
`equalToWithRelation`的。就像我们算文件和文件夹的 fileSize 道理一样，文件夹占用固定的
4k（举个:chestnut:），文件夹真正的大小就是算他下面的每一个文件大小，遇到文件夹，继续递归下去计算。

另外，看一下 `MASViewConstraint` 的 `secondViewAttribute` 被定义

    
    
    - (void)setSecondViewAttribute:(id)secondViewAttribute {
        if ([secondViewAttribute isKindOfClass:NSValue.class]) {
            [self setLayoutConstantWithValue:secondViewAttribute];
        } else if ([secondViewAttribute isKindOfClass:MAS_VIEW.class]) {
            _secondViewAttribute = [[MASViewAttribute alloc] initWithView:secondViewAttribute layoutAttribute:self.firstViewAttribute.layoutAttribute];
        } else if ([secondViewAttribute isKindOfClass:MASViewAttribute.class]) {
            _secondViewAttribute = secondViewAttribute;
        } else {
            NSAssert(NO, @"attempting to add unsupported attribute: %@", secondViewAttribute);
        }
    }
    

这也是为什么我们能够让`equalTo` 后面可以接 `NSNumber` 和 `UIView` 甚至是 `NSValue`

    
    
    make.left.equalTo(@0) // make.left.equalTo(self.view)
    

好了，到此为止，所有的链式代码已经解读完毕，至于 类似的 `offset` 道理都一样，相对简单，这里不再做过多的陈述。

最后是 `[constraintMaker install]` 的代码

调用函数如下(`self` 是 `MASConstraintMaker`)：

    
    
    - (NSArray *)install {
        if (self.removeExisting) {
            NSArray *installedConstraints = [MASViewConstraint installedConstraintsForView:self.view];
            for (MASConstraint *constraint in installedConstraints) {
                [constraint uninstall];
            }
        }
        NSArray *constraints = self.constraints.copy;   
        for (MASConstraint *constraint in constraints) {
            constraint.updateExisting = self.updateExisting;
            [constraint install];
        }
        [self.constraints removeAllObjects];
        return constraints;
    }
    

上面的代码 `removeExisting` 是 `mas_remakeConstraints` 做的事情， `Masonry` 用一个
`MutableSet` 记录了所有通过 `Masonry` 创建的 constraint， 这个 `set` 被定义在了
`MASConstraints.m` 里面

    
    
    #define MAS_VIEW UIView
    
    @interface MAS_VIEW (MASConstraints)
    
    @property (nonatomic, readonly) NSMutableSet *mas_installedConstraints;
    
    @end
    
    @implementation MAS_VIEW (MASConstraints)
    
    static char kInstalledConstraintsKey;
    
    - (NSMutableSet *)mas_installedConstraints {
        NSMutableSet *constraints = objc_getAssociatedObject(self, &kInstalledConstraintsKey);
        if (!constraints) {
            constraints = [NSMutableSet set];
            objc_setAssociatedObject(self, &kInstalledConstraintsKey, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return constraints;
    }
    
    @end
    

每次通过 `Masonry` 添加最后添加成功的 `constraint` 都会被加入到这个 `set` 里面

函数的最后把所有添加到 `MASConstraintMaker` 的 `constraints` 的数组清空（因为所有的 `constraint`
都已经被加入到了 `View` 里），这里也不是什么重点，可以直接跳过。

最后 我们看看 `install` 的代码

    
    
    NSArray *constraints = self.constraints.copy;   //这里为什么用 copy 我也不是很清楚作者是怎么想的，可能是出于线程安全的考虑
    for (MASConstraint *constraint in constraints) {
        constraint.updateExisting = self.updateExisting;
        [constraint install];
    }
    

`[constraint install]` 也是利用了 `Composite` 设计模式的特性（希望你能真正理解 `Composite` ）

`MASViewConstraint` 的 install 实现：

    
    
    - (void)install {
        if (self.hasBeenInstalled) {
            return;
        }
    
        if ([self supportsActiveProperty] && self.layoutConstraint) {
            self.layoutConstraint.active = YES;
            [self.firstViewAttribute.view.mas_installedConstraints addObject:self];
            return;
        }
    
        MAS_VIEW *firstLayoutItem = self.firstViewAttribute.item;
        NSLayoutAttribute firstLayoutAttribute = self.firstViewAttribute.layoutAttribute;
        MAS_VIEW *secondLayoutItem = self.secondViewAttribute.item;
        NSLayoutAttribute secondLayoutAttribute = self.secondViewAttribute.layoutAttribute;
    
        // alignment attributes must have a secondViewAttribute
        // therefore we assume that is refering to superview
        // eg make.left.equalTo(@10)
        if (!self.firstViewAttribute.isSizeAttribute && !self.secondViewAttribute) {
            secondLayoutItem = self.firstViewAttribute.view.superview;      
            secondLayoutAttribute = firstLayoutAttribute;
        }
        ////---------截止这里的代码都很好理解 就是在配好 NSLayoutConstraint 的所有 item 和 attribute， 而这些东西在之前的 make 链式语法都组装好了---------////
    
        ////---------其中 masonry 自己的注释也写明白了 为什么 make.left.equalTo(@10) 这样的代码能够被组装成 NSLayoutConstraint---------////     
        //MASLayoutConstraint 可以简单的认为就是 NSLayoutConstraint
        MASLayoutConstraint *layoutConstraint
            = [MASLayoutConstraint constraintWithItem:firstLayoutItem
                                            attribute:firstLayoutAttribute
                                            relatedBy:self.layoutRelation
                                               toItem:secondLayoutItem
                                            attribute:secondLayoutAttribute
                                           multiplier:self.layoutMultiplier
                                             constant:self.layoutConstant];
    
        layoutConstraint.priority = self.layoutPriority;
        layoutConstraint.mas_key = self.mas_key;
    
        if (self.secondViewAttribute.view) {
            MAS_VIEW *closestCommonSuperview = [self.firstViewAttribute.view mas_closestCommonSuperview:self.secondViewAttribute.view];
            NSAssert(closestCommonSuperview,
                     @"couldn't find a common superview for %@ and %@",
                     self.firstViewAttribute.view, self.secondViewAttribute.view);
            self.installedView = closestCommonSuperview;
        } else if (self.firstViewAttribute.isSizeAttribute) {
            self.installedView = self.firstViewAttribute.view;
        } else {
            self.installedView = self.firstViewAttribute.view.superview;
        }
    
    
        MASLayoutConstraint *existingConstraint = nil;
        if (self.updateExisting) {
            existingConstraint = [self layoutConstraintSimilarTo:layoutConstraint];
        }
        if (existingConstraint) {
            // just update the constant
            existingConstraint.constant = layoutConstraint.constant;
            self.layoutConstraint = existingConstraint;
        } else {
            [self.installedView addConstraint:layoutConstraint];
            self.layoutConstraint = layoutConstraint;
            [firstLayoutItem.mas_installedConstraints addObject:self];
        }
    }
    

这段代码是 install 的最后一个步骤，整体来说比较简单，就是把 `MASViewConstraint` 变成 `NSLayoutConstraint`
加入到具体的 `UIView` 当中，如果你还不清楚怎么用系统的 API 写 `AutoLayout` 的话，需要去了解一下。

其中 `mas_closestCommonSuperview` 是找 `firstViewAttribute.view` 和
`secondViewAttribute.view` 的共同公共的父 `View`, 这里的算法很简单，只是单纯的遍历

    
    
    - (instancetype)mas_closestCommonSuperview:(MAS_VIEW *)view {
        MAS_VIEW *closestCommonSuperview = nil;
    
        MAS_VIEW *secondViewSuperview = view;
        while (!closestCommonSuperview && secondViewSuperview) {
            MAS_VIEW *firstViewSuperview = self;
            while (!closestCommonSuperview && firstViewSuperview) {
                if (secondViewSuperview == firstViewSuperview) {
                    closestCommonSuperview = secondViewSuperview;
                }
                firstViewSuperview = firstViewSuperview.superview;
            }
            secondViewSuperview = secondViewSuperview.superview;
        }
        return closestCommonSuperview;
    }
    

截止为止，`Masonry` 的 `mas_makeConstraints` 的整个过程全部分析完毕，对于剩下的
`mas_remakeConstraints` 和 `mas_updateConstraints` 大同小异，这里不再做更多陈述

