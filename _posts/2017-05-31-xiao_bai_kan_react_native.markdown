---
layout: post
title: "小白看react native"
date: 2017-05-31 10:36:00
categories: ios
author: peterlmeng
tags: reactnat...
---

* content
{:toc}



* * *

# 1.what is react native
<!--more-->

![react
native](/image/xiao_bai_kan_react_native/c5ab4b65b604f834bfb58e03bcd479a52816f2049ef4cacdf3c8b6687f0e5bca)  
众所周知，产品的需求总是想快速的迭代。但是由于应用分发市场的审核机制（主要是ios审核），使一些快速迭代的需求只能选择web作为应用场景。虽然web应用已经是一个很成熟的业务，h5的助力也使web应用快速占据移动市场。但是web应用有web应用的瓶颈，在一些交互、性能方面还是无法媲美原生应用。这个时候，react
native的出现，也许给我们带来了一点点新的思路。react native从出生就带有着，跨平台，快速迭代，节省安装包等标签。在react
native之前，也有很多技术意图跨平台，但是真正做到完全跨平台的技术，准确来说应该是没有的。也许react native提出的‘learn once,
write anywhere’可行。本次，就以一个小白的视角，来管中窥豹一下react native。

* * *

# 2.工欲善其事，必现利其器

![名言](/image/xiao_bai_kan_react_native/00a7371f7908c07b48f582125e83a6e7269d39d6b9a92dd043f16a8bc167f086)

工欲善其事，必现利其器是自古以来不变的道理。在我们平时开发的时候，一款好的ide会使我们的开发效率成倍提升。而好的ide也会助力于好的语言的未来发展。就像oc或者swift，就伴随着xcode；c++或者c#，大家肯定想到visual
stutio。

![webstrom](/image/xiao_bai_kan_react_native/35aef829c47ec50d558228f7daded2c3808c4ead9534535230259f36430f3f87)

虽然说，开发react
native的ide有很多。著名的有nuclide，sublime，webstrom。但是，个人比较偏爱于webstrom，这款号称最聪明的javascript
ide。

* * *

# 3.jsx

    
    
    //使用jsx
    react.render(
        <div>
            <div>
                <div>demodiv>
            div>
        div>,
        document.getelementbyid('demo')
    );
    
    //不使用jsx
    react.render(
        react.createelement('div', null,
            react.createelement('div', null,
                react.createelement('div', null, 'demo')
            )
        ),
        document.getelementbyid('demo')
    );
    

jsx语法，像是在javascript代码里直接写xml的语法，实质上这只是一个语法糖，每一个xml标签都会被jsx转换工具转换成纯javascript代码，react
官方推荐使用jsx， 当然你想直接使用纯javascript代码写也是可以的，只是使用jsx，组件的结构和组件之间的关系看上去更加清晰。

* * *

# 4.es6

我们在看react native的同时，首先得了解react
native使用的语言。es6作为javascript语言下一代标准，我们稍微了解一下几个关键的es6的语法，会更好的理解react native。

### let，const

let和var一样都可以声明变量。只是不同都是，let为javascript新增了作用域的概念，用他声明的变量，只在命令所在的代码块内有效。  
const也可以用了声明变量，但是声明的是常量。一旦声明，就不能改变其中的值。

### class，extends，super

    
    
    class dog{
    
      constructor(){
          this.type = 'dog';
      }
    
      eat(){
          console.log(this.type + " eat");
      }
    }
    
    let dog = new dog();
    dog.eat();//dog eat
    
    class bigdog extends dog{
    
        constructor(){
            super();
            this.type = 'bigdog';
        }
    }
    
    let bigdog = new bigdog();
    bigdog.eat();//bigdog eat
    

### arrow function

更简洁的函数书写

    
    
    function(x, y) {
          x++;
          y‐‐;
          return x + y;
    } //旧写法
    
    (x, y) => {x++; y‐‐; return x+y} //新写法
    

### default，rest

default很简单，意思就是默认值。大家可以看下面的例子，调用 say() 方法时忘了传参  
数，传统的做法就是加上这一句 type = type || ‘1’ 来指定默认值。  
如果用es6我们而已直接这么写：

    
    
    function say(type = '1'){
          console.log(type)
    }
    say()//''1''
    

