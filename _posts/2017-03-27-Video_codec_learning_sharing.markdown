---
layout: post
title: "视频编解码学习分享"
date: 2017-03-27 19:04:58
categories: 视频
---

* content
{:toc}

**目录**

1. 视频为什么要编解码
2. 视频是否可以压缩
3. 编解码实现原理
4. 编解码标准和国际组织
5. 视频文件封装（容器）
6. 视频质量评价体系

<!--more-->

## 1.为什么视频要编解码？

未经过压缩的视频数据量非常大，存储困难，同时也不便于在网络中传输。

**以数字电视一秒钟的数据量为例，观看一秒钟数字电视需要等待9秒钟。**

数据量约1113KB，如果按照1M传输带宽计算，比特率是9123840，大约需要9秒钟

| FPS      |    Size	| Bits/pixel | Bit-rate(bps)	 | 	File Size(KB) |
| :--: | :--: | :--: | :--: | :--: |
| 30 | 176 * 144	|  12    | 9,123,840 | 1113 |

**IPhone6 16G手机,最多只能存储50秒视频。**

拍摄10秒钟视频,未经压缩的数据量是2.4G，16G的IPhone6除去系统占用的部分，剩下的存储空间最多是12G

| FPS      |    Size	| Bits/pixel | Bit-rate(Mbps)	 | 	File Size(MB) | Compressed Size(MB) | Compress-rate（H.264） |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| 30 | 1920 * 1080	|  32    | 1990 | 2488 | 25 | 100:1 |

**要解决视频存储难、传输难的问题，综合考虑软硬件成本，最有效的办法应该是压缩视频体积！**

## 2.视频是否可以压缩？

答案是肯定的，因为原始视频包含大量的冗余信息，比如：人的视觉系统有一些先天的特性，对某些细节不敏感。所以从理论上分析，基于人的视觉特性去掉视频冗余信息既可以保证视频质量又可以压缩视频体积。除此之外视频还有很多其他冗余信息可以去除，接下来我们详细介绍一下视频冗余信息。

#### 视频冗余信息

原始视频至少存在5个方面的信息冗余：空间冗余、时间冗余、编码冗余、视觉冗余、知识冗余，接下来详细讲解一下这5个方面的冗余。

##### 空间冗余：图像相邻像素之间有较强的相关性

由图可知，在颜色接近的色块区域，相邻像素是非常接近的有较强的相关性，这部分信息其实是冗余的，下文将的条、块编码就是去除这种空间冗余数据。

![Alt text](/image/Video_codec_learning_sharing/1.png)


##### 时间冗余：视频序列的相邻图像之间内容相似

视频一般由时间轴区间内一组连续画面组成，其中的相邻帧往往包含相同的背景和移动物体，只不过移动物体所在的空间位置略有不同，所以后一帧的数据与前一帧的数据有许多共同的地方，这就称为时间冗余。
如下图所示，或许只有人的嘴巴和手在动，其他大部分的像素都是没有变化的。

![Alt text](/image/Video_codec_learning_sharing/2.png)

##### 编码冗余：不同像素值出现的概率不同

先介绍一下等长编码和变长编码的概念

等长码：在一组码字集合C中的所有码字cm (m = 1,2, …,M)，其码长都相同，则称这组码C为等长码。

变长码：若码字集合C中的所有码字cm (m = 1,2, …,M)，其码长不都相同，称码C为变长码。

【例】设待压缩的数据文件共有100个字符，这些字符均取自字符集C={a，b，c，d，e，f}，分别使用等长、变长编码方案对比优劣。

**等长编码方案**

等长编码需要三位二进制数字来表示六个字符，因此，整个文件的编码长度为300bits。

**变长编码方案**

变长编码方案将采用Huffman编码，通过码字出现的频率高低构造一个Huffman树，频度高的字符编码设置短，将频度低的字符编码设置较长。

