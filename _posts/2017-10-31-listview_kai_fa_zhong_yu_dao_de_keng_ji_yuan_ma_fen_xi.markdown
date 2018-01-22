---
layout: post
title: "ListView开发中遇到的坑及源码分析"
date: 2017-10-31 23:49:00 +0800
categories: android
author: slimxu
tags: Android
---

* content
{:toc}



### 1、起因

之前在需求开发的时候碰到过一个坑，出于某种原因，在Adapter的getView()方法中不能使用xml的资源，只能new出一个View，例如：
<!--more-->

    
    
     @Override
     public View getView(int position, View convertView, ViewGroup parent) {
          TextView textView = new TextView(mContext);
          LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                  ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
          textView.setLayoutParams(params);
          return textView;
      }
    

这时需要的是给这个View设置LayoutParams，在之前的概念中对这个LayoutParams的类型没有直接的要求，一般是看需求使用LinearLayout.LayoutParams或者RelativeLayout.LayoutParams，然后设置给View后就返回了。然后一段时间的平安无事后，测试突然丢了段crash日志给我，图我找不到了，但是第一行就是：LinearLayout.LayoutParams
cannot cast to AbsListView.LayoutParams：

可以看出这是类型转换异常，但是我拿到这个日志后就很奇怪，因为在我的测试机上不会有问题，而在测试的机子上这是必现crash，我想应该是API版本问题，我的测试机是API
21以上的，而测试的机型是Kitkat（API 19），于是我直接分析API 19 的源码。

### 2、跟踪源码（API 19）

我们知道，View的绘制机制是onMeasure()->onLayout()->onDraw()，这种类型转换异常肯定是在Measure的步骤就发生了的，毕竟Measure的时候肯定得使用LayoutParams的，于是跟踪进ListView的onMeasure方法中看它做了什么：

    
    
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    
        int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        int heightMode = MeasureSpec.getMode(heightMeasureSpec);
        int widthSize = MeasureSpec.getSize(widthMeasureSpec);
        int heightSize = MeasureSpec.getSize(heightMeasureSpec);
    
        int childWidth = 0;
        int childHeight = 0;
        int childState = 0;
    
        // 根据我们继承的Adapter的getCount()方法得到一共有多少个Child
        mItemCount = mAdapter == null ? 0 : mAdapter.getCount();
        if (mItemCount > 0 && (widthMode == MeasureSpec.UNSPECIFIED ||
                heightMode == MeasureSpec.UNSPECIFIED)) {
            // 这里通过obtainView()拿到childView
            final View child = obtainView(0, mIsScrap);
            // 去测量该childView --- crash的地点！
            measureScrapChild(child, 0, widthMeasureSpec);
    
            // 省略代码...
        }
    
       /**
         * 省略根据widthMode 和 heightMode 计算 widthSize 和 heightSize 的代码
         */
    
        setMeasuredDimension(widthSize , heightSize);
        mWidthMeasureSpec = widthMeasureSpec;        
    }
    

onMeasure()方法根据obtainView()拿到每一个childView后，会紧接着调用measureScrapChild(child)去测量，我们继续跟进这个方法：

    
    
    private void measureScrapChild(View child, int position, int widthMeasureSpec) {
        // 取出ChildView的LayoutParams进行强转，试图转成AbsListView.LayoutParams，就是这里发生了crash
        LayoutParams p = (LayoutParams) child.getLayoutParams();
        if (p == null) {
            p = (AbsListView.LayoutParams) generateDefaultLayoutParams();
            child.setLayoutParams(p);
        }
        p.viewType = mAdapter.getItemViewType(position);
        p.forceAdd = true;
    
        // 省略部分代码...
    
        child.measure(childWidthSpec, childHeightSpec);
    }
    

这样就找到了原因，ListView认为它所有的子View的LayoutParams都必须是AbsListView.LayoutParams类型的，如果是通过inflate
xml文件得到的View，会自动设置上AbsListView.LayoutParams，但是通过代码new出来的View，如果不亲自设置，就会在源码中出现类型转换的crash。

### 3、解决问题（多种方案）

