---
layout: post
title: "Android旁门左道之动态替换应用程序类"
date: 2017-08-31 23:04:00 +0800
categories: 未分类
author: yarkeyzhang
tags: Android 旁门左道
---

* content
{:toc}

| 导语 本文讲述如何通过替换应用程序类的方法，可以协助开发调试甚至应用于项目中。

作者： yarkeyzhang  2017.8.31

# 一，引子
<!--more-->

继上一篇文章（[Android旁门左道之动态替换系统View类](
"Android旁门左道之动态替换系统View类"
)）中我们讨论的，动态替换布局中的View，从而实现不需要修改xml布局文件的情况下控制View对象的创建。同事表示因吹斯听，思路轻奇；后来发现这个功能也可以应用于某些开发场景，比如日迹业务接入手Q基础拍摄框架，不需要修改到框架代码以及布局文件，通过动态替换View方案便可以实现业务特殊功能；以及用于定位并规避一些系统View类的Bug。然而自始至终我们一直局限在View的层次，有没有办法实现动态替换任意类？我们来继续讨论这个因吹斯听的话题吧！

# 二，安卓平台机制

Android App进程通过应用程序唯一的包名（package
name）可以获取到Apk包的信息（apk路径），然后通过dalvik.system.PathClassLoader来加载对应的应用程序类。而用户自定义的Application派生类（比如MyAppApplication）是一个应用程序中第一个被加载的用户类，我们查看它的ClassLoader如下：

    
    
    |- dalvik.system.PathClassLoader[DexPathList[[zip file "/data/app/com.xxx.xxx-1/base.apk"], nativeLibraryDirectories=[/data/app/com.xxx.xxx-1/lib/arm, /vendor/lib, /system/lib]]]
    |- java.lang.BootClassLoader

这里的BootClassLoader是PathClassLoader的“parent”。BootClassLoader可以加载各种基础的类（比如：List,String,Activity），PathClassLoader则完成从Apk中加载用户类。加载顺序：先BootClassLoader尝试加载，如果找不到类则由PathClassLoader加载。ClassA类加载ClassB类，默认使用ClassA类的ClassLoader。（包括new关键字，以及Class.forName(String)等等）

# 三，修改应用程序ClassLoader

我们的想法很简单，想要替换类，也就是能够控制类的加载，那么需要能够自行创建应用程序的ClassLoader。我们一旦成功地修改了应用程序ClassLoader，那么便可以动态控制用户类的加载。比如动态修改某个Activity（比如MyMainActivity）。只需要重写ClassLoader中的public
Class> loadClass(String className)方法。比如：（示意代码）

    
    
    public class MyClassLoader extends ClassLoader {
        @Override
        public Class> loadClass(String className) throws ClassNotFoundException {
            if (className.equals("com.xxx.xxx.OldActivity")) {
                className = “com.xxx.xxx.NewActivity”;
            }
            return super.loadClass(className);
        }
    }

如何修改应用程序ClassLoader？

### 1，插件框架方案：

有了解过插件框架原理的同学想必已经明白，比较彻底的做法是通过Android单进程多Application实例的特性：让假的FakeApplication先启动进程，然后构建一个NewClassLoader加载真正的MyAppApplication类。这样一来，我们整个App的用户代码都会被NewClassLoader加载，而不是默认的PathClassLoader。在NewClassLoader的实现中做手脚，我们可以动态替换类。插件框架的改动会比较大，我们不想把事情搞太大，看看能否在应用内自身完成替换。对插件框架有兴趣的我们可以私下一起讨论。

### 2，应用自身替换

应用自身替换，也就是需要在Application类以及启动之后开始做手脚。

    
    
    private static boolean hookPackageClassLoader(Context context, ClassLoader appClassLoaderNew) {
        try {
            Field packageInfoField = Class.forName("android.app.ContextImpl").getDeclaredField("mPackageInfo");
            packageInfoField.setAccessible(true);
            Object loadedApkObject = packageInfoField.get(context);
            Class> LoadedApkClass = Class.forName("android.app.LoadedApk");
            Method getClassLoaderMethod = LoadedApkClass.getDeclaredMethod("getClassLoader");
            ClassLoader appClassLoaderOld = (ClassLoader) getClassLoaderMethod.invoke(loadedApkObject);
            Field appClassLoaderField = LoadedApkClass.getDeclaredField("mClassLoader");
            appClassLoaderField.setAccessible(true);
            appClassLoaderField.set(loadedApkObject, appClassLoaderNew);
            return true;
        } catch (Throwable ignored) {
        }
        return false;
    }
    
    public class MyAppApplication extends Application {
        @Override
        protected void attachBaseContext(Context base) {
            super.attachBaseContext(base);
            hookPackageClassLoader(base, new NewClassLoader());
        }
    }

替换一个应用程序的ClassLoader核心代码如上所示。加上了以上的代码之后，启动一下我们的首页MyMainActivity。

    
    
    public class MyMainActivity extends Activity {
        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            Log.e("MyMainActivity", "getClass().getClassLoader() : " + getClass().getClassLoader());
            Log.e("MyMainActivity", "getClassLoader() : " + getClassLoader());
            Log.e("MyMainActivity", "MyView classLoader : " + MyView.class.getClassLoader());
        }
    }

非常成功！我们发现MyMainActivity.class，以及context.getClassLoader都会是我们自定义的NewClassLoader。而且！如上第三句日志，自定义MyView类，它的ClassLoader也是NewClassLoader，也证明了ClassLoader的“传承”。自此，MyMainActivity类中加载的类都会经过NewClassLoader，于是我们可以控制它们的加载。

但是！这里比插件框架方案迟了一步。细心的你发现了问题，也就是说无论如何，我们的MyAppApplication类需要先被系统加载起来，它的ClassLoader是系统创建的PathClassLoader，而不是我们想要的NewClassLoader。根据以上我们说的“传承”，那么MyAppApplication类中创建出来的对象，都会跟随MyAppApplication类的ClassLoader。这些对象之后创建的对象，也会是如此！这条线我们无法控制。

# 四，类加载器终极修改

![“美女”的图片搜索结果](/image/android_pang_men_zuo_dao_zhi_dong_tai_ti_huan_ying_yong_cheng_xu_lei/fd84528328db0cc860f13ec8a6db12846e0f05b283fdc92cde77ee9bb3c72c5d)

_待续，记得再来看我 ... ( ⊙ o ⊙ )_

