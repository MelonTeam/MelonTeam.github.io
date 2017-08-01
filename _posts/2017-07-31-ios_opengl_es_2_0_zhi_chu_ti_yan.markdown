---
layout: post
title: "[iOS] OpenGL ES 2.0之初体验"
date: 2017-07-31 20:36:00 +0800
categories: ios
author: monawang
tags: iOS OpenGL
---

* content
{:toc}

| 导语 OpenGL ES 是专门为手持设备制定的 3D 规范，是 OpenGL 的简化版，目前最新规范版本为 3.0。 由于iPhone
5C及以下设备不支持OpenGL ES 3.0，所以这里我以2.0版本为例进行OpenGL ES的入门探索。

        虽然 iOS 5在 GLKit 中提供了方便使用OpenGL ES的GLKView，但我这里还是先从零开始设置自己的GL ES
view，从而更进一步了解OpenGL ES是如何工作的。
<!--more-->

### (1)引入需要的库

· OpenGLES.framework：

         OpenGLES.framework提供了OpenGL ES 1.1、2.0、3.0版本在iOS上的实现，包含了OpenGL
ES的所有接口。在OpenGL ES开发中，我们主要使用的就是OpenGLES.framework。

· QuartzCore.framework：

QuartzCore.framework提供了图形处理和视频图像处理的能力，主要包括CALayer和CAAnimation两大图形展示与动画效果的必备接口。不过这一次，我们要用到的只有CAEAGLLayer。

加入到工程中：

![](/image/ios_opengl_es_2_0_zhi_chu_ti_yan/8f588e0b3d3b344b595aad13e61c36c0a06bbf2679ad44fa4d7b736e9e20126d)

### (2)定义一个View

    
    
    #import 
    #import 
    #include 
    #include 
    
    @interface OpenGLView : UIView{
        CAEAGLLayer* _eaglLayer;
        EAGLContext* _context;
        GLuint _colorRenderBuffer;
        GLuint _frameBuffer;
    }
    @end

 · CAEAGLLayer：

CAEAGLLayer是CALayer的子类，它提供了一个OpenGLES渲染环境。各种各样的OpenGL绘图缓冲的底层可配置项都需要用CAEAGLLayer完成。

· EAGLContext：

     EAGLContext是OpenGL ES 的渲染上下文，管理所有使用OpenGL ES
进行描绘的状态、命令以及资源信息。类似于drawRect: 方法里的CGContextRef。

### (3)设置layer

复写UIView的layerClass方法，改变UIView自带layer为CAEAGLLayer。这样当我们调用self.layer时返回的就会是一个CAEAGLLayer对象，我们才能在其上描绘OpenGL内容。

    
    
    + (Class)layerClass {
        return [CAEAGLLayer class];
    }
    
    
    - (void)setupLayer
    {
        _eaglLayer = (CAEAGLLayer*) self.layer;
        
        // CALayer 默认是透明的，必须将它设为不透明才能让其可见
        _eaglLayer.opaque = YES;
        
        // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
        _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    }

·
kEAGLDrawablePropertyRetainedBacking：这个key表示是否要保持呈现的内容不变，默认为NO。因为设置为YES时对性能和资源影像较大，如果不是想要让展示保持不变不推荐设置为YES。

· kEAGLDrawablePropertyColorFormat：设置颜色格式，默认值为kEAGLColorFormatRGBA8。

                --kEAGLColorFormatRGBA8：
对应OpenGL的GL_RGBA8，一个像素32bits，每一个像素的Red、Green、Blue、Alpha都分别用一个byte(8bits)来表示。

--kEAGLColorFormatRGB565：对应OpenGL的GL_RGB565，一个像素16bits，用5bits表示Red、6bits表示Green、5bits表示Blue。

      从颜色的存储大小能够看出，RGBA8能表示更多的颜色，画质更高。一般情况下都使用RGBA8，RGB565的图像画质较差，且不能表达alpha值。

### (4)设置OpenGL ES

至此 layer 的配置已经完成，下面我们来设置与OpenGL ES相关的东西。

· 设置上下文EAGLContext：

    
    
    - (void)setupContext {
        // 指定OpenGL渲染API的版本，在这里我们使用OpenGL ES 2.0 
        EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
        _context = [[EAGLContext alloc] initWithAPI:api];
        if (!_context) {
            NSLog(@"Failed to initialize OpenGLES 2.0 context");
            exit(1);
        }
        
        // 设置为当前上下文
        if (![EAGLContext setCurrentContext:_context]) {
            NSLog(@"Failed to set current OpenGL context");
            exit(1);
        }
    }

· 设置renderbuffer：

_colorRenderBuffer实际上是一个uint32_t，表示这块renderBuffer的id，我们只能通过这个id来操作renderBuffer。

glGenRenderbuffers函数就是用来给renderBuffer分配id。p.s. id 0被OpenGL ES保留，不会分配给外部。

    
    
    glBindRenderbuffer函数将指定id的renderbuffer绑定为当前renderbuffer。第一个参数必须为GL_RENDERBUFFER，第二个参数就是使用glGenRenderbuffers分配的id。当指定id的 renderbuffer第一次被设置为当前renderbuffer时，会初始化该renderbuffer对象
    
    
    - (void)setupRenderBuffer {
        glGenRenderbuffers(1, &_colorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        // 为 color renderbuffer 分配存储空间
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    }

renderbufferStorage:fromDrawable:使用我们上文设置好的CAEAGLLayer来为renderbuffer分配存储空间。其中将使用我们在前面设置的颜色格式RGBA8以及Layer的宽高。

· 设置framebuffer object：

framebuffer object 通常也被称之为 FBO，它相当于 buffer(color, depth, stencil)的管理者，三大buffer
可以附加到一个 FBO 上。

    
    
    - (void)setupFrameBuffer {    
        glGenFramebuffers(1, &_frameBuffer);
        // 设置为当前 framebuffer
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                                  GL_RENDERBUFFER, _colorRenderBuffer);
    }
    
    
    · 销毁操作：  
    当 UIView 在进行布局变化之后，由于 layer 的宽高变化，导致原来创建的 renderbuffer不再相符，我们需要销毁既有 renderbuffer 和 framebuffer
    
    
    - (void)destoryRenderAndFrameBuffer
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }

###  (5)渲染

简单设置一下背景颜色：

    
    
    - (void)render {
        glClearColor(0, 1.0, 0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
    
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }

###  (6) Run!

    
    
    - (void)layoutSubviews {
    
        [self setupLayer];        
    
        [self setupContext];
    
        [self destoryRenderAndFrameBuffer];
    
        [self setupRenderBuffer];        
    
        [self setupFrameBuffer];    
    
        [self render];
    }



![](/image/ios_opengl_es_2_0_zhi_chu_ti_yan/ada3f8f4e448afe124acd18a3726be34211b90c928461f1964fb921c6dd57871)

