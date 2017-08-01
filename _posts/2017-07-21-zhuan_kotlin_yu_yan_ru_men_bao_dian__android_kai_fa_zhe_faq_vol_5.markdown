---
layout: post
title: "[转]Kotlin 语言入门宝典 | Android 开发者 FAQ Vol.5"
date: 2017-07-21 18:12:00 +0800
categories: android
author: ippan
tags: kotlin
---

* content
{:toc}

| 导语 官方出的 FAQ ，kotlin是兼容 java 6.0 的 jvm 语言，此篇 FAQ 中，大概需要重点关注的大概是 APK 的影响吧:
Kotlin 在运行时可能会在您的 debug APK 中增加 7000 个方法和 1M 的大小，如果您使用 Kotlin 替换如 Guava、RxJava
等其他的库，影响可能会小一些。但是您可以在后期通过 ProGuard 来优化减小包的大小。

![cover](/image/zhuan_kotlin_yu_yan_ru_men_bao_dian__android_kai_fa_zhe_faq_vol_5/a522bacc61d13d46e739ef461296cfb9bc5f340cb4ac9044d8a8ab8cfaec21ae)
<!--more-->

随着 Kotlin 的快速崛起，我们注意到越来越多的开发者开始关注这个新兴的语言。本期《Googel Play 开发者 FAQ》，我们特别推出了
Kotlin 语言专题，希望这些内容有助于您更好地了解 Kotlin 语言的特性和发展现状，并尝试使用 Kotlin 语言进行 Android 开发。

## 为什么我们要使用 Kotlin 作为 Android 的最佳支持语言？

Kotlin 做为 Android 所支持的开发语言，拥有简洁、强大以及类型和空指针安全的特性。它能与 Java 语言完美地融合工作，这样就使得那些热爱
Java 语言的开发者们能继续使用 Java，同时还能额外添加 Kotlin 代码以及使用 Kotlin 语言的代码库。另外，许多 Android
开发者已经发现使用 Kotlin 进行开发更加快捷且乐趣十足，所以我们决定更好地支持这些开发者。您可以在我们的官方文档里阅读到更多关于 Kotlin 和
Android 的说明。

## 我很久之前就用了 Kotlin，现在有什么变化呢？

我们推出了 Android Studio 3.0 以及更高版本，它包含完整的 Kotlin 支持。这将会为您带来更容易、更稳定的开发体验。

## 使用 Kotlin 开发具有哪些优势？

