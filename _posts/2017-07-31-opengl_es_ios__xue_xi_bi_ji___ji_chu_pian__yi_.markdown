---
layout: post
title: "OpenGL ES (iOS) 学习笔记 — 基础篇（一）"
date: 2017-07-31 16:31:00 +0800
categories: ios
author: justinytang
tags: Opengles iOS
---

* content
{:toc}



最近一直在做视频相关的工作，结合最近很火的AR技术，所以准备好好学习一下3D渲染的相关知识。因为一直在iOS移动端开发，所以学习一下OpenGL ES
技术。

<!--more-->
目前OpenGL ES的学习，让我了解了一些基本概念和知识，算是对OpenGL
ES在iOS上的应用有了初步的认识。这篇笔记并不是教程，主要是对学习后的体会做一些总结。

整个OpenGL ES基础知识可以分成四个部分：

一、Shader的应用。

二、基本图形的绘制和变换。

三、透视投影和正交投影以及摄像机。

四、光照和纹理的应用。

其中前两个部分主要是2D世界图形的创建，后两个部分则是描述了3D世界。这篇文章我将介绍前两个部分的内容，实现2D世界的图形创建。

## **Shader****的应用**

着色器编程（shader programming）是OpenGL
ES2.0中的一个重要应用。主要是将图形处理流水线实现可编程管线，而不是以前的固定管线。从而方便开发者直接操作硬件。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__yi_/bfd8a0907d5581853f3d72acbfc595fa981d909ef99bee2b7d01dab42022507f)

图中阴影部分的 Vertex Shader 和 Fragment Shader
是可编程管线。可编程管线就是说这个操作可以动态编程实现而不必固定写死在代码中。可动态编程实现这一功能一般都是脚本提供的，在OpenGL ES
中也一样，编写这样脚本的能力是由着色语言(Shader
Language)提供的。可编程管线方便开发者动态修改渲染过程，而无需重写编译代码，当然也和很多脚本语言一样，调试起来不太方便。

### **Vertex Shader****（顶点着色器）**

顶点着色器实现了顶点变换阶段的功能。其输入时定点数据，即位置、颜色、法线等。顶点shader可以编写代码实现如下功能：

1、使用模型视图矩阵以及投影矩阵进行顶点变换。

2、法线变换及归一化。

3、纹理坐标生成和变换。

4、逐顶点或逐像素光照计算。

5、颜色计算。

一旦你使用了Vertex
Shader，顶点处理器的所有固定功能都将被替换。所以开发者不能只编写法线变换的Shader，而指望固定功能帮你完成纹理坐标生成。顶点处理器只是操作顶点而不是面，所以顶点处理器不能进行类似背面剔除这样的操作。顶点shader至少需要一个变量：gl_Position，通常要用模型视图矩阵以及投影矩阵进行变换。顶点处理器还可以访问OpenGL的状态，所以可以用来处理材质和光照。最新的设备还可以访问纹理。

### **Fragment Shader****（片断着色器）**

片断着色器可替代片断纹理化和色彩化的功能。片断处理器运行Fragment Shader以后可以进行如下操作：

1、逐像素计算颜色和纹理坐标。

2、应用纹理。

3、雾化计算。

4、如果需要逐像素光照，可以用来计算法线。

片断处理器的输入是顶点坐标、颜色、法线等计算插值得到的结果。Vertex
Shader对每个顶点的属性值进行了计算，现在将对图元中的每个片断进行处理，因此需要插值的结果。和顶点处理器一样，当你编写Fragment
Shader后，所有固定功能将被取代，所以不能实现诸如对片断材质化的同时，利用固定功能进行雾化。开发者必须编写程序实现需要的所有效果。片断处理器只对每个片断独立进行操作，并不知道相邻片断的内容。类似顶点shader，我们必须访问OpenGL状态，才可能知道应用程序中设置的雾颜色等内容。

Fragment Shader只有两种输出：

1、抛弃片断内容，什么也不输出。

2、计算片断的最终颜色gl_FragColor，当要渲染到多个目标时计算gl_FragData。

### 如何使用shader？

