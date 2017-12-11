---
layout: post
title: "Android资源热修复之修改aapt源码"
date: 2017-08-31 18:07:00 +0800
categories: android
author: andyqtchen
tags: 热修复 资源 Android AAPT
---

* content
{:toc}

| 导语 在Windows下定制自己的aapt！

## 一、环境配置

### 1.1 软件和源码
<!--more-->

`Codeblocks`下载地址：<  
`mingw64`下载地址：<https://jaist.dl.sourceforge.net/project/tdm-gcc/TDM-
GCC%20Installer/>  
`aapt`源码地址（为了避免麻烦，特地弄好了`aapt`的`Codeblocks`项目，直接从我的`github`上`clone`下来就能在`Codeblocks`中用）：<https://github.com/ClaymanTwinkle/aapt>

### 1.2 软件配置

> 软件安装好了就要先配置下

#### 1.2.1`Codeblocks`配置`Compiler`

**步骤一：**  
选择进入工具栏 `Settings` >> `Compiler`，如下图所示；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/b95b4dac559d1bb0d6f10133ff21a044dee876f66971c7cea3e845c5565817c9)

**步骤二：**  
（1）选择`Global compiler settings`；  
（2）在`Selected compiler`中选择`GNU GCC Compiler`，然后下方点击`Copy`按钮，就会出现`Copy of GNU
GCC Compiler`；  
（3）在下方`Toolchain executables`配置`mingw64`，相关配置如下图所示；  
（4）最后选择`OK`即可；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/84f70e48d3b15134b78c70cd0ab9a2a4c029095ddc382ecb7d40b67425e1dd85)

配置好编译环境后，就可以打开项目了；进入`aapt/aapt-v24`中打开`aapt-v24.workspace`；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/69af3770563d9a3fc0837cfadb2f48fd198a472b88956a0c983434b0bb9422d0)

工程目录结构如下图所示；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/bc88e6cda6814e924837401befb2a0dd3fc04f0b635ce6e7797b6b3fa51e713c)

#### 1.2.2 为每个工程配置`Compiler`

**步骤一：右键一个工程，在右键菜单中选择`Build Options`；**

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/17c393334d5bbb8cb50779ca9cb49e73e946a97a4d8006dd948ce02c142dca09)

**步骤二：第一次配置的时候，会出现一个弹窗，如下图；选择刚刚自己创建的`Copy of GNU GCC Compiler`，点击确定；**

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/6d8ca880c6e103c585589a3aa74edb177c7ed8599a4c525c35a768170a16d808)

**步骤三：注意，如果此时，出现以下对话框，请选择`否`；**

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/ceaeba9afb605e9e09f3e10d9668c4c7788d3ee8df1b86801d7f41a9a5a93605)

> 对每个工程重复以上步骤；

## 二、改`aapt`源码

> 没错，如果上面的步骤都弄成功了，现在就可以改aapt源码了，是的，在Windows上改aapt源码，想想就激动！  
>
普及一下一个小知识，在`R.Java`中可以看到系统资源的id都是以`0x01`开头的，而自己的资源id都是以`0x7f`开头的；这也就是说`0x01`到`0x7f`之间的的值我们都可以拿来用。  
> 废话不多说，赶紧动手！

### 2.1 试改`0x7f`为`0x66`

（1）在`CodeBlocks`中打开`aapt-v24`，找到我们要找的入口类`main.cpp`；同时也找到了入口方法`main`；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/f20040230e62f5b75faad7cb7f6b51625174368eb746b9c4c30d911697253cfd)

（2）找到这个`main.cpp`有什么用，怎么修改`0x7f`呢？

> 我们可以这样，按快捷键`Ctrl+F`（真的很好用！），在`aapt-v24`中搜索`0x7f`，如下图所示；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/21f21cf85a5aa8a879ac99c36957b48368b89cba0a6cf1e56cf28e096b356c7b)

> 搜索结果如下，这样我们就找到赋值`0x7f`的地方了；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/dbd57b0f394857382f87d9fb7fdebb6a0ff1301bffbc20b35c3cb862ab4337fc)

