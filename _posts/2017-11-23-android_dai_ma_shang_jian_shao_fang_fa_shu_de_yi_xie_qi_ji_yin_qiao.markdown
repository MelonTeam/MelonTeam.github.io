---
layout: post
title: "Android代码上减少方法数的一些奇技淫巧"
date: 2017-11-23 17:08:00 +0800
categories: android
author: andyqtchen
tags: Android 方法数 方法数优化 方法数超出
---

* content
{:toc}

| 导语
随着Android项目代码量的增加，当应用方法数量超过了65536的时候，编包的时候就会报出著名“64k”方法数问题。虽然然最简单粗暴的方法是分dex，还有其他像混淆等，但本人还是研究了几种代码上减少方法的方式，希望能帮到“有缘人”。

# 一、工具介绍

<!--more-->
  * [Android Studio](https://developer.android.com/studio/index.html)
  * [dex2jar](https://sourceforge.net/projects/dex2jar/)

# 二、代码场景与方法数分析

> 下面要介绍下几种常见的代码使用场景，分析方法数增加情况。

## 1.1 子类中调用了父类中未被子类重写的方法

### （1）场景

先看一个简单的类：

    
    
    public class MainActivity extends AppCompatActivity {
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.activity_main);
        }
    }
    

按照我们手算出来的方法数是`2`（一个默认构造器，一个onCreate方法）；

那我们使用工具看下这个类的方法数。

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/1c10feb59af07c2ef900735f88de97d9222818f02baf70533b8d8859fb2e1eba)  

[ MainActivity的方法数 ]

  

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/1120e5441dfa8482b32bac7ab4ee3ddc83243139cb3b645111345db371ad1e85)  

[ MainActivity.smali文件 ]

3个？为什么是3个？原来是多了`setContentView`这个方法。因为按照java的语义，如果有覆盖父类的方法，则会直接调用覆盖的方法。从`smali`文件可以看出`setContentView`是属于`MainActivity`的方法。

### （2）解决方案

那这次我们改成这样：

    
    
    public class MainActivity extends AppCompatActivity {
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            super.setContentView(R.layout.activity_main);
        }
    }
    

工具看下方法数：

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/9d636434802e75512a19b1ef0dbff21c7fd93289e7920c6c23967fced5a52bc5)  

[ 修改后MainActivity的方法数 ]

结果的确和我们手算出来的一样！

### （3） 其他特例

    
    
    public class MainActivity extends AppCompatActivity {
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            super.setContentView(R.layout.activity_main);
        }
    }
    
    public class TestActivity extends MainActivity {
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            super.setContentView(R.layout.activity_main);
        }
    }
    

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/70c0e45fe027e94c1d37f97d24be0b996805816c6ed0c0710c221b07afed8108)  

[ MainActivity和TestActivity的方法数 ]

  

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/ca838ded72ed18531ccbe233b05a05c44548d2456767ff907e647037168a27c4)  

[ TestActivity.smali文件 ]

方法数实际增加了**5**个。因为`TestActivity`的`super`就是`MainActivity`，而`MainActivity`并没有`setContentView`这个方法，而`AppCompatActivity`才有，所以这时候的`super.setContentView`相当于`this.setContentView`。  
这个其实也是有解决办法的，可以这样写`((AppCompatActivity)this).setContentView`。

### （4）综上所述：

子类中调用了父类中未被子类重写的方法时，请尽量使用`super`来调用或者使用方法的父类强转下`this`。

## 1.2 私有内部类

### （1）场景

    
    
    public class MainActivity extends AppCompatActivity {
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            super.setContentView(R.layout.activity_main);
            new Thread(new Task()).start();
        }
    
       private class Task implements Runnable{
    
            @Override
            public void run() {
            }
        }
    }
    

目测，`MainActivity`**2**个方法数（默认构造器、`onCreate`），`Task`**2**个方法数（默认构造器、`run`）。  
那，事实是不是这样呢？  
工具看下方法数：

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/6d282d86a43461838faab777f359e51e93896077f58c2650f98dc713fdf236d4)  

[ MainActivity和Task方法数 ]

  

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/83a749f7a12f60e69154049f7420077774a931068489ff6ecd6bb2e7a4b2531a)  

[ MainActivity$Task.smali文件 ]

`MainActivity`方法数没错，而`Task`实际上得出来的方法数却是**3**个。私有内部类默认直接增加了两个带参构造器。  
其他情况呢？

### （2）解决方案

实验了下非私有的内部类，是正常的,**2**个方法数。所以将内部类改成非`private`就能解决。

### （3）综上所述：

建议定义内部类是尽量使用非私有的。

## 1.3 在内部类中访问外部类的私有方法/变量

### （1）场景

    
    
    public class MainActivity extends AppCompatActivity {
    
        private String text = "在内部类里调用";
    
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            super.setContentView(R.layout.activity_main);
            new Thread(new Task()).start();
        }
    
       class Task implements Runnable{
    
            @Override
            public void run() {
                System.out.println(text);
            }
        }
    }
    

同`1.2`分析，目测是：`MainActivity`**2**个方法数（默认构造器、`onCreate`），`Task`**2**个方法数（默认构造器、`run`）。  
而实际上，是：

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/8ba1978507a5ae2edd9fe69c3cda340092b141d4a96fd43dfeb378a1f20f22b7)  

[ MainActivity和Task方法数 ]

  

![](/image/android_dai_ma_shang_jian_shao_fang_fa_shu_de_yi_xie_qi_ji_yin_qiao/bdce24771a54b0d4e4f618a2dc90ec4399d5d22fd4e7fdafa467a89cac1560f4)  

[ MainActivity.smali文件 ]

在外部类中，增加了一个`access$000`的方法，这方法是为了支持`Task`访问`MainActivity`的`private`变量。

若将字段变成非私有，就不会产生`access$000`的方法。

### （2）综上所述：

若外部类字段有可能被内部类访问到，就尽量不使用`private`。

# 三、总结

（1）子类中调用了父类中未被子类重写的方法时，请尽量使用`super`来调用。  
（2）建议定义内部类是尽量使用非私有的。  
（3）若外部类字段有可能被内部类访问到，就尽量不使用`private`。

