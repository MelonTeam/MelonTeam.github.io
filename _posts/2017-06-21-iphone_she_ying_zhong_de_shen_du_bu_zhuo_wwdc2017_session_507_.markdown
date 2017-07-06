---
layout: post
title: "iPhone摄影中的深度捕捉(WWDC2017-Session 507)"
date: 2017-06-21 09:17:00 +0800
categories: ios
author: yoferzhang
tags: iOS 图像
---

* content
{:toc}

| 导语 iPhone 7 Plus上的人像模式展现了摄影深度的强大功能。 在iOS 11中，驱动此功能的深度数据现在开放使用。
了解如何利用深度信息为创意成像开辟新的可能性。 获得对高层次深度概念的更广泛的了解，并学习如何从相机中捕获流式传输和静态图像深度数据。

[视频地址,只能用safari观看](https://developer.apple.com/videos/play/wwdc2017/507/)

<!--more-->
# 前言

507是深度媒体相关的概念层面的内容。主要为下面4个部分：

  * Depth and disparity on iPhone 7 Plus
  * Streaming depth data from the camera
  * Capturing photos with depth data
  * Dual photo capture

# Depth and disparity on iPhone 7 Plus

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/4dec8534ea072882081d0a315890deb0dabf4b1e7d8124321493022481cc7b8e)

7 Plus
有两个摄像头，28毫米的广角摄像头，56毫米的长焦镜头。它们都是1200万像素，分享同样的配置项、格式。可以单独使用它们，也可以用一个虚拟的第三方摄像头来共同使用它们，使它们配合。它以同步的方式运行，相同的帧速率，并且一起运行它们可以实现两个选框功能。

## Dual Camera Zoom 双摄变焦

  * Switches between wide and tele automatically 
  * Matches exposure, focus, and frame rate 
  * Compensates for parallax shift to smooth the transition

  * 在缩放时，会自动切换广角与长焦；

  * 适配曝光、对焦和帧速率；
  * 对视差偏移进行补偿，使其在广角和长焦之间来回切换时平滑过渡。

## Portrait Mode

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/5a6cd0e820dc98bb803b40e400523cbff8174dbaca0bc80ad8a752778a9e7661)

人像模式锁定在长焦摄像头，但是会同时使用广角和长焦来生成一副浅景深效果的图像。聚焦的**前景**清晰，**背景**则会逐渐模糊。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/06fee1822de33430dd694c00ac436f95410215fd726821f4026642b7b6b1c368)

iOS11 上改进了对焦区域的渲染。更准确的展现了一个自由度高的快速镜头，例如上图中清晰明亮的花束圈。还改进了前景和背景边缘的渲染。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/28a5e29caaf69f23d3cdc9e03aa04ddd82afa8a846947e85b4a38c060d141877)

为了生成这样效果的图片，就要有能力区分前景和背景，也就是需要**depth**。在iOS10，depth信息还只是包含在苹果自己相机的人像模式中。iOS11，苹果正在向第三方应用开放depth
map。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/4c4667bf168968c93ab0a7886e2080a3c25aca98248e0ece4c23e39f0033e064)

上面这幅图中内嵌了下面这样一个灰度可视化的深度图：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/4e633bde55b50b4345cb9d41ce1ea806a7ac3b3cc187988795720f59f5b10120)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/127ed877ecbf9201d3dc3cd3025f1298d5f032c8014e5319cea482d66f1aed92)

深度信息有了对图像编辑更多的可能性，例如上图对前景和背景应用不同的滤光器；将黑白滤光器应用到背景，Fade Filter应用到前景。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/072a3de7026735a747fd205cae7bb58ff749aa5612b1961c12eef7dfa3e03ddc)

也可以像上图，将前景的范围缩小到手和花。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e387473d51f58f57dcd551a5521fceb3ff8628b18bf293343620839200a9171a)

还可以对前景和背景应用不同的曝光

# Deep Learning

## Depth Map

首先定义depth map。真实世界中depth 意思是你和观察物体之间的距离。深度图是将三维场景转化为二维表示，并将深度设置为恒定距离。

下面对针孔相机做一点研究：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/733bdedce00e9397841a2e11863a94aa578451965b6669c77247d9da43b4a81e)

