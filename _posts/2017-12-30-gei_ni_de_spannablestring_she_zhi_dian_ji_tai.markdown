---
layout: post
title: "给你的SpannableString设置点击态"
date: 2017-12-30 00:20:00 +0800
categories: 未分类
author: nearlei
tags: TextView
---

* content
{:toc}

| 导语 让你的ui更加灵动

### 背景

为了使界面的点击操作能更加形象化，我们通常会给点击的View 添加点击态，让使用者发现，哦，原来这个view在响应我的点击动作。
<!--more-->

而我们给一个普通的View添加点击态的普通做法就是，给它设置一个 selector

类似这样 设置在不同点击状态下显示不同的背景图片

    
    
    xml version="1.0" encoding="utf-8"?>
    <selector xmlns:android="http://schemas.android.com/apk/res/android">
        <item android:drawable="@drawable/install_btn_press" android:state_pressed="true"/>
        <item android:drawable="@drawable/install_btn" android:state_enabled="true"/>
        <item android:drawable="@drawable/install_btn_disabled" android:state_enabled="false"/>
    selector>
    

又类似这样 给TextView 设置不同点击状态下的文字颜色，粗细，字体等

    
    
    xml version="1.0" encoding="utf-8"?>
    <selector xmlns:android="http://schemas.android.com/apk/res/android">
        <item android:color="@color/qim_text_color" android:state_pressed="true"/>
        <item android:color="@color/qim_text_color"/>
    selector>
    

基本上，这些设置都够用了。

然而，当我们需要在文本的不同部分显示不同的样式时，譬如，一篇文章里面，当中显示的人名需要加粗，显示的号码需要变成另外一种染色，显示的链接则需要加下划线,
并且各自都有自己的点击事件。  
Android系统为开发者提供了 SpannableString 和 SpannableStringBuilder 去实现上面的效果，（具体使用方法查看
<https://developer.android.com/reference/android/text/SpannableString.html> ）  
本文主要针对SpannableStringBuilder，因为它更加灵活。

开发者使用SpannableStringBuilder 的SetSpan
函数，指定需要的特殊样式，指定该部分的开始和结束位置，即可以得到上面的效果，android原生SDK就提供了ClickableSpan
实现指定位置响应点击事件的类，但是，并没有提供一个能给指定位置设置点击态的Span。

没有，我们就自己实现一个SelectorSpan吧~~

### 思路

TextView 里绘制文字相关的工作都有 TextLine 来负责，查看里面的绘制相关的逻辑，里面处理Span 的代码如下

    
    
          if (mSpanned == null) {
          // 没Span，直接绘制
              TextPaint wp = mWorkPaint;
              wp.set(mPaint);
              final int mlimit = measureLimit;
              return handleText(wp, start, mlimit, start, limit, runIsRtl, c, x, top,
                      y, bottom, fmi, needWidth || mlimit < measureLimit);
          }
    
          // 按行循环处理
          final float originalX = x;
          for (int i = start, inext; i < measureLimit; i = inext) {
              TextPaint wp = mWorkPaint;
              wp.set(mPaint);
    
             // 处理其他不相干的Span类型的代码，目前先忽略
            .... hide code ....
            //
    
              if (replacement != null) {
                   x += handleReplacement(replacement, wp, i, mlimit, runIsRtl, c, x, top, y,
                           bottom, fmi, needWidth || mlimit < measureLimit);
                    continue;
               }
    
               // 按位置处理相关的Span
              for (int j = i, jnext; j < mlimit; j = jnext) {
                  jnext = mCharacterStyleSpanSet.getNextTransition(mStart + j, mStart + mlimit) -
                          mStart;
    
                  wp.set(mPaint);
                  for (int k = 0; k < mCharacterStyleSpanSet.numberOfSpans; k++) {
                      // Intentionally using >= and <= as explained above
                      if ((mCharacterStyleSpanSet.spanStarts[k] >= mStart + jnext) ||
                              (mCharacterStyleSpanSet.spanEnds[k] <= mStart + j)) continue;
    
                      CharacterStyle span = mCharacterStyleSpanSet.spans[k];
                      // 找到这个位置里所有的Span，把绘制的textPaint 传给对应的Span让他去设置画笔样式
                      span.updateDrawState(wp);
                  }
    
                  // Only draw hyphen on last run in line
                  if (jnext < mLen) {
                      wp.setHyphenEdit(0);
                  }
                  x += handleText(wp, j, jnext, i, inext, runIsRtl, c, x,
                          top, y, bottom, fmi, needWidth || jnext < measureLimit);
              }
          }
    