> 在`ResourceTable.cpp`这个类中；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/eac1fe2c22a06907572f9a3584dbe741bb2aac54dd6e2a4bc7cedd2a579c134a)

（3）既然找到了位置，那赶紧改下这个值试试（直接改硬编码不太优雅，后面介绍一种优雅的方式），修改结果如下图所示；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/a00e514c3136e1d4d38a24a7c3731841d6fae223745d9f1fd656fafa79864c5e)

> 接着，打包出自己的`aapt`吧！

（4）右键`aapt-v24`，在右键菜单中选择`build`或者`rebuild`，编译成功，打包出`aapt.exe`。

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/59da4fb6735d4010ace37432080f3385239e7730d54037cea44aee7dfc4f2396)

  

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/7b8840ed98bb9dabe6b02cbcdfcd4a7277ca23bf0d6da9ab7fc835887d82eaf8)

> 从`aapt\aapt-v24\bin\Debug`目录下可以看到打包好的`aapt-24.exe`。

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/47ac807423f0230eb5ccdab6cfc1bc099a93392fc1050a4130648b0a62dab31a)

（5）打包好了，是骡子是马牵出来溜溜吧。

> 随便找个`Android`工程，然后在`cmd`中敲出类似这样一段命令行生成`R.java`：

>  
>  
>     aapt-v24.exe p -f -m -I C:\Android\sdk\platforms\android-25\android.jar
-J C:\Users\andyqtchen\Desktop\plurals -M
C:\Android\workspace\AndroidQQ_Lite_proj/QQLite//AndroidManifest.xml -S
C:\Android\workspace\AndroidQQ_Lite_proj/QQLite/res

>  
>

>
结果……出乎意料啊，居然错了，是啊，哪有那么容易，想得美；但是，这些`log`好像是`aapt`自己内部打印出来吧？让我们看看这些`log`是从哪里打印出来的！

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/53b65ae42cc9a0503923f783f35d7a4668fdbce385076d377429884d9fce71d4)

（6）神一样的快捷键`Ctrl+F`，搜~，结果如下图所示；

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/3deda53b7779f1fa959977e12e604818cfb46c922d116c2ca281fe295d79f853)

> 原来是在`androidfw`工程下的`ResourceTypes.cpp`搞的鬼！  
> 先看看`ResourceTypes.cpp`耍的是什么把戏！

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/f529e549440cda36d0350018edaec69e255e7decc7eb4c3899ae7c45e11b594b)

> 原来是这么回事，`aapt`除了会在`aapt-v24`中赋值，在`androidfw`中后面还会做一个判断拦截；

那么我在这里再加一个或者`packageId==0x66`就ok了（又一不文明操作，请勿模仿）！  
改完重新`rebuild androidfw`，然后`rebuild aapt-24`打包出`aapt.exe`；  
重新生成一次`R.java`，接下来就是见证奇迹的时刻！

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/02f743a8cf0643b9ba89dc9bcabb2ed3ec8c59c264a7e8ec0a1d485b4b95ad0d)

  

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/5351afd107a5c076a2a19463299f644420eaf1b52b8658a59fc2bff9d045252d)

### 2.2 定制化`aapt`

> 好了，上面的`2.1`只是小打小闹的一个实验而已，接下来要定制下随意修改资源`ID`前缀（`packageId`）的`aapt`；

#### 步骤一、定义一个单例