我们在iOS程序中如何使用Shader呢？其实只需要三个步骤就可以实现。

  * 第一步编译Shader代码：

    
    
    bool compileShader(GLuint *shader, GLenum type, const GLchar *source) {
        GLint status;
        if (!source) {
            printf("Failed to load vertex shader");
            return false;
        }
        *shader = glCreateShader(type);
        glShaderSource(*shader, 1, &source, NULL);
        glCompileShader(*shader);
    
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    #if Debug
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            printf("Shader compile log:\n%s", log);
            printf("Shader: \n %s\n", source);
            free(log);
        }
    #endif
        glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
        if (status == 0) {
            glDeleteShader(*shader);
            return false;
        }
        return true;
    }
    

  *  第二步把编译好的Shader附加到Program上，Program可以理解为一个跑在GPU上的小程序：

    
    
      // Attach vertex shader to program.
      glAttachShader(program, vertShader);
      // Attach fragment shader to program.
      glAttachShader(program, fragShader);

  *  第三步链接Program：

    
    
        // Link program.
        if (!linkProgram(program)) {
            printf("Failed to link program: %d", program);
            if (vertShader) {
                glDeleteShader(vertShader);
                vertShader = 0;
            }
            if (fragShader) {
                glDeleteShader(fragShader);
                fragShader = 0;
            }
            if (program) {
                glDeleteProgram(program);
                program = 0;
            }
            return false;
        }



    
    
    bool linkProgram(GLuint prog) {
        GLint status;
        glLinkProgram(prog);
    #if Debug
        GLint logLength;
        glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(prog, logLength, &logLength, log);
            printf("Program link log:\n%s", log);
            free(log);
        }
    #endif
        glGetProgramiv(prog, GL_LINK_STATUS, &status);
        if (status == 0) {
            return false;
        }
        return true;
    }

经过上述的步骤，我们就得到一个已经链接好的Program，所有和GPU交互的代码都会用到program的值。激活Vertex
Shader属性的代码就用到了program。

    
    
        // 启用Shader中的两个属性
        // attribute vec4 position;
        // attribute vec4 color;
        GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");
        glEnableVertexAttribArray(positionAttribLocation);
        GLuint colorAttribLocation = glGetAttribLocation(self.shaderProgram, "color");
        glEnableVertexAttribArray(colorAttribLocation);
        
        // 为shader中的position和color赋值
        // glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
        // indx: 上面Get到的Location
        // size: 有几个类型为type的数据，比如位置有x,y,z三个GLfloat元素，值就为3
        // type: 一般就是数组里元素数据的类型
        // normalized: 暂时用不上
        // stride: 每一个点包含几个byte，本例中就是6个GLfloat，x,y,z,r,g,b
        // ptr: 数据开始的指针，位置就是从头开始，颜色则跳过3个GLFloat的大小
        glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData);
        glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData + 3 * sizeof(GLfloat));

## **基本图形的绘制和变换**

OpenGL可以绘制点、直线和三角形，这是它的基本图形，正方形是由2个三角形拼在一起绘制成的，其他形状以此类推。

在OpenGL ES中，坐标系使用的是笛卡尔坐标系，原点位于手机的正中间，z轴指向手机外。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__yi_/08536be64f3a81d7e921125427bc26796a3381473e263b34daa3aaacbe641fcb)

顶点位置信息就是由这个坐标系来决定的，坐标长度的单位为1。手机的宽度为2，高度也为2。相当于手机的左下角是（-1，-1），右上角是（1，1）。

在实际应用中，图形绘制有三种变化是最常用的，分别是平移、缩放、旋转。通常做变换，都是通过平移变量（tx, ty, tz）、缩放变量（sx, sy,
sz）、旋转变量（rx, ry,
rz）。在渲染的时候把这些变量附加到原始的位置数据上实现变换。但是这种方式虽然可行但不够好，尤其是在GPU上这种方式产生的运算负担远大于使用矩阵。我们通过平移矩阵、缩放矩阵和旋转矩阵，与原来的位置矩阵进行运算。

平移矩阵就是一个4X4的单位矩阵的第4行的前三个元素用（tx，ty，tz）填充之后的矩阵。

缩放矩阵就是在4X4的单位矩阵中，将三个缩放元素（sx，sy，sz），分布到从左到右的对角线上，矩阵相乘后位置的x，y，z分别乘以了sx，sy，sz，从而实现了缩放。

