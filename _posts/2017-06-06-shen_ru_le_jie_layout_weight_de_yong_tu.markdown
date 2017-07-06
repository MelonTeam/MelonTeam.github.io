---
layout: post
title: "深入了解layout_weight的用途"
date: 2017-06-06 19:46:00
categories: android
author: kylepeng
tags: layout_w... LinearLa...
---

* content
{:toc}

| 导语 当需要某个View自动占满剩余空间,或者多个View平分空间时,你会想到使用layout_weight,但如果想按比例使用空间,
你会怎么用呢,又有什么坑呢?

layout_weight是LinearLayout中的一个属性,通常我们用途是

<!--more-->
1.给其中一个view设上layout_weight=1,这样这个view就能把剩下的空间都占满.

2.如果是想让多个view占一样的宽(高), 就设上同样的layout_weight=1.这样这几个View就会等分parent的宽(高)



layout_weight的官方解释是, 下面是直译的

标示将LinearLayout中的额外空间分配给与这些View的比重。如果View不应该被拉伸，则指定0。否则，在重量大于0的所有View中，额外的空间将被评估。可能是浮点值，如“1.2”

其实layout_weight还可以用于将空间按比例分配

比如你有3个TextView,你想将这3个TextView按1:2:3的比例使用横向空间,你就可以把这3个View的layout_weight设成1,2,3.如下面的xml

    
    
    <LinearLayout 
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            >
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                style="@style/LinearLayoutViewStyle1"
                android:text="123456789" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_weight="2"
                style="@style/LinearLayoutViewStyle2"
                android:text="123456789" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_weight="3"
                style="@style/LinearLayoutViewStyle3"
                android:text="123456789" />
        LinearLayout>

 实际的效果

![](/image/shen_ru_le_jie_layout_weight_de_yong_tu/41947d9c42a5e6c3ffe16bb458f82523547ae3c6fa5c44634130eef56d661346)

宽度比是1:1.25:1.51, 并不是1:2:3,问题出在哪呢?

仔细观察,数字后面的空间好像是1:2:3,仔细一量,确实是1:2:3, 为什么是剩余空间的比是1:2:3呢?

下面我再给出一些例子:

![](/image/shen_ru_le_jie_layout_weight_de_yong_tu/9109b7280eb2bcf6639d8cd18ee243a1981f1eb763850bcb9362eba1dcb9703e)

这里给出6个例子,每个都是一行有3个TextView,
每个TextView的layout_weight都如图所示,还有差别就是每个例子的layout_width是不一样的，xml的源代码见附件

其中对于layout_weight是1,2,3的例子,只有b和c是按比例占空间的.

实际上View的宽度公式是:

实际宽度 = 根据layout_width获得的宽度 + 剩下的宽度 * (自己的layout_weight / 所有的layout_weight)

这里剩下的宽度可能是负的哦.

例如:

a由于layout_width是wrap_content,他先把"123456789"所占的空间w1占了，剩下的空间w2=屏幕的宽度- 3*w1,
然后再对w2分成6份，按layout_weight分给3个TextView.

b虽然layout_width是wrap_content，但他的text是空，所以根据layout_width占的空间是0dp，剩下的空间就是屏幕的宽度，然后再按layout_weight分就是1：2：3

c由于layout_width是0dp,所以根据layout_width占的空间是0dp，剩下的空间就是屏幕的宽度，然后再按layout_weight分就是1：2：3

d由于layout_width是match_parent,根据layout_width每个TextView占的空间是屏幕的宽度w，这样剩下的空间w2 = w
- 3w = -2w,再按layout_weight对w2进行分配，

第一个View的实际分配的宽度tw1 = w + (1/6) * (-2w) = w - 1/3 * w = 2/3 * w

第二个View的实际分配的宽度tw2 = w + (2/6) * (-2w) = w - 2/3 * w = 1/3 * w

第三个View的实际分配的宽度tw3 = w + (3/6) * (-2w) = w - 3/3 * w = 0

所以看到的宽度比就是2:1:0

（注：有点奇葩的是，这个Linearlayout的高度变成“123456789”的纵向9行的高度，但又没任何和内容显示）

e由于layout_width是match_parent,根据layout_width每个TextView占的空间是屏幕的宽度w，这样剩下的空间w2 = w
- 3w = -2w,再按layout_weight对w2进行分配，

第一个View的实际分配的宽度tw1 = w + (1/3) * (-2w) = w - 2/3 * w = 1/3 * w

第二个View的实际分配的宽度tw2 = w + (1/3) * (-2w) = w - 2/3 * w = 1/3 * w

第三个View的实际分配的宽度tw3 = w + (1/3) * (-2w) = w - 2/3 * w = 1/3 * w

所以看到的宽度比就是1:1:1

f的效果等同于a的效果

### 结论:

### 上面可以不记,只要记住下面的要点就够了

###
和layout_weight搭配的layout_width（或layout_height）一定要用"0dp",绝对不要用"match_parent",也不要用"wrap_content"和固定长度

###

### 重要的事情说三遍：

### 和layout_weight搭配的layout_width（或layout_height）一定要用"0dp"

### 和layout_weight搭配的layout_width（或layout_height）一定要用"0dp"

### 和layout_weight搭配的layout_width（或layout_height）一定要用"0dp"