> 我在`androidfw`中定义一个单例，用来记录`0x7f`（默认值）或者其他自定义`packageId`的值；

    
    
    // BlinkPackageId.h文件
    #ifndef __BlinkPackageId_h
    #define __BlinkPackageId_h
    
    #include 
    #include 
    #include 
    #include 
    #include 
    #include 
    #include 
    
    using namespace std;
    
    class BlinkPackageId
    {
            ssize_t mPackageId;
    public:
            static BlinkPackageId* getInstance()
            {
                    static BlinkPackageId instance;
                    return &instance;
            }
            ssize_t getPackageId();
            void setPackageId(ssize_t packageId);
            void setPackageId(const char* packageId);
    protected:
            struct Object_Creator
            {
                    Object_Creator()
                    {
                            BlinkPackageId::getInstance();
                    }
            };
            static Object_Creator _object_creator;
            BlinkPackageId() {
                    mPackageId=0x7f;
            }
            ~BlinkPackageId() {
            }
    };
    #endif
    
    
    
    // BlinkPackageId.cpp文件
    #include 
    
    #include 
    #include 
    #include 
    using namespace std;
    
    // char2int
    static uint32_t apkgetHex(char c, bool* outError){
        if (c >= '0' && c <= '9') {
            return c - '0';
        } else if (c >= 'a' && c <= 'f') {
            return c - 'a' + 0xa;
        } else if (c >= 'A' && c <= 'F') {
            return c - 'A' + 0xa;
        }
        *outError = true;
        return 0;
    }
    
    // string2int
    static ssize_t apkStringToInt(const android::String8& s){
        size_t i = 0;
        ssize_t val = 0;
        size_t len=s.length();
        if (s[i] < '0' || s[i] > '9') {
            return -1;
        }
        // Decimal or hex?
        if (s[i] == '0' && s[i+1] == 'x') {
            i += 2;
            bool error = false;
            while (i < len && !error) {
                val = (val*16) + apkgetHex(s[i], &error);
                i++;
            }
            if (error) {
                return -1;
            }
        } else {
            while (i < len) {
                if (s[i] < '0' || s[i] > '9') {
                    return false;
                }
                val = (val*10) + s[i]-'0';
                i++;
            }
        }
        if (i == len) {
            return val;
        }
        return -1;
    }
    
    BlinkPackageId::Object_Creator BlinkPackageId::_object_creator;
    
    ssize_t BlinkPackageId::getPackageId(){
            return mPackageId;
    }
    void BlinkPackageId::setPackageId(ssize_t  packageId){
            mPackageId=packageId;
    }
    void BlinkPackageId::setPackageId(const char* packageId){
            android::String8 str = android::String8(packageId);
            mPackageId=apkStringToInt(str);
    }
    

#### 步骤二、改造`aapt`命令行

> 定个需求，要加个`--blink-package-id`命令参数，后面带`packageId`;

锁定到`aapt-v24`工程下`main.cpp`源代码：

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/d9f00bf2e029db7e0cc052c1e163c4d6704a10350a1cfd35a0c6b9384ee7e592)

在`ResourceTable.cpp`，将`0x7f`改成`BlinkPackageId::getInstance()->getPackageId()`

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/fc0250f32ce7c6a986cf5b008d7fd5f5ec9d3cf6bfd0aad365d05c4363e936ec)

然后到`androidfw`工程下，把`BlinkPackageId::getInstance()->getPackageId()`放到`if`中：

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/999b81889cdcdd7b06ebd813efcb2c18344950bdbf0f0dd2cef065bfadc250b4)

> ok！大功告成！

看看效果！！！

    
    
    aapt-v24.exe p -f -m -I C:\Android\sdk\platforms\android-25\android.jar -J C:\Users\andyqtchen\Desktop\plurals -M C:\Android\workspace\AndroidQQ_Lite_proj/QQLite//AndroidManifest.xml -S C:\Android\workspace\AndroidQQ_Lite_proj/QQLite/res --blink-package-id 0x55
    

![](/image/android_zi_yuan_re_xiu_fu_zhi_xiu_gai_aapt_yuan_ma/3339a3eddad5947ecc56eab444b826d138bd499b5042aa37a4900e45e153751c)

## 参考文章

[如何实现携程动态加载插件中对aapt的改造](http://blog.csdn.net/lzyzsd/article/details/49768283)  
[
Android中如何修改编译的资源ID值(默认值是0x7F…可以随意改成0x02~0x7E)](http://blog.csdn.net/jiangwei0910410003/article/details/50820219)

