---
layout: post
title: "Metal学习（一）-画个矩形"
date: 2017-09-14 11:37:00 +0800
categories: 未分类
author: chaodong
tags: Metal
---

* content
{:toc}

| 导语 Metal学习开篇，简单介绍iOS上的Metal，从零开始画一个矩形。

# Metal概要

iOS 8.0起，Apple为了更充分地发挥GPU的潜力，引入了Metal框架。Metal提供了比OpenGL
<!--more-->
ES更底层的接口，可以更加高效的利用GPU资源。通过Metal，我们可以直接使用通用计算流水线，也就是GPU的Compute Shader（OpenGL
ES 3.1开始支持）。因此，在目前的Metal框架中可以使用三种着色器——Vertex Shader、Fragment Shader以及Compute
Shader。

# 基本概念

## Metal特有概念

### MTLDevice

在Metal 的架构中，MTLDevice 协议定义了简单的代表GPU
的接口,此协议提供了方法去查询设备的属性,创建设备的特殊对象，比如缓冲区或者纹理，编码和排队渲染和计算命令被提交给GPU执行。

### MTLCommandQueue

命令通过与 Metal 设备相关联的命令队列提交给 Metal
设备。接受GPU将要顺序执行的命令缓冲区对象的列表，命令队列以线程安全的方式接收命令并顺序执行。

### MTLCommandBuffer&CommandEncoder

MTLCommandBuffer 协议提供了一下几种编码类型，决定了编码不同种类的GPU工作，到指定的命令缓冲区中。  
MTLRenderCommandEncoder：主要用户绘图编码  
MTLComputeCommandEncoder： 主要用于并行计算  
MTLBlitCommandEncoder：编码简单的缓冲区和纹理拷贝操作

a)在任何时候,只有单个命令编码器可以被激活,添加命令到一个命令缓冲区上去,下一个命令编码器被创建和用与同一缓冲区之前,必须将上一个命令编码器结束掉  
b)当所有编码完成时,你提交MTLCommandBuffer 对象,这就意味着GPU 已经标记了命令缓冲区,准备开  
始执行

下图展示了MTLCommandBuffer，CommandEncoder，CommandQueue之间的关系  

![](/image/metal_xue_xi__yi__hua_ge_ju_xing/515b24074ea5b569187ae0a97c6d5202ade68b6cd4f3bcdabe9f60ee1adcbd3a)

### 暂态的对象（创建和销毁是廉价的，它们的创建方法都返回 autoreleased对象）

1.Command Buffers  
2.Command Encoders

### 非暂态的对象（在性能相关的代码里应该尽量重用它,避免反复创建）

1.Command Queues  
2.Buffers  
3.Textures  
4.Sampler States Libraries  
5.Compute States  
6.Render Pipeline States  
7.Depth/Stencil States

# Metal实战

下面就来展示下代码，如何在屏幕上画一个矩形

## 初始化Metal

### 1.创建MTLDevice

    
    
        _device = MTLCreateSystemDefaultDevice();
    

### 2.创建一个CAMetalLayer

    
    
        _metalLayer = [CAMetalLayer layer];
        _metalLayer.device = _device;
        _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;//MTLTexture的像素格式，现在支持MTLPixelFormatBGRA8Unorm和MTLPixelFormatBGRA8Unorm_sRGB
        _metalLayer.framebufferOnly = YES;
        _metalLayer.frame = self.view.layer.frame;
        [self.view.layer addSublayer:_metalLayer];
    

CAMetalLayer 是 CALayer 的子类，它可以展示 Metal 帧缓冲区的内容。我们必须告诉 layer 该使用哪个 Metal 设备
(我们刚创建的那个)，并通知它所预期的像素格式。我们选择 8-bit-per-channel BGRA 格式，即每个像素由蓝，绿，红和透明组成，值从
0-255。

### 3.创建一个Vertex Buffer

    
    
        GLuint dataSize = sizeof(GLfloat) * 3 * 6; //获取vertex data的字节大小
        _vertexBuffer = [_device newBufferWithBytes:&vertices length:dataSize options:MTLResourceCPUCacheModeDefaultCache];//在GPU创建一个新的buffer，将数据传到GPU中
    

这里的vertices是我们的顶点数据，声明如下

    
    
    GLfloat vertices[] = {
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
        -0.5f,  0.5f, 0.0f,
    
        0.5f, -0.5f, 0.0f,
        -0.5f,  0.5f, 0.0f,
        0.5f,  0.5f, 0.0f
    };
    

因为我们要绘制一个矩形，所以顶点数组里有两个三角形的顶点，共同拼成一个矩形。

### 4.创建一个Vertex Shader

### 5.创建一个Fragment Shader

    
    
        id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id <MTLFunction> vertextProgram = [defaultLibrary newFunctionWithName:@"basic_vertex"];
        id <MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"basic_fragment"];
    

一个 Metal 库是一组函数的集合。你的所有写在工程内的着色器函数都将被编译到默认库中，这个库可以通过设备获得；我们通过对应的方法名可以查找到相应的方法。

