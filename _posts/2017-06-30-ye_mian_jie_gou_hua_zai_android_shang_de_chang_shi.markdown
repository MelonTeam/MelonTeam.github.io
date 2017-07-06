---
layout: post
title: "页面结构化在Android上的尝试"
date: 2017-06-30 16:38:00 +0800
categories: android
author: bizaitan
tags: LEGO 页面结构化
---

* content
{:toc}

| 导语
MVP开发模式可以帮助项目结构解耦，但其庞大的方法数增加，较为笨重设计对于手Q项目并不很适合。参考之前Web开发经验，提出以页面结构化的解耦方式组织代码。下面讲讲Lego在Android上一次小小尝试

**一，MVP简介**

<!--more-->
**![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/d8b32fbd6fe4df60eab0f0a9c483c207cd9f0c32f2c89197af5529da6c3ca0d5)**

MVC太过常见这里不啰嗦。实际应用MVC当中，Activity占据打部分的工作，View和Controller的身份分不清。而MVP则是一种设计模式专门优化Activity
/ Fragment。

先来看看MVP模式的核心思想：**View不直接与Model交互**

MVP 把 Activity 中的 UI 逻辑抽象成 View 接口，把业务逻辑抽象成 Presenter 接口，Model 类还是原来的 Model

在MVP设计模式中，

**View**：由Activity充当，并且响应生命周期

**Model**：还是原来的数据层，网络，缓存，解析等。

**Presenter**：作为View和Model的中间纽带，View不能直接对Model进行操作，必须经过Presenter

**View interface**：需要View实现的接口，View通过View interface与Presenter进行交互，降低耦合

二，日迹MVP实战应用

【Mode层】我们直接忽略

【View
Interface】首页的View接口，抽离出view和presnter交互的接口。由Activity继承实现（Now.java，QQStoryMainActivity.java）

    
    
    public interface IMyStoryListView {
        public void setData(MyStorys myStoryList, RecentStory recentStoryList);
        public void setSegmentData(String key, Object data,boolean needRefreshUi);
        /**
         * 更新数据后刷新界面走的回调
         * @param success
         * @param isManualPullRefresh
         */
        public void pullRefreshCompleted(boolean success,boolean isReqCompleted);
        public void launchNewVideoTakeActivity(boolean autoStart, boolean checkSo, int entranceType,String extra);
        public void setPlayVideoBtnDisplay(boolean display);
        public void showStartDownload();
        public void showDownloadCompleted(boolean success);
        public void storyPreLoadCompleted(String category, String uin);
        public void LoadMoreCompleted(boolean repositoryUpdated, boolean isEnd);
        public void showEmptyView(boolean display);
        public void requestDataCompleted();
        public void openMyStoryListView(boolean open);
    }

【View】我们的Activity实现了View接口，并且实现生命周期

    
    
    
    public class QQStoryMainAcitivty extends QQStoryBaseActivity implements IMyStoryListView {
    
        protected StoryHomePushYellowBarHandler mStoryHomePushYellowBarHandler = new StoryHomePushYellowBarHandler();
        protected MystoryListView mainListView;
        protected IMyStroyPresenter myStoryListPresenter;
    
        @Override
        protected boolean doOnCreate(Bundle savedInstanceState) {
            super.doOnCreate(savedInstanceState);
            mainListView = (MystoryListView) super.findViewById(R.id.qqstory_story_main_listview);
            //Presenter
            myStoryListPresenter = new StoryListPresenter(this);
            myStoryListPresenter.setIView(this);
            return true;
        }
    
        @Override
        public void onStartAutoRequestFromNet() {
            startTitleProgress();
            mainListView.pullToRefresh();
            mStoryHomePushYellowBarHandler.clearYellowBar();
            myStoryListPresenter.requestAllDataFromNet();
        }
    
        private void startTitleProgress(){
            // do more
        }
    }
    



举个例子，用户下拉刷新一下。触发到Activity的onStartAutoRequestFromeNet。View逻辑在Activity。

业务逻辑则由Presnter的requestAllDataFromNet去实现。

【Presenter】具体的View->Model,Mode->View由这里实现，其中View是有View接口抽象，进一步规范化View的逻辑。

