---
layout: post
title: "OpenGL4.3新特性: 计算着色器 Compute Shader"
date: 2017-09-13 15:06:00 +0800
categories: ios
author: yoferzhang
tags: OpenGL shader dispatch 共享变量
---

* content
{:toc}

| 导语 介绍计算着色器的空间，调度，局部大小以及一些限制。

计算着色器是一个完全用于计算任意信息的
[着色器阶段(Stage)](https://www.khronos.org/opengl/wiki/Shader#Stages)
。虽然它可以渲染，但它通常用于与绘制三角形和像素无关的任务。
<!--more-->

# 概述

计算着色器与其他着色器阶段的操作不同。 所有其他着色器阶段都有一组明确的输入值，一些是内置的，一些是用户定义的。 着色器阶段执行的频率由该阶段的性质指定;
例如顶点着色器对每个输入顶点执行一次（尽管有些执行可以通过缓存进行跳过）。 片段着色器执行是由从光栅化过程生成的片段定义。

计算着色器的工作方式截然不同。 计算着色器操作的“空间”主要是抽象的; 每个计算着色器都可以决定这个空间是什么意思。
计算着色器执行的数量是由用于执行计算操作的函数定义。 最重要的是，计算着色器没有用户定义的输入，并且完全没有输出。
内置输入仅定义执行特定计算着色器调用的“空格”位置。

因此，如果计算着色器想要将某些值作为输入，则由着色器本身通过[纹理访问](https://www.khronos.org/opengl/wiki/Sampler_\(GLSL)
， [任意图像加载]( ，
[着色器存储块](https://www.khronos.org/opengl/wiki/Shader_Storage_Buffer_Object)
或其他形式的接口来获取该数据。 类似地，如果计算着色器要实际计算任何东西，它必须明确地写入图像或着色器存储块。

## 计算空间

计算着色器操作的空间是抽象的。 有一个工作组的概念; 这是用户可以执行的最小的计算操作量。 或者换句话说，用户可以执行一些工作组。

执行计算操作的工作组的数量由用户调用计算操作时定义。 这些组的空间是三维的，所以它有多个“X”，“Y”和“Z”组。
任何这些可以是1，所以可以执行二维或一维计算操作，不用执行三维。 这对于处理粒子系统的图像数据或线性阵列或其他任何东西都是有用的。

当系统实际计算工作组时，可以按任何顺序执行。 所以如果给出一个工作组（3, 1, 2），可以先执行组（0, 0, 0），然后跳到组（1, 0,
1），然后跳到（2, 0, 0）等等。因此，计算着色器不应该依赖于处理单个组的顺序。

不要认为单个工作组与单个计算着色器调用相同; 有一个原因叫做“组”。 在单个工作组中，可能会有许多计算着色器调用。
计算着色器本身定义了多少，而不是执行它的调用。 这被称为工作组的局部大小 。

每个计算着色器都具有三维局部大小（同样，尺寸可以为1，以允许2D或1D局部处理）。 这定义了将在每个工作组中进行的着色器的调用次数。

因此，如果计算着色器的局部大小为（128, 1, 1），然后使用数量为（16, 8, 64）的工作组执行，那么您将获得1,048,576个单独的着色器调用。
每个调用都将有一组唯一标识该特定调用的输入。

这种区别对于进行各种形式的图像压缩或解压是有用的; 局部大小将是图像数据块（例如8×8）的大小，而组计数将是图像大小除以块大小。
每个块都作为单个工作组进行处理。

工作组中的个人调用将并行执行。 区分工作组数和局部大小的主要目的是工作组中不同的计算着色器调用可以通过一组共享变量和特殊函数进行通信。
不同工作组中的调用（在同一计算着色器调度中）无法有效地进行通信。 不是没有潜在的死锁系统。

# 调度 Dispatch

计算着色器不是常规[渲染管道](https://www.khronos.org/opengl/wiki/Rendering_Pipeline_Overview)的一部分。
因此，当执行[绘图命令](https://www.khronos.org/opengl/wiki/Drawing_Command)时
，不涉及连接到当前程序或管道的计算着色器。

初始化计算操作有两个函数。
它们将使用当前活动的计算着色器（通过[glBindProgramPipeline](https://www.khronos.org/opengl/wiki/GLAPI/glBindProgramPipeline)或[glUseProgram](https://www.khronos.org/opengl/wiki/GLAPI/glUseProgram)
，遵循用于确定阶段的活动程序的通常规则）。 虽然它们不是“
[绘图命令](https://www.khronos.org/opengl/wiki/Drawing_Command)” ，但它们是“
[渲染命令](https://www.khronos.org/opengl/wiki/Rendering_Command)”
，因此可以[有条件地执行](https://www.khronos.org/opengl/wiki/Conditional_Rendering)它们。

    
    
     void glDispatchCompute(GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
    

`num_groups_ *`参数在三维中定义了工作组计数。 这些数字不能为零。
对可调度工作组的数量有[限制](https://www.khronos.org/opengl/wiki/Compute_Shader#Limitations)
。

对于来自存储在[缓冲区](https://www.khronos.org/opengl/wiki/Buffer_Object)对象信息的工作组计数，可以执行调度操作。这与[顶点数据的间接绘图](https://www.khronos.org/opengl/wiki/Indirect_Drawing)类似：

    
    
    void glDispatchComputeIndirect(GLintptr indirect);
    

`indirect`参数是当前绑定到 `GL_DISPATCH_INDIRECT_BUFFER` 目标的缓冲区的字节偏移量。请注意，
[对工作组计数的相同限制](https://www.khronos.org/opengl/wiki/Compute_Shader#Limitations)仍然适用;
然而，间接调度绕过了OpenGL的常见错误检查。 因此，尝试使用超出范围的工作组大小进行调度可能会导致崩溃甚至GPU硬锁，因此在生成此数据时要小心。

# 输入

计算着色器不能有任何用户定义的输入变量。

计算着色器具有以下内置输入变量。

    
    
    in uvec3 gl_NumWorkGroups;
    in uvec3 gl_WorkGroupID;
    in uvec3 gl_LocalInvocationID;
    in uvec3 gl_GlobalInvocationID;
    in uint  gl_LocalInvocationIndex;
    

`gl_NumWorkGroups` : 该变量包含传递给调度函数的工作组数。

`gl_WorkGroupID` : 这是此着色器调用的当前工作组。 每个XYZ组件将在半开放范围[0，gl_NumWorkGroups.XYZ]上。

`gl_LocalInvocationID` : 这是工作组中着色器的当前调用。 每个XYZ组件都将在半开放范围[0，
gl_WorkGroupSize.XYZ ]上。

`gl_GlobalInvocationID` : 该值在这个计算调度调用的所有调用中唯一标识计算着色器的此特定调用。 这是数学计算的一个简单的手段：

    
    
    gl_WorkGroupID * gl_WorkGroupSize + gl_LocalInvocationID;
    

`gl_LocalInvocationIndex` : 这是gl_LocalInvocationID的1D版本。 它在工作组内识别此调用的索引。
这个数学计算很简单：

    
    
       gl_LocalInvocationIndex =
               gl_LocalInvocationID 。  z * gl_WorkGroupSize 。  x * gl_WorkGroupSize 。  y +
               gl_LocalInvocationID 。  y * gl_WorkGroupSize 。  x + 
               gl_LocalInvocationID 。  x ;
    

## 局部大小

计算着色器的局部大小在着色器中定义，使用特殊的布局输入声明：

    
    
      layout（local_size_x = X， local_size_y = Y， local_size_z = Z） in;
    

默认情况下，局部大小为1，因此如果只需要一维或二维工作组空间，则只能指定X或 X和 Y组件。
它们必须是大于0的积分常数表达式。它们的值必须遵守以下[限制](https://www.khronos.org/opengl/wiki/Compute_Shader#Limitations)
; 如果没有，编译器或链接器错误发生。

局部大小作为编译时常量变量可用于着色器，因此您不需要自己定义它：

    
    
    const uvec3 gl_WorkGroupSize ;
    

# 共享变量

计算着色器中的全局变量可以使用共享存储限定符声明。 这些变量的值在工作组中的所有调用之间共享。 不能将任何不透明类型声明为共享，但聚合（数组和结构）都可以。

在工作组开始时，这些值未初始化。 此外，变量声明不能具有初始化器，因此这是非法的：

    
    
    shared uint foo = 0; //没有共享变量的初始化器。
    

如果要将共享变量初始化为特定值，则其中一个调用必须将变量显式设置为该值。 由于以下原因， 只有一个调用必须这样做。

## 共享内存一致性

> 主要文章：
[内存模型＃不相干的内存访问](https://www.khronos.org/opengl/wiki/Memory_Model#Incoherent_memory_access)

共享变量访问使用非相干内存访问的规则。 这意味着用户必须执行某些同步才能确保共享变量可见。

共享变量都被隐式声明为相关的 ，所以不需要（而且不能使用）限定符。 但是，仍然需要提供适当的内存障碍。

[通常的内存障碍集](https://www.khronos.org/opengl/wiki/Incoherent_Memory_Visibility)可用于计算着色器，但它们也可以访问`memoryBarrierShared()`;
这个障碍专门用于共享变量排序。`groupMemoryBarrier()`的作用就像`memoryBarrier()`，为各种变量排序内存写入，但它只为当前工作组排序
读/写。

虽然工作组中的所有调用都被称为“并行”执行，但这并不意味着可以假设所有这些调用都是以锁步执行的。
如果需要确保调用已经写入某个变量，以便可以读取它，则需要同步带有这个调用的执行，而不仅仅是发出内存障碍（您仍然需要内存屏障）。

要在工作组内的调用之间同步读取和写入操作，您必须使用 `barrier()` 函数。 这将强制在工作组中的所有调用之间进行显式同步。
在所有其他调用达到这一障碍之前，工作组内的执行将不会运行。 一旦执行完 `barrier()` ，以前在组内所有调用中写入的所有共享变量都将可见。

对于如何调用`barrier()` 有一些限制。 然而，计算着色器在使用此函数时并不像[Tessellation Control
Shaders](https://www.khronos.org/opengl/wiki/Tessellation_Control_Shader)那样受限。
`barrier()` 可以从流控制调用，但只能从均匀流控制中调用。
导致对`barrier()`进行评估的所有表达式必须是[动态均匀的](https://www.khronos.org/opengl/wiki/Dynamically_Uniform_Expression)
。

简而言之，如果执行相同的计算着色器，无论它们获取的数据有多么不同，每次执行都必须以完全相同的顺序命中完全相同的barrier（）调用集。
否则可能会发生严重错误。

## 原子操作

> 主要文章：
[着色器存储缓冲区对象＃原子操作](https://www.khronos.org/opengl/wiki/Shader_Storage_Buffer_Object#Atomic_operations)

可以对整数类型的共享变量（还有向量/数组/结构体）执行多个原子操作。
这些函数与[着色器存储缓冲区对象](https://www.khronos.org/opengl/wiki/Shader_Storage_Buffer_Object)原子共享。

所有原子函数返回原始值。 术语“ `nint` ”可以是int或uint 。

    
    
    nint atomicAdd(inout nint mem, nint data)
    

将data添加到 mem。

    
    
    nint atomicMin(inout nint mem, nint data)
    

mem的值不低于data。

    
    
    nint atomicMax(inout nint mem, nint data)
    

mem的值不大于data。

    
    
    n int atomicAnd（inout n int mem， n int data）
    

mem 和 data 按位进行与运算

    
    
    nint atomicOr(inout nint mem, nint data)
    

mem 和 data 按位进行或运算

    
    
    nint atomicXor(inout nint mem, nint data)
    

mem 和 data 按位进行异或运算

    
    
    nint atomicExchange(inout nint mem, nint data)
    

将mem的值设置为data。

    
    
    n int atomicCompSwap（inout n int mem， n int compare， n int data）
    

如果mem的当前值等于compare，则将mem设置为data。 否则保持不变。

# 限制

可以在单个调度调用中调度的工作组数由 `GL_MAX_COMPUTE_WORK_GROUP_COUNT` 定义。
必须使用[glGetIntegeri_v](https://www.khronos.org/opengl/wiki/GLAPI/glGet)进行查询，索引处于闭合范围[0,2]，表示最大工作组计数的X，Y和Z分量。
尝试使用超出此范围的值调用[glDispatchCompute](https://www.khronos.org/opengl/wiki/GLAPI/glDispatchCompute)是一个错误。
尝试调用[glDispatchComputeIndirect](https://www.khronos.org/opengl/wiki/GLAPI/glDispatchComputeIndirect)更糟糕;
它可能导致程序终止或其他坏结果。

请注意，所有三个轴的最小值必须为65535。 所以你可能有很多的工作空间。

局部大小也有限制; 有两套限制。 对于局部尺寸维度有一般限制，以与上述相同的方式查询`GL_MAX_COMPUTE_WORK_GROUP_SIZE` 。
请注意，这里的最小要求要小得多：X和Y为1024，Z为64。

还有一个限制：工作组中的调用总数。
也就是说，局部大小的X，Y和Z组件的乘积必须小于`GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS` 。 这里的最小值是1024。

计算着色器中所有共享变量的总存储大小也存在限制。 是`GL_MAX_COMPUTE_SHARED_MEMORY_SIZE` ，以字节为单位。
OpenGL所需的最小值为32KB。 OpenGL没有指定GL类型和共享变量存储之间的精确映射，尽管您可以使用std140布局规则和UBO /
SSBO大小作为一般准则。

> 后记：可惜opengl es 3.1才支持这个新特性，而iPhone还只支持到3.0。