针孔相机是一个没有镜头的简单的防光盒，观察物体通过一个孔映射到传感器上。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/65c26455dd9c1360ecb6570ebf156031c88603c452153ed474c63c46fbbdb5e6)

光线通过的孔被称为焦点，聚焦到成像平面的距离就是焦距，物体在成像平面上的缩放程度就取决于焦距。较短的焦距意味着更宽的视野；而更长的焦距，较长的盒子意味着较窄的视野。

简单来说，深度图是将3D深度转换为2D，单通道图像，其中每个像素值是不同的深度，如五米，四米，三米。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/32722eb2b547053b4aab003a23787a1fe25e82bdc1e9d0621fa351c107b9e6fd)

为了真正测量深度，需要一个专用的摄像头，比如飞行时间相机。例如，一个系统，它从物体反射光信号，然后测量返回到传感器所需的时间。

iPhone 7双摄像头不是飞行时间相机。相反，它是一个基于**Disparity**的系统。

## Disparity

Disparity 是从两个不同的摄像机（如眼球）观测到的物体的偏移量的量度。Disparity 是视差的另一个名称。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f9cf81c1bf6fc5b51a71f3ef5a9f61f5461a0cb53fae2ec239083c827b435076)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e22a9b6d3ef56b118d5bc6ec990803a4fec3028aa09c08391ca3742ae8788a91)

你可以通过稳定头部并将目光固定在靠近的位置上观察此效果，然后不移动您的头部，闭上一只眼睛，然后闭上另一只眼睛。而且你可以看到彩色的铅笔看起来比后面的标记更多，因为它们更接近。这就是
Disparity效果，或者说视差效果。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/2e6d96e2022b19f618f94af476be10caf9fe2c6080b509202008bd8b61b4b6d3)

现在我已经拍摄了两台被认为是立体纠正相机的鸟瞰图。意思是说，它们彼此平行，它们指向同一个方向，而且焦距是相同的，这个很重要。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/42bba71e3a2f7183080235ede40d8cebf653a3dd3015d1f80b5ea62114471c76)

每个相机将具有测量的光学中心或主要点，并且如果从针孔到图像平面绘制垂直线，则光学中心是其与图像平面相交的点。

### baseline基线

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/3416682b73a42ab6779afb656374eaf1ab8b2ec1c6fa866f650c9f7be9235306)

基线是指立体纠正系统中透镜的两个光学中心之间的距离。 下面是它的工作原理：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/cfcfcd2beac0f8bcfba2bf55adb1b7de0a3b13d7f5f4146c60db440bca2d4fa6)

来自被观察物体的光穿过光学中心，或者说穿过两个照相机的图像平面上的不同点的孔径和平台。

### Z

Z是深度或者真实世界深度的规范术语

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/87a1109f2920a60fb6802afe81e28ed000875bc5116abb13722eb83df37446a8)

现在看看当观察点越远，图像平面上的点更加接近，同理观察点越近，图像平面上的点间隔越远。

所以当相机是立体纠正时，这些偏移只能在一个方向上移动。他们要么靠近要么远离彼此，要么在同一条线上，要么是对极线。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b1fcc21a33e93cf43b7b1ba22c79cf638683d174c64e7ea60d33300a62325af9)

有了基线，可以沿着它们的光学中心排列相机，并减去图像平面上的观察点之间的距离来获得**视差**。一般用像素单位来表示。

但是现在对于编辑并不是很方便，如果将图像缩小，实际是改变了像素大小，然后必须在深度图中缩放每个值。

### Removing Despair from Disparity

苹果选择使用对缩放操作有弹性的归一化值来表示Disparity。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/945b6000dec2fd385772ba6913d772d09a68227ebd1ff10ce2f454b3c94a1205)

这里有两个相似三角形，高亮：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/7335e75e2d0a148b0ed42b1ba05b1e991cbecb085d9cafc5542aca6d74de3291)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b919ee5358526ee7976a97348ce845a4dd8b275bc1bec57e0c01096ccc34331f)

现实世界的三角形边是Z，单位是米，而基线是两个光学中心之间的距离。在防光盒内，同一个三角形表示为像素中的焦距和以像素为单位的Disparity。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/55d47294c59cc0d5d7b70070615a08a2dc5c61ab63209fe847e933f7c3c6fa29)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/55d47294c59cc0d5d7b70070615a08a2dc5c61ab63209fe847e933f7c3c6fa29)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/797f65ef2bf7f63758737e25f3907e2cdb1dfe5f0e4e1332a369f8e995496679)

