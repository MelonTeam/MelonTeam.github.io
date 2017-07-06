---
layout: post
title: "Android旁门左道之动态替换系统View类"
date: 2017-06-29 15:46:00
categories: android
author: yarkeyzhang
tags: Android 旁门左道
---

* content
{:toc}

| 导语 本文讲述如何通过替换系统View类的方法，定位一个特殊机型问题

作者： yarkeyzhang  2017.6.29

## 一，ImageView抛来一个异常
<!--more-->

应用程序Crash是Android
App开发习以为常的问题，大部分Crash我们通过日志找到调用栈可以很快定位到出错的代码。然而有一些Crash却显得没那么直接，比如下面这个由Android系统抛(throw)出来的异常。

    
    
    17-06-06 11:36:20|1496720179572[20047]1|E|StatisticCollector|  
    getCrashExtraMessage...
    isNativeCrashed: false 
    crashType=java.lang.RuntimeException 
    crashAddress=android.graphics.Canvas.throwIfCannotDraw(Canvas.java:1270) 
    crashStack=android.graphics.Canvas.throwIfCannotDraw(Canvas.java:1270)
    android.graphics.Canvas.drawBitmap(Canvas.java:1404)
    android.graphics.drawable.BitmapDrawable.draw(BitmapDrawable.java:544)
    android.widget.ImageView.onDraw(ImageView.java:1246)
    android.view.View.draw(View.java:16245)
    android.view.View.updateDisplayListIfDirty(View.java:15242)
    android.view.View.draw(View.java:16015)
    android.view.ViewGroup.drawChild(ViewGroup.java:3740)
    android.view.ViewGroup.dispatchDraw(ViewGroup.java:3530)
    android.view.View.draw(View.java:16248)
    android.view.View.updateDisplayListIfDirty(View.java:15242)
    android.view.View.draw(View.java:16015)
    android.view.ViewGroup.drawChild(ViewGroup.java:3740)
    android.view.ViewGroup.dispatchDraw(ViewGroup.java:3530)
    android.view.View.updateDisplayListIfDirty(View.java:15237)
    android.view.View.draw(View.java:16015)
    android.view.ViewGroup.drawChild(ViewGroup.java:3740)
    android.view.ViewGroup.dispatchDraw(ViewGroup.java:3530)
    android.view.View.updateDisplayListIfDirty(View.java:15237)
    android.view.View.draw(View.java:16015)
    android.view.ViewGroup.drawChild(ViewGroup.java:3740)
    android.view.ViewGroup.dispatchDraw(ViewGroup.java:3530)
    android.view.View.draw(View.java:16248)
    com.android.internal.policy.PhoneWindow$DecorView.draw(PhoneWindow.java:2822)
    android.view.View.updateDisplayListIfDirty(View.java:15242)
    android.view.ThreadedRenderer.updateViewTreeDisplayList(ThreadedRenderer.java:282)
    android.view.ThreadedRenderer.updateRootDisplayList(ThreadedRenderer.java:288)
    android.view.ThreadedRenderer.draw(ThreadedRenderer.java:323)
    android.view.ViewRootImpl.draw(ViewRootImpl.java:2649)
    android.view.ViewRootImpl.performDraw(ViewRootImpl.java:2468)
    android.view.ViewRootImpl.performTraversals(ViewRootImpl.java:2072)
    android.view.ViewRootImpl.doTraversal(ViewRootImpl.java:1108)
    android.view.ViewRootImpl$TraversalRunnable.run(ViewRootImpl.java:6146)
    android.view.Choreographer$CallbackRecord.run(Choreographer.java:892)
    android.view.Choreographer.doCallbacks(Choreographer.java:704)
    android.view.Choreographer.doFrame(Choreographer.java:640)
    android.view.Choreographer$FrameDisplayEventReceiver.run(Choreographer.java:878)
    android.os.Handler.handleCallback(Handler.java:739)
    android.os.Handler.dispatchMessage(Handler.java:95)
    android.os.Looper.loop(Looper.java:148)
    android.app.ActivityThread.main(ActivityThread.java:5648)

