---
layout: post
title: "小白看React Native"
date: 2017-05-31 10:36:00
categories: ios
author: peterlmeng
tags: ReactNat...
---

* content
{:toc}



* * *

# 1.What is React Native
<!--more-->

![React
Native](/image/xiao_bai_kan_React_Native/f6b0e150c759b964a84b9fb557da5ee67b21e5a9119bee5c3beaf1753b4d2c78)  
众所周知，产品的需求总是想快速的迭代。但是由于应用分发市场的审核机制（主要是iOS审核），使一些快速迭代的需求只能选择web作为应用场景。虽然web应用已经是一个很成熟的业务，H5的助力也使web应用快速占据移动市场。但是web应用有web应用的瓶颈，在一些交互、性能方面还是无法媲美原生应用。这个时候，React
Native的出现，也许给我们带来了一点点新的思路。React Native从出生就带有着，跨平台，快速迭代，节省安装包等标签。在React
Native之前，也有很多技术意图跨平台，但是真正做到完全跨平台的技术，准确来说应该是没有的。也许React Native提出的‘Learn once,
write anywhere’可行。本次，就以一个小白的视角，来管中窥豹一下React Native。

* * *

# 2.工欲善其事，必现利其器

![名言](/image/xiao_bai_kan_React_Native/ed5471a3ecad068ac5e6cf89867813bb1a83303ba9f19c7c1fd18d335e23182e)

工欲善其事，必现利其器是自古以来不变的道理。在我们平时开发的时候，一款好的IDE会使我们的开发效率成倍提升。而好的IDE也会助力于好的语言的未来发展。就像oc或者swift，就伴随着xcode；c++或者c#，大家肯定想到visual
stutio。

![WebStrom](/image/xiao_bai_kan_React_Native/9c9daa5413ac4544b31309016ea042f287616e7d7baa689e183e825bf497a547)

虽然说，开发React
Native的IDE有很多。著名的有Nuclide，Sublime，WebStrom。但是，个人比较偏爱于WebStrom，这款号称最聪明的javascript
IDE。

* * *

# 3.JSX

    
    
    //使用JSX
    React.render(
        <div>
            <div>
                <div>demodiv>
            div>
        div>,
        document.getElementById('demo')
    );
    
    //不使用JSX
    React.render(
        React.createElement('div', null,
            React.createElement('div', null,
                React.createElement('div', null, 'demo')
            )
        ),
        document.getElementById('demo')
    );
    

JSX语法，像是在Javascript代码里直接写XML的语法，实质上这只是一个语法糖，每一个XML标签都会被JSX转换工具转换成纯Javascript代码，React
官方推荐使用JSX， 当然你想直接使用纯Javascript代码写也是可以的，只是使用JSX，组件的结构和组件之间的关系看上去更加清晰。

* * *

# 4.ES6

我们在看React Native的同时，首先得了解React
Native使用的语言。ES6作为javascript语言下一代标准，我们稍微了解一下几个关键的ES6的语法，会更好的理解React Native。

### let，const

let和var一样都可以声明变量。只是不同都是，let为javascript新增了作用域的概念，用他声明的变量，只在命令所在的代码块内有效。  
const也可以用了声明变量，但是声明的是常量。一旦声明，就不能改变其中的值。

### class，extends，super

    
    
    class Dog{
    
      constructor(){
          this.type = 'Dog';
      }
    
      eat(){
          console.log(this.type + " eat");
      }
    }
    
    let Dog = new Dog();
    Dog.eat();//Dog eat
    
    class BigDog extends Dog{
    
        constructor(){
            super();
            this.type = 'BigDog';
        }
    }
    
    let BigDog = new BigDog();
    BigDog.eat();//BigDog eat
    

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
如果用ES6我们而已直接这么写：

    
    
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

有了这两个关键字。我们就可以像iOS一样，把不同的js当成不同的模块，需要暴漏出来的export出来。需要引用的import进来。

* * *

# 5.布局

### 像素密度

React Native 提供的是像素无关的长度单位

### Flex in React Native

Flex布局类似于web中的Flex布局，只不过，在React Native中的Flex布局取了web中的Flex布局的子集。

### 绝对布局和相对布局

React Native中的绝对布局和相对布局，就有点像我们传统终端开发中的布局方式，区别是一个是相对路径，一个是绝对路径。

* * *

# 6.pros&state

![pros&state](/image/xiao_bai_kan_React_Native/1050b123fee00e1baad39869828066dc73fba74fe58d9331656c30b3a47ac570)

state  
state是React中组件的一个对象.React把用户界面当做是状态机,想象它有不同的状态然后渲染这些状态,可以轻松让用户界面与数据保持一致.  
React中,更新组件的state,会导致重新渲染用户界面(不要操作DOM).简单来说,就是用户界面会随着state变化而变化.

props  
组件中的props是一种父级向子级传递数据的方式.

* * *

# 7.Virtual Dom

![Virtual
Dom](/image/xiao_bai_kan_React_Native/df707a4b3c8aa3fe89f94a7a4a37189222e6cb20ea7ec4cd590c6aaca6c460d6)