数学表示，并化简得到1 / z。当物体移动得更远时，视差会缩小。基线现在绑定在Disparity中了，当处理深度图时，不需要单独携带该信息。

Disparity单位1/米，它可以承受缩放操作，并且从深度到Disparity的转换很简单，只需要 **1除以** 这样一个操作。

## Disparity vs. Depth

  * iPhone 7 Plus双摄像头系统是基于Disparity的
  * Disparity是深度的代理
  * 归一化Disparity是深度的倒数

# New Term: Depth Data

Depth Data是通用术语，对于任何depthy，都可以叫depth data。可以指深度图或者视差图，因为都是深度相关的。

## Introducing AVDepthData

  * 苹果的平台( iOS, macOS, and tvOS)对于深度的规范表示叫做`AVDepthData`。
  * 它是AVFoundation框架中的一个类。
  * 它代表深度或差异图。
  * 它还提供了一些方法，可以在深度和差异之间进行转换。

    
    
    public var kCVPixelFormatType_DisparityFloat16: OSType { get } /* 'hdis' */
    public var kCVPixelFormatType_DisparityFloat32: OSType { get } /* 'hdis' */
    public var kCVPixelFormatType_DepthFloat16: OSType { get } /* 'hdep' */
    public var kCVPixelFormatType_DepthFloat32: OSType { get } /* 'fdep' */
    

像RGB图像一样，除了是单通道，但它们仍然可以表示为CV像素缓冲区，现在 `CoreVideo`
定义了在上一张幻灯片中看到类型的四个新像素格式。因为如果是在GPU上，会要求16位的值，而在CPU上，就都是32位的值。

AVDepthData的核心属性：

    
    
    @available(iOS 11.0, *)
    open class AVDepthData: NSObject {
        open var depthDataType: OSType { get }
        open var depthDataMap: CVPixelBuffer { get }
        open var isDepthDataFiltered: Bool { get }
        open var depthDataAccuracy: AVDepthDataAccuracy { get }
    }
    

### Holes

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/ac8004cec37882cbb910e544c190666138e1c19fe1d253a3061809caff92dc74)

由于光线，或者边缘难以分清等因素，可能会出现无法得到Disparity的点，这种点叫做holes。深度图也可能被处理来填补这些点。
可以通过基于周围深度数据进行内插，或者通过使用RGB图像中存在的元数据来实现。 `AVDepthData` 的 `isDepthDataFiltered`
属性告诉是否以这种方式处理了map。

### Calibration Errors 校准错误

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b0b2fb220bcb9a7f65acfc6b06903bc2108b15f5bf3cf908105fa17b7d87a1e0)

比如基线计算错误。

iPhone相机不是针孔，iPhone有透镜，并且它的透镜都不是固定的。

  * Optical Image Stabilization 
  * Gravity
  * Focus Coil

如果使用OIS，则透镜可以横向移动来抵消手抖动。重力可以发挥作用，因为它会导致镜头下垂。聚焦致动器实际上是施加电流的弹簧。所以这些原因可能会导致它横向移动一点，而光学中心位置的这些非常小的误差可能导致Disparity的巨大误差。当发生这种情况时，结果是map中每个像素的误差是一个恒定的。
Disparity 值相对于彼此仍然可用，但它们不再反映真实世界的距离。

### Depth Data Accuracy

    
    
    extension AVDepthData {
        public enum Accuracy: Int {
            case relative
            case absolute 
        }
    }
    

因此 `AVDepthData`
有一个精度的概念。绝对值的精度值意味着单位确实反映了现实世界的距离，没有校准问题。相对精度意味着Z排序仍然保留，但是现实世界的尺度已经丢失。从第三方摄像机获取的深度数据可以报告为绝对或相对，但由于刚刚提到的校准错误，iPhone
7 Plus总是报告相对精度。

相对精度并不是坏的精度。双摄像头的depth完全可以使用。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/ac0fd9187202beed82768847959a1de904350c35f77af0f581bf6a887cc53b2b)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/ae962a2f98a1efcbbb3127be29291121b8bc5f12c59b2f03f9ae1b3422456343)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/33b54efd23f9d1bd93958ff8e653ba389b4dd13dc65eb5366476411ccb0a8380)

