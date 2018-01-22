---
layout: post
title: "OpenGL ES (iOS) 学习笔记 — 基础篇（二）"
date: 2017-11-30 17:50:00 +0800
categories: ios
author: justinytang
tags: openglES基础 iOS
---

* content
{:toc}



上一篇文章（<
ES是如果描述2D世界的，这篇我们将走入3D世界，里面的内容是我学习后想记录的。

<!--more-->
根据上一篇文章的总结，整个OpenGL ES基础知识可以分成四个部分：

一、Shader的应用。

二、基本图形的绘制和变换。

三、透视投影和正交投影以及摄像机。

四、光照和纹理的应用。

前两个部分已经介绍过，我们这次介绍后面两个部分，已经它们在3D渲染中的作用。

## **透视投影和正交投影**

这两个投影是描述看世界的方式：

透视投影主要作用是模仿人眼观察3D世界的规律，让物体近大远小，所以被称为透视。

正交投影主要作用是将坐标系映射到其他大小，主要用于2D UI绘制。

### 透视投影

对于3D世界的物体来说，透视投影就是将其投射在观察平面上，下面是透视投影的示意图：

![]()![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__er_/8fb716d22c83e2aa2698b700ea094430e1f27f8ae371958748b82da94d4ebd65)

先来看一下透视投影的代码

    
    
    // 透视投影
        float aspect = self.view.frame.size.width / self.view.frame.size.height;
        GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 10.0);
        GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(0, 0, -1.6);
        self.transformMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
        self.transformMatrix = GLKMatrix4Multiply(perspectiveMatrix, self.transformMatrix);  
    

> GLKMathDegreesToRadians是将角度转换成弧度

分析一下，GLKit提供了`GLKMatrix4MakePerspective`方法便捷的生成透视投影矩阵。方法有4个参数`float
fovyRadians, float aspect, float nearZ, float
farZ`。`fovyRadians`表示视角。`aspect`表示屏幕宽高比，为了将所有轴的单位长度统一，所以需要知道屏幕宽高比多少。`nearZ`表示可视范围在Z轴的起点到原点(0,0,0)的距离，`farZ`表示可视范围在Z轴的终点到原点(0,0,0)的距离,`nearZ`和`farZ`始终为正。下面是透视投影的剖面示意图：

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__er_/59b3f029d473736064a85357fd0ae47612c425ca02420db2aee6ccde5df9f193)

透视投影矩阵默认的可视方向是向Z轴的反方向生长的。视角（fovyRadians）越大，看到的东西就越多。只有在nearZ和farZ两个平面范围内的点才会被投影到屏幕上，当然这些点也必须在视角的范围内。

### 正交投影

老规矩先看一下代码：

    
    
     // 正交投影
        float viewWidth = self.view.frame.size.width;
        float viewHeight = self.view.frame.size.height;
        GLKMatrix4 orthMatrix = GLKMatrix4MakeOrtho(-viewWidth/2, viewWidth/2, -viewHeight / 2, viewHeight/2, -10, 10);
        GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(200, 200, 200);
        self.transformMatrix = GLKMatrix4Multiply(scaleMatrix, rotateMatrix);
        self.transformMatrix = GLKMatrix4Multiply(orthMatrix, self.transformMatrix);

 正交投影其实比较好理解，原先屏幕的X轴从左到右是-1到1，Y轴从上到下是1到-1，经过`GLKMatrix4 orthMatrix =
GLKMatrix4MakeOrtho(-viewWidth/2, viewWidth/2, -viewHeight / 2, viewHeight/2,
-10, 10)`正交矩阵的变换，就会变成X轴从左到右是-viewWidth/2到viewWidth/2，Y轴从上到下是viewHeight/2到-
viewHeight / 2，viewWidth和viewHeight是屏幕的宽和高。