表达清晰、简洁、扩展性强  
类型安全  
空指针安全  
和 JAVA、C++ 无缝对接  
因此，我们对使用 Kotlin 的开发者做了更好的支持，如果您对 Kotlin 感兴趣，首先需要将 Android Stuido 升级到 3.0
版本，Kotlin 工具直接绑定到了这个版本当中。如果您在使用中遇到了问题请参考以下链接中的 [“Kotlin 在 Android Studio
的常见问题”](https://developer.android.google.cn/studio/preview/kotlin-issues.html)

## 如何在 Android Studio 中使用 Kotlin？

Android Studio 3.0 上您可以很方便的创建一个 Kotlin 文件项目，转换 Java 语言为 Kotlin 语言，并且继续使用您熟悉的
Andoid Studio 的工具，例如 autocomplete, lint checker, refactoring, debugging 等。  
创建一个包含 Kotlin 的项目  
在 Android Studio 中， 点击 “File > New > New Project”.  
在初始页面，点击 Include Kotlin support  
点击下一步继续,直到您的项目创建完成

![](/image/zhuan_kotlin_yu_yan_ru_men_bao_dian__android_kai_fa_zhe_faq_vol_5/1a2da33f5f41c5aec065aec6811bdbc863e593038398137e6bdf446c80be2f74)

这样在选择了一个 Activity 模版后，源码会以 Kotlin 代码的形式提供，但目前只是一些手机或者平板的模版代码提供了原生的 Kotlin
代码，其余的只会从 Java 代码转换而成，这些代码可能并没有用到 Kotlin 最好的语言特征。

## 在 Android Studio 中如何 Debug Kotlin？

在 Debug 方面，您可以像以前 Debug Java 来调试您的应用。

## 为 Kotlin 提供了什么其他 IDE 支持？（比如 Link，autocomplete，refactoring 等）

在 Android Stuido 3.0 上，Kotlin 提供了全部工具的支持，如果在使用中发现了问题，请参考以下链接中的 [“Kotlin
互操作文档”。](https://kotlinlang.org/docs/reference/java-interop.html)

## Kotlin 在未来的发展方向？

我们使用 Kotlin 的一个原因是因为 JetBrains 公司在设计这门语言时十分周到和有启发性的工作。Google 和 Kotlin
的合作确保了使用Kotlin的过程是一个完整而美妙的故事 —— 从语言、框架到工具。我们非常高兴这样的合作能使 Kotlin
成为一个非盈利的工具来为广大开发者所用。

## Kotlin 是开源的吗？

在 Kotlin 上，我们首选的开源协议是 [“Apache Software License, Version
2.0”](http://www.apache.org/licenses/LICENSE-2.0) “Apache 2.0”。

并且主要的 Kotlin 软件都使用了 Apache 2.0。虽然 Kotlin 项目都会遵循这个协议，但可能有例外的情况会有特殊的处理。比如，Kolint
使用的某些第三方库可能使用与 Apache 2.0 兼容的其他开源协议。

## 在 Kotlin 和 Java 之间我应该如何选择？

您不必担心这个问题，您可以两个一起使用，如果您想知道 Kotlin 是否适用您，您可以在 Android 上试一试或者学习更多有关于 Kotlin
语言资料。  
文档：  
[“Kotlinlang.org”](https://kotlinlang.org/) Kotlin 的官方网站，包含了所有的
[“基本语法”](https://kotlinlang.org/docs/reference/basic-syntax.html) 和
[“标准库参考”](https://kotlinlang.org/api/latest/jvm/stdlib/index.html)  
[“Kotlin Koans Online”](https://try.kotlinlang.org/) 在线 IDE 中的一系列练习，可帮助您学习
Kotlin 语法

视频：

△ “Introduction to Kotlin” Google I/O 2017大会上介绍 Kotlin 成为官方支持语言  
“O’Reilly course” (<http://shop.oreilly.com/product/0636920052982.do>) 一个 8
小时的 Kotlin 课程，视频的讲师是 JetBrains 公司的开发者 Hadi Hariri，介绍 Kotlin 编程设计。需要购买订阅，7
天免费试用。  
“Treehouse course” (<https://teamtreehouse.com/library/kotlin-for-java-
developers>)  
“Udemy course” (<https://www.udemy.com/kotlin-course/>) “Kotlin
初学者”，从头教起，需要购买订阅，初学者有折扣优惠。

书籍：

“Kotlin in Action” (<https://www.manning.com/books/kotlin-in-action>) : 由
JetBrains 公司 Kotlin 的开发者 Dmitry Jemerov 和 Svetlana Isakova 编写  
“Kotlin for Android Developers” (<https://leanpub.com/kotlin-for-android-
developers>) 最早的 Kotlin 书籍之一，由 Antonio Leiva 编写

社交渠道：  
“Kotlin Community” (<https://kotlinlang.org/community/>) kotlinlang.org
的线下社区项目与小组  
“Kotlin Slack” (<http://slack.kotlinlang.org/>) Kotlin 使用者讨论社区  
“Talking Kotlin” (<http://talkingkotlin.com/>) Kotlin 的半月刊博客

## 我可以在 Kotlin 中调用 Android 或者其他 Java 语言的库吗？

Kotlin 提供了Java 语言的互通性，这表示 Kotlin 文件中您可以不用 annotation 或 Kotlin 指定语意义，就可以在直接在
Kotlin 里面调用 Java 的方法，这意味着您的项目中可以并存 Java 和 Kotlin 的代码。

## 我可以在用 Kotlin 中使用 C++ 吗？

当然可以，JNI 是完全支持 Kotlin 的。  
要调用 native 的 C 或 C ++代码，只需提前使用 external modifier 来标记一下即可：

    
    
    external fun foo(x: Int): Double
    

## 我怎么在现有的项目中增加 Kotlin 文件？

如果想将 Kotlin 增加到已经存在的项目中，点击 “File > New” 选择一个模版。如果您没有看到这个菜单，需要首先打开 Project
窗口并选择您的 app 组件。

当配置向导出现，选择 “Source Language” 选择 “Kotlin”

至于其他的方式，您可以通过 “File > New > Kotlin File/Class” 去创建一个基本的文件，“New Kotlin
File/Class” 窗口提供了一些文件的选择，因为在您更改了类型之后，Kotlin 会自动转换文件类型，所以您选择什么都不重要。

Kotlin 文件保存在 “src/main/java/”, 您会发现 Kotlin 文件和 Java 文件在一个文件夹里面，但是如果您想让您的
Kotlin 文件和 Java 文件分开，您可以用 “src/main/kotlin/” 代替，如果您需要这样做，只需要在您的配置中添加下面的语句就可以了。

    
    
    Android {
      sourceSets {
          main.java.srcDirs += 'src/main/kotlin'
      }
    }
    

## 我怎么将 Java 代码转换成 Kotlin 代码？

在 Android Studio 3.0, 打开一个 Java 文件然后选择 “Code > Convert Java File to Kotlin
File”.

或者创建一个 Kotlin 文件 “(File > New > Kotlin File/Class)”, 然后复制您的 Java 代码到
Kotlin 文件中。当有提示出现的时候，点击 “Yes” 将 Java 代码转换为 Kotlin 代码，并且可以勾选 “Don’t show this
dialog next time” 来方便您下一次转换。

## 针对 Kotlin 也会提供（与 Java 相同）完整的对应文档、代码和模版吗？

我们正在努力的将我们的文档、代码、模版尽可能的同时覆盖于 Java 和 Kotlin。与此同时，开发者可以依赖 Java 和 Kotlin 的互操作性，将
Java 代码转换为 Android Studio 中的 Kotlin 代码。

## Kotlin 在 Android 上的协程使用怎么样？异步、等待等操作如何？

Kotlin 的协程目前应该是可以使用，但由于 Kotlin 的这套机制尚在实验设计阶段，因此 Kotlin 对未来的状态不会有任何的保证，同样的
Android 也不会。

## Kotlin 会影响 APK 大小吗？会影响方法数吗？

Kotlin 在运行时可能会在您的 debug APK 中增加 7000 个方法和 1M 的大小，如果您使用 Kotlin 替换如 Guava、RxJava
等其他的库，影响可能会小一些。但是您可以在后期通过 ProGuard 来优化减小包的大小。

## 使用 Kotlin 会不会有什么性能影响？

Kotlin 没有直接的性能影响。但是它和 Java 一样，性能方面的表现和您的使用息息相关。  
比如说：在多个 collection 实例中，重复的复制操作会影响 GC 性能，调用一个接受非空类型的方法，会增加一个空检查的方法调用（但是您可以通过设置
-Xno-param-assertions 来禁用编译时运行空指针检查）

## 哪一个版本支持 Kotlin？

Kotlin 是兼容 Java 6.0 的，所以您可以在所有的 Android 版本上安全的使用 Kotlin。

以上就是本期有关入门 Kotlin 语言的开发者 FAQ 了，如果您有其他问题，欢迎您通过留言的方式反馈给我们。

