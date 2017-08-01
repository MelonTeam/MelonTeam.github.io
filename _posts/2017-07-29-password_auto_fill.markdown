---
layout: post
title: "Password Auto Fill"
date: 2017-07-29 11:56:00 +0800
categories: ios
author: pikachuqiu
tags: iOS11 iOS
---

* content
{:toc}



## 前言

在 WWDC 17 Session 206 中，介绍了这个 iOS 11
<!--more-->
加入的新功能。尽管这个功能特别简单，但几乎是今年所有发布的新功能中我最喜欢的一个了。  
如果你之前使用过类似于 “1Password” 的产品，并且尝试使用复杂的密码登录 “手机QQ” ， 你就会处于一种崩溃的状态（”手机QQ”
不支持复制粘贴；我要怎么把我变态的密码输入进去啊）。而当我升级到 iOS 11 Beta 版本之后，我发现 “手机QQ” 居然支持了 “Password
Auto Fill” 这个 Feature，那叫一个欣喜若狂啊。

![](/image/password_auto_fill/749ec988229db0a2c915e0b0ac570b6a5f3f55e43c35517e8a1c2f9f114a7a69)

## 基础功能

“Password Auto Fill”的功能支持非常简单，只需要设置你的 `textField` 的 `contentType` 为 `username`
和 `password` 就行。 就像这样：

    
    
    override func viewDidLoad() {
       super.viewDidLoad()
       usernameTextField.textContentType = UITextContentType.username
       passwordTextField.textContentType = UITextContentType.password
    }
    

理论上来说，上述的代码也可以在 `Storyboard` 或者是 `nib` 的图形界面中完成，但是我试了一下一直不成功，只能通过代码来实现，不知道是不是
Beta 版本的 bug。

好了，截止目前为止 “Password Auto Fill” 的基础功能已经接入完毕，你可以获得和”手机QQ”一样的体验效果。

* * *

## 自动识别网站

接下来是 “Password Auto Fill” 的一个更高级的功能，能够自动在 “QuickType” 区域，显示出你的网站，用户可以直接从
“QuickType” 选择对应的网站密码，免去了搜索的过程。就像下图：

![](/image/password_auto_fill/9129ed77e408ea3232fbf2214cc47ec3cdc82ac521d970e86513a7ce5c406b10)

整个过程也很简单：  
一、在项目的 “Associated Domains” 中输入 “webcredentials:你的域名”，比如 我的域名是
“tjfa.github.io” 我就输入 “webcredentials:tjfa.github.io” ，**这个域名必须是 https 的**

![](/image/password_auto_fill/c787aa88247677f1446a53bf87b8e2df54e08355afecb94cb560183049e633b0)

二、确保你的 “App ID” 也关联了 “Associated Domains”， 具体可以去
<https://developer.apple.com/account/> 中查看，如果这两个都配置正确 “Associated Domains” 下面的
“Steps” 会出现两个勾, 就像上图

![](/image/password_auto_fill/50a77aafe4cb4ac28240f079b47c2053c24cc4ac8626fba1adca3fb5f9d63656)

三、创建一个 JSON 文件，内容如下

    
    
    {
       "webcredentials": {
              "apps": ["YPE39BAJY9.me.qiufeng.www.demo.autofillpassword"]
             }
    }
    

其中 `YPE39BAJY9` 是你的 “TeamID”，上述截图中的 “Prefix”, 不是 Xcode 中的 “Signing
Certificate”。 把这个文件，放到你域名下，确保访问 “<https://example.com/.well-known/apple-app-
site-association>“ 或者 “<https://example.com/apple-app-site-association>“
能够访问到这个文件。  
比如，我的域名是 “<https://tjfa.github.io>“, 我选择后者的域名，那么我访问 [“https://tjfa.github.io
/apple-app-site-association”](https://tjfa.github.io/apple-app-site-
association) 就应该出现如下内容：

![](/image/password_auto_fill/16949c61463a93bb159728b809f19f7ee12130f18560daaa1897c357b443b38d)

**四、确保你设备中 “Settings” -> “Accounts & Passwords” -> “App & Website Passwords” 有你网站的密码**

![](/image/password_auto_fill/c6a0813cc76d151dec995230bdc2285f94dfc719c3ed090708af3b67d6194be4)

五、大功告成，调试运行。可以看到和我一样，在 “QuickType” 区域，程序为你选择了对应的网站账号密码，只需要直接点击即可。

![](/image/password_auto_fill/9129ed77e408ea3232fbf2214cc47ec3cdc82ac521d970e86513a7ce5c406b10)

## 关于调试

调试的话，需要看 Device 的 Log, 在 Xcode 中是看不到的。比如：当我把 “Associated Domains” 换成另外一个域名
“qiufeng.me” 的时候（这个域名不支持 https），然后重新运行，虽然也有 “Password Auto Fill”的功能，但是缺少了
“QuickType” 的自动识别网站。

这时候打开 App “Console “, 选择到你的 Device, 然后在搜索框输入 “swcd”, 可以看到对应的错误帮助调试。

![](/image/password_auto_fill/03e3bd13670fff45432278c605843c16633f5b93a7b5144a52d275ac1c022a92)

![](/image/password_auto_fill/4e87bfc8905064bcc3d3a3d0d661db44135ce0d987a0e00c858a8a05aacbf998)

![](/image/password_auto_fill/d8924c47ab38e3f46c61472c5cdc7ec22a645f8e08d9de15b3d7918ad570071f)

## 关于添加密码

目前好像并不支持这个功能，只能通过手动添加或者访问某个网站之后，通过 Safari 自动记录下来。