### 6.创建一个Render Pipeline

    
    
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineStateDescriptor.vertexFunction = vertextProgram;
        pipelineStateDescriptor.fragmentFunction = fragmentProgram;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm; //指定MTLTexture的像素颜色格式
    
        NSError *error = nil;
        _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    

我们需要一个渲染管线将vertextProgram和fragmentProgram组合起来。

### 7.创建一个Command Queue

    
    
    _commandQueue = [_device newCommandQueue];
    

创建一个CommandQueue，我们要在GPU中执行的命令都会放入到这个队列中并按顺序执行。

## 渲染

完成Metal的初始化了就要开始绘制了

### 1.创建一个Display link。

我们创建一个DisplayLink进行屏幕刷新

    
    
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    

并在render中实现每次渲染需要的操作

    
    
    - (void)render{
    
    }
    

### 2.创建一个Render Pass Descriptor

    
    
        id<CAMetalDrawable> drawable = _metalLayer.nextDrawable;
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;//nextDrawable()方法，它会返回需要绘制的纹理，使其显示在屏幕上
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;//loadAction设置为清除，这意味着“在绘制之前，将纹理设置为透明色”
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1.f, 1.f);//指定透明色。是RGBA的颜色格式，这里指定的是蓝色。
    

### 3.创建一个Command Buffer

    
    
        id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    

要放入设备的命令队列的命令必须被编码到命令缓冲区里。命令缓冲区是一个或多个命令的集合，可以以一种 GPU 了解的紧凑的方式执行和编码。

### 4.创建一个Render Command Encoder

    
    
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //创建一个RenderCommandEncoder
        [renderEncoder setRenderPipelineState:_renderPipelineState]; //指定之前创建好的RenderPipeline
        [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];//设置顶点缓存
    
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];//指定要绘制的形状和顶点总数
        [renderEncoder endEncoding];//告诉Encoder我们设置已经完成
    

### 5.提交Command Buffer的内容

现在我们的绘制指令已经被编码并准备就绪，我们需要通知命令缓冲区应该将结果在屏幕上显示出来。调用 presentDrawable，使用当前从 Metal
layer 中获得的 drawable 对象作为参数:

    
    
        [commandBuffer presentDrawable:drawable];
    

执行 commit 告诉缓冲区已经准备好安排并执行:

    
    
        [commandBuffer commit];
    

## Shader编写

Metal的Shader与OpenGL ES的shader稍有不同，更加接近C++的语法  
我们可以看下编写出来的shader

    
    
    #include 
    using namespace metal;
    
    vertex float4 basic_vertex(const device packed_float3* vertex_array [[ buffer(0) ]], unsigned int vid [[ vertex_id ]]) {
        return float4(vertex_array[vid], 1.0);
    }
    
    fragment half4 basic_fragment() {
        return half4(1, 0, 0, 1);
    }
    

可以看出来整体语法更加贴近C++，并且Vertex和Fragment两个Shader写到同一个文件中了，并不像OpenGL ES那样分来来。

我们一行行拆开来看

    
    
    #include 
    using namespace metal;
    

导入`metal_stdlib`头文件，指定metal的命名空间。

    
    
    vertex float4 basic_vertex(const device packed_float3* vertex_array [[ buffer(0) ]], unsigned int vid [[ vertex_id ]]) {
        return float4(vertex_array[vid], 1.0);
    }
    

  1. 所有的vertex shaders必须以关键字vertex开头。函数必须至少返回顶点的最终位置——你通过指定float4（一个元素为4个浮点数的向量）。然后你给一个名字给vetex shader，以后你将用这个名字来访问这个vertex shader。
  2. 第一个参数是一个指向一个元素为packed_float3(一个向量包含3个浮点数)的数组的指针，如：每个顶点的位置。这个 [[ … ]] 语法被用在声明那些能被用作特定额外信息的属性，像是资源位置，shader输入，内建变量。这里你把这个参数用 [[ buffer(0) ]] 标记，来指明这个参数将会被在你代码中你发送到你的vertex shader的第一块buffer data所遍历。
  3. vertex shader会接受一个名叫vertex_id的属性的特定参数，它意味着它会被vertex数组里特定的顶点所装入。
  4. 现在你基于vertex id来检索vertex数组中对应位置的vertex并把它返回。同时你把这个向量转换为一个float4类型，最后的value设置为1.0。

    
    
    fragment half4 basic_fragment() {
        return half4(1, 0, 0, 1);
    }
    

  1. 所有fragment shaders必须以fragment关键字开始。这个函数必须至少返回fragment的最终颜色——你通过指定half4（一个颜色的RGBA值）来完成这个
  2. 这里你返回half4(1, 0, 0, 1)的颜色，也就是红色。

# 参考附录

1.<https://developer.apple.com/library/content/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014221-CH1-SW1>  
2.<https://www.objccn.io/issue-18-2/>