# Streaming Depth Data

## AVCamPhotoFilter

## Introducing AVCaptureDepthDataOutput

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/8d57ae340e40ad3241a1c0c8c1d48bfa05d3fc79cdacd06f48363d2d55ec8993)

`AVFoundation` 框架相机捕获类分为三大部分。第一个是
`AVCaptureSession`，仅仅是个控制对象。你可以告诉它开始或者停止运行，它不做任何事情，除非给它一个输入，比如
`AVCaptureDeviceInput` ，这里与双摄像头的设备关联，并且给session提供输入。然后需要一个输出，这里是一个新的输出类型
`AVCaptureDepthDataOutput`，它的功能类似于 `VideoDataOutput`，除了提供 `CoreMedia`
示例缓冲区之外，它提供了 `AVDepthData` 对象。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/c6afd61dfe09fbc24e6f631acb2a9527dc7b471006cc9d8a82acbc683cd36225)

  * 只有双摄像头才能支持 `AVCaptureDepthDataOutput`。
  * 将 `DepthDataOutput` 附加到会话中时，双摄像机自动缩放到2倍，即长焦的全部视野，这是因为为了计算视差，焦距必须相同，而在2倍变焦下，广角摄像机的焦距与长焦相匹配。在计算深度时缩放是被禁用的。
  * 苹果已经向 `AVCaptureDevice` 添加了一些新的访问器。在双摄像头上，您可以通过查询 `supportedDepthDataFormats` 属性来发现哪些视频格式支持深度。
  * 还有一个新的 `activeDepthDataFormat` 属性，可以让您看到 `activeDepthDataFormat` 是什么或选择一个新的 DepthDataFormat。

## Supported Depth Resolutions for Streaming

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b2717c0f31b3f895397ed9125dcc9e7c59b3a66f7a6e90ca4268cedf2a31fd8f)

第一个是受欢迎的照片预设。 在照片预设中，可以从 `VideoDataOutput`
中获得屏幕尺寸的预览，还可以从photoOutput中获得1200万像素的完整图像。所以在这里
VideoDataOutput提供了1440x1080，这是屏幕尺寸。如果使用DepthDataOutput，可以获得24
fps，最大320x240的depthData。这么小的原因是每秒处理24次视差图已经消耗很多性能了。也可以以较低的分辨率得到它，160x120。

第二个是16x9的格式，这是今年的新格式。去年有一个720p 16x9的格式，帧率高达60 fps。今年这个新格式只有30
fps，但是支持depth。同样支持两种分辨率。

最后，有一个非常小的VGA大小的预设或活动格式，如果只是想要非常小非常快，可以使用它。

## Depth Frame Rate Examples

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/3bd7eec7c728f50cb5c8a4119f00279043c006fe1943c1210f104a9e243208f3)

AVCaptureDevice允许设置最小和最大视频帧速率，但不允许独立于视频帧速率设置深度帧速率。因为深度需要和视频帧率一致，或者小于视频帧率。例如，如果选择最大视频帧率为24，深度可以跟上这一点，所以得到24
fps的深度。但是，如果选择30 fps视频，则深度跟不上，不过不会选择24，而是15，倍数是比较好的选择。

DepthDataOutput支持过滤深度数据。这样就可以填满空洞，并且随着你的移动也可以比较平滑，这样就不会看到从帧到帧的时间跳跃。

    
    
    open var isFilteringEnabled: Bool
    

## 非同步数据输出

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f480ca2ca44e1e81213f6085db1f20c30b2ce086b34c5c6ef219bc9793917b72)

现在有四种数据输出：

第一个是 `VideoDataOutput` ，从iOS 4开始，它是以30 fps或60 fps的流媒体方式一次给出视频帧。 还有一个
`AudioDataOutput`，通常会以44.1的速度一次推送1024个PCM帧。 还有一个 `MetadataOutput`
可以提供面部，检测到的面孔或条形码，并且这些都偶尔出现。 他们可能会有一些延迟，寻找面孔多达四帧延迟。

第四个就是 `DepthDataOutput` ，是以视频的帧速率或以视频均匀分割的速率传送。