最后一个rest语法也很简单，直接看例子：

    
    
    function say(...types){
        console.log(types)
    }
    say('1', '2, '3') //["1", "2", "3"]
    

### import export

有了这两个关键字。我们就可以像ios一样，把不同的js当成不同的模块，需要暴漏出来的export出来。需要引用的import进来。

* * *

# 5.布局

### 像素密度

react native 提供的是像素无关的长度单位

### flex in react native

flex布局类似于web中的flex布局，只不过，在react native中的flex布局取了web中的flex布局的子集。

### 绝对布局和相对布局

react native中的绝对布局和相对布局，就有点像我们传统终端开发中的布局方式，区别是一个是相对路径，一个是绝对路径。

* * *

# 6.pros&state

![pros&state](/image/xiao_bai_kan_react_native/b0c403955a0408a33627be7ec497bacc6eb502b840c6093e45dcd536a808654e)

state  
state是react中组件的一个对象.react把用户界面当做是状态机,想象它有不同的状态然后渲染这些状态,可以轻松让用户界面与数据保持一致.  
react中,更新组件的state,会导致重新渲染用户界面(不要操作dom).简单来说,就是用户界面会随着state变化而变化.

props  
组件中的props是一种父级向子级传递数据的方式.

* * *

# 7.virtual dom

![virtual
dom](/image/xiao_bai_kan_react_native/afd21d435144a7e11ddfddc252855bef8455c2deb3955d389488f2ecb1d1111a)

dom操作很慢是两个原因，一个是因为需要操作具体的native控件，这本身操作就不快，第二是我们处理dom的方式很慢，virtual
dom解决了我们对dom的低劣操作，它的想法是，它想让我们不需要直接进行dom操作，而是将希望展现的最终结果告诉react，react通过js构造一个新的数据结构即virtual
dom进行render，这个virtual dom 仅仅存在于数据结构中，并没有实际渲染出dom。当你试图改变显示内容时，新生成的virtual
dom会与现在的virtual
dom对比，通过diff算法找到区别，这些操作都是在快速的js中完成的，最后对实际dom进行最小的dom操作来完成效果，这就是virtual
dom的概念。总结的来说，就是通过引入新的数据结构，计算出最小移动dom的方法，再去真实操作dom，这样的成本是最低的。

* * *

# 8.diff算法

### 传统 diff 算法

计算一棵树形结构转换成另一棵树形结构的最少操作，这是一个复杂且值得研究的问题。传统 diff 算法通过循环递归对节点进行依次对比，效率低下，算法复杂度达到
o(n3)，其中 n 是树中节点的总数。

### react diff

传统 diff 算法的复杂度为 o(n3)，显然这是无法满足性能要求的。react 通过制定大胆的策略，将 o(n3) 复杂度的问题转换成 o(n)
复杂度的问题。  
1.ui 中 dom 节点跨层级的移动操作特别少，可以忽略不计。  
2拥有相同类的两个组件将会生成相似的树形结构，拥有不同类的两个组件将会生成不同的树形结构。  
3.对于同一层级的一组子节点，它们可以通过唯一 id 进行区分。  
基于以上三个前提策略，react 分别对 tree diff、component diff 以及 element diff
进行算法优化，事实也证明这三个前提策略是合理且准确的，它保证了整体界面构建的性能。而这种算法的优化，也使算法复杂度，趋紧于o(n) 。大大提升了性能。

* * *

# 9.react native生命周期

![lifecycle\(图片来源于互联网\)](/image/xiao_bai_kan_react_native/4138235d18ef4c57ae7dfb8b93951baf903a7fb267bb1ec83a82232fdb1198f1)

react native的生命周期和我们终端开发中所接触的生命周期不太一样。react
native的构成是组件化，所以，生命周期也就围绕着组建的创建，组建的更新，组建的消亡展开的。  
组件生命周期大致分为三个阶段：  
第一阶段：组建的创建，这是组件第一次绘制阶段，这里会进入组建的初始化函数。  
第二阶段：在是组件在运行和交互阶段，这个阶段组件可以处理用户交互，或者接收事件更新界面；  
第三阶段：是组件卸载消亡的阶段，组建会做一些销毁函数。  
(此模块图片来源于互联网)

* * *

# 10.react native自定义控件

![video插件](/image/xiao_bai_kan_react_native/c98e38eb6969462308cd5aa9f31b457e3cb4fc6514175c96e66ab5e05b603921)

react native对插件的支持非常解耦合。比如，我们想添加一个video的插件，我们就可以 直接输入 npm install react-
native-video —save,然后再输入 react-native link,就自动向native模块中添加了各种依赖和导包的操作。

![project](/image/xiao_bai_kan_react_native/95072ffced96e86e8777a83daf4304c55e2bab9a9311a3b3fcb3862bf2df4b0f)

以上工程目录就可以看到，video插件已经link到工程目录中了。

* * *

# 11.react native debug

### 红屏

![红屏](/image/xiao_bai_kan_react_native/fc1d53944a09a785ece9dcfbed1b7c0044c7a51a4c379fc3c7cf5f9f50d868fc)

红屏错误只有在debug模式中才会出现。在react
native中一旦出现了红屏问题，就说明你的js代码在运行中出了错误，一般的错误红屏会直接指出出错的行数或者错误的类型以及堆栈信息。如果没有指出的话，那就得依靠调试工具或者log信息了。

### chrome debug

![chrome
debug](/image/xiao_bai_kan_react_native/6d617637fdb1ee06bc90dafed95db76ca24c7ab8515644c8fa6ab9e12d6e047c)

react native的调试神器就是chrome，安装chrome插件。模拟器选择command + r 真机选择摇一摇，就可以唤出debug
menu。选择debug in chrome，就可以唤出chrome调试器。chrome调试器非常强大，像普通的单步断点调试，条件调试，堆栈信息等。

### log

![log](/image/xiao_bai_kan_react_native/931314149e7261e04a0fb16cc121a9f9135f9021e8714f69a739e91e6b2af1d2)

log的信息无论是开发环境还是生产环境都是很重要的。chrome
debug可以直接在命令行中打印出log信息。生产环境，可以选择将log打印到文件中，进行上报分析。

* * *

# 12.hot reload

![hot
reload](/image/xiao_bai_kan_react_native/836e83afb9e5a6913c21ca7d11301f47ac28fcac255a4863a49728c14f001fbb)

所见即所得是react native的一大亮点。无论是真机还是模拟器，只要填好对应的ip。就可以实时显示代码。模拟器选择command + r
真机选择摇一摇，就可以唤出debug menu。可以在debug menu中选择hot reload 的方式。

* * *

# 13.小结

本次带着大家，走马观花式的观看了react native的简介，语言以及重要语法，样式，性能分析，重要的state&props
，生命周期等等。这些介绍虽然浅浅介绍，没有深入探究。但是这样的管中窥豹，希望大家对react native有了一点点大概的印象，起到小白入门的作用。

