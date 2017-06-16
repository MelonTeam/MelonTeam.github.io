---
layout: post
title: "ndk代码支持断点调试"
date: 2017-04-25 10:40:00
categories: android
author: parrzhang
tags: android ndk
---

* content
{:toc}


# <font>背景</font>

android的ndk代码编写一直被认为是很痛苦的一件事情，除了android程序员对c++的陌生外，还有一个主要原因是无法断点调试。无法断点调试很难发现和排查问题，大大影响开发效率。实际上android studio从2.2开始就完全支持ndk开发，并且可以进行断点调试。

实际应用中发现，真正使用新版studio构建c/c++工程的项目极少。<strong>这里有个误区是android studio其实是支持ndk-build和cmake两种构建方式的</strong>，但是几乎所有的博客在给教程的时候都是用的官方推荐的cmake构建方式。老项目使用ndk-build构建，工程大的mk文件也很复杂，迁移和学习成本都很大。ndk-build和cmake只是编译方式的不同，两者均可以利用lldb进行断点调试，对于其它功能支持也是一样的。

从大的方向上来看，使用cmake构建很美好，cmake作为通用跨平台编译方案，以后肯定有更好的前景。但是对于android本身来说，大家相对都更熟悉ndk-build方案，而如果都能支持相同的功能，显然直接把ndk-build方案迁移过去成本最小。


<!--more-->


# <font>迁移步骤</font>

** **

下面给出ndk代码的迁移步骤（以下假设你的工程结构是studio工程结构）。build.gradle整体配置如下：

<font><img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/14325a357786d69da10e1b13a58e8ee64aa6aa255f868c5ccb052a4527963b53"/></font>

<font>0、首先，在app/src/main/中新建cpp文件夹，将原工程jni中的文件</font><font>全部复制过来到cpp文件夹中。</font>

<font><img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/dce6e999201f0fb58ecadfe0cde03a6c41343460c02d044fd3f3f1fc15367d93"/></font>

<font>1、配置ndk编译参数。<strong>注意有些博客提到可以设置arguments参数ndk_application_mk来支持原工程的application.mk配置文件，这个配置在最新版本的android studio实际验证无效。</strong></font>

<font>这一步实际上相当于application.mk文件的迁移。cppflags对应的就是application.mk中的app_cppflags配置，abifilters对应的是app_abi配置，其它参数配置则移到arguments中。</font>

<font>2、配置android.mk路径。这里是根据build.gradle设置的相对路径</font>

<font>3、添加支持的架构。官方工程给的方法是配置productflavors参数</font>

<font><img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/a164e2817ad8ef26da8f3e25a62471ea2ec0e0f9c78a02e520b89224912d540d"/></font>

<font>两种配置方法的区别在于，配置defaultconfig中的ndk的abifilters参数，android studio会将所有的架构so打包到一个apk中，但是如果使用productflavors，将会根据不同架构打包不同的apk。google play是支持根据架构下发不同apk到手机上的，但是国内的应用市场不支持。因此如果要在国内上线建议还是使用abifilters参数的方式。</font>

<font>4、打开gradle.properties，添加</font>

```
android.usedeprecatedndk=true
```

<font>这是因为工程仍然继续使用ndk-build构建方式</font>

<font/>

**官方文档上给了一个选择gradle关联外部cmake和ndk-build的可视化界面的方法。操作是打开project窗格并选择android视图，右键点击您想要关联到原生库的模块（例如 app 模块），并从菜单中选择 link c++ project with gradle。然后就可以看到这样的一个对话框**

**<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/f1a5e412c9bd3a24ecaca56f35c8dd19b9ba9987b53fbe3629e6a5ac050d7170"/>**

**但是我试着操作了一下，发现没有找到 link c++ project with gradle的选项。不过这个操作最终也是改gradle文件，我们直接修改gradle文件就行。**



<h1 class="p0" style="margin-bottom: 0pt; margin-top: 0pt;">补充</h1>

<p class="p0" style="margin-bottom: 0pt; margin-top: 0pt;"/>

<p class="p0" style="margin-bottom: 0pt; margin-top: 0pt;">如果有现有的so想要添加进去，可以在app/src/main中新建jnilibs文件夹，根据架构放入相应的so

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/6dc32278fc71028251262b84bf0f5f0c014f54282fcc4d07481650f33854186c"/>

使用android studio编译c/c++不会单独生成so，不过可以使用android studio的apk 分析工具查看生成的so。

选择build->analyze apk，从app/build/outputs/apk/目录中选择apk并点击ok。这时候可以在lib/<abi>/下看到相应的so</abi>

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/3d6de245a7267393ddf7dbff22232657bb95db7330bcb06ec1610794ce1693bf"/>



<h1 class="p0" style="margin-bottom: 0pt; margin-top: 0pt;"><font/></h1>

<h1 class="p0" style="margin-bottom: 0pt; margin-top: 0pt;"><font>断点调试和自动补全</font></h1>

<p/>

<p class="p0" style="margin-bottom: 0pt; margin-top: 0pt;"><font/>点击run app按钮，android studio会提示你下载缺失的组件，按照操作下载即可。

如果没有配置过ndk地址，需要在local.properties中配置ndk地址。

```
ndk.dir=/users/zhangpengyu/documents/android/android-ndk-r12
```

 运行后断点，attach到对应进程，等待lldb（android studio用于断点调试的工具）设置完成即可断点到对应工程。

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/00331e03be6027a6a2a95058035a64504c666164c24df3dc8a88b5d08a42cff2"/>

此时我们可以直接在android studio中编辑c++代码，支持自动补全，方法跳转。以及ide所有的其它常见操作，如格式化代码，重构变量名，查看引用等

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/78cd9aa85425a63bd753fc226393520e7156aa1ed2468f5c9a8ad742d809099f"/>

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/afde5ce0f9b7d44285e5709f31e9b5cb33e1141bdbfec00b21f7e223a744a2b6"/>

# 其它

作为强迫症知道官方推荐用cmake，就是想把项目切换成cmake构建怎么办。我自己试了一下把ffmpeg用cmake编译。其实这部分也有不少文章介绍，但是几乎所有的文章都是链接ffmpeg编译出的动态库。但是实际应用中，我们很少会把ffmpeg编译成动态库再做链接，因为这样安装包过大。我试着使用ffmpeg编译的静态库再使用cmake编译，出现如下错误。有知道如何解决麻烦告诉我<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/9f1e89dc2ebf7d47c4aff6eed8154d71ff6d681c1b66417f7f3abaa0b61d0f39" border="0"/>

<img src="/image/ndk_dai_ma_zhi_chi_duan_dian_diao_shi/abb2f7c536d012ff3b83496688fdbdeb7dcc4868f0d37fa36087ec4d898e0db3"/>

虽然ndk-build编译方案目前官方已经不再推荐，但是大部分时候来说，项目能够快速迁移ndk代码支持断点调试是第一位的。而在长期的历史进程中，我们也相信，google是一家有立场的公司。绝对不会像苹果公司一样，swift语言一个版本是一门语言，并且根本不向下兼容。不尊重开发者，一升级xcode就是不能用。ndk-build构建方式以后可能会不支持，但是那应该也是swift发布10.0版本的时候了。

# 总结

将ndk代码迁移到android studio中，让c++代码支持断点调试，自动补全，能大大提高我们的开发效率。需要在android中用到ndk编程的同学都可以试试。