如果关心同时处理所有这些数据，或者处理一定的演示时间。为了处理所有这些数据输出，您必须拥有一个非常复杂的缓冲机制，以便跟踪所有进入的时间，

## Synchronized Data Output

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fdbdfad28cdf5e0691ed5264f500c40aa8dd05d50a4aebd585abd2946a589d5d)

在iOS 11中，苹果添加了一个名为 `AVCaptureDataOutputSynchronizer`
的新同步对象。它可以在单个统一回调中为给定呈现时间，提供所有可用数据，并传递一个称为`AVCaptureSynchronizedDataCollection`
的集合对象。

所以这样就可以指定一个主输出，一个最重要的输出，一个希望所有其他东西要同步的输出，然后只要它需要，就可以做这个工作，
以确保给定演示时间的所有数据在可用之前提供给单独的统一回调。它将为你提供输出的所有数据，或者如果确保没有特定输出的数据，它将继续提供与它有关的集合。

下面一个代码示例：

    
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        // Iterate through an AVCaptureSynchronizedDataCollection using fast enumeration
        for syncedData in synchronizedDataCollection {
            if let syncedDepthData = syncedData as? AVCaptureSynchronizedDepthData {
                // ...
            }
        }
    }
    

可以像数组一样使用它，也可以像字典那样使用它，具体取决于要做什么。

    
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        // Use dictionary-esque subscripting to find a particular data
        if let synDepth = synchronizedDataCollection[self.ddo] as? AVCaptureSynchronizedDepthData {
            // ...
        }
    }
    

## Streaming Camera Intrinsics

iOS 11中还有一个新的流式传输功能，当使用 `VideoDataOutput` 时，支持每个视频帧的相机内在功能。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f34529ff84ad802b32fbd9c63ec730c1f17851b819ff7a092335e461abb34de2)

上面讲到针孔相机，为了将3D空间中的点转换为2D空间，需要两个信息，光学中心和焦距。在计算机视觉中，可以使用这些属性通过使用逆变换将2D图像重新投影回3D空间，这在新的AR
kit中是重点。

iOS 11中的新功能，可以选择在每个视频帧中收到这样一组内在函数，通过调用 `AVCaptureConnection` 的
`isCameraIntrinsicMatrixDeliveryEnabled` 来选择。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/11d87ad1706f4c84674fd9c6369d2d41cf6c2837263f6c78dfc7a65a8743fd20)

相机内在函数是描述相机几何属性的3x3矩阵。fx和fy是像素焦距。它们是分开的x值和y值，因为有时相机具有变形镜头或变形像素。

在iOS设备上，我们的相机总是具有一致的像素，所以fx和fy总是相同的值。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/0b8b3b8d27df91c10cbaa4a7bd95d77d7e02acce5ed0f51f9aff57578824fafb)

x0和y0是透镜光学中心的像素坐标。

这些都是像素值，它们是以提供它们的视频缓冲区的分辨率给出的。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/c641aad231b9ad16cc155e7e47cd35bfb7502344a23b6887b02214ac563084a5)

所以，一旦你选择了，可以期望以流式方式获取样本缓冲区，可以获得这个附件，有效载荷是一个C/F数据，它包装一个矩阵3x3浮点数，这是一个SIMD数据类型。

# Capturing Photos with Depth

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/7b8e98fd5bff2e1c91449e80da2cebcef9f3a3fca067449b87e444763b49c31f)

AVCam是显示如何使用 `AVFoundation` 拍摄照片和电影的示范代码。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/40ed5ef3fbe9efc0607f30ef86aac5e55d85589edfa23bfa8b51b7f02107b21b)

注意，虽然已经添加了深入支持，但是你看不到任何depth相关的东西。因为当能够拍摄这些铅笔时，实际上并没有看到深度的表现，而是存储在照片中。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/1c009860cb4074f17e7050be0a9c5ea4682bd7abbd7e273496ef9166163125e4)

照相结束后，打开相册后编辑，上面有了景深的按钮，可以对景深做效果处理。在iOS
11中，以人像模式拍摄的所有照片现在都会在照片中存储深度信息，因此它们会为您的新创意应用程序添加素材。

## Photos with Depth

当拍摄深度照片时，支持很多的捕获选项。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/25e89f0edca2e6a450dddcdce445d17c97edbd9828c3727291039e332c55a011)

