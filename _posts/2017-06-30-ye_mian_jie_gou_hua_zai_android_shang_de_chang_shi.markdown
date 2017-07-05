---
layout: post
title: "页面结构化在android上的尝试"
date: 2017-06-30 16:38:00
categories: android
author: bizaitan
tags: lego 页面结构...
---

* content
{:toc}

| 导语
mvp开发模式可以帮助项目结构解耦，但其庞大的方法数增加，较为笨重设计对于手q项目并不很适合。参考之前web开发经验，提出以页面结构化的解耦方式组织代码。下面讲讲lego在android上一次小小尝试

**一，mvp简介**

<!--more-->
**![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/d8b32fbd6fe4df60eab0f0a9c483c207cd9f0c32f2c89197af5529da6c3ca0d5)**

mvc太过常见这里不啰嗦。实际应用mvc当中，activity占据打部分的工作，view和controller的身份分不清。而mvp则是一种设计模式专门优化activity
/ fragment。

先来看看mvp模式的核心思想：**view不直接与model交互**

mvp 把 activity 中的 ui 逻辑抽象成 view 接口，把业务逻辑抽象成 presenter 接口，model 类还是原来的 model

在mvp设计模式中，

**view**：由activity充当，并且响应生命周期

**model**：还是原来的数据层，网络，缓存，解析等。

**presenter**：作为view和model的中间纽带，view不能直接对model进行操作，必须经过presenter

**view interface**：需要view实现的接口，view通过view interface与presenter进行交互，降低耦合

二，日迹mvp实战应用

【mode层】我们直接忽略

【view
interface】首页的view接口，抽离出view和presnter交互的接口。由activity继承实现（now.java，qqstorymainactivity.java）

    
    
    public interface imystorylistview {
        public void setdata(mystorys mystorylist, recentstory recentstorylist);
        public void setsegmentdata(string key, object data,boolean needrefreshui);
        /**
         * 更新数据后刷新界面走的回调
         * @param success
         * @param ismanualpullrefresh
         */
        public void pullrefreshcompleted(boolean success,boolean isreqcompleted);
        public void launchnewvideotakeactivity(boolean autostart, boolean checkso, int entrancetype,string extra);
        public void setplayvideobtndisplay(boolean display);
        public void showstartdownload();
        public void showdownloadcompleted(boolean success);
        public void storypreloadcompleted(string category, string uin);
        public void loadmorecompleted(boolean repositoryupdated, boolean isend);
        public void showemptyview(boolean display);
        public void requestdatacompleted();
        public void openmystorylistview(boolean open);
    }

【view】我们的activity实现了view接口，并且实现生命周期

    
    
    
    public class qqstorymainacitivty extends qqstorybaseactivity implements imystorylistview {
    
        protected storyhomepushyellowbarhandler mstoryhomepushyellowbarhandler = new storyhomepushyellowbarhandler();
        protected mystorylistview mainlistview;
        protected imystroypresenter mystorylistpresenter;
    
        @override
        protected boolean dooncreate(bundle savedinstancestate) {
            super.dooncreate(savedinstancestate);
            mainlistview = (mystorylistview) super.findviewbyid(r.id.qqstory_story_main_listview);
            //presenter
            mystorylistpresenter = new storylistpresenter(this);
            mystorylistpresenter.setiview(this);
            return true;
        }
    
        @override
        public void onstartautorequestfromnet() {
            starttitleprogress();
            mainlistview.pulltorefresh();
            mstoryhomepushyellowbarhandler.clearyellowbar();
            mystorylistpresenter.requestalldatafromnet();
        }
    
        private void starttitleprogress(){
            // do more
        }
    }
    



举个例子，用户下拉刷新一下。触发到activity的onstartautorequestfromenet。view逻辑在activity。

业务逻辑则由presnter的requestalldatafromnet去实现。

【presenter】具体的view->model,mode->view由这里实现，其中view是有view接口抽象，进一步规范化view的逻辑。

