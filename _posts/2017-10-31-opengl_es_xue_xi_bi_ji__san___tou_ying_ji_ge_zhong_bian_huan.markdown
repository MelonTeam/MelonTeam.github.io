---
layout: post
title: "OpenGL ES学习笔记（三）——投影及各种变换"
date: 2017-10-31 15:47:00 +0800
categories: android
author: vianhuang
tags: OpenGL
---

* content
{:toc}

| 导语 3D应用程序开发中，一项很重要的工作就是对场景中的物体进行各种投影与变换。OpenGL ES 1.x在变换方面采用的是封闭模式，而OpenGL
ES
2.0则是采用了开放模式，其API中不再提供完成各种变换的方法，变换所用的矩阵需要由开发人员直接提供给渲染管线。因此需要多了解一些投影和变换相关的知识。

  * 1\. 摄像机的设置
<!--more-->
  * 2\. 两种投影方式
    * 2.1 正交投影
    * 2.2 透视投影
    * 2.3 视口
  * 3.各种变换
    * 3.1 基本变换的相关知识
    * 3.2 平移变换
    * 3.3 旋转变换
    * 3.4 缩放变换
    * 3.5 所有变换的完整流程
  * 4\. 绘制方式

# 1\. 摄像机的设置

**摄像机的设置主要需要给出3方面的信息：包括摄像机的位置，观察的方向以及up方向。**  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/58caca25d8746dcc27d673d9dd9b42cd7e4065f5f4a98b971e13b18f63866c2e)  

[ 摄像机观察物体 ]

摄像机设置方法：

    
    
    Matrix.setLookAtM(
        mVMatrix,          //存储生成矩阵元素的float[]类型数组
        0,                 //起始偏移量
        cx, cy, cz,        //摄像机位置的x, y, z坐标
        tx, ty, tz,        //观察方向向量在x, y, z轴上的分量
        upx, upy, upz      //up向量在x, y, z轴上的分量
    );
    

# 2\. 两种投影方式

根据应用程序提供的投影矩阵，管线会确定一个可视空间区域，称为视景体。视景体由6个面组成：上平面，下平面，左平面，右平面，近平面，远平面。

## 2.1 正交投影

正交投影的投影线是平行的，故视景体是长方体，投影到近平面上的图形不会有近大远小的效果。  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/8141777e256005022627bcbd5c0b4ee2399bb276595b9f9c371dbf4490f25089)  

[ 正交投影示意图 ]

> 说明：其中视点即摄像机位置。

设置正交投影的代码如下：

    
    
    Matrix.orthoM(
        mProjectMatrix, //存储生成矩阵元素的float[]类型数组
        0，//填充起始偏移量
        left, right, //near面的left，right
        bottom, top, //near面的bottom，top
        neat, far //near面，far面与视点的距离
    );
    

## 2.2 透视投影

透视投影的投影线相交于视点，故视景体是梯形体，投影到近平面上的图形会有近大远小的效果。  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/962684a63edb829d04cadda7e3f9ab812cddfdfd4232f4541c67e601c9a085ea)  

[ 透视投影示意图 ]

设置正交投影的代码如下：

    
    
    Matrix.frustumM(
        mProjectMatrix, //存储生成矩阵元素的float[]类型数组
        0，//填充起始偏移量
        left, right, //near面的left，right
        bottom, top, //near面的bottom，top
        neat, far //near面，far面与视点的距离
    );
    

## 2.3 视口

场景中的物体投影到近平面后最终会映射到显示屏的视口中。视口也就是显示屏上指定的矩形区域。通过以下代码设置：

    
    
    GLES20.glViewPort(x, y, width, height);
    

视口用屏幕坐标系的原点并不在屏幕左上角，而在屏幕左下角。同时，此坐标系中x轴向右，y轴向上。一般情况下，应该保证近平面的宽高比与视口的宽高比相同，否则显示在屏幕上的图形会被拉伸变形。  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/72c2360e26518a398eee939608d880f0672128588b5bc357728241cfdc9d873b)  

[ 视口示意图 ]

# 3.各种变换

## 3.1 基本变换的相关知识

基本变换都是通过将表示点坐标的向量与特定的变换矩阵相乘完成的，进行基于矩阵的变换时，三维空间中点的位置需要表示成齐次坐标形式。所谓齐次坐标形式也就是在x,
y, z3个坐标值后面添加第四个量w，未变换时w值一般为1，如P=(Px, Py, Pz, 1)。  
例如P与一个特定的变换矩阵M相乘即可以完成一次基本变换，如下所示：  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/fe130b3b3cbd9b592134e6d52bf8a2e3e827bcffb16d68695ca3b9f6546308e0)

## 3.2 平移变换