可以使用深度进行闪光拍摄，可以静态图像稳定带深度信息。 甚至可以自动曝光括号，例如加2，减2 EV。 可以使Live Photos带有深度信息。

## Capturing Photos with Depth

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/987a7aae4d4b9a3c99ccb59c87bfc44dda08aeccc398af7952b0437d09be6e3c)

`AVCapturePhotoOutput`，这是去年推出的一个类，它是 `AVCaptureStillImageOutput`
的继承者。它处理复杂的照片请求非常出色。

编程模型是填写一个称为 `AVCapturePhotoSettings`
的请求，通过传递请求和稍后再调用的代理来启动照片捕获。而且photoOutput是捕获实时照片，裸RAW图像和Apple
P3宽色图像的唯一界面。此外，在iOS 11中，它是捕获HEIF文件格式的唯一方法。`AVCapturePhotoOutput`
需要进行许多更改以支持HEIF，因此在iOS 11中，为了适应这些许多变化，添加了新的委托回调。

一个简单示例：

    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto
    , error: Error?)
    

这是替代将获得示例缓冲区的回调。现在得到一个名为 `AVCapturePhoto` 的新对象。`AVCapturePhoto`
是深度唯一的传递媒介，所以如果想要深度，需要通过实现这个新的代理回调来操作。

## Requesting Depth with Photos

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/1cd1bda6b0406dd033f6b88e82dae0994ea6429d0b74439bd375d370bd4c7d3c)

此外，在开始会话之前需要明确地选择 `DepthDataDelivery`。它需要放大到2倍，使焦距匹配，并且需要锁定自己，禁止缩放。

开始运行会话之前，告诉photoOutput我想要
`DepthDataDeliveryEnabled(photoOutput.isDepthDataDeliveryEnabled)`，然后在每个照片请求的基础上，这里是当你实际拍摄照片，你会填写一个设置对象，并且再一次我想在这张照片中深度(`photoSettings.isDepthDataDeliveryEnabled`)。

然后，可以使用产生的`AVCapturePhoto`，它具有一个名为 `AVDepthData` 的访问器。

## High Res Photo Depth Maps

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/079e4af88e280e5a2e3666740f25e0fb9100bd90e9633ee77f81eedd9684f175)

在iOS上，大多数AVCaptureDevice格式都具有比流式分辨率更高的静态图像分辨率。depth也是同理。

如果是流式深度，用实时的方式来满足24
fps，有很多工作需要做，但是如果是照片，有一点额外的时间，因为它不需要实时发送，所以可以达到非常高品质的map，超过流分辨率的两倍。

长宽比与视频的长宽比一致。

## Rectilinear vs. Lens Distorted Images

捕获和嵌入照片的深度图都是畸变的。

之前展示的所有相机图是针孔相机。 针孔相机没有镜头，因此图像是直线的; 也就是说，光以直线穿过小孔，并在图像平面上呈现几何完美的复制倒置物体。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/b85372f5d98130378d040066d0c539515e0277eca866b36a5e34d6d429987821)

如果有一个这样的完美的正方形网格，并用针孔相机拍摄它，它将在图像平面上看起来像这样，但是颠倒的。直线会保持直线。

但是在现实世界中，需要让更多的光线进入，所以需要镜头，镜头有径向变形。这些失真也存在于捕获的图像中，因为它们以稍微奇怪的方式弯曲成图像传感器。

在极端情况下，通过不良镜头捕获的直线可能看起来像这样：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f2b8c9229531673fb827c237860e16252c0c8145fcadd81215632a11b4740213)

在比较广角和长焦图像之前，必须做一个额外的步骤：

必须使那些扭曲的图像直线化; 也就是说，使用校准的系数集合来解决它们，并且这些系数表征了镜头的失真。

## Depth Map Distortions

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/fdfd7ff6618a27609502218784255dbad58de08c7a146ea503c748e5ef616a12)

现在可以确定地比较两个图像中的点，并找到一个完美的，真实的，直线的视差图，看起来像这样：

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/2b5722cdc29f52f2bb1db7c2dd385aca797a330df0546740525d044e5d64a2dc)