这里增加了一个缩放矩阵`GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(200, 200,
200)`，是为了可以看见渲染出来的矩形。因为它原本只有1 x
1的大小，在正交投影后，也就是一个像素的大小，几乎是看不见的。正交投影里的nearZ和farZ代表可视的Z轴范围，超出的点就不可见了。

## **摄像机**

上面介绍的是投影矩阵，但是我们在观察一个3D的物体的时候，并不只有投影矩阵在作用，整个观察的系统可以用MVP矩阵模型来描述。

MVP表示的是模型矩阵（Model），观察矩阵（View），投影矩阵（Projection）。

投影矩阵上面介绍过了。

模型矩阵针对的是单个3D模型，渲染每一个3D模型前，需要将各自的模型矩阵传递给Vertex Shader。

观察矩阵针对的是场景中的所有物体，当观察矩阵改变时，所有顶点的位置都会受到影响，就好比在现实生活中，你移动摄像机会导致拍摄到的场景不一样。所以观察矩阵可以理解为OpenGL
3D世界中的摄像机。有了这个矩阵的存在，我们就可以自由的在3D世界中浏览，以第一人称的身份观察这个世界。

实现MVP矩阵很简单，只要我们修改一下Vertex Shader。

    
    
    attribute vec4 position;
    attribute vec4 color;
    
    uniform float elapsedTime;
    uniform mat4 projectionMatrix;
    uniform mat4 cameraMatrix;
    uniform mat4 modelMatrix;
    
    varying vec4 fragColor;
    
    void main(void) {
        fragColor = color;
        mat4 mvp = projectionMatrix * cameraMatrix * modelMatrix;
        gl_Position = mvp * position;
    }

 需要注意的是相乘的顺序，这个顺序的结果是先进行模型矩阵变换，再是观察矩阵，最后是投影矩阵变换。

而观察矩阵的初始化也很简单：

    
    
    // 使用透视投影矩阵
        float aspect = self.view.frame.size.width / self.view.frame.size.height;
        self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 100.0);
        
        // 设置摄像机在 0，0，2 坐标，看向 0，0，0点。Y轴正向为摄像机顶部指向的方向
        self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2, 0, 0, 0, 0, 1, 0);
        
        // 先初始化矩形1的模型矩阵为单位矩阵
        self.modelMatrix1 = GLKMatrix4Identity;
        // 先初始化矩形2的模型矩阵为单位矩阵
        self.modelMatrix2 = GLKMatrix4Identity;

上述代码中，投影矩阵使用了透视投影进行初始化。两个模型矩阵初始化为单位矩阵。观察矩阵初始化为摄像机在（0，0，2）坐标，看向（0，0，0）点，向上朝向（0，1，0）。`GLKMatrix4MakeLookAt`提供了快捷创建观察矩阵的方法，需要传递9个参数，摄像机的位置eyeX，eyeY，eyeZ，摄像机看向的点centerX，centerY，centerZ，摄像机向上的朝向upX,
upY, upZ。改变这几个参数就能控制摄像机在3D世界中通过不同角度拍摄物体。

修改一下透视投影的示意图，加入观察矩阵后的示意图：

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__er_/f2b334a7a9470393dd3e7edfb48332ec53b021d0002d9f7bfd671bf444618301)

> 图中的lookAt就是center。游戏中通过观察矩阵，可以让第一人称玩家360度观察周边景物。

## 基本的光照和纹理

### 光照模型

现实世界的光照是极其复杂的，诸多因素的影响会导致各种变化，这是我们很难模拟的。因此OpenGL的光照仅仅使用了简化的模型并基于对现实的估计来进行模拟，这样处理起来会更容易一些，而且看起来也差不多一样。这些光照模型都是基于我们对光的物理特性的理解。