我们看看日志，ViewRootImpl.doTraversal()是遍历Window所有View刷新界面的过程，这个过程由系统触发，我们在调用栈中找不到任何的App客户代码。过程中，ImageView在执行onDraw()的时候出现了异常。这是某部手机在开启多窗口模式时必现Crash。怎么办？

* * *

## 二、寻求解决思路

这个问题出现在一个编辑图片的页面，页面中含有很多的ImageView（大约20个）实例，单单靠调用栈我们无法定位具体哪个ImageView出现了问题。

不过相信大家已经有很多解决思路：

1. 通过日志文件寻找出错前后是否有更多帮助信息，配合源码定位问题

2. 借到问题手机，连接电脑配合源码打断点（ImageView,BitmapDrawable,Canvas）

思路1无法快速解决问题；思路2恕我实在借不到那个型号的手机，另外我们IDE中的Android源码与手机中行数不一定匹配，给ImageView,BitmapDrawable等等这些系统类打断点，代码行数对不上的话也就很难搞。

这里我想到了一个思路：能不能重写ImageView.onDraw()方法，在出现异常时打印出所有我们需要的日志信息（比如view id）

* * *

## 三、往LayoutInflater下手

重写ImageView.onDraw()方法实际上等于我们需要替换ImageView类，把所有的xml布局文件中的ImageView换成我们新定义的CatchExceptionImageView？这个显然不太好办。最后我在LayoutInflater类中找到了方法。

![](/image/Android_pang_men_zuo_dao_zhi_dong_tai_ti_huan_xi_tong_View_lei/ad947170e91ba0b5e64f376019da94b3552102cf14d1ac876cbced9cbb5c6873)

每个Activity拥有一个LayoutInflater 对象，它负责解析Android xml 布局文件然后实例化View或者View子类对象。核心函数是
LayoutInflater.createViewFromTag(View parent, String name, AttributeSet
attrs)，它通过xml标签指定的类名字，实例化出View对象。在这里做手脚，我们可以将xml中所有的标签实例化成
CatchExceptionImageView。

![](/image/Android_pang_men_zuo_dao_zhi_dong_tai_ti_huan_xi_tong_View_lei/950108b9e6717511666023bd26ec644fc640244f5123b63164ee9dbe12059260)

查看createViewFromTag()源码我们可以发现， LayoutInflater其实支持外部提供工厂类来自定义View的创建机制，对应的方法是
setFactory() 和 setFactory2()。

如果大家有用过android.support.v7.app.AppCompatActivity，那么你会发现，xml布局中的Button标签实际上创建了android.support.v7.widget.AppCompatButton对象，TextView标签实际上创建了android.support.v7.widget.AppCompatTextView对象，这是通过LayoutInflater.Factory来影响View的创建实现的。

所以，我们调用 setFactory()或者setFactory2()方法有可能会遇到失败：“A factory has already been set
on this LayoutInflater”。最后，我通过反射把我定义的Factory对象安全地注入到了LayoutInflater对象中。

具体代码请详见微码：<http://code.oa.com/v2/weima/detail/96896>

* * *

## 四、调试代码协助定位问题

为了捕捉到抛出异常的ImageView，我大概写了下面这样的代码：

    
    
        public static class CatchExceptionImageView extends ImageView {
            public CatchExceptionImageView(Context context) {
                super(context);
            }
            public CatchExceptionImageView(Context context, AttributeSet attrs) {
                super(context, attrs);
            }
            @Override
            protected void onDraw(Canvas canvas) {
                Drawable drawable = getDrawable();
                if (drawable instanceof BitmapDrawable) {
                    BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
                    if (bitmapDrawable.getBitmap().isRecycled()) {
                        Log.e(TAG, "we'll crash !! " + this);
                    }
                }
                super.onDraw(canvas);
            }
        }
    
    
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
    
            HashMap hookViewMap = new HashMap();
            hookViewMap.put("ImageView", CatchExceptionImageView.class.getName());
            new LayoutDebugHelper().onActivityCreate(this, hookViewMap);
            
            setContentView(R.layout.activity_main);
        }

我构建了新的包发送给远方的优测测试人员，帮我复现了问题并抓了日志，最后找到了Crash的ImageView信息，通过view id便可以找到了出错的点。

* * *

够折腾吧，哈哈，机型问题虐我千百遍！

全文完，感谢阅读！

