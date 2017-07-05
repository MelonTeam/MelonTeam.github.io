---
layout: post
title: "iphone摄影中的深度捕捉(wwdc2017-session 507)"
date: 2017-06-21 09:17:00
categories: ios
author: yoferzhang
tags: ios 图像
---

* content
{:toc}

| 导语 iphone 7 plus上的人像模式展现了摄影深度的强大功能。 在ios 11中，驱动此功能的深度数据现在开放使用。
了解如何利用深度信息为创意成像开辟新的可能性。 获得对高层次深度概念的更广泛的了解，并学习如何从相机中捕获流式传输和静态图像深度数据。

[视频地址,只能用safari观看](https://developer.apple.com/videos/play/wwdc2017/507/)

<!--more-->
# 前言

507是深度媒体相关的概念层面的内容。主要为下面4个部分：

  * depth and disparity on iphone 7 plus
  * streaming depth data from the camera
  * capturing photos with depth data
  * dual photo capture

# depth and disparity on iphone 7 plus

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/30a0f0ff6233a96d8ad38c064f48a26af949acf6578accb943d907f5aa9f71c4)

7 plus
有两个摄像头，28毫米的广角摄像头，56毫米的长焦镜头。它们都是1200万像素，分享同样的配置项、格式。可以单独使用它们，也可以用一个虚拟的第三方摄像头来共同使用它们，使它们配合。它以同步的方式运行，相同的帧速率，并且一起运行它们可以实现两个选框功能。

## dual camera zoom 双摄变焦

  * switches between wide and tele automatically 
  * matches exposure, focus, and frame rate 
  * compensates for parallax shift to smooth the transition

  * 在缩放时，会自动切换广角与长焦；

  * 适配曝光、对焦和帧速率；
  * 对视差偏移进行补偿，使其在广角和长焦之间来回切换时平滑过渡。

## portrait mode

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/4607dcc11b4dadbbe4245ba7e8d763703f0c92b8af78bbd0ca795295d3b617fa)

人像模式锁定在长焦摄像头，但是会同时使用广角和长焦来生成一副浅景深效果的图像。聚焦的**前景**清晰，**背景**则会逐渐模糊。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fb835d31db6aad5412371623f95b416da60bd19af00f8c60db1fbc87d46b0d19)

ios11 上改进了对焦区域的渲染。更准确的展现了一个自由度高的快速镜头，例如上图中清晰明亮的花束圈。还改进了前景和背景边缘的渲染。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/69b87c5d6fd7b8bfaa49580fe375315b4936395a786540e4abcbc54b9c71baca)

为了生成这样效果的图片，就要有能力区分前景和背景，也就是需要**depth**。在ios10，depth信息还只是包含在苹果自己相机的人像模式中。ios11，苹果正在向第三方应用开放depth
map。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/342b53ac2b11f9414ded3bb414afc637055d2e3f592dd0cbfbd14ca3ff63390f)

上面这幅图中内嵌了下面这样一个灰度可视化的深度图：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/3b5786f8804d007ce81a5f4e6ba792f27bb3664ae69046fdcc87494dfdce1895)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/82e7532b325fd1fc9fab47ba278b6166a98ba1109e59b081f1d8003c86284e7d)

深度信息有了对图像编辑更多的可能性，例如上图对前景和背景应用不同的滤光器；将黑白滤光器应用到背景，fade filter应用到前景。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/c7cd6215c619446eabad01e6241709f9c4a97dc71c4615dc15956db16c2fac16)

也可以像上图，将前景的范围缩小到手和花。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/29d4a998dc9fae7bf941646ed4235954423d4fba61b56922f3886c153d29fcfc)

还可以对前景和背景应用不同的曝光

# deep learning

## depth map

首先定义depth map。真实世界中depth 意思是你和观察物体之间的距离。深度图是将三维场景转化为二维表示，并将深度设置为恒定距离。

下面对针孔相机做一点研究：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f8accf814ce617e671a3e9e6fedd21a4abbb0895bd8b29474d311124e22ce26f)

针孔相机是一个没有镜头的简单的防光盒，观察物体通过一个孔映射到传感器上。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/763a7aedf26ddddb220d64b5073ba09aeacf241fe7c066dccc429620b516068c)