必要是可以抽出presenter接口（其实日迹这里没有必要）

    
    
    public class storylistpresnter implements imystroypresenter{
        protected imystorylistview miview;
        protected feeditem mfeeditem;
        protected parallelstepexecutor mrequestnetdataexecutor;
    
        @override
        public void oncreate(boolean needupdatefromnet) {
            // 生命周期的逻辑处理
            mfeeditem = new feeditem();
        }
        @override
        public void setiview(imystorylistview iview) {
            // 设置view接口(目前实现的是activity，但其实由其他fragment，view实现都是可以的，这就是mvp的好处之一，解耦)
            miview = iview;
        }
    
        public boolean requestalldatafromnet() {
            mrequestnetdataexecutor.addstep(new getuserselfinfostep(null))
                    .addstep(new reportwatchvideoliststep(storylistpresenter.this))
                    .addstep(new getuserguideinfostep(storylistpresenter.this))
                    .oncompleted(new simplestepexector.completedhandler() {
                        @override
                        public void done(feeditem item) {
                            // 伪代码
                            mfeeditem = item;                       // 处理model层
                            miview.openmystorylistview(mfeeditem);  // 根据view接口调用view更新
                        }
                    }).run();
        }
    
    }

mvp的优缺点：

优点：

1\. 解耦，绝对的。不然抽这么多接口干嘛

2\. 模块职责明确，层次清晰

3\. presenter可复用（在日迹的需求中，首页和4tab公用一个presnter）

4\. 方便单元测试

5\. 避免activity内存泄露， acitvity一身轻松



mvp的缺点也是非常明确的

1\. 非常的笨重。一个view就对应一个presenter，轻业务一个activity能解决的就不要解决

2\. presnter依然逻辑繁重。acitivty轻松了，业务逻辑庞大的时候presnter依然是大胖子。

3\. 代码复杂度，学习成本。这玩意不好理解，需要实战中理解。

4. 在手q项目里，mvp会激增很多方法数，

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/c7712fbf9c37de4ed1d2b697d12dbcce00b329c7dfaf1c7c86b197e60f37c7fa)  

三，lego页面结构化

** **

前面铺垫这么多，终于到我要吹水的时候了。mvc，mvp，还有mvvm等mvx系列的设计模式，都是一种大而全的统一管理。在项目结构中最为关键其实是：分模块！

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/33a461966937ac209e4478fedf4506c21f5a889c4464a54d4ab01b817f7c3f4a)

看看某宝的首页，顶部搜索栏，banner，导航分类，抢购，特价，底部tab。这是一个activity的话，你再怎么mvp，也是需要划分模块，然后分而治之。

一个再大的系统，都可以划分一个个小的模块，分而治之

页面结构化，并不是新玩意，是当时做web的一套代码风格。下图是当时做web总结组件化的一张图。现在看来，也就并没有过时

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/fa1f198b6ca44df1b81968f2c20928e7b1aced3457b77dc973202d4ec4da29e6)

页面被划分问一个个区域的模块，有自身的逻辑和规划。有人说，这不就是一个个组件嘛。然后“页面结构化”并不是指组件。

例如上图的tabcontainer，imgscontainer，listcontainer，每一个模块都有自己的渲染模板（xml），请求的数据的cgi（数据源），自身的事件绑定（listener）
，状态机（生命周期），并不只是一个组件，而是一个个有自己生命力，能自己管理的小页面。

**根据页面结构，划分出一个个独立维护模块，这就是页面结构化。**

**##  页面结构化（lego）与组件化的区别**

1\. 组件处于通用性，是不带业务逻辑的。而页面结构化是带业务逻辑。

2\. 页面结构化目的是为了代码维护性，项目管理，优化。组件复用可以有，但不是必要

3\. 组件与lego不冲突。组件 +数据，业务逻辑 = lego

下面就以问答的形式，用日迹评论赞项目实战，来讲解lego好处

四，分析页面结构化特性

**##  lego自己拉取自己的数据，如果一个页面5,6个模块，就拉5,6分pb协议，谈何性能？**

这里带出lego两个特性：

1\. 每个lego是有自己的数据，并不是一定要自己拉取，数据可以有其他lego传递

2\. lego有父子关系。一个页面/activity需要一个顶层lego管理