平移变换矩阵的基本格式如下：  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/c226fb90f05fd4d16a8b083580a1452f01d17bb5f7088c54c6174ea3b0c0978c)

  
上述矩阵中的mx, my, mz分别表示平移变换中沿z, y, z轴方向的位移。通过简单的线性代数计算即可验证。  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/6931ba41d15118a016c168827bbd3914010f03891f57e5339be31687b8ce363e)

  
平移变换可以通过Matrix.translateM()方法设置，代码如下：

    
    
       /**
         * Translates matrix m by x, y, and z in place.
         *
         * @param m matrix
         * @param mOffset index into m where the matrix starts
         * @param x translation factor x
         * @param y translation factor y
         * @param z translation factor z
         */
        public static void translateM(
                float[] m, int mOffset,
                float x, float y, float z);
    

## 3.3 旋转变换

旋转变换矩阵的基本格式如下：  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/73241e2f82814deec5bc170386126f0655b3efbd14affe9256df07d635d00ec9)

  
上述矩阵表示将指定点P绕轴向量u旋转θ度，其中的ux， uy， uz表示u向量在x，y，z轴上的分量。

> OpenGL ES中旋转角度的正负可以用右手螺旋定则来确定：右手握住旋转轴，使大拇指指向旋转轴的正方向，4指环绕的方向即为旋转的正方向。  
>

>

>
![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/57b615ac05f304cb4468aec6ea956906f7b9b90da76d10523e6e090336b8588a)  
>

>

> [ 旋转正方向的确定 ]

旋转变换可以通过Matrix.rotateM()方法设置，代码如下：

    
    
        /*
         * Rotates matrix m in place by angle a (in degrees)
         * around the axis (x, y, z).
         *
         * @param m source matrix
         * @param mOffset index into m where the matrix starts
         * @param a angle to rotate in degrees
         * @param x X axis component
         * @param y Y axis component
         * @param z Z axis component
         */
        public static void rotateM(float[] m, int mOffset,
                float a, float x, float y, float z)
    

## 3.4 缩放变换

缩放变换矩阵的基本格式如下：  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/49e8b901576f14b9c0d77572c482c78d07d8f4fa7c54e94e1ef075554c3b13b6)

  
上述矩阵中的sx, sy, sz分别表示缩放变换中沿z, y, z轴方向的缩放率。通过简单的线性代数计算即可验证。  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/065c293242601a67caf032bc41b2320290603b4434643cb8234de683013c0aed)

缩放变换可以通过Matrix.scaleM()方法设置，代码如下：

    
    
        /**
         * Scales matrix m in place by sx, sy, and sz.
         *
         * @param m matrix to scale
         * @param mOffset index into m where the matrix starts
         * @param x scale factor x
         * @param y scale factor y
         * @param z scale factor z
         */
        public static void scaleM(float[] m, int mOffset,
                float x, float y, float z);
    

## 3.5 所有变换的完整流程

`最终传入渲染管线的是由摄像机矩阵，投影矩阵，基本变换总矩阵相乘得到的总变换矩阵。`在顶点着色器程序中，着色器将接收到的原始顶点位置与传入的总变换矩阵相乘，得到顶点最终的绘制位置，其基本代码如下：

    
    
    gl_Position = uMVPMatrix * vec4(aPosition, 1);
    

# 4\. 绘制方式

OpenGL ES中支持的绘制方式大概分3类：点，线，三角形。

  * **GL_POINTS**  
将传入渲染管线的一系列顶点单独进行绘制，不组装成更高一级的图元。

  * **GL_LINE**  
将传入渲染管线的一系列顶点按照顺序两两组织成线段进行绘制，若顶点数为奇数，管线则自动忽略最后一个顶点。

  * **GL_LINE_STRIP**  
将传入渲染管线的一系列顶点按照顺序依次组织成线段进行绘制。

  * **GL_LINE_LOOP**  
将传入渲染管线的一系列顶点按照顺序依次组织成线段进行绘制。与GL_LINE_STRIP的区别是，将最后一个顶点与第一个顶点相连，形成线段环。

  * **GL_TRIANGLES**  
将传入渲染管线的一系列顶点按照顺序每3个组织成一个三角形进行绘制。

  * **GL_TRIANGLES_STRIP**  
将传入渲染管线的一系列顶点按照顺序每3个组织成一个三角形进行绘制。最后形成的是一个三角形条带。

  * **GL_TRIANGLES_FAN**  
将传入渲染管线的一系列顶点中的第一个顶点作为中心点，其他顶点作为边缘点绘制出一系列组成扇形的相邻三角形。

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/8805b5e93f37f80a8c04367edc14ede8710f52dedcecd7fd4db4cd43a289c092)

  

![](/image/opengl_es_xue_xi_bi_ji__san___tou_ying_ji_ge_zhong_bian_huan/dff02d2aa660e685b701fe0d823d1b3aefbc68ed494b7b44418b6ef30c427c67)