光线通过的孔被称为焦点，聚焦到成像平面的距离就是焦距，物体在成像平面上的缩放程度就取决于焦距。较短的焦距意味着更宽的视野；而更长的焦距，较长的盒子意味着较窄的视野。

简单来说，深度图是将3d深度转换为2d，单通道图像，其中每个像素值是不同的深度，如五米，四米，三米。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/29bf52639f1d65e36a4ac4708a615baa4db61bb9cce87564c70d29ad9c1b79a6)

为了真正测量深度，需要一个专用的摄像头，比如飞行时间相机。例如，一个系统，它从物体反射光信号，然后测量返回到传感器所需的时间。

iphone 7双摄像头不是飞行时间相机。相反，它是一个基于**disparity**的系统。

## disparity

disparity 是从两个不同的摄像机（如眼球）观测到的物体的偏移量的量度。disparity 是视差的另一个名称。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/35362f0827f38a0e254f7d1d9d8ffa1394598ad8ccf632b2100ac18be12b493d)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/9f7d1f6ca8a3e788f2ab32d859d0dd624d5287c5f23c1b15381900a190d734cc)

你可以通过稳定头部并将目光固定在靠近的位置上观察此效果，然后不移动您的头部，闭上一只眼睛，然后闭上另一只眼睛。而且你可以看到彩色的铅笔看起来比后面的标记更多，因为它们更接近。这就是
disparity效果，或者说视差效果。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/6ce1f44d36f3091e251bad0d56dfbd4421e9d8c6b7bdcc2c7fd05449409f5856)

现在我已经拍摄了两台被认为是立体纠正相机的鸟瞰图。意思是说，它们彼此平行，它们指向同一个方向，而且焦距是相同的，这个很重要。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/d23585185eb0047afcf57cdb55985be8c6bdfca3a698fdfb40d5306bf8316aed)

每个相机将具有测量的光学中心或主要点，并且如果从针孔到图像平面绘制垂直线，则光学中心是其与图像平面相交的点。

### baseline基线

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/60af64b64673e78f9fe772212fee9b3bec8b9ef9e97fb656b440ffdf7c3b5ae9)

基线是指立体纠正系统中透镜的两个光学中心之间的距离。 下面是它的工作原理：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/a33e62fa28fcf15fdf901924b0aea5ee8b33995a9b373193c66133aba93e72e8)

来自被观察物体的光穿过光学中心，或者说穿过两个照相机的图像平面上的不同点的孔径和平台。

### z

z是深度或者真实世界深度的规范术语

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/43127b8640a572b05dd7fba0dec36c42518d4cd6ae10260ac0a743ca544fbcca)

现在看看当观察点越远，图像平面上的点更加接近，同理观察点越近，图像平面上的点间隔越远。

所以当相机是立体纠正时，这些偏移只能在一个方向上移动。他们要么靠近要么远离彼此，要么在同一条线上，要么是对极线。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/90d6cbae4d6704e575fc34ba189f5aeea4dd5e1d570d0c9de6e60b11560be7f4)

有了基线，可以沿着它们的光学中心排列相机，并减去图像平面上的观察点之间的距离来获得**视差**。一般用像素单位来表示。

但是现在对于编辑并不是很方便，如果将图像缩小，实际是改变了像素大小，然后必须在深度图中缩放每个值。

### removing despair from disparity

苹果选择使用对缩放操作有弹性的归一化值来表示disparity。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/431eba8914892b0f566c96f4a3a50688dfacdf3074c88d3fcdb27475de0db196)

这里有两个相似三角形，高亮：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/776bc9e625ce63d7f4e8bfd2d9868b85092a59f1a31a475ec210d4910a8b2c6e)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/a0bbde3c3bddcd321de1a2322fd2390f19d704255547e4d72e25e6d4afb9f8b2)

现实世界的三角形边是z，单位是米，而基线是两个光学中心之间的距离。在防光盒内，同一个三角形表示为像素中的焦距和以像素为单位的disparity。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/93a3af918283a14bcaef7110127079e7f6a5cee1cefdd9bb6366ea000692631c)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/93a3af918283a14bcaef7110127079e7f6a5cee1cefdd9bb6366ea000692631c)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/12c2105c50b77ad6d5bb6e55d0fde0c87a3b11df6cd2f4f12e3a325d7bef0560)