必要是可以抽出Presenter接口（其实日迹这里没有必要）

    
    
    public class StoryListPresnter implements IMyStroyPresenter{
        protected IMyStoryListView mIView;
        protected FeedItem mFeedItem;
        protected ParallelStepExecutor mRequestNetDataExecutor;
    
        @Override
        public void onCreate(boolean needUpdateFromNet) {
            // 生命周期的逻辑处理
            mFeedItem = new FeedItem();
        }
        @Override
        public void setIView(IMyStoryListView IView) {
            // 设置View接口(目前实现的是Activity，但其实由其他Fragment，View实现都是可以的，这就是MVP的好处之一，解耦)
            mIView = IView;
        }
    
        public boolean requestAllDataFromNet() {
            mRequestNetDataExecutor.addStep(new GetUserSelfInfoStep(null))
                    .addStep(new ReportWatchVideoListStep(StoryListPresenter.this))
                    .addStep(new GetUserGuideInfoStep(StoryListPresenter.this))
                    .onCompleted(new SimpleStepExector.CompletedHandler() {
                        @Override
                        public void done(FeedItem item) {
                            // 伪代码
                            mFeedItem = item;                       // 处理Model层
                            mIView.openMyStoryListView(mFeedItem);  // 根据View接口调用View更新
                        }
                    }).run();
        }
    
    }

MVP的优缺点：

优点：

1\. 解耦，绝对的。不然抽这么多接口干嘛

2\. 模块职责明确，层次清晰

3\. Presenter可复用（在日迹的需求中，首页和4Tab公用一个Presnter）

4\. 方便单元测试

5\. 避免Activity内存泄露， Acitvity一身轻松



MVP的缺点也是非常明确的

1\. 非常的笨重。一个View就对应一个Presenter，轻业务一个Activity能解决的就不要解决

2\. Presnter依然逻辑繁重。Acitivty轻松了，业务逻辑庞大的时候Presnter依然是大胖子。

3\. 代码复杂度，学习成本。这玩意不好理解，需要实战中理解。

4. 在手Q项目里，MVP会激增很多方法数，

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/c7712fbf9c37de4ed1d2b697d12dbcce00b329c7dfaf1c7c86b197e60f37c7fa)  

三，Lego页面结构化

** **

前面铺垫这么多，终于到我要吹水的时候了。MVC，MVP，还有MVVM等MVX系列的设计模式，都是一种大而全的统一管理。在项目结构中最为关键其实是：分模块！

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/33a461966937ac209e4478fedf4506c21f5a889c4464a54d4ab01b817f7c3f4a)

看看某宝的首页，顶部搜索栏，banner，导航分类，抢购，特价，底部Tab。这是一个Activity的话，你再怎么MVP，也是需要划分模块，然后分而治之。

一个再大的系统，都可以划分一个个小的模块，分而治之

页面结构化，并不是新玩意，是当时做web的一套代码风格。下图是当时做Web总结组件化的一张图。现在看来，也就并没有过时

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/fa1f198b6ca44df1b81968f2c20928e7b1aced3457b77dc973202d4ec4da29e6)

页面被划分问一个个区域的模块，有自身的逻辑和规划。有人说，这不就是一个个组件嘛。然后“页面结构化”并不是指组件。

例如上图的tabContainer，imgsContainer，listContainer，每一个模块都有自己的渲染模板（xml），请求的数据的CGI（数据源），自身的事件绑定（listener）
，状态机（生命周期），并不只是一个组件，而是一个个有自己生命力，能自己管理的小页面。

**根据页面结构，划分出一个个独立维护模块，这就是页面结构化。**

**##  页面结构化（Lego）与组件化的区别**

1\. 组件处于通用性，是不带业务逻辑的。而页面结构化是带业务逻辑。

2\. 页面结构化目的是为了代码维护性，项目管理，优化。组件复用可以有，但不是必要

3\. 组件与Lego不冲突。组件 +数据，业务逻辑 = Lego

下面就以问答的形式，用日迹评论赞项目实战，来讲解Lego好处

四，分析页面结构化特性

**##  Lego自己拉取自己的数据，如果一个页面5,6个模块，就拉5,6分PB协议，谈何性能？**

这里带出Lego两个特性：

1\. 每个Lego是有自己的数据，并不是一定要自己拉取，数据可以有其他Lego传递

2\. Lego有父子关系。一个页面/Activity需要一个顶层Lego管理

