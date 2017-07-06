---
layout: post
title: "使用Anko Layouts来开发Android(翻译)"
date: 2017-06-29 11:06:00 +0800
categories: android
author: baobaowang
tags: 布局 kotlin
---

* content
{:toc}

| 导语 Kotlin现在已成为Android的另一官方语言。JetBrains针对Android开发者也推出了一些有用的库和工具。Anko
Layouts是使用Kotlin针对Android布局写的一个DSL，很多方面体现了kotlin这个语言的一些特性，也确实能简化开发工作，使用时有眼前一亮的感觉。因此这里翻译了一下Anko这个库布局部分。

## 为什么需要Anko Layouts

<!--more-->
默认情况下，Android里的UI是用XML来写的。它有几个不方便的点：

  * 不是类型安全的
  * 不是空安全的
  * 它强迫你在每个布局中写几乎一样的代码
  * XML需要解析，这会浪费CPU和电池
  * 最重要的是不能代码复用

当然你可以使用动态代码来生成UI，但是一般来说很难，因为这些代码不仅难看而且难维护。这里有一个kotlin的版本(如果用Java的话代码更长):

    
    
    val act = this
    val layout = LinearLayout(act)
    layout.orientation = LinearLayout.VERTICAL
    val name = EditText(act)
    val button = Button(act)
    button.text = "Say Hello"
    button.setOnClickListener {
        Toast.makeText(act, "Hello, ${name.text}!", Toast.LENGTH_SHORT).show()
    }
    layout.addView(name)
    layout.addView(button)

DSL能够使同样的逻辑更加易读易写，并且没有额外的运行时开锁:

    
    
    verticalLayout {
        val name = editText()
        button("Say Hello") {
            onClick { toast("Hello, ${name.text}!") }
        }
    }

 注意，onClick()支持协程（接受可suspending lambda表达式)，所以可以直接写异步代码，而不需要通过显示的async(UI)调用。

## 兼容已经存在的代码

不一定要使用Anko来重写所有的UI。你可以保持现有的Java写好的类。当然，如果你仍然想要写Kotlin风格的 activity类，并且inflate
XML布局，可以使用View属性，这样可以更简单:

    
    
    // Same as findViewById() but simpler to use
    val name = find(R.id.name)
    name.hint = "Enter your name"
    name.onClick { /*do something*/ }

 如果使用Kotlin Android Extensions，还可以使代码更简洁。

注：Kotlin Android Extensions是个插件，使用后可以这样写代码：

    
    
    import kotlinx.android.synthetic.main.activity_main.*
    
    class MyActivity : Activity() {
        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
            setContentView(R.layout.activity_main)
            textView.setText("Hello, world!")
            // Instead of findViewById(R.id.textView) as TextView
        }
    }



## Anko是怎么工作的

这里没有魔法。Anko由一些类型安全的kotlin扩展函数和属性构成。 因为手写这些扩展比较乏味，所以他们是用android.jar文件自动生成的。

## Anko是可扩展的吗

答案是yes。

比如你想在DSL中使用MapView，只要在任意kotlin文件中写下面的代码：

    
    
    inline fun ViewManager.mapView() = mapView(theme = 0) {}
    
    inline fun ViewManager.mapView(init: MapView.() -> Unit): MapView {
        return ankoView({ MapView(it) }, theme = 0, init)
    }

 { MapView(it) } 是个你自定义view的工厂方法，它接收一个Context实例，现在你可以这样用它：

    
    
    frameLayout {
        val mapView = mapView().lparams(width = matchParent)
    }

 如果想要用户能够应用一种自定义的主题，可以这么写：

    
    
    inline fun ViewManager.mapView(theme: Int = 0) = mapView(theme) {}
    
    inline fun ViewManager.mapView(theme: Int = 0, init: MapView.() -> Unit): MapView {
        return ankoView({ MapView(it) }, theme, init)
    }

 在项目中使用Anko Layouts