数学表示，并化简得到1 / z。当物体移动得更远时，视差会缩小。基线现在绑定在disparity中了，当处理深度图时，不需要单独携带该信息。

disparity单位1/米，它可以承受缩放操作，并且从深度到disparity的转换很简单，只需要 **1除以** 这样一个操作。

## disparity vs. depth

  * iphone 7 plus双摄像头系统是基于disparity的
  * disparity是深度的代理
  * 归一化disparity是深度的倒数

# new term: depth data

depth data是通用术语，对于任何depthy，都可以叫depth data。可以指深度图或者视差图，因为都是深度相关的。

## introducing avdepthdata

  * 苹果的平台( ios, macos, and tvos)对于深度的规范表示叫做`avdepthdata`。
  * 它是avfoundation框架中的一个类。
  * 它代表深度或差异图。
  * 它还提供了一些方法，可以在深度和差异之间进行转换。

    
    
    public var kcvpixelformattype_disparityfloat16: ostype { get } /* 'hdis' */
    public var kcvpixelformattype_disparityfloat32: ostype { get } /* 'hdis' */
    public var kcvpixelformattype_depthfloat16: ostype { get } /* 'hdep' */
    public var kcvpixelformattype_depthfloat32: ostype { get } /* 'fdep' */
    

像rgb图像一样，除了是单通道，但它们仍然可以表示为cv像素缓冲区，现在 `corevideo`
定义了在上一张幻灯片中看到类型的四个新像素格式。因为如果是在gpu上，会要求16位的值，而在cpu上，就都是32位的值。

avdepthdata的核心属性：

    
    
    @available(ios 11.0, *)
    open class avdepthdata: nsobject {
        open var depthdatatype: ostype { get }
        open var depthdatamap: cvpixelbuffer { get }
        open var isdepthdatafiltered: bool { get }
        open var depthdataaccuracy: avdepthdataaccuracy { get }
    }
    

### holes

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/795e1d9c19fbbb2bac64b440f5354eade3a492b1bcc41ee9e630ccdf5fb00ee8)

由于光线，或者边缘难以分清等因素，可能会出现无法得到disparity的点，这种点叫做holes。深度图也可能被处理来填补这些点。
可以通过基于周围深度数据进行内插，或者通过使用rgb图像中存在的元数据来实现。 `avdepthdata` 的 `isdepthdatafiltered`
属性告诉是否以这种方式处理了map。

### calibration errors 校准错误

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/a23561fd053d5d846663c9ba2c133eff23d3e553eb9c2942ff0d0597b5a64ac2)

比如基线计算错误。

iphone相机不是针孔，iphone有透镜，并且它的透镜都不是固定的。

  * optical image stabilization 
  * gravity
  * focus coil

如果使用ois，则透镜可以横向移动来抵消手抖动。重力可以发挥作用，因为它会导致镜头下垂。聚焦致动器实际上是施加电流的弹簧。所以这些原因可能会导致它横向移动一点，而光学中心位置的这些非常小的误差可能导致disparity的巨大误差。当发生这种情况时，结果是map中每个像素的误差是一个恒定的。
disparity 值相对于彼此仍然可用，但它们不再反映真实世界的距离。

### depth data accuracy

    
    
    extension avdepthdata {
        public enum accuracy: int {
            case relative
            case absolute 
        }
    }
    

因此 `avdepthdata`
有一个精度的概念。绝对值的精度值意味着单位确实反映了现实世界的距离，没有校准问题。相对精度意味着z排序仍然保留，但是现实世界的尺度已经丢失。从第三方摄像机获取的深度数据可以报告为绝对或相对，但由于刚刚提到的校准错误，iphone
7 plus总是报告相对精度。

相对精度并不是坏的精度。双摄像头的depth完全可以使用。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/50278770b9aecdab172e13856012d8c0f1c16242d75a5d56dbf346c08613db1c)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/47a1a9d7b22c0254de61e51423d7ee179e02f4f9746ee3237aa4fe2a9bd65c04)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e3253a7e3785422b6ccfe23e86c6e7b70492ae30a6d6ba83a01f8ba492b2cbac)