差距图匹配物理世界，但它与刚刚拍摄的图像不符，因为镜头有扭曲，所以现在必须做另一个步骤，就是将视差图重新映射回图像，使用一组逆透镜系数来做到这一点，最后的视差图具有与其伴随图像相同的几何失真。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/af63bfc37753f841883a51afa4cddc3db967f6819c4defd9ad74434daf8d9632)

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/c9b3e42238852c73cc713d4720d2adf38a77cfbaad3fc582e9a851ad5393c3ef)

这意味着开箱即用的depthDataMaps附带的照片适用于过滤器，适用于效果。不完美的是重建3D场景。 如果想这样做，应该使它们是直线的：

## Depth in Image Files

简单地介绍图像文件中的深度数据的物理结构。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/c45e928c6814c83eb761e305cf59c2286a753ef82bb97cf4a9137567e096ce0a)

iOS 11苹果有两种图像支持深度。第一个是HEIF
HEVC，新格式，也称为HEIC文件，对深度的支持是最好的。文件内有一个称为辅助图像的区域，可以存储视差或深度或透明度map，这就是存储的地方。

我们将其编码为单色HEVC，还存储对于深度工作非常重要的元数据，例如有关滤光器的信息，精度，相机校准信息（如镜头失真）以及一些渲染指令。所有这些都与辅助图像一起编码为XMP。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/f9118a913efb7978137da81997f79028fb3b7716598c0dc8d125af44c58943e1)

第二个就是JPEG，虽然这并不是很好的方法，但还是支持了。map是8位有损JPEG，如果它被过滤，或者如果它没有一个数字，使用16位无损JPEG编码来保存所有非数字，苹果将它作为第二个图像存储在JPEG的底部，如果你熟悉的话，它就像一个多画面对象。同样编码是XMP。

# Dual Photo Capture

对于双摄像机最需要的开发者功能，双重照片捕获。

到目前为止，当使用双相机拍照时，仍然只能获得一张图像。
它是来自广角还是来自长焦，取决于缩放的位置，或者如果在1和2X之间的区域，可能会获得两者的一部分，因为苹果进行了一些混合，使得到更好的图片，但仍然只有一个。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/1049673c50badc00b0b44286a2a2846dc114f3fa35d3a0df405f569fd94d049b)

现在，苹果两张图片都给了：通过单一请求，可以获得广角和长焦的全部1200万像素的照片。

## Requesting Dual Photo Delivery

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/5af1bff4aa8cb8d77e13f1c047585402cbbab60c69ddfd3ffd8159e412a9250f)

与上述的深度操作非常相似。设置两个属性 `photoOutput.isDualCameraDualPhotoDeliveryEnabled` ,
`photoSettings.isDualCameraDualPhotoDeliveryEnabled` 为`ture`。照片的回调就会给两份。

假设你要求RAW 和 HEIF双照。 那么会得到4份，因为将得到两个广角和两个长焦的RAW和HEIF。

## Dual Photo Capture

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/2f83778a5aff5a04db530a68fd1d20b7787e68135e1f014d60943a24edc25344)

现在，我们支持与深度相关的所有功能，可以使用双摄照片，自动SIS，曝光等级，可以根据需要选择深度。

## Dual Photo Capture + Zoom

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/919f19915818ab7cca7850028da934892ecb0355ccd75eee78c2251904c7f36d)

假设你的应用程序只显示长焦的视野。
那么广角摄像机有更多的信息，所以如果你拍照，实际上给人的可见区域以外的东西，这可能是一个隐私的关注。所以如果是缩放，苹果提供双重照片，但外部变黑，使它们与预览中看到的视野相匹配。

如果您想要完整的图像，可以不要设置缩放。

怎么知道外面是否有黑色区域？在图像内部，存储一个纯净的孔径矩形，它定义了有效像素的区域。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/18ae16c9b758f50fbefe5edc5c8668335e75ff551c34926aefebb3fcc83d4c03)

也可以使用相机校准数据传送双重照片。相机校准数据是进行增强现实，虚拟现实，镜头失真校正等需要的数据。
因此，无论是广角的还是长焦和相机校准数据，都可以制作自己的深度图。

## Introducing AVCameraCalibrationData

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/d4ec504e0d535dcd691a1aef6e8585e9a833026676af341ad8a56cf0e20dc3ef)

相机校准的属性。`AVCameraCalibrationData` 是相机校准的model类。如果要求深度，可以得到一个 `AVDepthData`。
这就是 `AVDepthData` 的属性。 如果从AVCapturePhoto中选择了此功能，也可以获得该功能。
所以选择加入这个照片来说，我想用相机进行相机校准，这个照片效果很好。

