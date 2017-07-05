---
layout: post
title: "使用anko layouts来开发android(翻译)"
date: 2017-06-29 11:06:00
categories: android
author: baobaowang
tags: 布局 kotlin
---

* content
{:toc}

| 导语 kotlin现在已成为android的另一官方语言。jetbrains针对android开发者也推出了一些有用的库和工具。anko
layouts是使用kotlin针对android布局写的一个dsl，很多方面体现了kotlin这个语言的一些特性，也确实能简化开发工作，使用时有眼前一亮的感觉。因此这里翻译了一下anko这个库布局部分。

## 为什么需要anko layouts

<!--more-->
默认情况下，android里的ui是用xml来写的。它有几个不方便的点：

  * 不是类型安全的
  * 不是空安全的
  * 它强迫你在每个布局中写几乎一样的代码
  * xml需要解析，这会浪费cpu和电池
  * 最重要的是不能代码复用

当然你可以使用动态代码来生成ui，但是一般来说很难，因为这些代码不仅难看而且难维护。这里有一个kotlin的版本(如果用java的话代码更长):

    
    
    val act = this
    val layout = linearlayout(act)
    layout.orientation = linearlayout.vertical
    val name = edittext(act)
    val button = button(act)
    button.text = "say hello"
    button.setonclicklistener {
        toast.maketext(act, "hello, ${name.text}!", toast.length_short).show()
    }
    layout.addview(name)
    layout.addview(button)

dsl能够使同样的逻辑更加易读易写，并且没有额外的运行时开锁:

    
    
    verticallayout {
        val name = edittext()
        button("say hello") {
            onclick { toast("hello, ${name.text}!") }
        }
    }

 注意，onclick()支持协程（接受可suspending lambda表达式)，所以可以直接写异步代码，而不需要通过显示的async(ui)调用。

## 兼容已经存在的代码

不一定要使用anko来重写所有的ui。你可以保持现有的java写好的类。当然，如果你仍然想要写kotlin风格的 activity类，并且inflate
xml布局，可以使用view属性，这样可以更简单:

    
    
    // same as findviewbyid() but simpler to use
    val name = find(r.id.name)
    name.hint = "enter your name"
    name.onclick { /*do something*/ }

 如果使用kotlin android extensions，还可以使代码更简洁。

注：kotlin android extensions是个插件，使用后可以这样写代码：

    
    
    import kotlinx.android.synthetic.main.activity_main.*
    
    class myactivity : activity() {
        override fun oncreate(savedinstancestate: bundle?) {
            super.oncreate(savedinstancestate)
            setcontentview(r.layout.activity_main)
            textview.settext("hello, world!")
            // instead of findviewbyid(r.id.textview) as textview
        }
    }



## anko是怎么工作的

这里没有魔法。anko由一些类型安全的kotlin扩展函数和属性构成。 因为手写这些扩展比较乏味，所以他们是用android.jar文件自动生成的。

## anko是可扩展的吗

答案是yes。

比如你想在dsl中使用mapview，只要在任意kotlin文件中写下面的代码：

    
    
    inline fun viewmanager.mapview() = mapview(theme = 0) {}
    
    inline fun viewmanager.mapview(init: mapview.() -> unit): mapview {
        return ankoview({ mapview(it) }, theme = 0, init)
    }

 { mapview(it) } 是个你自定义view的工厂方法，它接收一个context实例，现在你可以这样用它：

    
    
    framelayout {
        val mapview = mapview().lparams(width = matchparent)
    }

 如果想要用户能够应用一种自定义的主题，可以这么写：

    
    
    inline fun viewmanager.mapview(theme: int = 0) = mapview(theme) {}
    
    inline fun viewmanager.mapview(theme: int = 0, init: mapview.() -> unit): mapview {
        return ankoview({ mapview(it) }, theme, init)
    }

 在项目中使用anko layouts

需要包括下面的库依赖：

    
    
    dependencies {
        // anko layouts
        compile "org.jetbrains.anko:anko-sdk25:$anko_version" // sdk15, sdk19, sdk21, sdk23 are also available
        compile "org.jetbrains.anko:anko-appcompat-v7:$anko_version"
    
        // coroutine listeners for anko layouts
        compile "org.jetbrains.anko:anko-sdk25-coroutines:$anko_version"
        compile "org.jetbrains.anko:anko-appcompat-v7-coroutines:$anko_version"
    }