# streaming depth data

## avcamphotofilter

## introducing avcapturedepthdataoutput

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b57413c88f3f0dd677c35c770fbaab196c32f311b9278823ca956a3e39056b4f)

`avfoundation` 框架相机捕获类分为三大部分。第一个是
`avcapturesession`，仅仅是个控制对象。你可以告诉它开始或者停止运行，它不做任何事情，除非给它一个输入，比如
`avcapturedeviceinput` ，这里与双摄像头的设备关联，并且给session提供输入。然后需要一个输出，这里是一个新的输出类型
`avcapturedepthdataoutput`，它的功能类似于 `videodataoutput`，除了提供 `coremedia`
示例缓冲区之外，它提供了 `avdepthdata` 对象。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/415c20c097eeff4ddefdc4d9b1225c06c9114b920ecf8b1a1b7c087410c11825)

  * 只有双摄像头才能支持 `avcapturedepthdataoutput`。
  * 将 `depthdataoutput` 附加到会话中时，双摄像机自动缩放到2倍，即长焦的全部视野，这是因为为了计算视差，焦距必须相同，而在2倍变焦下，广角摄像机的焦距与长焦相匹配。在计算深度时缩放是被禁用的。
  * 苹果已经向 `avcapturedevice` 添加了一些新的访问器。在双摄像头上，您可以通过查询 `supporteddepthdataformats` 属性来发现哪些视频格式支持深度。
  * 还有一个新的 `activedepthdataformat` 属性，可以让您看到 `activedepthdataformat` 是什么或选择一个新的 depthdataformat。

## supported depth resolutions for streaming

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/2cc97f44728ba9228055a9fb8631a2e41e0d5213a9e7294a39bb704f71e673c5)

第一个是受欢迎的照片预设。 在照片预设中，可以从 `videodataoutput`
中获得屏幕尺寸的预览，还可以从photooutput中获得1200万像素的完整图像。所以在这里
videodataoutput提供了1440x1080，这是屏幕尺寸。如果使用depthdataoutput，可以获得24
fps，最大320x240的depthdata。这么小的原因是每秒处理24次视差图已经消耗很多性能了。也可以以较低的分辨率得到它，160x120。

第二个是16x9的格式，这是今年的新格式。去年有一个720p 16x9的格式，帧率高达60 fps。今年这个新格式只有30
fps，但是支持depth。同样支持两种分辨率。

最后，有一个非常小的vga大小的预设或活动格式，如果只是想要非常小非常快，可以使用它。

## depth frame rate examples

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fbe63e227f9e5fd103bbcba945eddd8a3151b9bd7964c4e563de859175928c8d)

avcapturedevice允许设置最小和最大视频帧速率，但不允许独立于视频帧速率设置深度帧速率。因为深度需要和视频帧率一致，或者小于视频帧率。例如，如果选择最大视频帧率为24，深度可以跟上这一点，所以得到24
fps的深度。但是，如果选择30 fps视频，则深度跟不上，不过不会选择24，而是15，倍数是比较好的选择。

depthdataoutput支持过滤深度数据。这样就可以填满空洞，并且随着你的移动也可以比较平滑，这样就不会看到从帧到帧的时间跳跃。

    
    
    open var isfilteringenabled: bool
    

## 非同步数据输出

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/ec2c6d204e8568d8561266b1e9d34a17ff25fad3e93a647e123ddc0b10a2cc81)

现在有四种数据输出：

第一个是 `videodataoutput` ，从ios 4开始，它是以30 fps或60 fps的流媒体方式一次给出视频帧。 还有一个
`audiodataoutput`，通常会以44.1的速度一次推送1024个pcm帧。 还有一个 `metadataoutput`
可以提供面部，检测到的面孔或条形码，并且这些都偶尔出现。 他们可能会有一些延迟，寻找面孔多达四帧延迟。

第四个就是 `depthdataoutput` ，是以视频的帧速率或以视频均匀分割的速率传送。

如果关心同时处理所有这些数据，或者处理一定的演示时间。为了处理所有这些数据输出，您必须拥有一个非常复杂的缓冲机制，以便跟踪所有进入的时间，

## synchronized data output

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/873244061672980c6cd58c95208661305a21709db974319c91eacebc9ec183e6)