具体流程是 **TextView的onDraw —> Layout的onDraw —> TextLine的draw —>
当前Span的updateDrawState 方法设置画笔 —> 真正执行绘制**

如果想要特殊的点击态，可以使用 ReplacementSpan，不仅可以设置画笔，还提供了draw方法给你重写。实现更加丰富的样式。

我们目前需要的点击态只是字体颜色变一下，就不必劳师动众了。

再来跟踪一下TextView 怎么分发点击事件给Span，要设置ClickableSpan
，TextView都需要设置MoVeMentMethod才能生效，普通做法如下

    
    
    // LinkMovementMethod 基本够用了~~
    textView.setMovementMethod(LinkMovementMethod.getInstance());
    

从这里切入进去查看具体分发逻辑，这个Movement 是在TextView里的onTouch 方法里被调用

    
    
    @Override
        public boolean onTouchEvent(MotionEvent event) {
            //...省略无关代码
            if ((mMovement != null || onCheckIsTextEditor()) && isEnabled()
                    && mText instanceof Spannable && mLayout != null) {
                boolean handled = false;
    
                if (mMovement != null) {
                    handled |= mMovement.onTouchEvent(this, (Spannable) mText, event);
                }
    
                // ...省略无关代码
            }
            // ...省略无关代码
        }
    

TextView 的onTouch 里调用了Movement 的onTouch 去处理Spanable的click
事件,我们直接看LinkMovementMethod 里的实现

    
    
    @Override
        public boolean onTouchEvent(TextView widget, Spannable buffer,
                                    MotionEvent event) {
            int action = event.getAction();
    
            if (action == MotionEvent.ACTION_UP ||
                action == MotionEvent.ACTION_DOWN) {
                int x = (int) event.getX();
                int y = (int) event.getY();
    
                x -= widget.getTotalPaddingLeft();
                y -= widget.getTotalPaddingTop();
    
                x += widget.getScrollX();
                y += widget.getScrollY();
    
                Layout layout = widget.getLayout();
                // 计算出当前点击的行数
                int line = layout.getLineForVertical(y);
                // 计算出当前点击的具体位置
                int off = layout.getOffsetForHorizontal(line, x);
    
                // 查找这个位置设置的ClickableSpan
                ClickableSpan[] link = buffer.getSpans(off, off, ClickableSpan.class);
    
                if (link.length != 0) {
                    if (action == MotionEvent.ACTION_UP) {
                        // 抬起手指，就当是响应了点击事件，调用第一个ClickableSpan的onClick 回调
                        link[0].onClick(widget);
                    } else if (action == MotionEvent.ACTION_DOWN) {
                        // 按下手指，把当前部分设置为选中状态
                        Selection.setSelection(buffer,
                                               buffer.getSpanStart(link[0]),
                                               buffer.getSpanEnd(link[0]));
                    }
    
                    return true;
                } else {
                    Selection.removeSelection(buffer);
                }
            }
    
            return super.onTouchEvent(widget, buffer, event);
        }
    

具体就是当TextView 收到onTouch 事件的时候，把事件传给对应的Movement处理，Movement
根据具体的点击位置，找出当前位置的ClickableSpan，当手指抬起后，调用ClickableSpan的onClick回调。

了解完Span绘制和分发点击事件的大概逻辑，我们就有了如下思路：

一. **首先新添加一个SelectorSpan
继承ForegroundColorSpan（这里我们只想做一个颜色变浅的点击态，所以选择了设置前台颜色的Span来继承，如果有其他需求可以自行选择父类）**

二. **我们模仿
LinkMovementMethod，实现一个新MovementMethod设置给TextView，在他的onTouch方法里实现，在手指按下时，找出点击位置的SelectorSpan
，把他的状态设置成 点击状态，当手指抬起后，把他的状态设置成普通状态。**

三、**重写SelectorSpan的updateDrawState方法，根据不同的状态去设置不同的样式**

### 实现