日迹首页评论赞

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/6c6ab3ada2ff3727941c4a7deaf4b931c2a2cfa102e64d5a191deb9ecf42261f)

    
    
    public feedcommentlikelego(context context, activity activity, viewgroup parentview, homefeeditem feeditem, int feedtype) {
        super(context, parentview);
        mhomefeeditem = feeditem;
        mfeeditem = feeditem.mfeedbasicitem;
        mactivity = activity;
        mfeedtype = feedtype;
        mlikemanager = (likemanager) supermanager.getappmanager(supermanager.like_manager);
        mparentview = layoutinflater.from(context).inflate(r.layout.qqstory_feed_commentlike_view, parentview, true);
    
        // 页面结构
        feedcommentlego commentlego = new feedcommentlego(mcontext, mparentview, mfeeditem, mfeedtype);
        feedlikelego likelego = feedlikelego.createindexfeedlikelego(mcontext, activity, mparentview, mfeeditem, mfeedtype);
        addlego(lego_key_comment, commentlego);
        addlego(lego_key_like, likelego);
        commentlego.feed(mhomefeeditem.getcommentlist());
        likelego.feed(mhomefeeditem.getlikeentrylist());
        boot();
    }



 从feedcommentlikelego的构造方法，我们得知

1\. 我是爸爸，我有两个儿子

2\. 我两个儿子不争气，需要我来喂养数据，自己不会挣钱（自己不拉数据）

3\. 全家我是一家之主，启动我说了算（lego启动boot后，会自己拉数据自己渲染，同时子lego也会相继boot）

日迹710这里就有场景，体验出lego切换数据源的优势。

【首页】出于性能优化，都会做请求合并。返回多个feed的视频列表，评论赞列表数据。

    
    
     commentlego.feed(mhomefeeditem.getcommentlist());  
     likelego.feed(mhomefeeditem.getlikeentrylist());

被喂养数据后，lego内部的dataprovider将不启动

【详情页】同一lego，默认情况就会启动资金的dataprovider，会自己拉数据

    
    
    @override  
    public legodataprovider getdataprovider() {  
        return new feedlikedataprovider(this, misdetailpage);  
    }

**## 一个lego类是究竟是什么？lego类之间的纽带？**

大部分页面的渲染流程线，如下图

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/bec1f8d682b167b63cc66af68ed6aeeabe8953f988245a96df99a0b63ae55dec)

我们把这些常用的网络请求，处理数据，事件绑定，上报，容错处理等一系列逻辑方法，以页面块为单位封装成一个lego模块。

这样的一个抽象层lego，我们可以清晰地看到该页面块，请求的数据是什么，绑定了什么事件，做了什么上报，出错怎么处理。

最后加上生命周期，页面结构化的lego，已经算是一个完整的功能单元了。



继承legobase，有几个核心的方法需要重写：

getevenhandler()  | 事件绑定器，一切需要setonxxxlisnter都丢给他  
---|---  
getdataprovider() | 数据拉取器，里面还有一套legorequestbase的网络封装，最大成本简化网络请求和回包处理  
initview()  | view的初始化，只会执行一次  
render()  | 这个lego的唯一渲染接口  
showloding()  | 状态机之一，可以展示loading菊花，可以db获取缓存先渲染缓存  
showsuccess()  | 状态机之一，success  
showerror()     | 状态机之一，error  
  
还有生命周期方法可以重写，但不是必要的。

你阅读/接手一个lego类，会是件很轻松的事情。一个lego类，核心方法这几个，其余都是业务逻辑方法。

改事件去该lego的eventhandler，数据要改去dataprovider，产品要求大v才展示底部尾巴，好，去render方法找。

lego之间的纽带，有三个：

parentview（公用xml）

feeddata（公用数据）

getlego（lego关系）

四，总结

lego的核心思想是：页面结构分模块，分而治之。解耦，代码可读性高，底层统一优化

在使用了两个版本之后，感觉完成度还是不够。

1\. 顶层lego情况复杂，底层统一优化不好做

2\. 接口之间约束，不够自由

但是对比mvp，lego能体验出轻便，逻辑清晰，方法数量少的优势。

lego页面结构化的应用其实还在尝试阶段。以上算我的一些个人思考和总结。

