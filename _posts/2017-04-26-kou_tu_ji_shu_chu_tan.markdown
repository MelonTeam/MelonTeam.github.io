---
layout: post
title: "抠图技术初探"
date: 2017-04-26 13:36:00
categories: android
author: zijianlu
tags: 抠图 android
---

* content
{:toc}


图像抠图英文名叫 image matting，顾名思义就是将目标图像从背景中分离出来的一种图像处理技术。根据图像背景的复杂程度，一般分为纯色背景抠图（“绿幕”或者“蓝幕”）和自然图像抠图。

<strong>“绿幕”抠图</strong><br/> 这项技术主要被用在电影工业中。比如有时看到电影拍摄的场景中周围全是绿色的背景，甚至里面的工作人员也穿着绿色的衣服。这些绿色的背景在后期的处理中会用抠图技术去除，替换上电影中的背景，制作出各种宏大的场景或者特效，比如：

<!--more-->

<img src="/image/kou_tu_ji_shu_chu_tan/c7bea93a8e6095ff5e902674f16926da345cc7df3ea503d8698b8ad448e6525b" width="327" height="170"/><img src="/image/kou_tu_ji_shu_chu_tan/8367ca9c957deab141d6addda9b31bbf2dec1eb642f062840e7dfce201b47443" width="328" height="170"/>

<img src="/image/kou_tu_ji_shu_chu_tan/36ecea987706b90a1baa62b30a8ea96ca60d72d84d2ce9b09fe6ea7fe4d53725" width="328" height="150"/><img src="/image/kou_tu_ji_shu_chu_tan/63302a1319fa339cc11083034b31e0d576557ab881ff33198541276a84e6e6b2" width="329" height="149"/>

<img src="/image/kou_tu_ji_shu_chu_tan/7a9534dff5c12fafabf66d5705fe3aa45b63358dab48027254edb4f552c259e0" width="330" height="151"/><img src="/image/kou_tu_ji_shu_chu_tan/fa673cc8758149be02192e94ed173a69afc13af7a4f1ee04d86b7de060fd3f0e" width="280" height="152"/>

看了这些对比图是不是再也不敢相信自己的眼睛了，同时也要佩服这些演员丰富的想象力。<br/><br/>上面说的就是抠图中最原始的“绿幕”或者“蓝幕”抠图技术，之所以选择绿色和蓝色，是因为这两种颜色和肤色相差最远，同时做为rgb三原色之一也更容易处理。欧美多用绿色，是因为他们有人是蓝眼睛。理论上用其他的纯色背景也是可以的，只是要确保背景和前景不要有重叠的颜色，否则前景中相同颜色的部分也会被扣掉。<br/>下面的代码就用opencv实现了一个最简单的绿幕抠图：  

```
        mat src = imread("d:\\samplepic\\g1.png");

        mat hsvsrc;

        mat result(src.size(), cv_8uc3, scalar(0,0,0));

        cvtcolor(src, hsvsrc, cv_bgr2hsv);//转换到hsv颜色空间

        for(int i = 0; i < src.rows; i++)

        {

            for (int j = 0; j < src.cols; j++)

            {

                uchar b = src.at<vec3b>(i,j)[0];  

                uchar g = src.at<vec3b>(i,j)[1];  

                uchar r = src.at<vec3b>(i,j)[2];  

             

                uchar h = hsvsrc.at<vec3b>(i,j)[0];  

                uchar s = hsvsrc.at<vec3b>(i,j)[1];  

                uchar v = hsvsrc.at<vec3b>(i,j)[2]; 

                

                if (h > 60 && h <= 130 && s > 100) //判断绿色像素点

                {

                    b = 0;

                    g = 0;

                    r = 0;

                }

                result.at<vec3b>(i,j)[0] = b;  

                result.at<vec3b>(i,j)[1] = g;  

                result.at<vec3b>(i,j)[2] = r;  

            }

        }</vec3b></vec3b></vec3b></vec3b></vec3b></vec3b></vec3b></vec3b></vec3b>
```

原理是首先将图像的颜色从rgb转换到hsv空间，hsv分别表示：色调（h），饱和度（s），明度（v），通过h来判断大致的绿色的范围，然后将原图中判断为绿色背景的像素点rgb都置为0。

网上找的一张绿色背景图试验的效果：

<img src="/image/kou_tu_ji_shu_chu_tan/565643c5d2d08aa92751751cf9ddfa34c5b64a1aa2fd98eee23503fbaa9118b0"/> <img src="/image/kou_tu_ji_shu_chu_tan/c295e22f98abfcaaf9ace343166e2944cc0552bdd4019bac4e7002d6f774df0d"/><br/> 当然这个只是最简单的处理，当背景不均匀时有可能会有一些残留，或者把前景图像中的某些像素扣掉，同时边缘也还有一些残留的绿色像素和锯齿，要达到理想的效果需要做进一步的处理。

