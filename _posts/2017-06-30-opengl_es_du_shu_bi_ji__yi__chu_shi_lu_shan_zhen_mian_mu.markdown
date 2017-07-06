---
layout: post
title: "OpenGL ES读书笔记（一）—初始庐山真面目"
date: 2017-06-30 21:37:00
categories: android
author: vianhuang
tags: Android OpenGL
---

* content
{:toc}



  * 1\. OpenGL ES简介
    * 1.1 顶点着色器
    * 1.2 片段着色器
<!--more-->
  * 2\. 一个OpenGL ES 2.0实例——绘制一个三角形
    * 2.1 创建简单的顶点和片段着色器
    * 2.2 编译和加载着色器
    * 2.3 创建一个程序对象并链接着色器
    * 2.4加载几何图形和绘制图元

## 1\. OpenGL ES简介

OpenGL ES（OpenGL for Embedded Systems）是以手持和嵌入式设备为目标的高级3D图形应用程序编程接口。OpenGL
ES是当今智能手机中占据统治地位的图形API，支持的平台包括IOS,，Android，BlackBerry，bada，Linux和Windows。  
OpenGL ES 实现了具有可编程着色功能的图形管线。下图展示了OpenGL ES 图形管线，图中带有阴影的方框表示OpenGL ES中管线的可编程阶段。  
![](/image/OpenGL_ES_du_shu_bi_ji__yi__chu_shi_lu_shan_zhen_mian_mu/bed68d59028baaf5ddda621d0c9b196ca19901b2e072f4879772e2e7de2f5375)

### 1.1 顶点着色器

其工作过程为首先将原始的顶点几何信息及其他属性传送到顶点着色器中，经过自己开发的顶点着色器处理后产生纹理坐标，颜色，点位置等后续流程需要的各项顶点属性信息，然后将其传递给图元装配阶段。  
![](/image/OpenGL_ES_du_shu_bi_ji__yi__chu_shi_lu_shan_zhen_mian_mu/16559f7ffb43acd09b53c950b5e25d3dfd177eff12a5db8e66fe5895d23985da)  
顶点着色器的输入包括：

  * 着色器程序——描述顶点上执行操作的顶点着色器程序源代码或者可执行文件。
  * 顶点着色器输入（或者属性）——用顶点数组提供的每个顶点的数据。
  * 统一变量（uniform）——顶点着色器使用的不变数据。
  * 采样器——代表顶点着色器使用纹理的特殊统一变量类型。

### 1.2 片段着色器

片元着色器是用于处理片元值及其相关数据的可编程单元，其可以执行纹理的采样，颜色的汇总，计算雾颜色等操作，每片元执行一次。片元着色器主要功能为通过重复执行（每片元一次），将3D物体中的图元光栅化后产生的每个片元的颜色等属性计算出来送入后继阶段。  
![](/image/OpenGL_ES_du_shu_bi_ji__yi__chu_shi_lu_shan_zhen_mian_mu/c372fe09285e5b04a93c088f3ab80b8ce762925ad77ea65dbfbb10ea073cb819)

片段着色器的输入包括：

  * 着色器程序——描述片段上所执行操作的片段着色器程序源代码或者可执行文件。
  * 输入变量——光栅化单元用插值为每个片段生成的顶点着色器输出。
  * 统一变量（uniform）——顶点着色器使用的不变数据。
  * 采样器——代表片段着色器使用纹理的特殊统一变量类型。 

## 2\. 一个OpenGL ES 2.0实例——绘制一个三角形

### 2.1 创建简单的顶点和片段着色器

OpenGL ES 2.0程序必须至少要有一个顶点着色器和一个片段着色器。  
着色器的代码可以存储在后缀名为”.glsl”文件中，这些文件存放到项目的asserts目录下。

  * **一个简单的顶点着色器**
    
        //assert目录下面的vertex.glsl
    //总变换矩阵
    uniform mat4 uMVPMatrix;
    //顶点位置
    attribute vec3 aPosition;
    //顶点颜色
    attribute vec4 aColor;
    //用于传递给片元着色器的易变变量
    varying vec4 vColor;
    void main(){
      //根据总变换矩阵计算此次绘制此顶点的位置
      gl_Position = uMVPMatrix * vec4(aPosition, 1);
      //将接收的顶点颜色传递给片元着色器
      vColor = aColor;
    }
    

  * **一个简单的片段着色器**
    
        //assert目录下面的fragment.glsl
    //声明着色器中浮点变量的默认精度
    precision mediump float;
    //接收从顶点着色器传过来的易变变量
    varying vec4 vColor;
    void main(){
      //给此片元赋颜色值
      gl_FragColor = vColor;
    }
    