# 理解anko

## 基本知识

在anko中，不须要继承任何特殊的类，直接用标准的activity，fragment,fragmentactivity或者别的你想用的。

使用的时候，先要在类中引入org.jetbrains.anko.*

然后在oncreate()中,dsl就可以用了:

    
    
    override fun oncreate(savedinstancestate: bundle?) {
        super.oncreate(savedinstancestate)
    
        verticallayout {
            padding = dip(30)
            edittext {
                hint = "name"
                textsize = 24f
            }
            edittext {
                hint = "password"
                textsize = 24f
            }
            button("login") {
                textsize = 26f
            }
        }
    }



note:不需要显示的调用setcontentview(r.layout.something),anko会自动的给activities调用这个方法。

hint 和 textsize都是javabean风格的getters和setters
扩展属性，padding是从anko扩展的扩展属性。这些属性可以让你使用text = "some text"来代替settext("some
text")的写法。

verticallayout(一个linearlayout，但是已经有了linearlayout.vertical方向属性),edittext和button都是扩展函数，用来构建新的
view实例并且将它们添加到parent。我们将以块的方式来引用这些方法。

在android
framework中，块在几乎所有view中都存在，它们可以工作在activities,fragments甚至是context。例如，如果你有一个ankocontext实例，就可以写出下面的块:

    
    
    val name: edittext = with(ankocontext) {
        edittext {
            hint = "name"
        }
    }



## ankocomponent

尽管你可以在不创建任何额外类的情况下使用dsl，但如果在分开的类中使用会更方便。如果使用提供的ankocomponent界面，还可以免费获得dsl布局预览功能。

    
    
    class myactivity : appcompatactivity() {
        override fun oncreate(savedinstancestate: bundle?, persistentstate: persistablebundle?) {
            super.oncreate(savedinstancestate, persistentstate)
            myactivityui().setcontentview(this)
        }
    }
    
    class myactivityui : ankocomponent<myactivity> {
        override fun createview(ui: ankocontext<myactivity>) = with(ui) {
            verticallayout {
                val name = edittext()
                button("say hello") {
                    onclick { ctx.toast("hello, ${name.text}!") }
                }
            }
        }
    }



## 辅助代码块

你应该早注意到了,在前面的节中，button()方法接受一个string参数。在频繁使用的view中，比如textview,edittext,button或者imageview中，这种代码块经常存在。

如果不需要设置别的一些属性，可以直接忽略 {}，写button("ok")甚至只写button()都可以:

    
    
    verticallayout {
        button("ok")
        button(r.string.cancel)
    }



## 带主题的块

anko也提供 可以设置主题的块:

    
    
    verticallayout {
        themedbutton("ok", theme = r.style.mytheme)
    }



## layouts和layoutparams

在平常开发中我们可以使用layoutparams来调整组件在父容器中的位置。使用xml来实现的时候是这样的：

    
    
    <imageview 
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginleft="5dip"
        android:layout_margintop="10dip"
        android:src="@drawable/something" />



在anko中，你可以在描述好了view之后使用lparams()来指定view的layoutparams

    
    
    linearlayout {
        button("login") {
            textsize = 26f
        }.lparams(width = wrapcontent) {
            horizontalmargin = dip(5)
            topmargin = dip(10)
        }
    }



如果你指定了lparams, 但是忽略了width和(或者)height,这时候会有默认值wrapcontent。

其他一些要关注的很方便的辅助属性:

  * horizontalmargin 设置左右margin
  * verticalmargin 设置上下margin
  * margin 同时设置所有margin

要注意，lparams()在不同的布局中有不同的用法。比如relativelayout:

    
    
    val id_ok = 1
    
    relativelayout {
        button("ok") {
            id = id_ok
        }.lparams { alignparenttop() }
    
        button("cancel").lparams { below(id_ok) }
    }



## 监听器

anko的监听器辅助可以无缝支持协程。你可以在监听器中直接写异步代码：

    
    
    button("login") {
        onclick {
            val user = myretrofitservice.getuser().await()
            showuser(user)
        }
    }



这段代码和下这个功能一样：

    
    
    button.setonclicklistener(object : onclicklistener {
        override fun onclick(v: view) {
            launch(ui) {
                val user = myretrofitservice.getuser().await()
                showuser(user)
            }
        }
    })



如果监听器中有许多的方法，anko在这种情况下会很有帮助。考虑下下面的没使用anko的代码:

    
    
    seekbar.setonseekbarchangelistener(object : onseekbarchangelistener {
        override fun onprogresschanged(seekbar: seekbar, progress: int, fromuser: boolean) {
            // something
        }
        override fun onstarttrackingtouch(seekbar: seekbar?) {
            // just an empty method
        }
        override fun onstoptrackingtouch(seekbar: seekbar) {
            // another empty method
        }
    })



如果使用anko:

    
    
    seekbar {
        onseekbarchangelistener {
            onprogresschanged { seekbar, progress, fromuser ->
                // something
            }
        }
    }



如果你在同一个view中设置了两个不同的监听，一个实现了onprogresschanged，一个实现了onstarttrackingtouch，那这两个listener会被合并。如果两个listener实现了同一方法，最后的那个会生效。

## 自定义协程上下文

你可以传递一个自定义的协程上下文到监听器中:

    
    
    button("login") {
        onclick(yourcontext) {
            val user = myretrofitservice.getuser().await()
            showuser(user)
        }
    }



## 使用资源标识符

前面的所有章节中使用原始的java
strings，但是这很难说是最佳实践。典型的情况，你把所有string数据放在res/values/目录中，通过运行时调用来访问它们。比如，getstring(r.string.login)。

幸运的是，在anko中，你可以传递资源标识符到辅助块(button(r.string.login))和扩展属性中(button{textresource =
r.string.login })

这里注意属性名是不一样的:不是text,hint,image，而是要使用textresource,hintresource ,和imageresource

## 实例的速记符号

有时候我们需要从activity代码中传递一个context实例到一些android
sdk方法中。通常情况下，可以直接用this,但如果你是在一个内部类中呢？可能你在java中会用someactivity.this，或是在kotlin中用this@someactivity。

使用anko的话你可以直接使用ctx。它是一个扩展属性，可以在activity,service甚至是fragment(实际使用getactivity()实现)中使用。还可以通过act扩展属性来得到一个activity实例。

## include tag

想在dsl中插入一个xml布局很简单，使用include()方法就行：

    
    
    include(r.layout.something) {
        backgroundcolor = color.red
    }.lparams(width = matchparent) { margin = dip(12) }



你可以照样使用lparams()。如果提供了一个特殊的类型，你可以在{}块中使用这个类型：

    
    
    include(r.layout.textfield) {
        text = "hello, world!"
    }



# anko support plugin

anko support plugin在idea和android
studio中都可以使用。使用这个插件可以直接在工具窗口中预览使用anko写的ankocomponent类。

## 使用这个插件

假设使用anko写好了下面的类:

    
    
    class myactivity : appcompatactivity() {
        override fun oncreate(savedinstancestate: bundle?, persistentstate: persistablebundle?) {
            super.oncreate(savedinstancestate, persistentstate)
            myactivityui().setcontentview(this)
        }
    }
    
    class myactivityui : ankocomponent<myactivity> {
        override fun createview(ui: ankocontext<myactivity>) = ui.apply {
            verticallayout {
                val name = edittext()
                button("say hello") {
                    onclick { ctx.toast("hello, ${name.text}!") }
                }
            }
        }.view
    }



将鼠标放到myactivityui声明处，点菜单栏中的view -> tool windows -> anko layout
preview，点击刷新。

这需要构建工程，所以真正展示前需要花点时间。

## xml到dsl的转换器

这个插件也支持xml布局转换成anko布局代码。打开xml文件选择 code -> convert to anko layouts
dsl。可以同时转换多个xml布局文件。

原链接：<https://github.com/kotlin/anko/wiki/anko-layouts>