<strong>自然图像抠图</strong><br/>绿幕抠图对图像背景有苛刻的要求，现实中蓝绿纯色背景的图片太少，更多的是平时用手机或者相机拍摄的复杂背景的图片，这时候要想分离前景，就需要用到自然图像抠图技术。

自然图像抠图基本都基于这样一种模型：<br/><strong>c = αf + (1-α)b</strong><br/>这个模型把原始的图像看成了由前景和背景叠加合成所组成的图，其中：
- c 为图像当前可观察到的颜色，是已知的

- f 是前景色，

- b 背景色，

- α 不透明度（[0,1]区间变化，1为不透明，0为完全透明）。


这个模型表示图像像素的颜色是已经叠加合成过的颜色了也就是c，至于α、f、b都是未知的。而抠图算法就是要把三个变量给解出来。而要解出这些变量需要引入额外的约束信息，这通常需要用户的交互，由用户来指定一些初始的背景和前景的信息。

指定约束信息通常有两种方式：<br/><strong>1. trimap</strong><br/> 一般用白色部分表示前景，黑色表示背景，灰色表示待识别的部分<br/><img src="/image/kou_tu_ji_shu_chu_tan/9dc8302e50e7c65120fca3a560df99c345fa749074ad15565ff749ad57ce3c39" width="241" height="321"/> <img src="/image/kou_tu_ji_shu_chu_tan/2f2f09eec1106dda052ceeca2a4d5ea1c65676264ed408b7c68ac499ceffed8c"/>

                      原图                                                trimap图<br/><br/><strong>2. scribbles</strong><br/> 在前景和背景画几笔的草图。<br/><img src="/image/kou_tu_ji_shu_chu_tan/4bc08165e7390ba52a6575f3b71ae6312e23a1425fd8c1f9f09f4cc395810d53" width="176" height="237"/> <img src="/image/kou_tu_ji_shu_chu_tan/201421b341c8a9da0f764585f7613ac6f783899f9dcd6071fce330e918af0c2a" width="179" height="238"/> <img src="/image/kou_tu_ji_shu_chu_tan/9f7ec5f31cc463c391b66bb7eb54cac46a4b594f83b13f916463cd4f46ebc9f0" width="179" height="239"/>

               原图                             前景scribble                     背景scribble

<br/>       各种抠图算法做的事情，就是如何更准确更快速地通过用户指定的约束信息估计出未知区域的α、b、f来。抠图算法解出每个像素的α值后就可以生成一张α图，这张图前景是白色的，其余都是黑色的蒙板图，它和原图结合后就完成了抠图。

       在 [alphamatting](http://www.alphamatting.com) 网站中对历年出现的45种抠图算法进行了评测和排名。评测方法是使用8张不同类型图片做标准，测试每种算法在不同的trimap下对这些图片的抠图效果。从排名来看，2017年新出现的两种算法，抠图的效果相对最好。当然也可以看到没有一种算法是在所有的评测图片中都表现最好，从这里也可以看到自然图像抠图的复杂性。

<img src="/image/kou_tu_ji_shu_chu_tan/72fbd37535b31f92a4d187a77128ab78bd906fa2a3500f45237502d975777217"/>

<br/> 看下排名靠前的几种算法抠图的效果：<br/> information-flow matting 算法<br/><img src="/image/kou_tu_ji_shu_chu_tan/f122390cc49cffdfab424f31fe85c76536b871204d02502ff71b1aa37a66d242" width="213" height="172"/> <img src="/image/kou_tu_ji_shu_chu_tan/929c3fda8eeba6ea51b84e51243d93a1b8558d1befe526b28dd8f59463297c54" width="215" height="175"/> <img src="/image/kou_tu_ji_shu_chu_tan/2de13bd4e297e5509685a6eb293d351a3e04205fc14784720a3dffbbaca9adc9" width="211" height="175"/><br/><br/> deep matting 算法<br/><img src="/image/kou_tu_ji_shu_chu_tan/8e2cece3554a9dba1d40bdcd984ce7f22f5bfbc09f8711f152eec41cf9d6169a" width="214" height="151"/> <img src="/image/kou_tu_ji_shu_chu_tan/ac9333e80c0048e42435083692fcb891147b397651a374b6edd1455bb76f7b53" width="214" height="151"/> <img src="/image/kou_tu_ji_shu_chu_tan/bc9b0bec5e0804adb280a171e5583c382b8c0eaa2fc475e7023ba57b937294fb" width="214" height="151"/>

看抠图效果是不是很惊叹，头发的细节都能扣出来，然而这些算法运算速度普遍的很慢，要想在实时性要求比较高的场景中使用，需要大量的工程化改进和优化工作。
