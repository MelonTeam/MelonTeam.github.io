---
layout: post
title: "IOS触摸事件分发机制详解"
date: 2017-03-27 12:40:54
categories: IOS
tags: 事件
---

* content
{:toc}
## 前言

很多时候大家都不关心IOS触摸事件的分发机制的实现原理，当遇到以下几种情形的时候你很可能抓破头皮都找不到解决方案:

某个点击消息由父视图来处理，子视图怎么把消息传递给父视图
这个按钮不灵敏，怎么扩大点击响应区域
怎么在一个页面处理手绘、表情拖动放缩、文本编辑三种消息
阅读本文，你会明白两个问题：IOS如何找到响应者、响应者是如何做出响应，明白这两个问题你就能解决类似上述的疑难杂症。通过控制Hit-test view 、人为干预响应者能否对这一事件作出响应最终来控制触摸事件的分发机制。

<!--more-->

## 原理详解

IOS把用户触发事件打包成一个UIEvent对象，作为事件传递的消息载体，放入当前活跃的APP的消息队列中，然后通过Hit-Testing来找到响应者，响应者通过响应链的传递做出响应，这就是IOS事件分发机制的实现原理。

接下来从这三个概念UIEvent,UIResponder、Hit-Testing、Responder Chain入手，为你详细讲解这句话的含义。

#### UIEvent

UIEvent包含最常见的三种事件：Touch Events(触摸事件)、Motion Events(运动事件，比如重力感应和摇一摇等)、Remote Events(远程事件，比如用耳机上得按键来控制手机)， 通过 type、 subtype属性表明事件类型。IOS把屏幕监测到的点击事件用UITouch对象来表示，最终被封装成UIEvent作为事件的消息载体在响应链上传递。

#### Hit-Testing

屏幕上有很多UIView，你点击一下屏幕，IOS是怎么知道你点击的是哪个UIView呢？

Hit-Testing就完美的解决了这个问题，通过检测触摸点是否在相关的视图边界范围内，如果在，就继续递归检测该视图的所有子视图，离用户最近的那个视图的边界如果包含触摸点，那么它就是我们要找的Hit-Test view。
举例说明，假如用户点击下图中的 view E，那么IOS是通过如下顺序来找到view E的：

点击在view A的范围内,所以就检测它的子视图 view B和 view C。
点击不在view B内，但是在view C内，所以接下来检测view D和view E
点击不在view D内，而是在view E内，并且view E是在包含点击的视图树中离用户最近的，所以view E就是要找的Hit-Test view。

![Alt text](/image/IOS_touch_event_distribution_mechanism/1.png)

具体的检测工作是通过UIView中两个方法来完成的

```objectivec
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;   // recursively calls -pointInside:withEvent:. point is in the receiver's coordinate system
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event;   // default returns YES if point is in bounds  
```

`hitTest:withEvent:` 方法通过传递进来CGPoint和UIEvent返回Hit-Test view，该方法调用 `pointInside:withEvent:` 方法来检测point是否在view的边界范围内，如果在view的边界范围内，则返回YES，然后，在子视图中递归调用 `hitTest:withEvent:` 。如果不在范围内，则返回NO，那么它的所有子视图都会被忽略，hitTest:withEvent:返回 `nil` 。

Hit-Test view只是有权优先处理该事件，如果它不能处理那么事件消息就会沿着响应链传递给下一个响应者来处理。所以能通过控制 Hit-Test view 和 能否响应两个途径来控制消息的传递和处理。

#### UIResponder

`UIResponder` 类提供了一组接口专门用来响应用户的操作，处理各种事件，其中包括触摸事件(Touch Events)、运动事件(Motion Events)、远程控制事件(Remote Control Events)，标准文本编辑事件(Standard Edit Actions)如：复制、选择、粘贴、剪切等。在UIKit中，UIApplication、UIView、UIViewController这几个类都是直接继承自UIResponder类

**第一响应者（first responder）**

第一响应者能够优先处理事件，通常是一个UIView的对象，如果一个普通的对象想成为第一响应者，只需要做两件事情：