在ios 11中，苹果添加了一个名为 `avcapturedataoutputsynchronizer`
的新同步对象。它可以在单个统一回调中为给定呈现时间，提供所有可用数据，并传递一个称为`avcapturesynchronizeddatacollection`
的集合对象。

所以这样就可以指定一个主输出，一个最重要的输出，一个希望所有其他东西要同步的输出，然后只要它需要，就可以做这个工作，
以确保给定演示时间的所有数据在可用之前提供给单独的统一回调。它将为你提供输出的所有数据，或者如果确保没有特定输出的数据，它将继续提供与它有关的集合。

下面一个代码示例：

    
    
    func dataoutputsynchronizer(_ synchronizer: avcapturedataoutputsynchronizer, didoutput synchronizeddatacollection: avcapturesynchronizeddatacollection) {
        // iterate through an avcapturesynchronizeddatacollection using fast enumeration
        for synceddata in synchronizeddatacollection {
            if let synceddepthdata = synceddata as? avcapturesynchronizeddepthdata {
                // ...
            }
        }
    }
    

可以像数组一样使用它，也可以像字典那样使用它，具体取决于要做什么。

    
    
    func dataoutputsynchronizer(_ synchronizer: avcapturedataoutputsynchronizer, didoutput synchronizeddatacollection: avcapturesynchronizeddatacollection) {
        // use dictionary-esque subscripting to find a particular data
        if let syndepth = synchronizeddatacollection[self.ddo] as? avcapturesynchronizeddepthdata {
            // ...
        }
    }
    

## streaming camera intrinsics

ios 11中还有一个新的流式传输功能，当使用 `videodataoutput` 时，支持每个视频帧的相机内在功能。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/d061dc84983014d8c184564d1fc17d4f788c10d96487a7a2eecb776fad5fd1e9)

上面讲到针孔相机，为了将3d空间中的点转换为2d空间，需要两个信息，光学中心和焦距。在计算机视觉中，可以使用这些属性通过使用逆变换将2d图像重新投影回3d空间，这在新的ar
kit中是重点。

ios 11中的新功能，可以选择在每个视频帧中收到这样一组内在函数，通过调用 `avcaptureconnection` 的
`iscameraintrinsicmatrixdeliveryenabled` 来选择。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e7a2608d47b19ba66271c8df759add8223f5efe604a389ed5e2d94a4296f57e7)

相机内在函数是描述相机几何属性的3x3矩阵。fx和fy是像素焦距。它们是分开的x值和y值，因为有时相机具有变形镜头或变形像素。

在ios设备上，我们的相机总是具有一致的像素，所以fx和fy总是相同的值。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/59ca2988f1553bd37c637c97880486ff9c1cb90da495da7ba3d61194a40b4a1f)

x0和y0是透镜光学中心的像素坐标。

这些都是像素值，它们是以提供它们的视频缓冲区的分辨率给出的。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fc68a76d917df811278cd85d284d7fba7622690d910a710f6d07323ddd4b8a11)

所以，一旦你选择了，可以期望以流式方式获取样本缓冲区，可以获得这个附件，有效载荷是一个c/f数据，它包装一个矩阵3x3浮点数，这是一个simd数据类型。

# capturing photos with depth

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/798dd39870116dfa9f032752241530d9ef274e7bb9afde1f55d4dea80d5293e5)

avcam是显示如何使用 `avfoundation` 拍摄照片和电影的示范代码。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/17ddbfd7580f672bd62e3c6bf0bb74505d0a84d341975c5073a9fc4bda45ac38)

注意，虽然已经添加了深入支持，但是你看不到任何depth相关的东西。因为当能够拍摄这些铅笔时，实际上并没有看到深度的表现，而是存储在照片中。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/ce4993f358c13db0522b233dc96513bd1112c7bd1bced5c5cefaffeeeb68936d)

照相结束后，打开相册后编辑，上面有了景深的按钮，可以对景深做效果处理。在ios
11中，以人像模式拍摄的所有照片现在都会在照片中存储深度信息，因此它们会为您的新创意应用程序添加素材。

## photos with depth

当拍摄深度照片时，支持很多的捕获选项。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/7a281fab53a4797fef3c574dd9a810bab9003104af5867476abb1edc9ea29e67)