### 2.2 编译和加载着色器

上面已经定义了着色器源代码，接下来将着色器加载到OpenGL SE中。

    
    
    //ShaderUtil.java
    public static int loadShader(int shaderType, String source){
            //创建shader，并记录其id
            int shader = GLES20.glCreateShader(shaderType);
            if(shader != 0){
                //加载着色器的源代码
                GLES20.glShaderSource(shader, source);
                //编译
                GLES20.glCompileShader(shader);
                //获取shader的编译结果
                int[] compiled = new int[1];
                GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
                if(compiled[0] == 0){
                    Log.e("ES20_ERROR", "could not compile shader " + shaderType+ ":" + GLES20.glGetShaderInfoLog(shader));
                    shader = 0;
                }
            }
            return shader;
        }
    

### 2.3 创建一个程序对象并链接着色器

    
    
        //ShaderUtil.java
        public static int createProgram(String vertexSource, String fragmentSource){
            //加载顶点着色器
            int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
            if(vertexShader == 0){
                return 0;
            }
    
            //加载片元着色器
            int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
            if(fragmentShader == 0){
                return 0;
            }
    
            //创建程序
            int program = GLES20.glCreateProgram();
            if(program != 0){
                //程序创建成功后，向程序中加入顶点着色器和片元着色器
                GLES20.glAttachShader(program, vertexShader);
                GLES20.glAttachShader(program, fragmentShader);
    
                //链接程序
                GLES20.glLinkProgram(program);
    
                //获取链接情况，若链接失败则报错并删除程序
                int[] linkStatus = new int[1];
                GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
                if(linkStatus[0] != GLES20.GL_TRUE){
                    Log.e("ES20_ERROR", "could not link  program: " + GLES20.glGetProgramInfoLog(program));
                    GLES20.glDeleteProgram(program);
                    program = 0;
                }
            }
            return program;
        }
    

### 2.4加载几何图形和绘制图元

    
    
    public class MyGLSurfaceView extends GLSurfaceView {
        public MyGLSurfaceView(Context context) {
            super(context);
            //使用OpenGL ES 2.0需要设置该值为2
            this.setEGLContextClientVersion(2);
    
            //设置渲染器
            SceneRender render = new SceneRender();
            this.setRenderer(render);
            this.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        }
    
        private class  SceneRender implements  GLSurfaceView.Renderer{
            int mPositionHandle;
    
            @Override
            public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
                String vertexSource = ShaderUtil.loadFromAssertsFile("VertexShader.glsl", getContext());
                String fragmentSource = ShaderUtil.loadFromAssertsFile("FragmentShader.glsl", getContext());
                int mShaderProgram = ShaderUtil.createProgram(vertexSource, fragmentSource);
    
                GLES20.glUseProgram(mShaderProgram);
                mPositionHandle = GLES20.glGetAttribLocation(mShaderProgram, "aPosition");
            }
    
            @Override
            public void onSurfaceChanged(GL10 gl10, int width, int height) {
                //设置视口
                GLES20.glViewport(0, 0, width, height);
            }
    
            @Override
            public void onDrawFrame(GL10 gl10) {
                //缓冲区将用glCleanColor指定的颜色清除
                GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
    
                //将顶点位置数据传送进渲染管线
                GLES20.glVertexAttribPointer(mPositionHandle, 2, GLES20.GL_FLOAT, false, 0, mVertexBuffer);
                //启用顶点位置数据
                GLES20.glEnableVertexAttribArray(mPositionHandle);
                //执行绘制
                GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, 3);
            }
        }
    }
    

文章写得比较匆忙，如果有错别字或者理解错的，欢迎和楼主交流，谢谢~

