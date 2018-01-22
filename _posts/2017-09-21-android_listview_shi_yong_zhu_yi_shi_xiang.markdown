---
layout: post
title: "Android ListView使用注意事项"
date: 2017-09-21 19:01:00 +0800
categories: android
author: limingzhang
tags: ListView adapter Android
---

* content
{:toc}

| 导语
ListView是Android开发过程中最常用的View之一，虽然用法十分简单，但是在使用过程中还是几个需要注意一些地方，因为很可能你不经意间写的代码会给后续埋坑，增加维护成本。

## 一、getChildAt方法的使用

<!--more-->
**首先我们来看一个错误的例子：**
    
    
     for (int i = 0; i < mListAdapter.getCount(); i ++) {
          TroopAdmin item = (TroopAdmin)mListAdapter.getItem(i);
           if (TextUtils.equals(item.uin, uin)) {
                  View itemView = mListView.getChildAt(i);
                   if (itemView != null) {
                         //对该View进行处理......
                   }
           }
      }

例子中为了找到某个uin对应的view，先通过mListAdapter.getItem的方式先找到该data对应的index为i，再通过i找到对应的view，这样咋一看是没啥问题的，程序也能正常运行。但这里其实是有两个问题的：

1\. ListView的getChildAt是包含header和footer的，mListAdapter中的第i个数据，并不一定对应
ListView的第i个子view。

2\.
ListView的getChildAt只能获取到可见区域的view，即使没有header和footer，但如果列表划出了屏幕，mListAdapter中的第i个数据也无法对应ListView的第i个子view。

**这里有两种修改方案：**

方案一：加上头部和顶部不可见view的判断

    
    
    for (int i = 0; i < mListAdapter.getCount(); i ++) {
        TroopAdmin item = (TroopAdmin)mListAdapter.getItem(i);
        if (TextUtils.equals(item.uin, uin)) {
             //计算index时需要加上headCount并减去上方不可见的view数量
             int index = i + mListView.getHeaderViewsCount() - mListView.getFirstVisiblePosition();
             if (index < 0 || index >= mListView.getChildCount()) {
                  break;
             }
             View itemView = mListView.getChildAt(index);
             if (itemView != null) {
                  //对该view进行处理......
             }
        }
    }

 方案二：把uin放在view的holder里头，遍历所以子view，找到需要的view

    
    
    for (int i = 0, childCount = mListView.getChildCount(); i < childCount; i ++) {
        View view = mListView.getChildAt(i);
        ViewHolder viewHolder = (ViewHolder)view.getTag();
        if (viewHolder != null && TextUtils.equals(uin, viewHolder.uin)) {
             //对该view进行处理...
        }
    }

## 二、onItemClick的使用建议

**不恰当的使用方式：**

示例一：直接处理mDataList[position]的数据

    
    
    @Override
    public void onItemClick(AdapterView> parent, View view, int position, long id) {
        handleItemClick(mDataList[postion]);  
    }

 示例二：处理自定义adaper第position个item的数据

    
    
    @Override
    public void onItemClick(AdapterView> parent, View view, int position, long id) {
        handleItemClick(mListAdapter.getItem(position));
    }

 以上两种方式的做法都是有问题的，因为这里的postion都包含了header和footer,
即使现在使用起来没有问题，但是后期如果我们给他加了header或者footer会导致数据错乱，或者数据越界。

**修改方案：**
    
    
    @Override
    public void onItemClick(AdapterView> parent, View view, int position, long id) {
        handleItemClick(parent.getAdapter().getItem(position));
    }

你可能会有疑问，为什么使用parent.getAdapter()，用自定义的mListAdapter就不行呢？这两者难道指向的不是同一个adaper么？答案是不一定。我们一起看下setAdapter的部分源码。

    
    
    //ListView内部setAdapter的部分代码  
    @Override
    public void setAdapter(ListAdapter adapter) {
        ......  
        if (mHeaderViewInfos.size() > 0|| mFooterViewInfos.size() > 0) {
             mAdapter = new HeaderViewListAdapter(mHeaderViewInfos, mFooterViewInfos, adapter);
        } else {
             mAdapter = adapter;
        }  
        ......  
    }

这里我仅保留关键部分的代码，
可以看出ListView内部的adapter的值是不确定的，如果添加了头部或者是尾巴，会在内部创建一个HeaderViewListAdapter的代理类，
这类中帮我们处理好了header和footer的情况，
我们通过parent.getAdapter()拿到的就是它，大家有兴趣可以自己去看下这个类的代码，这里不再赘诉。

## 三、addHeadView的时机

如果addHeadView的时机在setAdapter之后，在4.4以下的版本中，会报出IllegalStateException的异常：

    
    
    public void addHeaderView(View v, Object data, boolean isSelectable)  {
        if (mAdapter != null && !(mAdapter instanceof HeaderViewListAdapter)){
             throw new IllegalStateException("Cannot add header view to list -- setAdapter has already been called.");
        }  
        ......  
    ｝

 这里处理的方式简单粗暴， 其实原因很简单，因为在setAdapter方法内部就必须需要知道是否添加了Header或者Footer，
如果在setAdapter后面添加的话无法正确地处理了。

后面google应该也发现了这个做法太多简单粗暴，对用户和开发者来说并不友好，于是在4.4及之后的版本中不直接抛异常了，而是又重新对adapter做了处理来完善接口。

    
    
    public void addHeaderView(View v, Object data, boolean isSelectable) {
        ......
        if (mAdapter != null) {
             if (!(mAdapter instanceof HeaderViewListAdapter)) {
                   mAdapter = new HeaderViewListAdapter(mHeaderViewInfos, mFooterViewInfos, mAdapter);
             }
             .....
        }  
    }

但这又引发了另外一个问题，我们平时开发过程中用的测试机基本都是4.4以上，所以即使顺序错了也不会有问题出现，但是在外网的用户是存在4.4版本以下的机型的。所以在开发过程中我们还是要时刻牢记
addHeadView 要写在setAdapter之前。

## 四、Adapter的数据设置

**不提倡的写法:**
    
    
    public void setData(List list) {  
        mDataList = list;  
        notifyDataSetChanged();
    ｝

我相信很多人在给Adapter赋值的时候会才用这样的写法，其实正常情况下是没有问题，但是有时候你会莫名其妙报出IllegalStateException的crash，我们从源码中找下原因：

    
    
    if (mItemCount == 0) {
        .......
    } else if (mItemCount != mAdapter.getCount()) {
          throw new IllegalStateException("The content of the adapter has changed but "
               + "ListView did not receive a notification. Make sure the content of "
               + "your adapter is not modified from a background thread, but only from "
               + "the UI thread. Make sure your adapter calls notifyDataSetChanged() "
               + "when its content changes. [in ListView(" + getId() + ", " + getClass()
               + ") with Adapter(" + mAdapter.getClass() + ")]");
    }

说明数据变化了，但是通知UI要发生变化。因为Adapter中的mDataList直接引用的是外部创建的对象，当前的Adapter是没法约束它的，外部对象发生变化了很有可能没有通知UI去更新。

**建议的写法：**
    
    
    public void setData(List list) {
        mDataList.clear();
        mDataList.addAll(list);
        notifyDataSetChanged();
    ｝

 把Adapter中持有的数据集合与数据源的集合区分开来。

## 五、总结

以上所讲述的四个点都是ListView使用过程中需要注意的问题，虽然目前写的代码在使用上没有出现问题，但是很可能会给后面埋坑，增加维护的成本。所以在写代码的过程中应该思考得更加全面，多考虑下边界条件以及当前模块与其他模块之间的依赖关系。