1. 重写`canBecomeFirstResponder`方法返回YES
2. 调用`becomeFirstResponder`

提示：当一个对象变成第一响应者的时候，要确保APP已经建立了object graph（暂且翻译为”对象图“），举例说明，你可以在viewDidAppear: 调用becomeFirstResponder，如果你在viewWillAppear:中调用这个方法可能会返回NO。

**触摸事件接口**

```objectivec
// Generally, all responders which do custom touch handling should override all four of these methods.
// Your responder will receive either touchesEnded:withEvent: or     touchesCancelled:withEvent: for each
// touch it is handling (those touches it received in touchesBegan:withEvent:).
// *** You must handle cancelled touches to ensure correct behavior in your application.  Failure to
// do so is very likely to lead to incorrect behavior or crashes.

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEstimatedPropertiesUpdated:(NSSet * _Nonnull)touches NS_AVAILABLE_IOS(9_1);
```

**运动事件**

```objectivec
- (void)motionBegan:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
- (void)motionEnded:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
- (void)motionCancelled:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
```

**远程控制事件**

```objectivec
- (void)remoteControlReceivedWithEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(4_0);
```

**标准编辑事件**

```objectivec
@implementation TBExtendedHitButton
+ (instancetype)extendedHitButton
{
    return (TBExtendedHitButton *)[TBExtendedHitButton buttonWithType:UIButtonTypeCustom];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect relativeFrame = self.bounds;
    UIEdgeInsets hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}
@end  
```

#### Responder Chain

`Responder Chain` 暂且翻译为“响应链”，它是由一些列的响应者（`UIResponder`）链接起来的，起始于第一响应者（first responder），结束于`UIApplication`,当第一响应者（first responder）不能处理该事件的时候,事件消息沿着响应链继续转发。响应链能为一下几种事件进行消息转发，但不仅限于一下几类事件类型：

触摸事件(Touch Events)
运动事件(Motion Events)
远程控制事件(Remote Control Events) 耳机等
control事件(Action messages)，UIBUtton，UISwitch等
编辑菜单事件（Editing-menu messages）复制、粘贴、剪切等
文本控件编辑事件（Text editing），UITextView、UITextfiled等

**传递路径**

如果初始化对象（initial object 即hit-test view或者first responder）不处理事件，`UIKit`会将事件传递给响应链中的下一个响应者。每个响应者决定它是传递事件还是通过nextResponder方法传递给它的下一个响应者。这个操作继续直到一个响应者处理该事件或者没有响应者了。

响应链序列在iOS确定一个事件并将它传递给initial object（通常是view）时开始。所以initial view有处理事件的第一个机会。
下图描述了两个不同的事件传递路径（因为不同的app设置），一个App的事件传递路径由app特殊的构成决定，但事件传递路径会遵守相同的规则。以下图片很能说明响应链是如何传递的。

![Alt text](/image/IOS_touch_event_distribution_mechanism/2.png)


## 应用

#### 扩大按钮点击区域

当视图调用 `- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event` 进行边界检测的时候，重写该方法扩大视图的检测边界值。

```objectivec
@implementation TBExtendedHitButton
+ (instancetype)extendedHitButton
{
    return (TBExtendedHitButton *)[TBExtendedHitButton buttonWithType:UIButtonTypeCustom];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect relativeFrame = self.bounds;
    UIEdgeInsets hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}
@end  
```

#### 子视图消息传递给父视图

解决办法通常有两种：

父视图和子视图都重写- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;,其中子视图返回nil，让父视图成为Hit-Test view.
父视图成为first responder，子视图把事件沿着响应链转发。
更多应用解决方案，请参考http://zhoon.github.io/ios/2015/04/12/ios-event.html

## 参考文献

[UIResponder Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIResponder_Class/)
[UIResponder Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIEvent_Class/index.html)
[Event Handling Guide for iOS](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html#//apple_ref/doc/uid/TP40009541-CH4-SW4)
[深入浅出iOS事件机制](http://zhoon.github.io/ios/2015/04/12/ios-event.html)