DOM操作很慢是两个原因，一个是因为需要操作具体的native控件，这本身操作就不快，第二是我们处理dom的方式很慢，Virtual
Dom解决了我们对Dom的低劣操作，它的想法是，它想让我们不需要直接进行Dom操作，而是将希望展现的最终结果告诉React，React通过js构造一个新的数据结构即Virtual
dom进行render，这个Virtual dom 仅仅存在于数据结构中，并没有实际渲染出Dom。当你试图改变显示内容时，新生成的Virtual
Dom会与现在的Virtual
dom对比，通过diff算法找到区别，这些操作都是在快速的js中完成的，最后对实际Dom进行最小的Dom操作来完成效果，这就是Virtual
Dom的概念。总结的来说，就是通过引入新的数据结构，计算出最小移动Dom的方法，再去真实操作Dom，这样的成本是最低的。

* * *

# 8.DIFF算法

### 传统 diff 算法

计算一棵树形结构转换成另一棵树形结构的最少操作，这是一个复杂且值得研究的问题。传统 diff 算法通过循环递归对节点进行依次对比，效率低下，算法复杂度达到
O(n3)，其中 n 是树中节点的总数。

### React diff

传统 diff 算法的复杂度为 O(n3)，显然这是无法满足性能要求的。React 通过制定大胆的策略，将 O(n3) 复杂度的问题转换成 O(n)
复杂度的问题。  
1.UI 中 DOM 节点跨层级的移动操作特别少，可以忽略不计。  
2拥有相同类的两个组件将会生成相似的树形结构，拥有不同类的两个组件将会生成不同的树形结构。  
3.对于同一层级的一组子节点，它们可以通过唯一 id 进行区分。  
基于以上三个前提策略，React 分别对 tree diff、component diff 以及 element diff
进行算法优化，事实也证明这三个前提策略是合理且准确的，它保证了整体界面构建的性能。而这种算法的优化，也使算法复杂度，趋紧于O(n) 。大大提升了性能。

* * *

# 9.React Native生命周期

![lifecycle\(图片来源于互联网\)](/image/xiao_bai_kan_React_Native/cc46b4c2c7555bd2dc6e6c0f333c5a4e3a37d702b054cf11113b094baafd4966)

React Native的生命周期和我们终端开发中所接触的生命周期不太一样。React
Native的构成是组件化，所以，生命周期也就围绕着组建的创建，组建的更新，组建的消亡展开的。  
组件生命周期大致分为三个阶段：  
第一阶段：组建的创建，这是组件第一次绘制阶段，这里会进入组建的初始化函数。  
第二阶段：在是组件在运行和交互阶段，这个阶段组件可以处理用户交互，或者接收事件更新界面；  
第三阶段：是组件卸载消亡的阶段，组建会做一些销毁函数。  
(此模块图片来源于互联网)

* * *

# 10.React Native自定义控件

![Video插件](/image/xiao_bai_kan_React_Native/39d6a93a4900155153f912161ae3e93ac4718443b2b30e13fbeba34e252d8e84)

React Native对插件的支持非常解耦合。比如，我们想添加一个Video的插件，我们就可以 直接输入 npm install react-
native-video —save,然后再输入 react-native link,就自动向native模块中添加了各种依赖和导包的操作。

![project](/image/xiao_bai_kan_React_Native/639184787e4220b5f33d76fa9c05b221887fce3aae2041f6711ce75ccabaa87c)

以上工程目录就可以看到，video插件已经link到工程目录中了。

* * *

# 11.React Native Debug

### 红屏

![红屏](/image/xiao_bai_kan_React_Native/f29537f932b47bc3a631bc613448568e347bde53f2e40cd355d1f338c944342d)

红屏错误只有在debug模式中才会出现。在React
Native中一旦出现了红屏问题，就说明你的js代码在运行中出了错误，一般的错误红屏会直接指出出错的行数或者错误的类型以及堆栈信息。如果没有指出的话，那就得依靠调试工具或者log信息了。

### Chrome Debug

![Chrome
Debug](/image/xiao_bai_kan_React_Native/44a1f4a8608ed2c494ec38a5b04a8f17c31bf8f3cec4a04cd13bf7951d29f90d)

React Native的调试神器就是Chrome，安装Chrome插件。模拟器选择command + R 真机选择摇一摇，就可以唤出Debug
Menu。选择debug in chrome，就可以唤出chrome调试器。chrome调试器非常强大，像普通的单步断点调试，条件调试，堆栈信息等。

### Log

![Log](/image/xiao_bai_kan_React_Native/8a376c65d16d16c9613192249fac97dcbfbcaab788e544859048743f250eed55)

Log的信息无论是开发环境还是生产环境都是很重要的。chrome
debug可以直接在命令行中打印出log信息。生产环境，可以选择将log打印到文件中，进行上报分析。

* * *

# 12.Hot Reload

![Hot
Reload](/image/xiao_bai_kan_React_Native/1be054dcd5a4628ea4272fc4e1c521fea34acdd5cb4aef1a65306ad8488186e8)

所见即所得是React Native的一大亮点。无论是真机还是模拟器，只要填好对应的ip。就可以实时显示代码。模拟器选择command + R
真机选择摇一摇，就可以唤出Debug Menu。可以在Debug Menu中选择Hot Reload 的方式。

* * *

# 13.小结

本次带着大家，走马观花式的观看了React Native的简介，语言以及重要语法，样式，性能分析，重要的state&props
，生命周期等等。这些介绍虽然浅浅介绍，没有深入探究。但是这样的管中窥豹，希望大家对React Native有了一点点大概的印象，起到小白入门的作用。

