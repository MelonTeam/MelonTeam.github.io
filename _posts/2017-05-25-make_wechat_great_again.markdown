---
layout: post
title: "make wechat great again"
date: 2017-05-25 12:23:00
categories: ios
author: rebootyang
tags: 微信 ios
---

* content
{:toc}


<strong>手机无需越狱</strong>，项目 github 地址: [fishchat](https://github.com/yulingtianxia/fishchat)，make wechat great again！

## <a name="工欲善其事必先利其器" class="reference-link"/>工欲善其事必先利其器

因为没有越狱手机，所以不是直接写 tweak 放手机里，而是需要将 `captainhook` 工程编译出的 dylib 注入到已砸壳 app 的二进制文件中。同样因为没有越狱机，所以砸壳的文件只能从 某 p 助手下载了。

我写了一个 shell 脚本 [autoswimfi.sh](https://github.com/yulingtianxia/fishchat/blob/master/shell/autoswimfi.sh) 帮我完成一些重复性的任务：
1. 查找可用的 iphone 开发者证书1. 解压 ipa 文件1. 拷贝 mobileprovision 文件和要注入的 dylib 文件到 app 文件夹中1. 向 app 中可执行文件的 `load commands` 段中加入一条加载 dylib 的指令1. 对 app 中所有的 app，appx，framework，dylib 文件用第 1 步获取的证书进行重签名1. 打包签名好的 ipa 文件1. 删除上述过程中产生的中间文件1. 通过 usb 线安装 ipa 文件手机上
[autoswimfi.sh](https://github.com/yulingtianxia/fishchat/blob/master/shell/autoswimfi.sh) 需要传入的三个参数分别为：已砸壳的 ipa 文件，没过期的 mobileprovision 文件，要注入的 dylib 文件。


<!--more-->


犹豫了很久，还是贴上脚本代码，壮气势充篇幅吧。

```
# !/bin/bash

sourceipa="$1"

mobileprov="$2"

dylib="$3"



cd ${sourceipa%/*}



security find-identity -v -p codesigning > cers.txt

while ifs='' read -r line || [[ -n "$line" ]]; do

    if [[ "$line" =~ "iphone developer" ]]; then

      developer=${line:47:${#line}-48}

    fi

done < cers.txt



unzip -qo "$sourceipa" -d extracted



application=$(ls extracted/payload/)



echo "copying dylib and mobileprovision"

cp "$dylib" "extracted/payload/$application/${dylib##*/}"

cp "$mobileprov" "extracted/payload/$application/embedded.mobileprovision"



echo "insert dylib into mach-o file"

yololib "extracted/payload/$application/${application%.*}" "${dylib##*/}"



echo "resigning with certificate: $developer"

find -d extracted  \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" \) > directories.txt

security cms -d -i "extracted/payload/$application/embedded.mobileprovision" > t_entitlements_full.plist

/usr/libexec/plistbuddy -x -c 'print:entitlements' t_entitlements_full.plist > t_entitlements.plist

while ifs='' read -r line || [[ -n "$line" ]]; do

    /usr/bin/codesign --continue -f -s "$developer" --entitlements "t_entitlements.plist"  "$line"

done < directories.txt



echo "creating the signed ipa"

cd extracted

zip -qry ../extracted.ipa *

cd ..



rm -rf "extracted"

rm directories.txt

rm cers.txt

rm t_entitlements.plist

rm t_entitlements_full.plist



echo "installing app to your ios device"

mobiledevice install_app extracted.ipa


```

想要让 [autoswimfi.sh](https://github.com/yulingtianxia/fishchat/blob/master/shell/autoswimfi.sh) 一气呵成执行下去，需要依赖以下几项：
1. mac 上需要有唯一可用的 iphone 开发者证书，如果有多个，默认选最后一个1. `yololib` 工具用于注入 dylib 文件到二进制文件中1. `mobiledevice` 可以将 ipa 安装到 usb 连接到 mac 上的手机中1. 一个可用的 mobileprovision 文件，十分关键，可以新建个工程在自己手机 run 一下，新生成的 app 里面就有 mobileprovision 文件。
在这里多再说几句：
1. 一年多前我尝试安装 `iosopendev` 很多次，一直失败，就当前辈们劝我还是用 `theos` 稳妥的时候，我觉得还是再试一次吧，果然还是失败了。不过新建 xcode 项目选择 template 时却出现了 `iosopendev` 哈哈哈哈！1. 一开始用 `insert_dylib` 注入 dylib 后 crash，后来用 `yololib` 就好了！不过 `yololib` 有个 bug 是对 dylib 的版本号有要求。这里可以直接改源码，把 `dylib_current_ver` 和 `dylib_compatibility_version` 的宏定义都改成 `0x0000`。懒人直接用我上传的 [yololib](https://github.com/yulingtianxia/fishchat/blob/master/yololib)。1. 如果要查看 mach-o 文件完整信息，建议用 machoview。`otool -l` 打印所有的 `load commands`，建议搭配 `grep` 进行正则过滤。`otool -l` 可以查看使用的库文件。1. 网上一些重签名工具没有将插件拓展或 watch 中的 dylib 重签名，导致签名失败等问题。微信的 apple watch 客户端用 swift 写的，因为还没有 abi 稳定，所以只好把大量 dylib 打包进去。1. 可以使用 `cycript` 来完成一些调试工作，这样就不用一次次打 log 了。同样也可以打印出视图层级，不过建议有条件的同学用 reveal 2，已经支持 usb 调试了。`cycript` 只支持在同网段下连接到手机 ip 的 `8888` 端口，cy 脚本还是跟 `lldb` 命令有一些差别的。如果 `cycript` 官网的 sdk 不好用，那就用用我上传的吧：[`cycript.framework`](https://github.com/yulingtianxia/fishchat/tree/master/cycript.framework)1. 找到视图对应的类之后，就需要在 `class-dump` 得到的头文件寻找蛛丝马迹了。dump 出的文件：[wechat-headers](https://github.com/yulingtianxia/fishchat/tree/master/wechat-headers)1. 查看设备 log 最简单的方式当然是从 xcode->devices->你的设备。 1. 安装时如果遇到 `amdevicesecureinstallapplication` 安装失败，可以将工程 clean 和 clean build folder 后重新编译，再跑一次我的脚本。如果还不行，尝试用 itools 等软件安装 ipa 到手机上。
## <a name="之后就是不停地 hook" class="reference-link"/>之后就是不停地 hook

我曾经在『[让你的微信不再被人撤回消息](http://yulingtianxia.com/blog/2016/05/06/let-your-wechat-for-mac-never-revoke-messages/)』这篇文章中说过：

> 

之前看的一些逆向的教程里，感觉前期工作都是装软件配环境，噼里啪啦命令一顿敲，整的挺玄乎，其实都是用人家现成儿的工具做些事情，美其名曰『站在巨人的肩膀上』，这里不再赘述。在我看来第一个真正意义上有难度的事情就是一个字儿：『猜』！



是啊，头文件有了，ui 层级有了，该猜了！那么检验是否猜对需要做啥？hook 呗！`captainhook` 的用法很简单，新建工程的模板注释里面已经写得很详细了，就不赘述了。

> 

mac 上需要安装 `iosopendev` 或 `theos`，本项目新建工程时使用 `iosopendev` 的 `captainhook` 模板。编译的时候要选自己的手机，不要选模拟器。



### <a name="关闭『发现』页面的各种入口 - 清君侧" class="reference-link"/>关闭『发现』页面的各种入口 - 清君侧

在关掉各种乱码七糟的功能之后，发现页面仍留下几个无法关闭的入口。本次逆向微信的动机也由此引发：我只想关闭朋友圈入口，并没想关闭自己朋友圈内容，不过微信的这项策略也是很符合一些人的需求的。很多人真的想关闭自己朋友圈不让别人看，不过将这个需求跟旧的『关闭朋友圈入口』功能强绑定在一起，就有些绑架用户的味道了，鱼和熊掌不可兼得啊！不过关闭朋友圈后，别人依然能看到自己在 timeline 上新发的内容，但是一旦点击头像进入主页后就提示『该朋友暂未开启朋友圈』，奇怪的是回到自己的 timeline 上后，以前那条新发的内容就消失了。我觉得这不是 bug，而是产品策略。微信在努力保持用户粘性，不得不在用户需求和产品数据之间权衡。好吧，扯远了。。。

我只保留了这俩『活儿好不粘人』的工具类入口：

<img src="/image/make_wechat_great_again/2164e4e62516adbc21d95499bc60fda7f6767100bb8c36e18d52cffa1d3aa7c5" alt=""/>

其实扫一扫页面可以通过右上角加号更快进入，也可以去掉。小程序其实平时也基本不用，偶尔用的时候现搜，鸡肋入口。不能再干掉了，否则还不如索性干掉整个发现页面。

删入口有两种思路，一种是删数据源，另一种是 hook `uitableviewdelegate` 和 `uitableviewdatasource`。发现页面的 vc 是 `findfriendentryviewcontroller`，发现数据源数组包含的结构体需要花功夫猜下含义，索性简单粗暴 plan b。

```
// 关闭朋友圈入口

choptimizedmethod2(self, cgfloat, findfriendentryviewcontroller, tableview, uitableview *, tableview, heightforrowatindexpath, nsindexpath *, indexpath)

{

    nsindexpath *timelineindexpath = [self valueforkeypath:@"m_wctimelineindexpath"];

    if ([indexpath isequal: timelineindexpath] || indexpath.section == 2) {

        nslog(@"## hide time line entry ##");

        return 0;

    }

    return chsuper2(findfriendentryviewcontroller, tableview, tableview, heightforrowatindexpath, indexpath);

}



choptimizedmethod2(self, uitableviewcell *, findfriendentryviewcontroller, tableview, uitableview *, tableview, cellforrowatindexpath, nsindexpath *, indexpath)

{

    nsindexpath *timelineindexpath = [self valueforkeypath:@"m_wctimelineindexpath"];

    uitableviewcell *cell = chsuper2(findfriendentryviewcontroller, tableview, tableview, cellforrowatindexpath, indexpath);

    if ([indexpath isequal: timelineindexpath] || indexpath.section == 2) {

        nslog(@"## hide time line entry ##");

        cell.hidden = yes;

        for (uiview *subview in cell.subviews) {

            [subview removefromsuperview];

        }

    }

    return cell;

}


```

简单粗暴地将想要隐藏的入口 cell 高度设为 `0` 后发现 `subview` 被挤出来了，我日，只好再干掉这些 `subview`。最后记得在页面出现时刷新下 table 数据：

```
choptimizedmethod1(self, void, findfriendentryviewcontroller, viewdidappear, bool, animated)

{

    chsuper1(findfriendentryviewcontroller, viewdidappear, animated);

    [self performselector:@selector(reloaddata)];

}


```

### <a name="修改微信运动步数 - 装逼党的自我修养" class="reference-link"/>修改微信运动步数 - 装逼党的自我修养

修改微信运动步数的方法网上一搜就有好多文章，就是 hook `wcdevicestepobject` 的 `m7stepcount` 方法罢了。我在这里为了更方便地装逼，当然不能 hook 时把步数写死了，随机数也不够屌，要装逼就装到位：

先到设置页面：

<img src="/image/make_wechat_great_again/042007a520fc38a4b6d53b50263b5f90ecdc18f01aa9fa82ed853954ee5da5a0" alt=""/>

在文本框输入个正数：

<img src="/image/make_wechat_great_again/8a7a0dfb2f3e6103afc98320d84f641aef7a6598f0a9b043cb379178bc3430b5" alt=""/>

完美：

<img src="/image/make_wechat_great_again/bf30eb035365a9b978a8fdb72fb4f7ffb85f0b0ab19f59556dcdb7a1d8e8aa1f" alt=""/>

> 

<strong>==我就问你怕不怕==</strong>



微信的一些列表页面是由数据来驱动 ui 的。table 对应 `mmtableviewinfo`，section 对应 `mmtableviewsectioninfo`，cell 对应 `mmtableviewcellinfo`。以前做项目时也见到过类似的框架，理解起来不难。但是这种过度的封装完全改变了原有系统 api，使用者碰到问题需要深入到框架去调试，又因为是内部框架，网上也搜不到方案。所以要求框架作者规范的编码习惯和较强的能力。又扯远了，我是用 `fishconfigurationcenter` 这个单例类来保存状态值的，目前还没在持久层写入磁盘。可以在 `mmtableviewcellinfo` 头文件看到微信中常用的 cell 是封装好的，这里直接获取个带文本框的就行了。我顺便还加了个夜间模式的开关 cell：

```
chdeclaremethod0(void, newsettingviewcontroller, reloadtabledata)

{

    chsuper0(newsettingviewcontroller, reloadtabledata);

    mmtableviewinfo *tableinfo = [self valueforkeypath:@"m_tableviewinfo"];

    mmtableviewsectioninfo *sectioninfo = [objc_getclass("mmtableviewsectioninfo") sectioninfodefaut];

    mmtableviewcellinfo *nightcellinfo = [objc_getclass("mmtableviewcellinfo") switchcellforsel:@selector(handlenightmode:) target:[fishconfigurationcenter sharedinstance] title:@"夜间模式" on:[fishconfigurationcenter sharedinstance].isnightmode];

    [sectioninfo addcell:nightcellinfo];

    mmtableviewcellinfo *stepcountcellinfo = [objc_getclass("mmtableviewcellinfo") editorcellforsel:@selector(handlestepcount:) target:[fishconfigurationcenter sharedinstance] tip:@"请输入步数" focus:no text:[nsstring stringwithformat:@"%ld", (long)[fishconfigurationcenter sharedinstance].stepcount]];

    [sectioninfo addcell:stepcountcellinfo];

    [tableinfo insertsection:sectioninfo at:0];

    mmtableview *tableview = [tableinfo gettableview];

    [tableview reloaddata];

}


```

然后获取步数的时候从单例里取值就可以啦：

```
// 微信运动步数

choptimizedmethod0(self, unsigned int, wcdevicestepobject, m7stepcount)

{

    if ([fishconfigurationcenter sharedinstance].stepcount == 0) {

        [fishconfigurationcenter sharedinstance].stepcount = chsuper0(wcdevicestepobject, m7stepcount);

    }

    return [fishconfigurationcenter sharedinstance].stepcount;

}


```

### <a name="小红点消除计划 - 我想静静" class="reference-link"/>小红点消除计划 - 我想静静

微信真的是越来越臃肿，大有追赶 qq 的架势，连小红点也是越来越多。『发现』页面撸的挺干净了，我就不信扫一扫入口还能有小红点（flag 已立）。『我』tab 页里什么钱包啊卡包啊老有小红点，真烦人，老得点进去。

通过查看视图层级发现小红点来源有两种，一种是 tabbar 上的小红点，另一种是 cell 上的小红点。前者是系统 api 带的，后者是微信的 `mmbadgeview` 类实现的。

微信的 `mmtabbarcontroller` 继承于 `uitabbarcontroller`，它提供了几个设置小红点的快捷方法，统统 hook 掉，屏蔽后两个『发现』和『我』上的小红点：

```
choptimizedmethod2(self, void, mmtabbarcontroller, settabbarbadgeimage, id, arg1, forindex, unsigned int, arg2)

{

    if (arg2 != 2 && arg2 != 3) {

        chsuper2(mmtabbarcontroller, settabbarbadgeimage, arg1, forindex, arg2);

    }

}



choptimizedmethod2(self, void, mmtabbarcontroller, settabbarbadgestring, id, arg1, forindex, unsigned int, arg2)

{

    if (arg2 != 2 && arg2 != 3) {

        chsuper2(mmtabbarcontroller, settabbarbadgestring, arg1, forindex, arg2);

    }

}



choptimizedmethod2(self, void, mmtabbarcontroller, settabbarbadgevalue, id, arg1, forindex, unsigned int, arg2)

{

    if (arg2 != 2 && arg2 != 3) {

        chsuper2(mmtabbarcontroller, settabbarbadgevalue, arg1, forindex, arg2);

    }

}


```

去除 `mmbadgeview` 就更简单了，直接隐藏掉就好了。不直接 remove 的好处是可以保留聊天页面的小红点提醒，而其他页面的小红点被隐藏了。我猜原因是聊天页面的小红点在添加上去后会设置下 `hidden = no`，因为 cell 是重用的。

```
choptimizedmethod1(self, void, uiview, didaddsubview, uiview *, subview)

{

    if ([subview iskindofclass:nsclassfromstring(@"mmbadgeview")]) {

        subview.hidden = yes;

    }

}


```

### <a name="夜间模式 - 辣眼睛" class="reference-link"/>夜间模式 - 辣眼睛

> 

她说睡了，其实是躺在被窝里继续玩手机罢了。



夜间模式其实也就是主题适配，这个手机 qq 玩的是最 6 的了，无人能敌。要想做一个完美的皮肤引擎是很庞大的工作，不仅是多套色值方案的存储和切换问题，还有多套图片资源的适配问题。这里由于时间仓促，只做了个很辣眼睛的夜间模式，而且切换回来需要杀进程重新进：

<img src="/image/make_wechat_great_again/acf2e5d3185b9e35b70a877b45ada0105b4e10e59989195d157eacd87faf9780" alt=""/>

这么辣眼睛的审美会被狂吐槽，就不贴代码了，有兴趣的去项目里查看哈哈。

### <a name="阻止撤回消息 - 知道真相的我眼泪掉下来" class="reference-link"/>阻止撤回消息 - 知道真相的我眼泪掉下来

有时候被撤回的消息看到了会后悔的，但这依然阻止不了我的好奇心+强迫症。

在 『[让你的微信不再被人撤回消息](http://yulingtianxia.com/blog/2016/05/06/let-your-wechat-for-mac-never-revoke-messages/)』 里我介绍过用 hopper 逆向的方法。直接看汇编代码来的不那么直接，还是 hook oc 代码稳一些。

撤回消息时会先调用 `-[cmessagemgr onrevokemsg:]` 方法，然后调用 `-[cmessagemgr delmsg:msglist: delall:]` 方法删除消息。随意在撤回的时候记录下标志位就好，不影响删除消息功能。

```
// 阻止撤回消息

choptimizedmethod1(self, void, cmessagemgr, onrevokemsg, id, msg)

{

    [fishconfigurationcenter sharedinstance].revokemsg = yes;

    chsuper1(cmessagemgr, onrevokemsg, msg);

}



chdeclaremethod3(void, cmessagemgr, delmsg, id, arg1, msglist, id, arg2, delall, bool, arg3)

{

    if ([fishconfigurationcenter sharedinstance].revokemsg) {

        [fishconfigurationcenter sharedinstance].revokemsg = no;

    }

    else {

        chsuper3(cmessagemgr, delmsg, arg1, msglist, arg2, delall, arg3);

    }

}


```

### <a name="要屏蔽 - 不要免打扰" class="reference-link"/>要屏蔽 - 不要免打扰

详细内容请见：[如何在逆向工程中 hook 得更准 - 微信屏蔽好友&群消息实战](http://yulingtianxia.com/blog/2017/03/06/how-to-hook-the-correct-method-in-reverse-engineering)

## <a name="后记" class="reference-link"/>后记

若不是时间匆忙，或许还可以让微信变得更伟大。比如加个『彻底清理缓存』按钮。平时使用微信确实有很多不爽的地方，尤其是群功能太弱太弱了。我还想加个功能就是如果对方发了超过 30s 的语音，并且对方不是妹子也不是老板不是亲戚，此时自动回复 #&*df@$@(m!…..我没太听清，请你重新再发一遍？

此项目仅用于逆向工程交流学习，黑产死开！