下面就是一个单位矩阵。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__yi_/de0f2cf75d2082e5f22090594e700312ae28031da3159926e48d144ce53248d9)

旋转矩阵相比于上面两个矩阵略微有些复杂，旋转包含两个重要元素，旋转的角度，绕什么轴旋转。旋转绕的轴根据向量，通过右手旋转法则确定旋转方向。

注意：如果三个变换都需要的时候，相乘的顺序一定是平移矩阵 * 旋转矩阵 *
缩放矩阵，这样可以保证先缩放再旋转，最后再平移。如果先平移再缩放，点的位置已经改变，缩放出来的结果自然就不对了。

### ****如何创建一个图形？

其实一个图形的创建也是OpenGL渲染的基本流程体现。

![](/image/opengl_es_ios__xue_xi_bi_ji___ji_chu_pian__yi_/19ac17a9c43cbc41a6e532acb16879f0932bb6b054a6339e2e96a346c42617b7)

从图中可以看出，最开始的输入是顶点数据。比如三角形，就是三个点。每个顶点数据可以包含任意数量的信息，最基本的有位置，颜色等。经过各种处理，最终放入FrameBuffer（帧缓冲区）。接下来我们按照这个流程分解绘制一个图形的代码流程。

  * 第一步，提供Vertex Data（顶点数据）：

    
    
        static GLfloat triangleData[18] = {
            0,      0.5f,  0,  1,  0,  0, // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
            -0.5f, -0.5f,  0,  0,  1,  0,
            0.5f,  -0.5f,  0,  0,  0,  1,
        };

 如代码所示，这里绘制的是一个三角形，三角形有3个点，每个点将包含位置信息和颜色信息，至于两点之间的颜色OpenGL
ES会处理的。因此每一个点需要分配6个GLfloat大小的空间，前三个存储位置（x, y, z），后三个存储颜色（r, g,
b）。三个点就是18个GLfloat的数组。

使用GLfloat而不是float是为了跨平台，保证不同平台的GLfloat占用的字节数都是一致的。从而规范化了传递给Shader的数据的格式和大小。

  * 第二步，调用Vertex Shader

    
    
    attribute vec4 position;
    attribute vec4 color;
    varying vec4 fragColor;  
    void main(void) {
        fragColor = color;
        gl_Position = position;
    }  
    

 这里调用的Shader代码很简单，只是将顶点数据里的颜色传递给了Fragment Shader，将位置传递给了OpenGL
ES，根据上面对Shader的介绍，通过链接好的Program，顶点数据通过API传递给Shader。

  * 第三步，Primitive Assembly

    
    
     glDrawArrays(GL_TRIANGLES, 0, 3);

这一步，以形状为单位汇总渲染指令，为下一步栅格化颜色插值做准备。除了绘制三角形，还可以通过glDrawArrays绘制直线，点等。

  * 第四步，Rasterization

这一步会栅格化绘制的形状。第一步提到过只需传递顶点的颜色，两点中间的颜色OpenGL会帮我们处理。OpenGL将会计算出每一个像素对应的属性，比如颜色，这些值都是根据顶点的属性值以及形状计算而来的。三角形内部的每个像素的颜色都是根据像素点与三个点的距离计算出来的。例如其中一个顶点是红色的，那么离红色顶点越近像素的红色成分越多。

  * 第五步，Fragment Shader

经过栅格化之后，每一个像素都要经过Fragment Shader处理一遍，如果你不需要处理，则把OpenGL计算出来的颜色直接递交回给OpenGL即可。

    
    
    varying lowp vec4 fragColor;
    
    void main(void) {
        gl_FragColor = fragColor;
    }

  *  第六步，Per-Fragment Operations

这里主要处理OpenGL对像素的一些固定操作。比如深度测试，剪裁测试等。可以通过OpenGL的API进行配置。不过这里我们不需要做这些操作。

  * 第七步，Frame Buffer

最终写入Framebuffer，交换缓冲区后显示在窗口上。这样我们就利用OpenGL创建了一个三角形在界面上，而且还是有颜色的。

以上是对OpenGL ES中Shader和2D世界创建图形的介绍，后续将进入奇妙的3D世界，学习OpenGL是如何描述3D世界中的物体的。

##