需要包括下面的库依赖：

    
    
    dependencies {
        // Anko Layouts
        compile "org.jetbrains.anko:anko-sdk25:$anko_version" // sdk15, sdk19, sdk21, sdk23 are also available
        compile "org.jetbrains.anko:anko-appcompat-v7:$anko_version"
    
        // Coroutine listeners for Anko Layouts
        compile "org.jetbrains.anko:anko-sdk25-coroutines:$anko_version"
        compile "org.jetbrains.anko:anko-appcompat-v7-coroutines:$anko_version"
    }



# 理解Anko

## 基本知识

在Anko中，不须要继承任何特殊的类，直接用标准的Activity，Fragment,FragmentActivity或者别的你想用的。

使用的时候，先要在类中引入org.jetbrains.anko.*

然后在onCreate()中,DSL就可以用了:

    
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    
        verticalLayout {
            padding = dip(30)
            editText {
                hint = "Name"
                textSize = 24f
            }
            editText {
                hint = "Password"
                textSize = 24f
            }
            button("Login") {
                textSize = 26f
            }
        }
    }



Note:不需要显示的调用setContentView(R.layout.something),Anko会自动的给Activities调用这个方法。

hint 和 textSize都是JavaBean风格的getters和setters
扩展属性，padding是从Anko扩展的扩展属性。这些属性可以让你使用text = "Some text"来代替setText("Some
text")的写法。

verticalLayout(一个LinearLayout，但是已经有了LinearLayout.VERTICAL方向属性),editText和button都是扩展函数，用来构建新的
View实例并且将它们添加到parent。我们将以块的方式来引用这些方法。

在Android
framework中，块在几乎所有View中都存在，它们可以工作在Activities,Fragments甚至是Context。例如，如果你有一个AnkoContext实例，就可以写出下面的块:

    
    
    val name: EditText = with(ankoContext) {
        editText {
            hint = "Name"
        }
    }



## AnkoComponent

尽管你可以在不创建任何额外类的情况下使用DSL，但如果在分开的类中使用会更方便。如果使用提供的AnkoComponent界面，还可以免费获得DSL布局预览功能。

    
    
    class MyActivity : AppCompatActivity() {
        override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
            super.onCreate(savedInstanceState, persistentState)
            MyActivityUI().setContentView(this)
        }
    }
    
    class MyActivityUI : AnkoComponent<MyActivity> {
        override fun createView(ui: AnkoContext<MyActivity>) = with(ui) {
            verticalLayout {
                val name = editText()
                button("Say Hello") {
                    onClick { ctx.toast("Hello, ${name.text}!") }
                }
            }
        }
    }



## 辅助代码块

你应该早注意到了,在前面的节中，button()方法接受一个String参数。在频繁使用的View中，比如TextView,EditText,Button或者ImageView中，这种代码块经常存在。

如果不需要设置别的一些属性，可以直接忽略 {}，写button("ok")甚至只写button()都可以:

    
    
    verticalLayout {
        button("Ok")
        button(R.string.cancel)
    }



## 带主题的块

Anko也提供 可以设置主题的块:

    
    
    verticalLayout {
        themedButton("Ok", theme = R.style.myTheme)
    }



## Layouts和LayoutParams

在平常开发中我们可以使用LayoutParams来调整组件在父容器中的位置。使用XML来实现的时候是这样的：

    
    
    <ImageView 
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginLeft="5dip"
        android:layout_marginTop="10dip"
        android:src="@drawable/something" />



在Anko中，你可以在描述好了View之后使用lparams()来指定View的LayoutParams

    
    
    linearLayout {
        button("Login") {
            textSize = 26f
        }.lparams(width = wrapContent) {
            horizontalMargin = dip(5)
            topMargin = dip(10)
        }
    }



如果你指定了lparams, 但是忽略了width和(或者)height,这时候会有默认值wrapContent。

其他一些要关注的很方便的辅助属性:

  * horizontalMargin 设置左右margin
  * verticalMargin 设置上下margin
  * margin 同时设置所有margin

要注意，lparams()在不同的布局中有不同的用法。比如RelativeLayout:

    
    
    val ID_OK = 1
    
    relativeLayout {
        button("Ok") {
            id = ID_OK
        }.lparams { alignParentTop() }
    
        button("Cancel").lparams { below(ID_OK) }
    }



## 监听器