**第一种方案：**  
最推荐的也是最简单的处理方法当然是在Adapter的getView中不随便使用LayoutParams而必须使用AbsListView.LayoutParams，这样保证不会出现crash，如果需要new多个View就给他们的Parent设置该LayoutParams并返回parent：

    
    
     @Override
     public View getView(int position, View convertView, ViewGroup parent) {
          TextView textView = new TextView(mContext);
          AbsListView.LayoutParams params = new AbsListView.LayoutParams(
                  ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
          textView.setLayoutParams(params);
          return textView;
      }
    

**第二种方案：**  
在老版本中，如果很任性，就是不按照第一种方案来，而是想搞个大新闻的话，有没有其他的方案呢？答案当然是有的，我们继续分析源码，上面提到过，ListView根据obtainView()去获取childView，那么跟进obtainView()中去看下它做了什么：

    
    
     View obtainView(int position, boolean[] isScrap) {
         Trace.traceBegin(Trace.TRACE_TAG_VIEW, "obtainView");
    
         isScrap[0] = false;
         View scrapView;
    
         scrapView = mRecycler.getTransientStateView(position);
         if (scrapView == null) {
             scrapView = mRecycler.getScrapView(position);
         }
    
         View child;
         // 调用Adapter.getView()拿到childView
         if (scrapView != null) {
             child = mAdapter.getView(position, scrapView, this);
             // 省略...
         } else {
             child = mAdapter.getView(position, null, this);
             // 省略...
         }
    
        // 如果mAdapterHasStableIds为true，则进入该分支
         if (mAdapterHasStableIds) {
             // 拿到child的LayoutParams
             final ViewGroup.LayoutParams vlp = child.getLayoutParams();
             LayoutParams lp;
             if (vlp == null) {
                 lp = (LayoutParams) generateDefaultLayoutParams();
             } else if (!checkLayoutParams(vlp)) {
                 // 如果拿到的LayoutParams不是AbsListView.LayoutParams，则给它包装成AbsListView.LayoutParams
                 lp = (LayoutParams) generateLayoutParams(vlp);
             } else {
                 lp = (LayoutParams) vlp;
             }
             lp.itemId = mAdapter.getItemId(position);
             child.setLayoutParams(lp);
         }
         //省略...
         return child;
     }
    
    // 检查是否为AbsListView.LayoutParams
    @Override
    protected boolean checkLayoutParams(ViewGroup.LayoutParams p) {
        return p instanceof AbsListView.LayoutParams;
    }
    
    // 包装为AbsListView.LayoutParams
    @Override
    protected ViewGroup.LayoutParams generateLayoutParams(ViewGroup.LayoutParams p) {
        return new LayoutParams(p);
    }
    

代码很简单，看注释就可以了。那么，很急很关键的是：mAdapterHasStableIds是个啥，它什么时候为true？很明显只要mAdapterHasStableIds==true，系统就会通过这个if分支对我们的LayoutParams进行保护处理，这样即使Adapter.getView中返回的View不是AbsListView.LayoutParams，也不会crash。  
mAdapterHasStableIds是个啥，我们从ListView.setAdapter()开始看起：

    
    
    // ListView.java
    @Override
    public void setAdapter(ListAdapter adapter) {
        // 省略...
    
        // 调用了AbsListView.setAdapter    
        super.setAdapter(adapter);
    
        // 省略...
        requestLayout();
    }
    
    // AbsListView.java
    @Override
    public void setAdapter(ListAdapter adapter) {
        if (adapter != null) {
            // 原来就是我们继承的Adapter的hasStableIds()的返回值！
            mAdapterHasStableIds = mAdapter.hasStableIds();
            if (mChoiceMode != CHOICE_MODE_NONE && mAdapterHasStableIds &&
                    mCheckedIdStates == null) {
                mCheckedIdStates = new LongSparseArray();
            }
        }
        // 省略...
    }
    

这样就很清楚了，我们写Adapter的时候，总会重写两个重要的方法：getCount()，getView()，但是Adapter还提供其他的方法的重写，比如getItemId()和hasStableIds()。所以想要解决这个crash，只要在Adapter的hasStableIds()返回true就搞定了。

**但是，总得告诉我为什么吧？**

### 4、知其然，更知其所以然

至于Adapter的hasStableIds()的方法到底起到什么样的作用，引用一段来自StackOverFlow的回答：

> Stable IDs allow the ListView to optimize for the case when items remain the
same between notifyDataSetChanged calls. The IDs it refers to are the ones
returned from getItemId.

>

> Without it, the ListView has to recreate all Views since it can’t know if
the item IDs are the same between data changes (e.g. if the ID is just the
index in the data, it has to recreate everything). With it, it can refrain
from recreating Views that kept their item IDs.

好了我知道你们没耐心翻译，简单来说就是：**如果hasStableIds()返回了true，那么在调用notifyDataSetChanged刷新界面时，决定重绘每个ItemView之前，会调用Adapter.getItemId(int
position)方法拿到该Item的新的id，和之前老的id对比，如果没有变化，则认为这个Item的数据没有变化，UI也不会发生变化，则不会Recreate这个ItemView，达到优化性能的目的。**

所以hasStableIds()方法需要和getItemId()配合使用，那么到底在getItemId中返回什么样的数才能标识该Item的数据没有变化呢？在大部分情况下，返回这个Item对应的Model的hashCode就好了，用hashCode来标识数据有没有发生变化，在下面的例子中，如果一个Student的id和name不发生变化，则认为该Item数据没变化，不用重绘UI：

    
    
    // StudentAdapter.java
    public class StudentAdapter extends BaseAdapter {
        @Override
        public long getItemId(int position) {
            Student student = mStudents.get(position);
            return student.hashCode();
        }
    
    
        @Override
        public boolean hasStableIds() {
            return true;
        }
    }
    
    // Student.java
    static class Student {
        int id;
        String name;
    
        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
    
            Student student = (Student) o;
    
            if (id != student.id) return false;
            return name != null ? name.equals(student.name) : student.name == null;
    
        }
    
        @Override
        public int hashCode() {
            int result = id;
            result = 31 * result + (name != null ? name.hashCode() : 0);
            return result;
        }
    }
    

