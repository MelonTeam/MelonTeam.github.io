---
layout: post
title: "把你的Android Library开源给全世界"
date: 2017-10-29 18:04:00 +0800
categories: android
author: vincanyang
tags: jcenter
---

* content
{:toc}

| 导语 想要把自己的开源组件分享给全世界，除了github，你还需要JCenter。

在Android Studio想要引用某个第三方library库，只要在项目文件build.gradle中添加一行代码即可：

    
<!--more-->
    
    dependencies {
        compile 'com.vincan:medialoader:1.0.0'
    }

就是这么简单，但这个library库是哪里来的呢？对java熟知的人都知道maven，没错，build.gradle里引用的第三方库都是来自maven仓库。目前Android
Studio最为常用的、默认的maven库就是JCenter。

## JCenter

JCenter是一个由[bintray.com](https://bintray.com/)维护的Maven仓库 。我们在项目的build.gradle
文件中如下定义仓库，就能使用JCenter了：

    
    
    allprojects {
        repositories {
            JCenter()
        }
    }

起初，Android Studio 选择Maven Central作为默认仓库。但是Maven
Central上传library异常困难，其他方面对开发者也不够友好。所以Android
Studio从0.8版本起，就将默认的Maven仓库由mavenCentral变为了JCenter。

相比Maven Central，JCenter主要有如下几个优势：

l  JCenter支持CDN传输library，开发者可以享受到更快的下载体验。

l  JCenter是全世界最大的Java仓库，是Maven Central的超集。

l  更容易上传，不需要像在 Maven Central上做很多复杂的事情。

l  支持library上传到 Maven Central 。

所以JCenter成为Android Studio默认的maven仓库已经毫无争议。

## 将Android library发布到JCenter

那么，如果我们想把自己的开源组件分享出去，也就是说怎么把一个library发布到JCenter呢？接下来我们以[MediaLoader](

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/99c5e72721b4f67d50cd61a48444a205419b82619433c014ebb1292216d7dcc1)

### 注册bintray帐号



![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/ebbfa48073579d1a93ef1c1f3de10121005adfa502f3e3ba15a4102128a20da6)

首先，我们需要注册bintray帐号。如上图所示，bintray的注册账号分为两种：分别是企业版本（图片左侧）和开源版本（图片右侧），前者可试用一段时间后再收费，开源版本相对享受较少的功能，但并不影响我们上传的功能，所以我们这里选择开源版本。

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/eaa63569258386efdfad6da2041a9434ef1d95ffbb469a5aba8c86acf6caa22b)

进入注册界面后，开始注册并通过邮箱激活，也可以选择更为方便的第三方注册如github，注册过程比较简单，不再赘述。

### 添加maven仓库

注册帐号后登录，新用户默认是没有maven仓库的，所以登录后我们首先需要创建一个maven repository，点击“Add New
Repository”：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/3d2bc6ebcc5e9b6206de32ff01a23a531622a368e367cde85998cb58a287e522)

然后，Repository  Name填写“maven”，Repository Type选择Maven：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/84375a38487032b3664689d4e08bac26a869cc7c68eb094fac56e9234d10a182)

点击“Create”，完成maven repository的创建。

### 引用bintray-release

接下来，我们需要在library中引用bintray-release，在build.gradle文件中增加如下配置：

第1步：添加编译依赖

    
    
    buildscript {
        repositories {
            JCenter()
        }
        dependencies {
            classpath 'com.novoda:bintray-release:0.3.4'
        }
    }

第2步：将library设置为bintray插件工程

    
    
    apply plugin: 'bintray-release'

第3步：添加发布信息

    
    
    publish {
        userOrg = 'yangwencan2002'//bintray.com用户名
        groupId = 'com.vincan'//library包名
        artifactId = 'medialoader'//library名称
        publishVersion = android.defaultConfig.versionName//版本号
        desc = 'Cache video/audio while playing for any android media player'//描述
        website = '
    }

### 编译并上传library文件

在引入bintray-release后，我们就可以使用bintrayUpload命令进行上传了，在Android
Studio的Terminal控制台输入如下命令：

    
    
    gradlew clean build bintrayUpload
     -PbintrayUser=yangwencan2002//bintray.com用户名
     -PbintrayKey=xxxxxxxxxxxxxxxxxxxxxx//bintray.com API Key
     -PdryRun=false

其中，PbintrayKey也就是API Key，在bintray.com的Edit Profile中可以获取到，如下图：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/8f3b65e58f0c70a83ce0b69b5aad1f512d25350960187bd50dc310f1c04b3446)

最终在Android Studio的Terminal控制台输入效果图如下：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/b0aa02a2d0719f3e2faae622da702af3e9f322f5991e14a09035021fc0de719c)

命令BUILD SUCCESSFUL后，在maven库下就可以看到上传library对应的package信息（package是maven
repository
下的组件名称，bintrayUpload命令会检测package是否存在，如果不存在就创建，实际上我们也可以在bintray.com上先手动创建package），如下所示

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/cccf33978e1830a98f8eb56e69cb863e69de89e7a9bd546274154f9f1a466a29)

### 提交JCenter审核

虽然我们已经能够在bintray.com上看到我们的library信息，但是还不能被引用，原因是因为它还没真正被加入到JCenter，所以我们还需要把它添加到JCenter。

进入library的package信息页面后，点击“Add To JCenter”进行添加：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/e995828a740ac3e5378c3e4feaad8880adf2855140d87ca2d23239fc659d4c0e)

然后填写一下你对该library的简单描述后提交就可以了。整个流程到此就结束了，不过最后还需要bintray的人工审核（通常需要3个小时以上），审核通过后会给你发送站内信息，如下图：

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/4b41aa20b59c622c6191c5b13b982579eccb451dd764040271c86de9dadce01f)

你也可以通过url（

![](/image/ba_ni_de_android_library_kai_yuan_gei_quan_shi_jie/cb678155f2c27c2e4fe0daada79d33c90855532cd6872d3332c6bd52a534559d)

### 总结

最后，总结一下整个过程如下：

1、注册bintray帐号（首次才需要）

2、添加maven仓库（首次才需要）

3、引用bintray-release

4、编译并上传library文件

5、提交JCenter审核

## 可能会遇到的问题

1、androidstudio mavenAndroidJavadocs FAILED GBK编码不可映射：

这是因为在构建javadocs时，代码注释中包含中文，所以需要在library的build.gradle添加：

    
    
    tasks.withType(Javadoc) {
        options {
            encoding "UTF-8"
            charSet 'UTF-8'
            links "http://docs.oracle.com/javase/7/docs/api"
        }
    }

或者干脆不要构建javadocs：

    
    
    tasks.withType(Javadoc).all {
        enabled = false
    }

2、Error:Execution failed for task ‘:xxx:bintrayUpload’.> Could not create
package> ‘xxxxx/maven/xxxxxxxxx’: HTTP/1.1 401 Unauthorized：

这是认证错误，可能是用户名或API Key出错导致。

3、lint报错：

解决报错或按提示在library的build.gradle添加如下即可：

    
    
    android {
        lintOptions {
            abortOnError false
        }
    }