| 字符    |    a | b | c	 | d | e | f |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: |
|频率（次）|	45	|13	|12	|16	|9|	5|
|概率	|0.45|	0.13	|0.12	|0.16|	0.09	|0.05|
|变长码字	|0	|101|	100|	111|	1101|	1100|
|定长码字|	000	|001|	010	|011|	100	|101|

根据计算公式：451+133+123+163+9*4+584=224
整个文件被编码为224bits，比定长编码方式节约了约25％的存储空间。

由此可知，在图像编码中，不同的像素值出现的概率不同，采用定长编码相对变长编码需要更多的存储空间，这一部分冗余就称之为编码冗余。

[了解更多Huffman编码](https://zh.wikipedia.org/wiki/%E9%9C%8D%E5%A4%AB%E6%9B%BC%E7%BC%96%E7%A0%81)

**视觉冗余：人的视觉系统对某些细节不敏感**

在介绍视觉冗余之前先来介绍一下人类视觉系统（Human Visual System，简称HVS）的几个特性：

1. 对亮度的变化敏感，对色度的变化相对不敏感。
2. 对静止图像敏感，对运动图像相对不敏感。
3. 对图像的水平线条和竖直线条敏感，对斜线相对不敏感。
4. 对整体结构敏感，对内部细节相对不敏感。
5. 对低频信号敏感，对高频信号相对不敏感（如：对边沿或者突变附近的细节不敏感）。

由于人类视觉系统的先天特性，原始图像中有一些数据是人眼感知不到的，在图像压缩过程中可以去掉，在图像恢复后不会影响图像的主观质量，这部分数据就是视觉冗余。例如，人类视觉的一般分辨能力为2的6次方（64）灰度等级，而一般的图像的量化采用的是2的8次方（256）灰度等级，即存在视觉冗余。

[了解更多人类视觉系统](http://aabbc1122.blog.163.com/blog/static/5704325720122225645945/)

**知识冗余：规律性的结构可由先验知识和背景知识得到**

有许多图像的理解与某些基础知识有相当大的相关性。 例如：人脸的图像有固定的结构，嘴的上方有鼻子。鼻子的上方有眼睛，鼻子位于正脸图像的中线上等等。这类规律
性的结构可由先验知识相背景知识得到，我们称此类冗余为知识冗余。

## 3.编解码实现原理

#### PBI帧

视频中每帧代表一幅静止的图像，而在实际压缩时，会采取各种算法减少数据的容量，其中IPB就是最常见的。简单地说，I帧是关键帧，属于帧内压缩。就是和AVI的压缩是一样的。 P是向前搜索的意思。B是双向搜索。他们都是基于I帧来压缩数据。

#### I帧

I帧表示关键帧，你可以理解为这一帧画面的完整保留；解码时只需要本帧数据就可以完成，因为包含完整画面。

#### P帧

P帧表示的是这一帧跟之前的一个关键帧（或P帧）的差别，解码时需要用之前缓存的画面叠加上本帧定义的差别，生成最终画面。也就是差别帧，P帧没有完整画面数据，只有与前一帧的画面差别的数据。

#### B帧

B帧是双向差别帧，也就是B帧记录的是本帧与前后帧的差别，换言之，要解码B帧，不仅要取得之前的缓存画面，还要解码之后的画面，通过前后画面的与本帧数据的叠加取得最终的画面。B帧压缩率高，但是解码时CPU会比较累。

![Alt text](/image/Video_codec_learning_sharing/3.png)

#### 码流层次结构

视频的二进制码流有一个固定的组织结构，从上到下层依次是：序列层、图像组层、图像层、条带层、宏块层、块层。

![Alt text](/image/Video_codec_learning_sharing/4.png)

**序列编码**

![Alt text](/image/Video_codec_learning_sharing/5.png)

序列：一段连续编码的并具有相同参数的视频图像。
序列起始码：专有的一段比特串，标识一个序列的压缩数据的开始MPEG-2的序列起始码为十六进制数000001(B3)。
序列头：记录序列信息档次（Profile），级别（Level），宽度，高度，是否是逐行序列，帧率等。
序列结束码：专有的一段比特串，标识该序列的压缩数据的结束,MPEG-2的序列结束码为十六进制数000001(B7)。

**图像组编码**

![Alt text](/image/Video_codec_learning_sharing/6.png)

**图像编码**

* 图像起始码：专有的一段比特串，标识一个图像的压缩数据的开始，MPEG-2
* 的图像起始码为十六进制数000001(00)。
* 图像头：记录图像信息
* 图像编码类型，图像距离，图像编码结构，图像是否为逐行扫描。

**图像分块编码**

![Alt text](/image/Video_codec_learning_sharing/7.png)

**条带编码**

![Alt text](/image/Video_codec_learning_sharing/8.png)

**宏块编码**

![Alt text](/image/Video_codec_learning_sharing/9.png)

* 宏块：16x16的像素块（对亮度而言）。
* 宏块内容：宏块编码类型，编码模式，参考帧索引，运动矢量信息，宏块编码系数等。

**块编码**

* 8x8或4x4块的变换量化系数的熵编码数据。
* CBP (Coded Block Patten)：用来指示块的变换量化系数是否全为零。
* 对于YUV(4:2:0)编码，CBP通常6比特长，每个比特对应一个块，当某一块的变换量化系数全为零时，其对应比特位值为0，否则为1。
* 每个块的变换量化系数的最后用一个EOB (End of Block)符号来标识。

#### 视频编解码主要流程和关键技术

![Alt text](/image/Video_codec_learning_sharing/10.png)

* 预测：通过帧内预测和帧间预测降低视频图像的空间冗余和时间冗余。
* 变换：通过从时域到频域的变换，去除相邻数据之间的相关性，即去除空间冗余。
* 量化：通过用更粗糙的数据表示精细的数据来降低编码的数据量，或者通过去除人眼不敏感的信息来降低编码数据量。
* 扫描：将二维变换量化数据重新组织成一维的数据序列。
* 熵编码：根据待编码数据的概率特性减少编码冗余。

**预测**

通过时间预测、空间预测技术，去除视频中存在的时间冗余和空间冗余，达到压缩的目的。

**空间预测**

利用图像空间相邻像素的相关性来预测的方法，关键技术是帧内预测技术和Intra图像编码（I帧）

帧内预测：利用当前编码块周围已经重构出来的像素预测当前块

**时间预测**

利用时间上相邻图像的相关性来预测的方法，关键技术是帧间预测和Inter图像编码。

帧间预测：运动估计（Motion Estimation，ME），运动补偿（Motion Compensation，MC）

运动估计:

* 为待预测块在参考帧上找到最佳的预测块，并记录预测块在参考帧上的相对位置。
* 记录运动矢量（Motion Vector，MV),参考帧上的预测块与当前帧上的的待预测块的相对位置
* 记录预测残差,待预测块的原始图像块减去预测的图像块所得结果。

![Alt text](/image/Video_codec_learning_sharing/11.png)

搜索算法：

* 三步搜索（Three Step Search，TSS）
* 二维Log搜索（2D Logarithmic Search，2DLOG）
* 正交搜索（Orthogonal Search Algorithm，OSA）
* 十字搜索（Cross Search Algorithm，CSA）
* 新三步搜索（New Three Step Search，NTSS）
* 四步搜索（Four Step Search，FSS）
* 共轭方向搜索（Conjugate Direction Search，CDS）
* 梯度下降搜索（Gradient Descent Search，GDS）
* 层次块搜索（Hierarchical Block Matching Algorithm，HBMA）

运动补偿：

* 根据运动矢量获取预测块
* 根据预测残差计算重构块

Inter图像编码：

前向预测编码图像（P帧）

双向预测编码图像（B帧）

![Alt text](/image/Video_codec_learning_sharing/12.png)

**变换**

###### 变换编码的目的

* 去除空间信号的相关性
* 将空间信号的能力集中到频域的一小部分低频系数上
* 能量小的系数可通过量化去除，而不会严重影响重构图像的质量

视频编码中常见的变换类型有：K-L变换、傅里叶变换、余弦变换、小波变换。

###### 变换原理

我们以傅立叶变换为例子来讲述一下变换的实现原理。关于傅立叶变换，可以用果汁牛奶打一个比方：

* 什么是傅立叶变换：对于一杯果汁牛奶，能分析出其食谱（recipe）
* 如何进行傅立* 叶变换：运行果汁牛奶的过滤器（filters）,将各类成分（ingredient）分离（extract）出来
* 为什么要进行傅立叶变换：食谱要比果汁牛奶要容易分析、比较、修改得多
* 如何再变换回去：根据食谱将成分再混合到一起，就又得到果汁牛奶了

![Alt text](/image/Video_codec_learning_sharing/13.png)

所谓“变换”，就是换个领域看问题（A Change Of Perspective），将某种情况下不易分析处理的领域换成易分析处理的领域。

接下来用一张gif图来展示一下傅立叶变换的过程

![Alt text](/image/Video_codec_learning_sharing/14.gif)

从上图可以看出：

* 任何连续周期信号都可以由一组适当的正弦曲线组合而成（这些正弦曲线通过叠加逼近，直至误差可以忽略），其实非周期信号也能通过傅里叶级数展开用正弦曲线叠加组合来无限逼近。
* 连续周期信号的表象是时域（time domain）波形，从时域上，我们很难进行分析、处理，而傅立叶变换就是将信号从时域（Observations In The Time Domain）转换到频域（Ingredients In The Frequency Domain）。频率只是信号的一个特征，它可以用来识别信号，在频域可以得到信号的成分（ingredients），就像果汁牛奶一样，Recipe比Object本身更容易分析、比较、修改。

傅立叶变换只是分离信号方法中的一种（靠频率分离）,由此可以想到傅立叶变换的一些应用有：

* 滤波：将不需要的频率对应的信号过滤掉，只留下需要的信号
* 调频：基于滤波，只专注于特定频率的信号进行接受
* 去噪：通过分离，把噪声对应频率的信号处理掉，增强核心的信号
* 压缩：将那些不太重要的部分忽略掉，保留主要部分（有损压缩）。例如，JPEG对.bmp压缩，MP3对.wav压缩都是这种方式

[了解更多傅里叶变换](http://joeshang.github.io/2014/03/11/signal-and-fft/)

###### DCT变换

DCT(Discrete Cosine Transform)，又叫离散余弦变换,是与傅里叶变换相关的一种变换，类似于离散傅里叶变换，但是只使用实数，经常用于信号和图像数据的压缩。经过DCT变换后的数据能量非常集中，一般只有左上角的数值是非零的，也就是能量都集中在离散余弦变换后的直流和低频部分。能量集中是DCT最显著的特征，如下图：

![Alt text](/image/Video_codec_learning_sharing/15.png)

接下来我们看一组用MATLAB进行DCT变换的实验数据

![Alt text](/image/Video_codec_learning_sharing/16.jpg)

将图像整分成8*8的块进行DCT变换，其中一个小分块变换后的系数分布。

![Alt text](/image/Video_codec_learning_sharing/17.jpg)

![Alt text](/image/Video_codec_learning_sharing/18.jpg)


整个图像的DCT系数

![Alt text](/image/Video_codec_learning_sharing/19.jpg)

保留左上三个单位系数，还原图像。

mask1=

[1 1 0 0 0 0 0 0

1 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0

0 0 0 0 0 0 0 0];%保留3个

![Alt text](/image/Video_codec_learning_sharing/20.jpg)

![Alt text](/image/Video_codec_learning_sharing/21.jpg)

![Alt text](/image/Video_codec_learning_sharing/22.jpg)

![Alt text](/image/Video_codec_learning_sharing/23.jpg)


**量化**

量化的基本思想：

* 映射一个输入间隔到一个整数
* 将含有大量的数据集合映射到含有少量的数据集合中，减少信源编码的bit
* 一般情况重构值与输入值不同

![Alt text](/image/Video_codec_learning_sharing/24.png)

量化的策略和模型直接影响图像还原后的质量，举例说明：

采用两个量化区间用1bit表示

![Alt text](/image/Video_codec_learning_sharing/25.png)


采用四个量化区间用2bit表示

![Alt text](/image/Video_codec_learning_sharing/26.png)


扫描

将二维数据转换为一维的数据序列

![Alt text](/image/Video_codec_learning_sharing/27.png)

![Alt text](/image/Video_codec_learning_sharing/28.png)



****编码**
用一句话概括就是，把信源用二进制表示。**
在视频编解码领域用到比较多的有：Huffman编码、行程编码、游程编码、二值算术编码、字典编码、等等…..

以大名鼎鼎的Huffman编码为例：

![Alt text](/image/Video_codec_learning_sharing/29.png)


## 4.编解码标准和国际组织

#### 国际标准组织

1. ITU (International Telecommunications Union)：国际电信联盟
2. ISO (International Standardization Organization)：国际标准化组织
3. IEC (International Electrotechnical Commission)：国际电工委员会

#### 视频编码专家组(Video Coding Experts Group—VCEG)

VCEG (Video Coding Experts Group)：视频编码专家组，属于ITU-T (Telecommunication)即**电信标准化部门**的Study Group 16/Question 6 (ITU-T SG16/Q.6)

VCEG制订标准：

1. H.261：第一个视频编码标准，用于ISDN（px64Kbps）传输的视频会议，主要采用了基于整象素的运动补偿
2. H.262 (MPE-2)：与MPEG合作制定的标准
3. H.263 (H.263+， H.263++)：用于低码率的视频编码，主要用于PSDN低于54Kbps的视频会议和视频电话，采用了1/2象素运动补偿，考虑了数据损失和错误鲁棒性的需要
4. H.26L： H.264的前身标准
5. H.264 (MPEG-4 AVC)：目前编码效率最高的标准

#### 动态图像专家组(Moving Picture Experts Group—MPEG)

MPEG（Moving Picture Experts Group，动态图像专家组）是ISO（International Standardization Organization，国际标准化组织）与IEC（International Electrotechnical Commission，国际电工委员会）于1988年成立的专门针对运动图像和语音压缩制定国际标准的组织。

MPEG制订标准：

1. MPEG-1 ： H.261+半象素运动补偿+双向预测+条带结构编码，用于VCD，LAN视频（最大1.5Mbps）
2. MPE-2： MPEG-1+隔行视频编码+缩放功能，用于HDTV（18Mbps） 、SDTV （2-5Mbps）数字信号传输和DVD（6-8Mbps）存储，兼容MPEG-1标准
3. MPEG-4 ASP (P-2) ：从H.263标准发展而来，基于视频对象平面编码，能在解码端控制视频对象，合成场景，并有音视频交互功能
4. MPEG-4 AVC (P-10)（H.264/AVC）：与VCEG合作制定的标准

![Alt text](/image/Video_codec_learning_sharing/30.png)

[了解更多MPEG-4 AVC (P-10)](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=39259)

[免费下载MPEG-4 AVC](http://kazus.ru/nuke/modules/Downloads/pub/144/0/ISO-IEC-14496-2-2001.pdf)

#### 视频编码标准发展历程

![Alt text](/image/Video_codec_learning_sharing/31.png)


#### 视频编码标准的应用场景

![Alt text](/image/Video_codec_learning_sharing/32.png)

## 5.视频文件封装（容器）

#### 封装格式

所谓封装格式就是将已经编码压缩好的视频轨和音频轨按照一定的格式放到一个文件中，这个文件也就相当于一个容器。采用不同的方式把视频编码和音频编码打包成一个完整的多媒体文件，也就出现了不同的后缀。

常见的封装格式:

1. AVI：微软在90年代初创立的封装标准，是当时为对抗quicktime格式（mov）而推出的，只能支持固定CBR恒定比特率编码的声音文件。
2. ts和ps：PS封装只能在HDDVD原版，
3. mov： MOV是Quicktime封装
4. WMV：微软推出的，作为市场竞争
5. mkv：MKV是Matroska的简称,万能封装器，有良好的兼容和跨平台性、纠错性，可带外挂字幕。
6. flv: 这种封装方式可以很好的保护原始地址，不容易被下载到，目前一些视频分享网站都采用这种封装方式
7. rmvb/rm：Real Video，由RealNetworks开发的应用于rmvb和rm的不同封装方式。rm是固定码率，rmvb是动态码率（就是静态画面采用用低码率，动态采用高码率）
8. MP4：主要应用于mpeg4的封装，主要在手机上使用。
9. 3GP：目前主要应用于H.263的封装，主要在3G手机上使用

常见的音视频组合方式：

封装容器	视频编码格式	音频编码格式

| 封装容器     |    视频编码格式 |   音频编码格式   |
| :------: | :------: | :------: |
|AVI|	Xvid| MP3|
|AVI	|Divx|	MP3|
|MKV|	Xvid	|MP3|
|MKV|	Xvid	|AAC|
|MKV|	H264	|AAC|
|MP4|	Xvid|	MP3|
|MP4|	H264	|AAC|
|3GP	|H.263|	AAC|

[了解更多视频文件封装](http://www.cnblogs.com/xkfz007/articles/2612932.html)

## 6.视频质量评价体系

#### 客观评价方法

![Alt text](/image/Video_codec_learning_sharing/33.png)

#### 主观评价方法

![Alt text](/image/Video_codec_learning_sharing/34.png)


#### 基于视觉的视频质量客观评价方法

将人的视觉特性用数学方法描述并用于视频质量评价的方式，结合了主观质量评价和客观质量评价两方面优点。

常用方法：结构相似度（Structural SIMilarity，SSIM）方法，是一种用以衡量两张数字影像相似程度的指标。当两张影像其中一张为无失真影像，另一张为失真后的影像，二者的结构相似性可以看成是失真影像的影像品质衡量指标。

![Alt text](/image/Video_codec_learning_sharing/35.png)

## 参考文献

[视频编解码学习](http://www.cnblogs.com/xkfz007/archive/2012/07/29/2613824.html)

[理解傅里叶变换](http://joeshang.github.io/2014/03/11/signal-and-fft/)

[An Intuitive Guide To The Fourier Transform](https://betterexplained.com/articles/an-interactive-guide-to-the-fourier-transform/)

[如何直观形象、生动有趣地给文科学生介绍傅立叶变换？](https://www.zhihu.com/question/19991026)

[傅里叶变换有哪些具体的应用？](https://www.zhihu.com/question/20460630)

[DCT变换在图像压缩中的实现](http://www.infocool.net/kb/Other/201608/177984.html)

[关于离散余弦变换（DCT）](http://www.jianshu.com/p/b923cd47ac4a)

[信号频域和时域的关系](https://www.zhihu.com/question/21040374)

[图像压缩中，为什么要将图像从空间域转换到频率域](https://www.zhihu.com/question/39689253)

[霍夫曼编码](https://zh.wikipedia.org/wiki/%E9%9C%8D%E5%A4%AB%E6%9B%BC%E7%BC%96%E7%A0%81)

[人类视觉系统（Human Visual System，HVS）](http://aabbc1122.blog.163.com/blog/static/5704325720122225645945/)

[MPEG-4 AVC (P-10)](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=39259)

[视频文件封装](http://www.cnblogs.com/xkfz007/articles/2612932.html)