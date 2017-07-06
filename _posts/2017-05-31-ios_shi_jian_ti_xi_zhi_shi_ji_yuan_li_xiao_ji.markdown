---
layout: post
title: "iOS 事件体系知识及原理小记"
date: 2017-05-31 22:39:00 +0800
categories: ios
author: jdochen
tags: iOS事件
---

* content
{:toc}



### 基本知识点：

**0 UITouch**
<!--more-->

当每一个指尖在屏幕上触发一次触摸事件时，系统就会生成对应一个UITouch对象，用于记录当前触摸的状态，主要包含运动相位、位置、大小、运动、力度（iOS9）等数据；当触摸事件发生变化时（指尖移动、压力变化），UITouch对象的相关信息也会跟着更新；每一次更新都是复用之前的UITouch对象，不会重新创建。

主要的一些属性与方法：

    
    
    @property(nonatomic,readonly) UITouchPhase        phase;  // 运动相位(开始、移动、静止、结束、取消)
    @property(nonatomic,readonly) NSUInteger          tapCount; // 在一小段时间内的连续计数
    @property(nonatomic,readonly) CGFloat majorRadius NS_AVAILABLE_IOS(8_0); // 触摸半径
    @property(nonatomic,readonly) CGFloat force NS_AVAILABLE_IOS(9_0); // 压力值
    - (CGPoint)locationInView:(nullable UIView *)view; // 获取当前坐标
    - (CGPoint)previousLocationInView:(nullable UIView *)view; // 获取上一次坐标

**1 UIEvent**

在iOS系统中一个UIEvent对象代表着一个事件在，有四种类型的事件：触摸事件( UIEventTypeTouches)、运动事件(
UIEventTypeMotion)、远程控制事件( UIEventTypeRemoteControl)、物理按键事件(
UIEventTypePresses)；例如屏幕被点击了，系统会创建一个UIEvent，如果UIEvent对象已经存在，那直接复用已有的UIEvent，UIEvent在应用中一旦被创建，它的生命周期会一直伴随着应用，所以千万别retain一个UIEvent或者通过return来获取一个UIEvent，如果你希望保存UIEvent的相关信息，你可以直接copy某个属性。（TODO：到底是一种类型的事件复用一个还是整个应用只复用一个UIEvent对象）

主要的一些属性与方法：

    
    
    @property(nonatomic,readonly) UIEventType    type NS_AVAILABLE_IOS(3_0); // 四种事件类型
    @property(nonatomic,readonly) UIEventSubtype  subtype NS_AVAILABLE_IOS(3_0); // 在各个大类型中再细化区分
    @property(nonatomic, readonly, nullable) NSSet <UITouch *> *allTouches; // 当前事件触发时的所有UITouch对象

**2 UIResponder**

事件响应者(UIResponder)的查找与事件的响应：

响应者（responder）的概念：在iOS系统中，响应者是指能响应并处理事件的对象，UIResponder是所有responder对象的基类。UIApplication
/ UIViewController / UIView
以及所有继承UIView的UIKit类（包含UIWindow）都直接或间接的继承了UIResponder，这就意味着所有的views以及大部分key
controller都能响应并处理事件对象。

（1）查找阶段：

先介绍UIView的两个方法：

\- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event;

该方法用于检查当前坐标是否落在当前view

\- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event

该方法的主要逻辑是：

  * 检查当前view是否能响应事件（userInteractionEnabled!=NO & hidden!=YES & alpha >0.01）
  * 不满足直接返回nil；
  * 通过pointInside:withEvent:方法，检查当前点击是否落在当前view中；
  *     * 如果点击落在当前view中，遍历subView执行hitTest:withEvent:；
    *       * 如果subView的hitTest:withEvent:有返回，则返回该返回；
      * 如果subView的hitTest:withEvent:没有返回，则返回当前view；
    * 如果点击没有落在当前view，则返回nil；

响应者查找阶段就要用到这两个方法，大致流程如下：

  * 当指尖触碰屏幕时，系统会创建一个UIEvent对象（如果已经存在，则复用），以及相应的UITouch；并将UIEvent对象放到当前活跃app的事件队列中；
  * UIApplication会从事件队列中取出最前面的事件进行分发以便处理，通常先发送事件给应用程序的主窗口(UIWindow)；
  * 主窗口会调用hitTest:withEvent:方法在视图(UIView)层次结构中找到一个最合适的UIView来处理触摸事件，并将UITouch与UIEvent交给UIView处理（通过touchesBegan/touchesMoved/touchesEnded等方法传递）

看个例子：

view 2是view 1的子view，当一个点击落在view 2区域内，这个查找过程会从UIWindow开始，然后一层层子view查找下去，最终view
2会作为最合适的响应者被hitTest返回，因为view 2满足了两个条件：

  1. 通过hitTest找到了view 2
  2. view 2内部没有其他子view

![](/image/ios_shi_jian_ti_xi_zhi_shi_ji_yuan_li_xiao_ji/f917d992a04a979280748b4409a4ebefc25acbdaca0868901765348edc8fcb0a)

再看看另一个特殊的场景：

view 2还是view 1的子view；但当一个点击落在view 2的区域内时，查找还是从UIWindow开始，但在view
1的hitTest中就返回了nil，因为点击区域不在view 1中，导致view
1的子view都不会再进行hitTest；这点跟web中的事件处理是截然不同的；这也导致一些超边界的点击必须由业务去重载hitText方法。

![](/image/ios_shi_jian_ti_xi_zhi_shi_ji_yuan_li_xiao_ji/f6754ccccb23a2b3dde193a0c273fc859f455083ea4e17d1ac53b5265bc91ddb)

（2）事件响应阶段（响应链）：

在上面提到的查找阶段，通过hitTest:withEvent:最终查找到的最后view自然就做为第一个可以响应该事件的view，当该view不能处理该事件，系统会通过nextResponder继续将事件传递给下一个响应者，如果一直没有能处理的响应者，这个事件会一直传递到UIApplication，最终废弃。所以，所谓的响应链就是一系列相连接的响应者，它由第一个响应者开始，通过nextResponder不断传递一直到UIApplication。

这里需要注意的是nextResponder的处理规则：

UIView的nextResponder属性，如果有管理此view的UIViewController对象，则为此UIViewController对象；否则nextResponder即为其superview。

UIViewController的nextResponder属性为其管理view的superview。

UIWindow的nextResponder属性为UIApplication对象。

UIApplication的nextResponder属性为nil

未完待续...