可以使用深度进行闪光拍摄，可以静态图像稳定带深度信息。 甚至可以自动曝光括号，例如加2，减2 ev。 可以使live photos带有深度信息。

## capturing photos with depth

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b62e51afd066ecf89adae6704eb0642422a838d957999114b472fe1e4bb4bb09)

`avcapturephotooutput`，这是去年推出的一个类，它是 `avcapturestillimageoutput`
的继承者。它处理复杂的照片请求非常出色。

编程模型是填写一个称为 `avcapturephotosettings`
的请求，通过传递请求和稍后再调用的代理来启动照片捕获。而且photooutput是捕获实时照片，裸raw图像和apple
p3宽色图像的唯一界面。此外，在ios 11中，它是捕获heif文件格式的唯一方法。`avcapturephotooutput`
需要进行许多更改以支持heif，因此在ios 11中，为了适应这些许多变化，添加了新的委托回调。

一个简单示例：

    
    
    func photooutput(_ output: avcapturephotooutput, didfinishprocessingphoto photo: avcapturephoto
    , error: error?)
    

这是替代将获得示例缓冲区的回调。现在得到一个名为 `avcapturephoto` 的新对象。`avcapturephoto`
是深度唯一的传递媒介，所以如果想要深度，需要通过实现这个新的代理回调来操作。

## requesting depth with photos

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/286431764c3d5efffb801f085bfe0c26ef3f6f24cd7c8c44437a44801f6551a1)

此外，在开始会话之前需要明确地选择 `depthdatadelivery`。它需要放大到2倍，使焦距匹配，并且需要锁定自己，禁止缩放。

开始运行会话之前，告诉photooutput我想要
`depthdatadeliveryenabled(photooutput.isdepthdatadeliveryenabled)`，然后在每个照片请求的基础上，这里是当你实际拍摄照片，你会填写一个设置对象，并且再一次我想在这张照片中深度(`photosettings.isdepthdatadeliveryenabled`)。

然后，可以使用产生的`avcapturephoto`，它具有一个名为 `avdepthdata` 的访问器。

## high res photo depth maps

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/800820b866aad66fb0c454e875b6b18d36cdaf09d99ead31bbcdd6eee818fa6b)

在ios上，大多数avcapturedevice格式都具有比流式分辨率更高的静态图像分辨率。depth也是同理。

如果是流式深度，用实时的方式来满足24
fps，有很多工作需要做，但是如果是照片，有一点额外的时间，因为它不需要实时发送，所以可以达到非常高品质的map，超过流分辨率的两倍。

长宽比与视频的长宽比一致。

## rectilinear vs. lens distorted images

捕获和嵌入照片的深度图都是畸变的。

之前展示的所有相机图是针孔相机。 针孔相机没有镜头，因此图像是直线的; 也就是说，光以直线穿过小孔，并在图像平面上呈现几何完美的复制倒置物体。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/38c4a6be2eabb45e163a21045f46148426a9ab19ca5a3b5e0babc8e9878ca014)

如果有一个这样的完美的正方形网格，并用针孔相机拍摄它，它将在图像平面上看起来像这样，但是颠倒的。直线会保持直线。

但是在现实世界中，需要让更多的光线进入，所以需要镜头，镜头有径向变形。这些失真也存在于捕获的图像中，因为它们以稍微奇怪的方式弯曲成图像传感器。

在极端情况下，通过不良镜头捕获的直线可能看起来像这样：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f75b632e255594a774478b867ae25ce5a7b877da0a672464ff4e8227f868d564)

在比较广角和长焦图像之前，必须做一个额外的步骤：

必须使那些扭曲的图像直线化; 也就是说，使用校准的系数集合来解决它们，并且这些系数表征了镜头的失真。

## depth map distortions

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/09fbc2199187f76a5a5c0d520a550290c63ec75deec6a8b190d218c85456784d)

现在可以确定地比较两个图像中的点，并找到一个完美的，真实的，直线的视差图，看起来像这样：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/5b21cede8106148ad116be614fbcca6cb4d08353df45550371a063a05cc8795d)

