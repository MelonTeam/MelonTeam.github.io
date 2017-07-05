---
layout: post
title: "图像处理之漫水填充算法（flood fill algorithm）"
date: 2017-06-28 19:54:00
categories: android
author: zijianlu
tags: 图像处理 opencv
---

* content
{:toc}

| 导语 介绍了漫水填充算法（flood fill algorithm）的基本思想，实现方式和应用场景，opencv中floodfill函数的使用方法。

**基本思想**

漫水填充算法，顾名思义就像洪水漫过一样，把一块连通的区域填满，当然水要能漫过需要满足一定的条件，可以理解为满足条件的地方就是低洼的地方，水才能流过去。在图像处理中就是给定一个种子点作为起始点，向附近相邻的像素点扩散，把颜色相同或者相近的所有点都找出来，并填充上新的颜色，这些点形成一个连通的区域。
<!--more-->
漫水填充算法可以用来标记或者分离图像的一部分，可实现类似windows 画图油漆桶功能，或者ps里面的魔棒选择功能。

  
**算法实现**

漫水填充算法实现最常见有**四邻域**像素填充法，**八邻域** 像素填充法，基于**扫描线**的填充方法。根据代码实现方式又可以分为递归与非递归。

四领域的递归实现：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/19e57951b16dca65d793d56826756d589dc3579954237e1f65f63bdee36d0ec6)

    
    
    //recursive 4-way floodfill, crashes if recursion stack is full
    public void floodfill4(int x, int y, int newcolor, int oldcolor)  
    {  
        if(x >= 0 && x < width && y >= 0 && y < height   
             && getpixel(x, y) == oldcolor && getpixel(x, y) != newcolor)   
        {   
            setpixel(x, y, newcolor); //set color before starting recursion  
            floodfill4(x + 1, y, newcolor, oldcolor);  
            floodfill4(x - 1, y, newcolor, oldcolor);  
            floodfill4(x, y + 1, newcolor, oldcolor);  
            floodfill4(x, y - 1, newcolor, oldcolor);  
        }     
    }
    

  
八领域的递归实现：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/3be24eb4141d9913934796bc058becdcbfc08b12777c4b0f7a2d55b4ad96636c)

    
    
    public void floodfill8(int x, int y, int newcolor, int oldcolor)  
    {  
        if(x >= 0 && x < width && y >= 0 && y < height &&   
                getpixel(x, y) == oldcolor && getpixel(x, y) != newcolor)   
        {   
            setpixel(x, y, newcolor); //set color before starting recursion  
            floodfill8(x + 1, y, newcolor, oldcolor);  
            floodfill8(x - 1, y, newcolor, oldcolor);  
            floodfill8(x, y + 1, newcolor, oldcolor);  
            floodfill8(x, y - 1, newcolor, oldcolor);  
            floodfill8(x + 1, y + 1, newcolor, oldcolor);  
            floodfill8(x - 1, y - 1, newcolor, oldcolor);  
            floodfill8(x - 1, y + 1, newcolor, oldcolor);  
            floodfill8(x + 1, y - 1, newcolor, oldcolor);  
        }     
    } 
    

  
扫描线算法：  
先扫描一行或者一列内的连通像素，然后再上下行或者左右列扫描，可以减少递归栈的深度。

递归实现算法好理解，但当连通的区域很大时，很可能会导致**栈溢出**。关于扫描线算法和这些算法的非递归实现可以参见这里的介绍
<http://lodev.org/cgtutor/floodfill.html>

  
**opencv 的 floodfill 函数**

在opencv中，漫水填充算法由floodfill函数实现，可以从指定的种子点开始填充一个连通域。连通性由像素值的接近程度来衡量。opencv2.x
有两个c++重载的floodfill函数：

    
    
    /* fills the semi-uniform image region starting from the specified seed point*/
    cv_exports int floodfill( inputoutputarray image,
                              point seedpoint, 
                              scalar newval, 
                              cv_out rect* rect=0,
                              scalar lodiff=scalar(), 
                              scalar updiff=scalar(),
                              int flags=4 );
    
    /* fills the semi-uniform image region and/or the mask starting from the
       specified seed point*/
    cv_exports int floodfill( inputoutputarray image,
                              inputoutputarray mask,
                              point seedpoint, 
                              scalar newval, 
                              cv_out rect* rect=0,
                              scalar lodiff=scalar(), 
                              scalar updiff=scalar(),
                              int flags=4 );
    

**• image**  
要处理的图片，既是入参也是出参，接受单通道或3通道，8位或浮点类型的图片。如果提供了mask而且设置了 floodfill_mask_only
的flag，输入图像才不会被修改，否则调用本方法填充的结果会修改到输入图像中。

**• mask**  
掩码图像，既是入参也是出参，接受单通道8位的图片，要求比要处理的图片宽和高各大两个像素。mask要先初始化好，填充算法不能漫过mask中非0的区域。比如可以用边缘检测的结果来做为mask，以防止边缘被填充。做为输出参数，mask对应图片中被填充的像素会被置为1或者下面参数指定的值。因此当多次调用floodfill方法，使用同一个mask时，可以避免填充区域叠加和重复计算。
因为 mask比image大，所以image中的点 p(x,y)，对应mask中的点 p(x+1, y+1)

**• seedpoint** 填充算法的种子点，即起始点  
**• newval** 填充的颜色  
**• lodiff** 最小的亮度或颜色的差值  
**• updiff** 最大的亮度者颜色的差值  
**• rect** 可选的输出参数，返回一个最小的矩形，可以刚好把填充的连通域包起来。

**• flags**  
   - 低八位[0-7]表示连通性，默认值4表示四领域填充，8表示八领域填充。  
   - [8-15]位表示用来填充mask的颜色值[1-255]默认是1  
   - 比如flag值(4|(255<<8)) 表示使用四领域填充，mask填充色值是255。  
  
   - 剩余的位有两个值可以单独设置或者用（|）同时设置：  
**     floodfill_mask_only** 表示不修改原始输入图像，只把结果输出到mask图中，在mask中将填充区域标上前面flag中指定的值。newval的参数值将被忽略。

**     floodfill_fixed_range** 表示待填充像素只和种子点比较。如果不设置这个标记，表示待   填充的像素是和相邻的像素比较（相当于差值范围是浮动的），这种情况下填充区域的像素可能      会和种子点相差越来越大。

**未知点的判断**

通过下面未知点是否应该填充的判断条件，可以更好的理解上述参数的含义。

灰度图固定范围时(flag中设置了 floodfill_fixed_range )，未知点的判断，只跟种子点比较：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/babf45ce1bc8424f7a043f44ed54e7fbdf2b389b7e78fd2ff7b23eb25dbff868)

灰度图浮动范围时，未知点的判断，跟相邻的已经填充的点比较：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/e1cc1d9ae1c70014ab18ae4b3db75edbf916ce0d00a5f83329205e449f3b43c0)

同理彩色图固定范围时的判断：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/afc40f5999c9d1552ad3f245825b20bcff20fa8ecf4755115c31bd42142a5714)

彩色图浮动范围时的判断：

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/947a8e774729353301d72bb678a96992af95d8113e544a7c67e449784a6adc4c)

eg：通过多次选择背景种子点和调用 floodfill，可以把背景和前景分离开，黑白图是mask图。

![](/image/tu_xiang_chu_li_zhi_man_shui_tian_chong_suan_fa_flood_fill_algorithm_/1967569a1fd069345e86869115f835ef2cf687bb94ea87d81d9b818e3cc1a8a9)