添加一个SelectorSpan

    
    
        public static class SelectorSpan extends ForegroundColorSpan{
    
            private int pressColor;
    
            private boolean isPressed;
    
            public SelectorSpan(int color,int pressColor) {
                super(color);
                this.pressColor = pressColor;
            }
    
            @Override
            public void updateDrawState(TextPaint ds) {
                if(isPressed){
                    ds.setColor(pressColor);
                }else{
                    super.updateDrawState(ds);
                }
            }
    
            public void pressStateChange(boolean isPressed){
                this.isPressed = isPressed;
            }
        }
    

继承 LinkMovementMethod 类，并且重写他的onTouchEvent方法 如下

    
    
        @Override
        public boolean onTouchEvent(TextView widget, Spannable buffer,
                                    MotionEvent event) {
            int action = event.getAction();
    
            if (action == MotionEvent.ACTION_UP ||
                action == MotionEvent.ACTION_DOWN ||
                action == MotionEvent.ACTION_CANCEL ) {
                int x = (int) event.getX();
                int y = (int) event.getY();
    
                boolean ret = false;
    
                x -= widget.getTotalPaddingLeft();
                y -= widget.getTotalPaddingTop();
    
                x += widget.getScrollX();
                y += widget.getScrollY();
    
                Layout layout = widget.getLayout();
                int line = layout.getLineForVertical(y);
                int off = layout.getOffsetForHorizontal(line, x);
    
                ClickableSpan[] link = buffer.getSpans(off, off, ClickableSpan.class);
    
                if (link.length != 0) {
                    if (action == MotionEvent.ACTION_UP) {
                        link[0].onClick(widget);
                    } 
                    // 去掉画选中状态的代码
                    ret = true;
                }
    
                // 上面几乎是抄LinkMovementMethod的源码
                // 下面是点击态相关逻辑代码，上下两段其实可以合并一些逻辑，有兴趣可以改动一下
                switch (action){
                       case MotionEvent.ACTION_DOWN: {
                           SelectorSpan[] selectorSpans = stext.getSpans(off, off, SelectorSpan.class);
                           if (selectorSpans.length != 0) {
                               selectorSpans[0].pressStateChange(true);
                               widget.invalidate();
                           }
                       }
                           break;
                       case MotionEvent.ACTION_UP: {
                           SelectorSpan[] selectorSpans = stext.getSpans(0, stext.length(),
                            SelectorSpan.class);
                           for(SelectorSpan selectorSpan : selectorSpans) {
                               selectorSpan.pressStateChange(false);
                               widget.invalidate();
                           }
                       }
                           break;
                       case MotionEvent.ACTION_CANCEL: {
                           SelectorSpan[] selectorSpans = stext.getSpans(0, stext.length(),
                            SelectorSpan.class);
                           for(SelectorSpan selectorSpan : selectorSpans) {
                               selectorSpan.pressStateChange(false);
                               widget.invalidate();
                           }
                       }
                           break;
                    }
            }
    
    
    
            return super.onTouchEvent(widget, buffer, event);
        }
    

为了避免某些特殊情况下，被设成点击状态的Span没有接受到ACTION_DOWN ， 和 ACTION_CANCEL
事件，我们也可以重写一下TextView 里的 drawableStateChange 方法

    
    
        @Override
        protected void drawableStateChanged() {
            super.drawableStateChanged();
            // 加入兜底逻辑，当view状态变为非点击状态时，找出全部的 SelectorSpan，把他们设成普通状态
            // 避免出现变显示错误
            if(!isPressed()) {
                Spannable stext = Spannable.Factory.getInstance().newSpannable(getText());
                MainActivity.SelectorSpan[] selectorSpens = stext.getSpans(0, stext.length(),
                 MainActivity.SelectorSpan.class);
                for (MainActivity.SelectorSpan selectorSpan : selectorSpens) {
                    selectorSpan.pressStateChange(false);
                }
            }
        }
    

### 用法

    
    
    // 构造一个SpannableStringBuilder
    SpannableStringBuilder builder = new SpannableStringBuilder("哈哈哈哈哈");
    
    // 设置SelectorSpan 的点击态和普通态颜色，设置Span具体位置
    builder.setSpan(new SelectorSpan(normalColor,pressColor),start,end,Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
    
    // 设置我们重新实现的Movement
    textView..setMovementMethod(MyLinkMovementMethod);
    
    textView.setText(builder);
    

### 结语

TextView 博大精深，功能丰富，希望大家继续深挖。