差距图匹配物理世界，但它与刚刚拍摄的图像不符，因为镜头有扭曲，所以现在必须做另一个步骤，就是将视差图重新映射回图像，使用一组逆透镜系数来做到这一点，最后的视差图具有与其伴随图像相同的几何失真。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/06e538fc5090eae9b5c60d0f2ded104ff3a7b55cc2b0333b6063cd97dd3fa40e)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/de3b7dfc81c86fbe9678ea09fd427e890b0d77b04e35abf5da5e08f971889546)

这意味着开箱即用的depthdatamaps附带的照片适用于过滤器，适用于效果。不完美的是重建3d场景。 如果想这样做，应该使它们是直线的：

## depth in image files

简单地介绍图像文件中的深度数据的物理结构。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fffdb93ef8bd8f4e3662ac3b02e1bce06b6bf7afddf8a5d49c6956d2f272a82a)

ios 11苹果有两种图像支持深度。第一个是heif
hevc，新格式，也称为heic文件，对深度的支持是最好的。文件内有一个称为辅助图像的区域，可以存储视差或深度或透明度map，这就是存储的地方。

我们将其编码为单色hevc，还存储对于深度工作非常重要的元数据，例如有关滤光器的信息，精度，相机校准信息（如镜头失真）以及一些渲染指令。所有这些都与辅助图像一起编码为xmp。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/d85396b46c73fa1c910db554be20b875fe3acaef3139cd39585955889c419f8e)

第二个就是jpeg，虽然这并不是很好的方法，但还是支持了。map是8位有损jpeg，如果它被过滤，或者如果它没有一个数字，使用16位无损jpeg编码来保存所有非数字，苹果将它作为第二个图像存储在jpeg的底部，如果你熟悉的话，它就像一个多画面对象。同样编码是xmp。

# dual photo capture

对于双摄像机最需要的开发者功能，双重照片捕获。

到目前为止，当使用双相机拍照时，仍然只能获得一张图像。
它是来自广角还是来自长焦，取决于缩放的位置，或者如果在1和2x之间的区域，可能会获得两者的一部分，因为苹果进行了一些混合，使得到更好的图片，但仍然只有一个。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/0d56d7c436b2977c56ba8c82a61d6263bd75128b62ca04c7b602b5094b3058ef)

现在，苹果两张图片都给了：通过单一请求，可以获得广角和长焦的全部1200万像素的照片。

## requesting dual photo delivery

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/37ef2b774650bf3b0994159319b993e00741815857de6ecb3ed1b5fff2638b77)

与上述的深度操作非常相似。设置两个属性 `photooutput.isdualcameradualphotodeliveryenabled` ,
`photosettings.isdualcameradualphotodeliveryenabled` 为`ture`。照片的回调就会给两份。

假设你要求raw 和 heif双照。 那么会得到4份，因为将得到两个广角和两个长焦的raw和heif。

## dual photo capture

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/a30710300dbce753613a1690d927d293be7028199e201f906dff240c6b3bf71d)

现在，我们支持与深度相关的所有功能，可以使用双摄照片，自动sis，曝光等级，可以根据需要选择深度。

## dual photo capture + zoom

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e1ceb4886cc7dbf125ae2a632ddc47e2bee34020338c99eb109a5af0fe50b72c)

假设你的应用程序只显示长焦的视野。
那么广角摄像机有更多的信息，所以如果你拍照，实际上给人的可见区域以外的东西，这可能是一个隐私的关注。所以如果是缩放，苹果提供双重照片，但外部变黑，使它们与预览中看到的视野相匹配。

如果您想要完整的图像，可以不要设置缩放。

怎么知道外面是否有黑色区域？在图像内部，存储一个纯净的孔径矩形，它定义了有效像素的区域。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/90d4441f0d988cc67511f91b9a1ef74bd0fd59f75a4266544dd500631688bb3f)

也可以使用相机校准数据传送双重照片。相机校准数据是进行增强现实，虚拟现实，镜头失真校正等需要的数据。
因此，无论是广角的还是长焦和相机校准数据，都可以制作自己的深度图。

## introducing avcameracalibrationdata

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/970310214c6c21ad378d8a250a28407369a96994961e380ab0518c457f011fc8)