所以我们重写Adapter时，不是只有getCount和getView方法重要，其他的方法也同样重要，以后如果允许的话，请不要简单的在getItemId()方法中返回position哦！

### 5、继续跟踪源码（API 21）

还遗留了最后一个问题，那么为啥在我的测试机(API
21)上不会出现crash呢，肯定是Android源码在新版本上进行了修改，同样去看AbsListView的obtainView()方法：

    
    
    View obtainView(int position, boolean[] outMetadata) {
    
        // 省略...
    
        final View scrapView = mRecycler.getScrapView(position);
        final View child = mAdapter.getView(position, scrapView, this);
    
        // 省略... 
    
        // 这里会设置ChildView的LayoutParams
        setItemViewLayoutParams(child, position);
    
        // 省略...
    
        return child;
    }
    

很容易看到的是，比起老版本，新版本代码多了一个setItemViewLayoutParams方法，只要调用obtainView就会进入这个方法里面，不会再有if条件。

    
    
    // 所有的ChildView都会通过这个方法设置LayoutParams，经过这层保护逻辑后，全部的LayoutParams都是AbsListView.LayoutParams类型拉
    private void setItemViewLayoutParams(View child, int position) {
        final ViewGroup.LayoutParams vlp = child.getLayoutParams();
        LayoutParams lp;
        if (vlp == null) {
            lp = (LayoutParams) generateDefaultLayoutParams();
        } else if (!checkLayoutParams(vlp)) {
            lp = (LayoutParams) generateLayoutParams(vlp);
        } else {
            lp = (LayoutParams) vlp;
        }
    
        // 其实还是会判断hasStableIds，只不过这里将ItemId直接赋值到LayoutParams里去了。
        if (mAdapterHasStableIds) {
            lp.itemId = mAdapter.getItemId(position);
        }
        lp.viewType = mAdapter.getItemViewType(position);
        lp.isEnabled = mAdapter.isEnabled(position);
        if (lp != vlp) {
          child.setLayoutParams(lp);
        }
    }
    

**这就是API >= 21不会出现Crash的原因啦！**

