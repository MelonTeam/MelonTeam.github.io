---
layout: post
title: "android旁门左道之动态替换系统view类"
date: 2017-06-29 15:46:00
categories: android
author: yarkeyzhang
tags: android 旁门左道
---

* content
{:toc}

| 导语 本文讲述如何通过替换系统view类的方法，定位一个特殊机型问题

作者： yarkeyzhang  2017.6.29

## 一，imageview抛来一个异常
<!--more-->

应用程序crash是android
app开发习以为常的问题，大部分crash我们通过日志找到调用栈可以很快定位到出错的代码。然而有一些crash却显得没那么直接，比如下面这个由android系统抛(throw)出来的异常。

    
    
    17-06-06 11:36:20|1496720179572[20047]1|e|statisticcollector|  
    getcrashextramessage...
    isnativecrashed: false 
    crashtype=java.lang.runtimeexception 
    crashaddress=android.graphics.canvas.throwifcannotdraw(canvas.java:1270) 
    crashstack=android.graphics.canvas.throwifcannotdraw(canvas.java:1270)
    android.graphics.canvas.drawbitmap(canvas.java:1404)
    android.graphics.drawable.bitmapdrawable.draw(bitmapdrawable.java:544)
    android.widget.imageview.ondraw(imageview.java:1246)
    android.view.view.draw(view.java:16245)
    android.view.view.updatedisplaylistifdirty(view.java:15242)
    android.view.view.draw(view.java:16015)
    android.view.viewgroup.drawchild(viewgroup.java:3740)
    android.view.viewgroup.dispatchdraw(viewgroup.java:3530)
    android.view.view.draw(view.java:16248)
    android.view.view.updatedisplaylistifdirty(view.java:15242)
    android.view.view.draw(view.java:16015)
    android.view.viewgroup.drawchild(viewgroup.java:3740)
    android.view.viewgroup.dispatchdraw(viewgroup.java:3530)
    android.view.view.updatedisplaylistifdirty(view.java:15237)
    android.view.view.draw(view.java:16015)
    android.view.viewgroup.drawchild(viewgroup.java:3740)
    android.view.viewgroup.dispatchdraw(viewgroup.java:3530)
    android.view.view.updatedisplaylistifdirty(view.java:15237)
    android.view.view.draw(view.java:16015)
    android.view.viewgroup.drawchild(viewgroup.java:3740)
    android.view.viewgroup.dispatchdraw(viewgroup.java:3530)
    android.view.view.draw(view.java:16248)
    com.android.internal.policy.phonewindow$decorview.draw(phonewindow.java:2822)
    android.view.view.updatedisplaylistifdirty(view.java:15242)
    android.view.threadedrenderer.updateviewtreedisplaylist(threadedrenderer.java:282)
    android.view.threadedrenderer.updaterootdisplaylist(threadedrenderer.java:288)
    android.view.threadedrenderer.draw(threadedrenderer.java:323)
    android.view.viewrootimpl.draw(viewrootimpl.java:2649)
    android.view.viewrootimpl.performdraw(viewrootimpl.java:2468)
    android.view.viewrootimpl.performtraversals(viewrootimpl.java:2072)
    android.view.viewrootimpl.dotraversal(viewrootimpl.java:1108)
    android.view.viewrootimpl$traversalrunnable.run(viewrootimpl.java:6146)
    android.view.choreographer$callbackrecord.run(choreographer.java:892)
    android.view.choreographer.docallbacks(choreographer.java:704)
    android.view.choreographer.doframe(choreographer.java:640)
    android.view.choreographer$framedisplayeventreceiver.run(choreographer.java:878)
    android.os.handler.handlecallback(handler.java:739)
    android.os.handler.dispatchmessage(handler.java:95)
    android.os.looper.loop(looper.java:148)
    android.app.activitythread.main(activitythread.java:5648)

我们看看日志，viewrootimpl.dotraversal()是遍历window所有view刷新界面的过程，这个过程由系统触发，我们在调用栈中找不到任何的app客户代码。过程中，imageview在执行ondraw()的时候出现了异常。这是某部手机在开启多窗口模式时必现crash。怎么办？

