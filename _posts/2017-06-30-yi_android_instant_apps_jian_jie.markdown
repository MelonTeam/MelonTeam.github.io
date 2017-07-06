---
layout: post
title: "[译]Android Instant Apps简介"
date: 2017-06-30 16:09:00
categories: android
author: jennyxia
tags: App Instant
---

* content
{:toc}

| 导语 Google最近发布了Instant Apps，可以帮助开发者进一步的增强Android的原生App体验。Instant
Apps旨在通过在需要时只下载应用程序的一部分，帮助用户尽可能快地进入最佳原生App体验。即使没有在他们的设备上安装应用，也可以快速轻松地用优秀的移动应用体验吸引用户。

Android Instant Apps是通过一个个小的功能模块传递给用户的，每个模块仅包含完成特定操作所需的代码和资源。Instant
Apps由URL触发，这意味着它们可以从任何位置启动，包括搜索结果，社交媒体分享，消息，beacons，NFC和其他应用程序甚至其他的Instant
<!--more-->
Apps。

Instant Apps与安装的对应软件apk共享一个代码库，并也是通过Google Play商店的Android Instant Apps区进行分发的。

##

## 开发即时应用程序

### 工具

为了开始使用Instant Apps，我们需要获得一些新的工具。

  1. Android Studio 3.0和Instant apps SDK ——除了Instant apps SDK外，Google还宣布推出[Android Studio 3.0 Preview](https://androidstudio.googleblog.com/2017/05/android-studio-30-canary-1-sdk-updates.html)，并附带了许多全新的功能，包括Instant Apps支持。需要下载并安装它才能开始使用。[这里](https://developer.android.com/topic/instant-apps/getting-started/setup.html)提供了一整套说明[](https://developer.android.com/topic/instant-apps/getting-started/setup.html)

  2. Gradle 4.0（Nightly）—— 随着其他改进，Gradle 4.0还提供了[新的依赖配置](https://docs.gradle.org/current/userguide/java_library_plugin.html#sec:java_library_separation)供你使用。值得一提的是，Gradle3.4废弃了`compile`配置，支持`api`和`implementation`。这些新配置可帮助你来控制哪些是作为公共的API的依赖; `Implementation`用于声明只在模块内部可用的依赖项，而声明的依赖关系`api`将被导出并提供给后续部分。

  3. 用于Gradle 3.0.0-alpha1的Android插件 —— 这附带了一些新的gradle插件，可帮助你模块化应用程序; `com.android.instantapp`和`com.android.feature`。

  4.  Instant Apps API——Google还提供了一个方便的实用程序集合，你可以将其包含在你的项目中：

    
    
    implementation “com.google.android.instantapps:instantapps:1.0.0”
    

它包含一些有用的静态方法来帮助检查用户是在和即时的还是安装的版本进行交互，并使用系统对话框提示他们安装完整的APK。

##

## 确定用例

第一个也许最重要的一步是确定应用程序的哪些部分最适合使用 Instant Apps 中的功能。 Instant Apps
由操作驱动，并在用户需要时将其自动提供给用户。例如，一个在停车场的用户可能没有安装停车计费器App，但是使用Instant
Apps，所有用户需要做的是访问URL，而native App可以快速，轻松的利用所有的支付API完成支付。

> Instant Apps should focus primarily on helping users complete whatever task
they set out to do with as little friction as possible, not drive full app
installs.（即时应用程序应该主要侧重于帮助用户完成任何他们设置的任务，尽可能少的摩擦，而不是驱动完整的应用程序安装。）

### 支持Deep Link和App Link

如果你已经完成了一个支持多个用户流的复杂应用程序，则可能会实现Deep
Link（深层链接）。深层链接允许任何人创建一个URL，直接链接到应用程序中的特定页面。由于 Instant App运行在网址上，因此Deep
Link和App Link已成为必需。常规深层链接的一个主要区别是不支持自定义URI scheme，例如

    
    
    myshoppingapp://products/600613
    

相反，你现在必须支持https URL

    
    
    https://.com/products/600613
    

如果你愿意，你可以继续在已安装的应用程序中使用自定义scheme，但是有一个很好的例子可以将所有深层链接切换到URL。Instant
App中的每个功能必须至少有一个入口点被定义为深层链接。这决定了用户在点击Instant App Url时会看到什么，或者是否从Instant
App中的其他功能导航到该功能。下面是一个将Deep Link模式绑定到一个`Activity`的 intent filter 的示例

    
    
    
                
                    
    
                    
                    
    
                    
                    
                    
                    
                
            
    

在这种情况下，`ItemDetailActivity`将在用户访问时launch

`https://bumblebee.willowtreeapps.com/items/600613`。

##

## App Links

其次，你还需要将你的web域与Instant App的包名相关联。这种绑定，称为Android App
Links，向Google证明你拥有并可以控制你想与应用关联的web域。以前，App
Links允许安装的应用程序自动将自己与你的网站关联，以便用户点击你的网站的URL时，他们会跳过提示对话框，直接转到你的应用程序。现在，通过为你的Instant
App设置App LInks，没有安装应用的用户将无缝地路由到你的Instant App。App
LInks对于已安装的应用程序是可选的，因为用户可以手动选择要处理Deep LInks的应用程序，但是，App LInks是Instant
App工作的必要条件。要设置它，你只需要在你的域或子域的根目录上托管一个JSON文件 `/.well-known/assetlinks.json`

    
    
    [
      {
        "relation": [
          "delegate_permission/common.handle_all_urls"
        ],
        "target": {
          "namespace": "android_app",
          "package_name": "com.myapp.packagename",
          "sha256_cert_fingerprints": [
            "96:14:26:30:CC:E3:C0:9B:05:12:7B:9A:31:9E:88:36:82:12:84:27:4C:52:2F:05:FE:66:A8:AB:B9:F0:F5:F0"
          ]
        }
      }
    ]
    

Instant App模块将需要具有单独的包名称来命名空间，你的Instant
App和可安装的应用程序可以共享其应用程序ID，因此你只需要在该`"package_name"`字段中注册该应用程序ID
。你可以在[这里](https://developer.android.com/training/app-
links/index.html)找到有关设置app links的更多信息。

##

## 模块化并重构应用

这可能是将Instant App集成到现有应用程序中最困难的一步。这是因为今天绝大多数应用程序大多是单个模块构建，支持Instant
Apps需要开发人员将其构建分为多个称为 features的模块。每个功能都代表应用程序的一部分，可以根据需要下载。

![功能模块关系](/image/yi_android_instant_apps_jian_jie/5659a05bdc421934a94770c0fe7e102d28101fa7d6462e0fbe5539e94de2f517)

  1. Feature modules ——  是应用新的 `com.android.feature 的`Gradle插件的模块。它们只是library 项目，`aar`在被其他模块使用时产生。值得注意的是，它们没有应用程序ID，因为它们只是library 项目。

    
    
    apply plugin: 'com.android.feature'
    android {
        ...
    }
    dependencies {
        implementation project(':base')
        ...
    }
    

Feature module 的manifest 也值得注意，因为它在功能上只是完整的应用程序的一部分，它的manifest
将在项目组合时与其他人合并。因此，Feature 的manifest应包含模块中包含的Activities 。每个Feature 的manifest
也应包含该模块的唯一包名称。

例如，这里是一个Feature module例子的manifest 。

    
    
    
        
            
                
                    
    
                    
                    
    
                    
                
                
                    
                    
                
            
        
    
    

  2. Base feature module —— 基本功能模块可以被认为是项目的根。它包含其他模块要使用的共享代码和资源。这个基本功能模块与其他feature的区别是`baseFeature`设置为`true`。

> 使用功能模块的每个项目必须具有一个基本模块，每个功能模块必须依赖于基本模块。

以下是基本功能模块构建脚本示例。

    
    
    apply plugin: "com.android.feature"
    
    android {
        baseFeature true
        ...
    }
    
    dependencies {
        feature project(“:feature”)
        application project(“:app”)
        ...
    }
    

基本功能的manifest 通常包含全局内容，如应用程序标签。这是一个示例base feature manifest 。

    
    
    
    
    
        
    
            
                
            
        
    
    
    

虽然不是强制性的，但建议基本功能manifest包含引用实现`default-
url`元数据的Activity的Activity标签。这告诉Android，如果你的即时应用程序没有从Deep
Links打开，而是像launcher这样的地方，Android会启动哪些Activity。

  3. APK模块——这是我们都熟悉的普通build模块。现在，它的设置是为了输出`apk`要安装在用户设备上的基础和功能模块。由于它的目的是输出一个可安装的artifact ，这个模块确实有一个应用程序ID。

    
    
    apply plugin: 'com.android.application'
    
    android {
        defaultConfig {
            applicationId "com.willowtreeapps.instantappsdemo.apk"
            ...
        }
        ...
    }
    
    dependencies {
      implementation project(":my-base-feature")
      implementation project(":my-feature")
    }
    

这里的应用程序manifest 是将所有其他从其他功能模块继承的manifest合并的结果。

    
    
    
    
    

  4. Instant App模块 - implements  `com.android.instant`插件。消费功能模块，并生成一个拆分APK zip，其中包含将进入Instant App的所有功能。它几乎是一个没有清单的manifest的空壳，只能在项目中实现其他功能功能模块。

以下是Instant App模块构建脚本的示例。

    
    
    apply plugin: "com.android.instantapp"
    
    dependencies {
        implementation project(":my-base-feature")
        implementation project(":my-feature")
    }
    

###

## 可能遇到的问题

现在我们已经了解了Instant Apps的结构，重要的是要看看我们在集成一个Instant
App时遇到的一些问题。你依赖的某些gradle插件可能无法正常工作。许多用于Android项目的gradle插件使用`com.android.application`或`com.android.library`插件检查模块。虽然新的`com.android.feature`插件，与library项目类似，他们没有样本包名，所以你最喜欢的gradle插件可能需要更新。

在支持Instant Apps时，使用deep links可以实现所有的应用内导航，在某些情况下也是有必要的。如果你刚刚添加https deep
links到你的应用程序（或切换到自定义方案），你可能会注意到，当通过深层链接从一个activity 导航到另一个activity
时，Android会弹出提示对话框。系统需要用户决定是否处理网页浏览器或应用程序中的deep
link。显然，你希望用户默认保留在你的应用程序中，而不让他们选择离开Web浏览器。这通过如上所述实现App
Links来解决。但是，如果在开发过程中你没有正确的Web服务器设置，你可以实现此解决方法，以避免弹出对话框：

    
    
    private static void invokeDeepLink(Context context, String deepLink) {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(deepLink));
            intent.setPackage(context.getPackageName()); // direct to activities in this app
            context.startActivity(intent);
        }
    

你可以从Context获取应用程序的包名称，并强制VIEW `Intent`仅考虑你的包名称下的Activity。

##

## 部署

### 开发测试

为了在开发过程中本地测试你的Instant App，你显然可以使用Android Studio来运行Instant App。下面说说它是怎么运作的。

我们假设你的instant-app模块名字是`instantapp`。首先运行gradle任务 `gradle
:instantapp:assembleDebug`
这将在你的builds文件夹中产生一个zip。接下来解压缩这个zip，你会发现几个APK，每个功能模块一个。最后运行这个adb命令

 `adb install-multiple -r -t --ephemeral base.apk feature1.apk feature2.apk`

来同时安装所有这些APK。
其中`base.apk`，`feature1.apk`和`feature2.apk`是你的功能APK。警告：我们注意到这个adb命令可能会间歇性地失败。。。。

### 发布

为了将Instant App发布到Google Play商店，你只需运行与上述相同的gradle task，但使用发行版本： `gradle
:instantapp:assembleRelease` 然后将zip存档上传到Play
Store控制台。你不需要解压缩。但是，在Google接受你的即时应用之前，你需要确保某些设置正确。

### 代码签名

Instant
Apps本质上是一组APK，每个功能模块一个。因此，你需要以与签名可安装APK相同的方式签名这些APK。这意味着你需要为每个功能模块`build.gradle`（包括基本功能模块）添加一个签名配置。

### Intent Filters

为了部署你的即时应用程序，你还需要验证你的manifests 中的intent
filters符不符合格式。有关工作设置的示例，请参阅上述``声明`ItemDetailActivity`。以下是关键点：

确保包括`android:autoVerify="true"`。此属性告诉Android自动验证你的App Links。由于即时应用程式适用于App
Links，因此此属性是必需的。确保你使用多个``标签，每个标签只有一个属性。所以不用这个

    
    
    
    

你应该使用

    
    
    
    
    
    
    

注意上面我们添加了一个方案声明`http`。虽然即时应用程序只支持`https`网址，你的意图过滤器需要同时处理`http`和`https`。

##

## 示例应用程序：Bumblebee

我们构建了一个名为“Bumblebee”的示例应用程序，只是为了了解Instant
Apps的可行性。Bumblebee是一个虚构的商店，有一个简单的目录和可共享的购物车。它使用Firebase进行目录数据，用户数据和资源托管。我们还使用Google的新架构组件构建了该应用程序，我们发现这些应用程序非常有用且易于使用。你可以在这里查看这些新的架构库的更详细的细节，我们建议你查看Eric
Richardson发布的这些文章。

[Lifecycles of the rich and
famous](https://willowtreeapps.com/ideas/google-i-o-2017-lifecycles-of-the-
rich-and-famous)

[The viewmodel is nice from up
here](https://willowtreeapps.com/ideas/google-i-o-2017-the-viewmodel-is-nice-
from-up-here)

Bumblebee是一个具有三个功能模块的即时应用程序，每个功能模块都包含自己的页面。根进入点是浏览功能，显示可购买的产品网格（实际上只是我们发现在办公室周围的物品的照片）。点击一个可以进入“物料明细”功能，其中列出了价格和完整描述。从这里，你可以选择将该项目添加到你的购物车。你可以使用购物车功能查看它，并轻松地共享你的购物车的即时应用程序链接。请记住，即时应用链接只是网址。你共享链接的任何人都可以立即直接访问你的购物车作为即时应用程序，而无需下载目录功能。

以下是你可以在Android手机上打开的一些链接来尝试 Bumblebee：

<https://bumblebee.willowtreeapps.com/>

<https://bumblebee.willowtreeapps.com/item/0>

你可以通过adb命令调用这些URL作为intents ：

    
    
    adb shell am start -a android.intent.action.VIEW -d "https://bumblebee.willowtreeapps.com/"
    

github repo ：[https](https://github.com/willowtreeapps/android-instant-apps-
demo/):[//github.com/willowtreeapps/android-instant-apps-
demo/](https://github.com/willowtreeapps/android-instant-apps-demo/)

原文链接：<https://willowtreeapps.com/ideas/an-introduction-to-android-instant-
apps>