如果正在进行双重照片拍摄，需要双面照片，并要求相机校准，将获得两张照片回调，并且可以获得具有广角效果的广角校准，和具有长焦效果的长焦校准。

### intrinsicMatrix

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/1ee3b33fa85813b89104e44546a326e03309f4c49717a813cfcbdfb1099b4ae6)

和之前的streaming
VideoDataOutput情况很相似。但是仅仅是这样深度数据的分辨率可能非常低，所以苹果又提供了一套单独的维度。通常，它们是传感器的完整尺寸，因此，您以获得很多精度，在
`intrinsicMatrix` 中有很高的分辨率。

### extrinsicMatrix

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/645cdd2c561aa2872a90de6418ce64153597afbdac98fed015c1b76cad4f333b)

`extrinsicMatrix`：这是描述相机在真实世界中姿势的属性。当使用从立体矫正摄像机得到的图像进行三角测量时，需要将其与另一个相比较。而外在特征被表现为一个单一的矩阵，但是两种矩阵被挤压在一起。

左边是旋转矩阵。这是一个3x3，它描述了相机相对于真实世界如何旋转。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/9dc506ac8abfbfb7056328707898ff4a208a9ffc13e113c8311c0154e4e883ff)

还有一个1x3矩阵，描述了相机的翻转，或与世界边缘的距离。注意，当使用双摄像头时，长焦摄像机是世界的边缘，这使得它非常容易。

如果只是得到一个长焦图像，你得到的矩阵将是一个单位矩阵。 如果正在使用广角和长焦，广角将不是单位矩阵，因为它描述了与长焦镜头的姿态和距离。
但是，使用extrinsics，可以计算广角与长焦之间的基线。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/e44faa45ee9864bee20d290e27c01f007eca9e473971d03d96c69fc796abb912)

这里有两个属性需要注意。一个是 `lensDistortionCenter`。这描述了传感器上与镜头失真中心重合的点。这通常与镜头的光学中心不同。

就像上图的扭曲，透镜上的径向扭曲像树环一样，这将是树环的中心。

同时还有一个属性是`lensDistortionLookupTable`，可以将其视为将 `lensDistortionCenter`
连接到最长半径的多个浮点数。`lensDistortionLookupTable`
是包含在数据中的C浮点数组。如果沿着这些虚线的每个点都是0，那么就拥有了世界上唯一一个完美的镜头，因为这就根本没有径向畸变了。

如果是正值，则表示半径有延长。如果是负值，则表示有压缩。

将整个表格整合在一起，就可以了解镜头的颠簸情况。

要对图像应用失真校正，需要以一个空目标缓冲区开始，然后逐行迭代，并且对于每个点，都使用 `lensDistortionLookupTable`
在失真的图像中找到相应的值，然后将该值写入到输出缓冲区中的正确位置。

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/a9700f5c735e31bbf74be824ed8090436c3b27afc316ceaa858bfd33ee8d8ca9)

这个是比较难实现的代码，苹果在 `AVCameraCalibrationData.h`
中提供了一个参考实现。实际是把代码放到了头文件里面。全都有注释。是个很大的objective
C函数。它描述了如何纠正图像或如何反扭曲图像，具体取决于传给它的表格。还有一个表格的逆，它描述了如何从扭曲回到非扭曲。

# Summary

![](/image/iphone_she_ying_zhong_de_shen_du_bu_zhuo_wwdc2017_session_507_/4863e7c2675202326ce91be98dec7a0e12e44e5842e1dc0fc8a7c8abdf0a3c0d)

  * iPhone 7 Plus双摄像头不是飞行时间相机系统，是Disparity系统。
  * 此外，苹果平台上对深度的规范表示是 `AVDepthData`。
  * 了解了intrinsics、extrinsics、lens distortion的信息。都是 `AVCameraCalibrationData` 的属性。
  * 了解了`AVCaptureDepthDataOutput`，它提供了可以过滤的流式深度。
  * 可以使用 `AVCapturePhotoOutput` 捕获带有深度信息的照片。
  * 最后讲到了双摄像头，双照片，对于某些计算机视觉可以单独用到广角和长焦的照片。