日迹首页评论赞

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/6c6ab3ada2ff3727941c4a7deaf4b931c2a2cfa102e64d5a191deb9ecf42261f)

    
    
    public FeedCommentLikeLego(Context context, Activity activity, ViewGroup parentView, HomeFeedItem feedItem, int feedType) {
        super(context, parentView);
        mHomeFeedItem = feedItem;
        mFeedItem = feedItem.mFeedBasicItem;
        mActivity = activity;
        mFeedType = feedType;
        mLikeManager = (LikeManager) SuperManager.getAppManager(SuperManager.LIKE_MANAGER);
        mParentView = LayoutInflater.from(context).inflate(R.layout.qqstory_feed_commentlike_view, parentView, true);
    
        // 页面结构
        FeedCommentLego commentLego = new FeedCommentLego(mContext, mParentView, mFeedItem, mFeedType);
        FeedLikeLego likeLego = FeedLikeLego.createIndexFeedLikeLego(mContext, activity, mParentView, mFeedItem, mFeedType);
        addLego(LEGO_KEY_COMMENT, commentLego);
        addLego(LEGO_KEY_LIKE, likeLego);
        commentLego.feed(mHomeFeedItem.getCommentList());
        likeLego.feed(mHomeFeedItem.getLikeEntryList());
        boot();
    }



 从FeedCommentLikeLego的构造方法，我们得知

1\. 我是爸爸，我有两个儿子

2\. 我两个儿子不争气，需要我来喂养数据，自己不会挣钱（自己不拉数据）

3\. 全家我是一家之主，启动我说了算（Lego启动boot后，会自己拉数据自己渲染，同时子Lego也会相继boot）

日迹710这里就有场景，体验出Lego切换数据源的优势。

【首页】出于性能优化，都会做请求合并。返回多个Feed的视频列表，评论赞列表数据。

    
    
     commentLego.feed(mHomeFeedItem.getCommentList());  
     likeLego.feed(mHomeFeedItem.getLikeEntryList());

被喂养数据后，Lego内部的DataProvider将不启动

【详情页】同一Lego，默认情况就会启动资金的DataProvider，会自己拉数据

    
    
    @Override  
    public LegoDataProvider getDataProvider() {  
        return new FeedLikeDataProvider(this, mIsDetailPage);  
    }

**## 一个Lego类是究竟是什么？Lego类之间的纽带？**

大部分页面的渲染流程线，如下图

![](/image/ye_mian_jie_gou_hua_zai_android_shang_de_chang_shi/bec1f8d682b167b63cc66af68ed6aeeabe8953f988245a96df99a0b63ae55dec)

我们把这些常用的网络请求，处理数据，事件绑定，上报，容错处理等一系列逻辑方法，以页面块为单位封装成一个Lego模块。

这样的一个抽象层Lego，我们可以清晰地看到该页面块，请求的数据是什么，绑定了什么事件，做了什么上报，出错怎么处理。

最后加上生命周期，页面结构化的Lego，已经算是一个完整的功能单元了。



继承LegoBase，有几个核心的方法需要重写：

getEvenHandler()  | 事件绑定器，一切需要setOnXXXLisnter都丢给他  
---|---  
getDataProvider() | 数据拉取器，里面还有一套LegoRequestBase的网络封装，最大成本简化网络请求和回包处理  
initView()  | View的初始化，只会执行一次  
render()  | 这个Lego的唯一渲染接口  
showLoding()  | 状态机之一，可以展示Loading菊花，可以DB获取缓存先渲染缓存  
showSuccess()  | 状态机之一，success  
showError()     | 状态机之一，error  
  
还有生命周期方法可以重写，但不是必要的。

你阅读/接手一个Lego类，会是件很轻松的事情。一个Lego类，核心方法这几个，其余都是业务逻辑方法。

改事件去该Lego的EventHandler，数据要改去DataProvider，产品要求大V才展示底部尾巴，好，去render方法找。

Lego之间的纽带，有三个：

parentView（公用xml）

feedData（公用数据）

getLego（Lego关系）

四，总结

Lego的核心思想是：页面结构分模块，分而治之。解耦，代码可读性高，底层统一优化

在使用了两个版本之后，感觉完成度还是不够。

1\. 顶层Lego情况复杂，底层统一优化不好做

2\. 接口之间约束，不够自由

但是对比MVP，Lego能体验出轻便，逻辑清晰，方法数量少的优势。

Lego页面结构化的应用其实还在尝试阶段。以上算我的一些个人思考和总结。