其中一个模型被称为冯氏光照模型(Phong Lighting
Model)。冯氏光照模型的主要结构由3个元素组成：环境(Ambient)、漫反射(Diffuse)和镜面(Specular)光照。

  * 环境光照(Ambient Lighting)：即使在黑暗的情况下，现实世界也会有一些光亮(例如月亮、一个来自远处的光等)，所以物体永远不会是完全黑暗的。我们使用环境光照来模拟这种情况，也就是无论如何永远都给物体一些颜色。
  * 漫反射光照(Diffuse Lighting)：模拟一个发光物对物体的方向性影响(Directional Impact)。它是冯氏光照模型最显著的组成部分。面向光源的一面比其他面会更亮。
  * 镜面光照(Specular Lighting)：模拟有光泽物体上面出现的亮点。镜面光照的颜色，相比于物体的颜色更倾向于光的颜色。

实现上述的三种光照，除了需要光照方向以外，还需要了解法线向量，通过法线向量，我们可以知道平面的朝向。在具体实现中，每个点都会有一个法线向量。所谓法线向量就是垂直于平面的一个三维向量，如下图所示。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__er_/7701077a41b0522994ec5a1eee18a5989c141d2f2379dc2ec9d5275be48fd3c7)

图中展示了两种法线向量的表示方法，左边是每个多边形的每个点有一个法线向量，右边是每个点有一个法线向量，共享点的法线向量是这个点在所有平面上的法线向量之和。法线向量应该总是被规范化成单位向量。有了法线向量和光照方向之后，只要将它们相乘即可得到光照强度。

具体实现代码就不贴出来了，这里只需要将`attribute vec4 color`换成了`attribute vec3
normal`，不再传递颜色数据，改为法线向量。然后将法线向量传递给Fragment Shader就可以了 `fragNormal = normal`。

### 纹理模型

纹理通常来说就是一张图片，我们为每一个顶点指定纹理坐标，然后就可以在Shader中获取相应的纹理像素点颜色了。了解纹理之前，我们先了解一下纹理坐标。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__er_/33bfd8e51ad647d3b6d3fcecbfd2b4abf90380991aba843325101a1b3ddc2565)

纹理坐标一般用（u，v）来展示，通过将顶点坐标和纹理坐标进行映射来实现对应顶点的纹理加载。有了正确的纹理坐标，我们该怎么加载纹理呢？

首先，我们要生成纹理，可以利用GLKit提供的方法：

    
    
    @property (strong, nonatomic) GLKTextureInfo *diffuseTexture;
    
    - (void)genTexture {   
        NSString *textureFile = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"jpg"];   
        NSError *error;   
        self.diffuseTexture = [GLKTextureLoader textureWithContentsOfFile:textureFile options:nil error:&error];   
    }

 diffuseTexture是GLKTextureInfo类型的，它的属性`name`将会被用来和OpenGL系统进行交互。

其次，我们需要绑定和使用纹理。

绑定纹理的流程是：

  1. 激活纹理的某个通道`glActiveTexture(GL_TEXTURE0)`,OpenGL ES中最多可以激活8个通道。通道0是默认激活的。
  2. 绑定生成的纹理到`GL_TEXTURE_2D`， `glBindTexture(GL_TEXTURE_2D, self.diffuseTexture.name)`，注意这里是绑定到`GL_TEXTURE_2D`而不是`GL_TEXTURE0`。
  3. 将0传递给`uniform` `diffuseMap`,如果激活的是`GL_TEXTURE1`就传递1，以此类推。

Fragment Shader中增加了`uniform sampler2D
diffuseMap`，`sampler2D`是纹理的参数类型。然后将`diffuseMap`在纹理坐标`fragUV`上的像素颜色作为基本色`vec4
materialColor = texture2D(diffuseMap,
fragUV)`。`texture2D`函数用来采样纹理在某个`uv`坐标下的颜色，返回值类型是`vec4`。

这样就可以实现将一个图片作为纹理加载到模型上了。

以上介绍的都是OpenGL
3D世界中最基础的概念，想要实现更复杂的场景，需要更多的知识积累。下一篇我将通过全景视频播放器的实现来介绍这些基础的概念是怎么应用到实际的场景中的。