相机校准的属性。`avcameracalibrationdata` 是相机校准的model类。如果要求深度，可以得到一个 `avdepthdata`。
这就是 `avdepthdata` 的属性。 如果从avcapturephoto中选择了此功能，也可以获得该功能。
所以选择加入这个照片来说，我想用相机进行相机校准，这个照片效果很好。

如果正在进行双重照片拍摄，需要双面照片，并要求相机校准，将获得两张照片回调，并且可以获得具有广角效果的广角校准，和具有长焦效果的长焦校准。

### intrinsicmatrix

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/3b2931fb968c14f1dfee9d8ba082f958d715c83017a83944ca85e4cd9b08d37e)

和之前的streaming
videodataoutput情况很相似。但是仅仅是这样深度数据的分辨率可能非常低，所以苹果又提供了一套单独的维度。通常，它们是传感器的完整尺寸，因此，您以获得很多精度，在
`intrinsicmatrix` 中有很高的分辨率。

### extrinsicmatrix

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/cac14fd00d4ce97cb16ba89a498b29c351c129a93f96008da046e80bfc0e8547)

`extrinsicmatrix`：这是描述相机在真实世界中姿势的属性。当使用从立体矫正摄像机得到的图像进行三角测量时，需要将其与另一个相比较。而外在特征被表现为一个单一的矩阵，但是两种矩阵被挤压在一起。

左边是旋转矩阵。这是一个3x3，它描述了相机相对于真实世界如何旋转。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/8af7789bb1ec1d5cde67d7c951e1953ae67454791ff48da05bcef649488390cd)

还有一个1x3矩阵，描述了相机的翻转，或与世界边缘的距离。注意，当使用双摄像头时，长焦摄像机是世界的边缘，这使得它非常容易。

如果只是得到一个长焦图像，你得到的矩阵将是一个单位矩阵。 如果正在使用广角和长焦，广角将不是单位矩阵，因为它描述了与长焦镜头的姿态和距离。
但是，使用extrinsics，可以计算广角与长焦之间的基线。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f37670ad50278eda72f348acc347e2190d1f9619bbb9d00faff172ae83c6f116)

这里有两个属性需要注意。一个是 `lensdistortioncenter`。这描述了传感器上与镜头失真中心重合的点。这通常与镜头的光学中心不同。

就像上图的扭曲，透镜上的径向扭曲像树环一样，这将是树环的中心。

同时还有一个属性是`lensdistortionlookuptable`，可以将其视为将 `lensdistortioncenter`
连接到最长半径的多个浮点数。`lensdistortionlookuptable`
是包含在数据中的c浮点数组。如果沿着这些虚线的每个点都是0，那么就拥有了世界上唯一一个完美的镜头，因为这就根本没有径向畸变了。

如果是正值，则表示半径有延长。如果是负值，则表示有压缩。

将整个表格整合在一起，就可以了解镜头的颠簸情况。

要对图像应用失真校正，需要以一个空目标缓冲区开始，然后逐行迭代，并且对于每个点，都使用 `lensdistortionlookuptable`
在失真的图像中找到相应的值，然后将该值写入到输出缓冲区中的正确位置。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/3d186bfa7f19b870ced7b34e9564e31b0de2c564bd406798f68eb8534bf173bb)

这个是比较难实现的代码，苹果在 `avcameracalibrationdata.h`
中提供了一个参考实现。实际是把代码放到了头文件里面。全都有注释。是个很大的objective
c函数。它描述了如何纠正图像或如何反扭曲图像，具体取决于传给它的表格。还有一个表格的逆，它描述了如何从扭曲回到非扭曲。

# summary

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/6ef380a47da5733b17543e0a38317afceb778b415456e78ff5366ffd287b5342)

  * iphone 7 plus双摄像头不是飞行时间相机系统，是disparity系统。
  * 此外，苹果平台上对深度的规范表示是 `avdepthdata`。
  * 了解了intrinsics、extrinsics、lens distortion的信息。都是 `avcameracalibrationdata` 的属性。
  * 了解了`avcapturedepthdataoutput`，它提供了可以过滤的流式深度。
  * 可以使用 `avcapturephotooutput` 捕获带有深度信息的照片。
  * 最后讲到了双摄像头，双照片，对于某些计算机视觉可以单独用到广角和长焦的照片。