Anko的监听器辅助可以无缝支持协程。你可以在监听器中直接写异步代码：

    
    
    button("Login") {
        onClick {
            val user = myRetrofitService.getUser().await()
            showUser(user)
        }
    }



这段代码和下这个功能一样：

    
    
    button.setOnClickListener(object : OnClickListener {
        override fun onClick(v: View) {
            launch(UI) {
                val user = myRetrofitService.getUser().await()
                showUser(user)
            }
        }
    })



如果监听器中有许多的方法，Anko在这种情况下会很有帮助。考虑下下面的没使用Anko的代码:

    
    
    seekBar.setOnSeekBarChangeListener(object : OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
            // Something
        }
        override fun onStartTrackingTouch(seekBar: SeekBar?) {
            // Just an empty method
        }
        override fun onStopTrackingTouch(seekBar: SeekBar) {
            // Another empty method
        }
    })



如果使用Anko:

    
    
    seekBar {
        onSeekBarChangeListener {
            onProgressChanged { seekBar, progress, fromUser ->
                // Something
            }
        }
    }



如果你在同一个View中设置了两个不同的监听，一个实现了onProgressChanged，一个实现了onStartTrackingTouch，那这两个listener会被合并。如果两个listener实现了同一方法，最后的那个会生效。

## 自定义协程上下文

你可以传递一个自定义的协程上下文到监听器中:

    
    
    button("Login") {
        onClick(yourContext) {
            val user = myRetrofitService.getUser().await()
            showUser(user)
        }
    }



## 使用资源标识符

前面的所有章节中使用原始的java
strings，但是这很难说是最佳实践。典型的情况，你把所有string数据放在res/values/目录中，通过运行时调用来访问它们。比如，getString(R.string.login)。

幸运的是，在Anko中，你可以传递资源标识符到辅助块(button(R.string.login))和扩展属性中(button{textResource =
R.string.login })

这里注意属性名是不一样的:不是text,hint,image，而是要使用textResource,hintResource ,和imageResource

## 实例的速记符号

有时候我们需要从Activity代码中传递一个Context实例到一些Android
SDK方法中。通常情况下，可以直接用this,但如果你是在一个内部类中呢？可能你在Java中会用SomeActivity.this，或是在Kotlin中用this@SomeActivity。

使用Anko的话你可以直接使用ctx。它是一个扩展属性，可以在Activity,Service甚至是Fragment(实际使用getActivity()实现)中使用。还可以通过act扩展属性来得到一个Activity实例。

## Include tag

想在DSL中插入一个XML布局很简单，使用include()方法就行：

    
    
    include(R.layout.something) {
        backgroundColor = Color.RED
    }.lparams(width = matchParent) { margin = dip(12) }



你可以照样使用lparams()。如果提供了一个特殊的类型，你可以在{}块中使用这个类型：

    
    
    include(R.layout.textfield) {
        text = "Hello, world!"
    }



# Anko Support plugin

Anko Support plugin在IDEA和Android
Studio中都可以使用。使用这个插件可以直接在工具窗口中预览使用Anko写的AnkoComponent类。

## 使用这个插件

假设使用Anko写好了下面的类:

    
    
    class MyActivity : AppCompatActivity() {
        override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
            super.onCreate(savedInstanceState, persistentState)
            MyActivityUI().setContentView(this)
        }
    }
    
    class MyActivityUI : AnkoComponent<MyActivity> {
        override fun createView(ui: AnkoContext<MyActivity>) = ui.apply {
            verticalLayout {
                val name = editText()
                button("Say Hello") {
                    onClick { ctx.toast("Hello, ${name.text}!") }
                }
            }
        }.view
    }



将鼠标放到MyActivityUI声明处，点菜单栏中的View -> Tool Windows -> Anko Layout
Preview，点击刷新。

这需要构建工程，所以真正展示前需要花点时间。

## XML到DSl的转换器

这个插件也支持XML布局转换成Anko布局代码。打开XML文件选择 Code -> Convert to Anko Layouts
DSL。可以同时转换多个XML布局文件。

原链接：<https://github.com/Kotlin/anko/wiki/Anko-Layouts>