* * *

## 二、寻求解决思路

这个问题出现在一个编辑图片的页面，页面中含有很多的imageview（大约20个）实例，单单靠调用栈我们无法定位具体哪个imageview出现了问题。

不过相信大家已经有很多解决思路：

1. 通过日志文件寻找出错前后是否有更多帮助信息，配合源码定位问题

2. 借到问题手机，连接电脑配合源码打断点（imageview,bitmapdrawable,canvas）

思路1无法快速解决问题；思路2恕我实在借不到那个型号的手机，另外我们ide中的android源码与手机中行数不一定匹配，给imageview,bitmapdrawable等等这些系统类打断点，代码行数对不上的话也就很难搞。

这里我想到了一个思路：能不能重写imageview.ondraw()方法，在出现异常时打印出所有我们需要的日志信息（比如view id）

* * *

## 三、往layoutinflater下手

重写imageview.ondraw()方法实际上等于我们需要替换imageview类，把所有的xml布局文件中的imageview换成我们新定义的catchexceptionimageview？这个显然不太好办。最后我在layoutinflater类中找到了方法。

![](/image/android_pang_men_zuo_dao_zhi_dong_tai_ti_huan_xi_tong_view_lei/ad947170e91ba0b5e64f376019da94b3552102cf14d1ac876cbced9cbb5c6873)

每个activity拥有一个layoutinflater 对象，它负责解析android xml 布局文件然后实例化view或者view子类对象。核心函数是
layoutinflater.createviewfromtag(view parent, string name, attributeset
attrs)，它通过xml标签指定的类名字，实例化出view对象。在这里做手脚，我们可以将xml中所有的标签实例化成
catchexceptionimageview。

![](/image/android_pang_men_zuo_dao_zhi_dong_tai_ti_huan_xi_tong_view_lei/950108b9e6717511666023bd26ec644fc640244f5123b63164ee9dbe12059260)

查看createviewfromtag()源码我们可以发现， layoutinflater其实支持外部提供工厂类来自定义view的创建机制，对应的方法是
setfactory() 和 setfactory2()。

如果大家有用过android.support.v7.app.appcompatactivity，那么你会发现，xml布局中的button标签实际上创建了android.support.v7.widget.appcompatbutton对象，textview标签实际上创建了android.support.v7.widget.appcompattextview对象，这是通过layoutinflater.factory来影响view的创建实现的。

所以，我们调用 setfactory()或者setfactory2()方法有可能会遇到失败：“a factory has already been set
on this layoutinflater”。最后，我通过反射把我定义的factory对象安全地注入到了layoutinflater对象中。

具体代码请详见微码：<http://code.oa.com/v2/weima/detail/96896>

* * *

## 四、调试代码协助定位问题

为了捕捉到抛出异常的imageview，我大概写了下面这样的代码：

    
    
        public static class catchexceptionimageview extends imageview {
            public catchexceptionimageview(context context) {
                super(context);
            }
            public catchexceptionimageview(context context, attributeset attrs) {
                super(context, attrs);
            }
            @override
            protected void ondraw(canvas canvas) {
                drawable drawable = getdrawable();
                if (drawable instanceof bitmapdrawable) {
                    bitmapdrawable bitmapdrawable = (bitmapdrawable) drawable;
                    if (bitmapdrawable.getbitmap().isrecycled()) {
                        log.e(tag, "we'll crash !! " + this);
                    }
                }
                super.ondraw(canvas);
            }
        }
    
    
        protected void oncreate(bundle savedinstancestate) {
            super.oncreate(savedinstancestate);
    
            hashmap hookviewmap = new hashmap();
            hookviewmap.put("imageview", catchexceptionimageview.class.getname());
            new layoutdebughelper().onactivitycreate(this, hookviewmap);
            
            setcontentview(r.layout.activity_main);
        }

我构建了新的包发送给远方的优测测试人员，帮我复现了问题并抓了日志，最后找到了crash的imageview信息，通过view id便可以找到了出错的点。

* * *

够折腾吧，哈哈，机型问题虐我千百遍！

全文完，感谢阅读！

