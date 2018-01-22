---
layout: post
title: "数据科学工具 Jupyter Notebook教程 in Python"
date: 2017-09-06 13:07:00 +0800
categories: deep learning
author: yoferzhang
tags: jupyter Python plotly 教程 绘图
---

* content
{:toc}

| 导语 主要内容为：如何安装，运行和使用IPython进行交互式 matplotlib 绘图，数据分析，还有发布代码。

# 简单介绍

Jupyter 是一个笔记本，这个笔记本可以编写和执行代码，分析数据，嵌入内容，以及共享可重复性的工作。Jupyter Notebook
<!--more-->
（以前成为iPython Notebook）可以在一个简单的笔记本中轻松分享代码，数据，图标以及说明。发布格式也比较灵活：PDF，
HTML，ipynb，dsahboards，slides，等等。代码单元是基于输入和输出格式。例如：

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/d9c578dbc7a6cc805ac8b49a0cf8261d98c7e0b5ed6ca582bfa6955eccaffe3d)

# 安装

有多种方式可以安装 Jupyter Notebook:

  * 使用 [`pip`](https://pypi.python.org/pypi/pip) 安装。在终端中输入 `$ pip install jupyter`
  * Windows用户可以使用 [setuptools](http://ipython.org/ipython-doc/2/install/install.html#windows) 安装。
  * [Anaconda](https://store.continuum.io/cshop/anaconda/) 和 [Enthought]( 可以下载 Jupyter Notebook的桌面版。
  * [nteract](https://nteract.io/) 可以通过一个桌面应用在 notebook 环境中工作。
  * [Microsoft Azure](https://notebooks.azure.com/) 提供对 Jupyter Notebook 的托管访问。
  * [Domino Data Lab](http://support.dominodatalab.com/hc/en-us/articles/204856585-Jupyter-Notebooks) 提供基于web的notebook。
  * [tmpnb](https://github.com/jupyter/tmpnb) 为个人用户启动一个临时在线的notebook。

> 主观观点：Windows 下常用[Anaconda](https://store.continuum.io/cshop/anaconda/)
，但并不是说 Mac 和 Linux用户就不需要了，个人觉得 Anaconda 都应该尝试一下，启动和管理库都很方便。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/580b3b9163094c3a2846488a3a8caf834d2a77ff0304d643bae0710fd2a09b1d)

# 入门指南

安装 notebook 之后，在终端中输入 `$ jupyter notebook` 来启动。此时将在
[localhost](https://en.wikipedia.org/wiki/Localhost) 打开浏览器到notebook的URL，默认是
<http://127.0.0.1:8888>。Windows 用户打开Command Prompt. 可以在一个dashboard
中看到所有的notebook，打开很方便。当编码和发布的时候，Notebook具有相同的优势。有所有的选项，移动代码，运行cell，更改
kernel，并且运行 NB的时候使用 [Markdown](https://github.com/adam-p/markdown-here/wiki
/Markdown-Cheatsheet)

# 有用的命令

  * **Tab Completion**: Jupyter 支持tab 自动补全！可以键入 `object_name.` 来查看对象的属性。有关cell magics，运行 notebook，探索对象的提示，可以查看 [Jupyter docs](https://ipython.org/ipython-doc/dev/interactive/tutorial.html#introducing-ipython)。
  * **Help**: 提供介绍和功能概述。
  * **Quick Reference**: 运行后打开快速参考：
  * **Keyboard Shortcuts**: Shift-Enter将运行一个cell, Ctrl-Enter将在空间内运行cell, Alt-Enter 将运行cell，并在下面插入一个cell. 更多的快捷键请看 [here](

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/ad75675cafa52c70404b5b49467edeb1b0e6ad594557b299a2b97d768f4e49d9)

# 语言

本教程的主要内容是讨论在 Jupyter notebooks 中执行python 代码。也可以使用 Jupyter notebooks 来执行 R
语言的代码。

# Package 管理

在Jupyter安装 package时，需要在shell中安装，或者运行感叹号前缀，例如：

    
    
    !pip install packagename
    

如果已经编辑了代码，可能需要 [reload submodules](http://stackoverflow.com/questions/5364050
/reloading-submodules-in-ipython)。IPython 自带重载机制。可以在执行新行之前重新加载所有更改的模块。

    
    
    %load_ext autoreload
    %autoreload 2
    

本教程使用到的一些package：

  * [Pandas](https://plot.ly/pandas/): 通过网址导入数据，创建数据框架，可以很简单的处理数据，进行分析和绘图。请参阅使用 Panda的例子：<https://plot.ly/pandas/>。
  * [NumPy](https://plot.ly/numpy/): 用于科学计算的package，用于代数，随机数生成，与数据库集成和管理数据的工具。请参阅使用 Numpy 的例子：<https://plot.ly/numpy/>。
  * [SciPy](http://www.scipy.org/): 一个基于Python的数学、科学和工程库。
  * [Plotly](https://plot.ly/python/getting-started): 用于制作交互式，达到出版品质图表的图形库。更多统计，科学，3D图表等，请参阅：[https://plot.ly/python](https://plot.ly/python.)

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/da7484eaea54b5adcd0f35a226db50637716a523939384ae5ee0511fa8e43d4e)

> 如果使用的是Anaconda
在Environments中可以发现，前三个库都已经默认帮你下载安装好了。然后把过滤条件改为All，搜Plotly，安装即可。非常方便

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/f90e24563bee6112d6e59df62fc1b15e64fa2976b31cb5148fa667dfa21fcf54)

# Import 数据

可以使用 pandas 的 `read_csv()` 函数来导入数据。下面的示例中，导入了一个 [hosted on
github](https://github.com/plotly/datasets/)
的csv，并使用Plotly将数据展示在一个table中。([table using
Plotly](https://plot.ly/python/table/))

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/13be7031cf59d82d086ad0d147f4b6f6af059eafd2c2ec738da760e74ece9578)

> `plotly.plotly.iplot()` 函数是在线的，需要先设置账号和key，具体请参阅：<https://plot.ly/python
/getting-started/>

使用`dataframe.column_title` 来索引 dataframe：

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/4d71fbaebd78aadd894fababb6263c27d50c6c03b2976a2aa2fe00ba9baf08af)

pandas大多数的函数也适用于整个 dataframe。例如，调用 `std()` 计算每列的标准差

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/6c6983dc970f4dc29602475998c660495552c26bebc22c43d8ea1791674b66df)

# 内联绘图

可以使用 [Plotly’s python API](https://plot.ly/python) ，通过调用
`plotly.plotly.iplot()` 或者离线工作的时候使用 `plotly.offline.iplot()`
。在notebook中绘制，可以将数据分析和绘图保存在一个位置。下面是一个可以交互的绘图。转到 [Plotly getting
started](https://plot.ly/python/) 页面，了解如何设置凭据。通过调用 `iplot` 自动生成内嵌 iframe
的交互式版本：

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/2fe40128a2ac546f0a92838b23e7f1197d54e1ecec5c4f28a252aba687331c2c)

绘制多个轨道，并使用 Plotly语法，自定义颜色和标题，来对图标进行样式化。还可以进行控制，将 `sharing` 设置为 `public` ,
`private`, 或者 `secret`。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/0ee1b902e70e765e362d4c72c5b98f1704fbbfaee8d62564be0b0abcdd70e2d5)

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/9d53498b0b345f0985896306870051ebb0ac91bf57b396a005c73cf3a52ae7f7)

现在notebook中显示了交互式图标。将鼠标悬停在图标上来查看每一栏的值，单击并拖动来放大到特定部分，或单击图例以隐藏/显示轨道。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/33dc38741ed9fd3f4ef186e27a1ddffb411175c66a1d3385d26049e7948ec0dc)

# 绘制交互式地图

Plotly 现在集成了 [Mapbox](https://www.mapbox.com/)。下面的例子，将绘制世界分级统计图。

    
    
    import plotly.plotly as py
    import pandas as pd
    
    df = pd.read_csv('https://raw.githubusercontent.com/plotly/datasets/master/2014_world_gdp_with_codes.csv')
    
    data = [ dict(
            type = 'choropleth',
            locations = df['CODE'],
            z = df['GDP (BILLIONS)'],
            text = df['COUNTRY'],
            colorscale = [[0,"rgb(5, 10, 172)"],[0.35,"rgb(40, 60, 190)"],[0.5,"rgb(70, 100, 245)"],\
                [0.6,"rgb(90, 120, 245)"],[0.7,"rgb(106, 137, 247)"],[1,"rgb(220, 220, 220)"]],
            autocolorscale = False,
            reversescale = True,
            marker = dict(
                line = dict (
                    color = 'rgb(180,180,180)',
                    width = 0.5
                ) ),
            colorbar = dict(
                autotick = False,
                tickprefix = '$',
                title = 'GDP
    Billions US$'),
          ) ]
    
    layout = dict(
        title = '2014 Global GDP
    Source:\
                [\
                CIA World Factbook](https://www.cia.gov/library/publications/the-world-factbook/fields/2195.html)',
        geo = dict(
            showframe = False,
            showcoastlines = False,
            projection = dict(
                type = 'Mercator'
            )
        )
    )
    
    fig = dict( data=data, layout=layout )
    py.iplot( fig, validate=False, filename='d3-world-map' )
    

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/055328e55e8a35b03071afe5fc94258a97f64c0de54b8ff29aeaba04e5b7498e)

# 3D绘图

使用Numpy和Plotly，可以在Notebook中绘制交互式3D图。

    
    
    import plotly.plotly as py
    from plotly.graph_objs import *
    
    import numpy as np
    
    s = np.linspace(0, 2 * np.pi, 240)
    t = np.linspace(0, np.pi, 240)
    tGrid, sGrid = np.meshgrid(s, t)
    
    r = 2 + np.sin(7 * sGrid + 5 * tGrid) # r = 2 + sin(7s + 5t)
    x = r * np.cos(sGrid) * np.sin(tGrid) # x = r * con(s) * sin(t)
    y = r * np.sin(sGrid) * np.sin(tGrid) # y = r * sin(s) * sin(t)
    z = r * np.cos(tGrid)                 # z = r * cos(t)
    
    surface = Surface(x = x, y = y, z = z)
    data = Data([surface])
    
    layout = Layout(
        title = 'Parametric Plot',
        scene = Scene(
            xaxis = XAxis(
                gridcolor = 'rgb(255, 255, 255)',
                zerolinecolor = 'rgb(255, 255, 255)',
                showbackground = True,
                backgroundcolor = 'rgb(230, 230, 230)'
            ),
            yaxis = YAxis(
                gridcolor = 'rgb(255, 255, 255)',
                zerolinecolor = 'rgb(255, 255, 255)',
                showbackground = True,
                backgroundcolor = 'rgb(230, 230, 230)'
            ),
            zaxis = ZAxis(
                gridcolor = 'rgb(255, 255, 255)',
                zerolinecolor = 'rgb(255, 255, 255)',
                showbackground = True,
                backgroundcolor = 'rgb(230, 230, 230)'
            )
        )
    )
    
    fig = Figure(data = data, layout = layout)
    py.iplot(fig, filename = 'parametric_plot')
    

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/a6df1a4a0f63510b3d7eaf6470cb85b7cfa32de9cadb079365204a5d35619255)

# 绘制动画

查看Plotly的 [animation documentation](https://plot.ly/python/#animations)
，来了解如果在Jupyter notebook中创建内联动画，比如：

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/56e0d6d91b37eaeeeb69b8918fb78c5c9e5f2ab39bc32bfb9cf2610dcea2e217)

# Plot 控件和IPython 小部件

给内联图表添加 silder, button, 和 dropdown：

    
    
    import plotly.plotly as py
    import numpy as np
    
    data = [dict(
            visible = False,
            line = dict(color = '00CED1', width = 6),
            name = 'v = ' + str(step),
            x = np.arange(0, 10, 0.01),
            y = np.sin(step * np.arange(0, 10, 0.01))) for step in np.arange(0, 5, 0.1)]
    data[10]['visible'] = True
    
    steps = []
    for i in range(len(data)):
        step = dict(
            method = 'restyle',
            args = ['visible', [False] * len(data)],
        )
        step['args'][1][i] = True # Toggle i'th trace to "visible"
        steps.append(step)
    
    sliders = [dict(
        active = 10, 
        currentvalue = {"prefix": "Frequency: "},
        pad = {"t": 50},
        steps = steps
    )]
    
    layout = dict(sliders = sliders)
    fig = dict(data = data, layout = layout)
    
    py.iplot(fig, filename = 'Sina Wave Slider')
    

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/bc7fa8f0dd182fa1b698d7e6b7c301c33ea05356cb38b108ed71621bf359118d)

此外，[IPython widgets](http://moderndata.plot.ly/widgets-in-ipython-notebook-
and-plotly/) 可以给notebook添加 silder， widget， 搜索框等。更多信息请参阅 [widget
docs](https://ipython.org/ipython-
doc/3/api/generated/IPython.html.widgets.interaction.html)
。为了让其他人能够访问你的工作，他们需要IPython，或者你可以使用基于云的NB选项。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/fb169c1f1ad702ec6ea27e969ae59c6566b5eb44034e2ea4da5afe6241c7921b)

# 运行R代码

IRkernel是Jupyter的R内核，允许在Jupyter笔记本中编写和执行R代码。 检查
[IRkernel文档](https://irkernel.github.io/installation/) 以获取一些简单的安装说明。
安装IRkernel后，通过调用 `$ jupyter notebook` 打开Jupyter Notebook，并使用“新建”下拉列表选择一个R笔记本。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/3e376ca51414331e9a00de4c6fab7566c4b9a7d23ab07c7209e0fefa0531bf09)

完整实例地址：<https://plot.ly/~chelsea_lyn/14069>

# 附加嵌入功能

IPython.display可以嵌入其他功能，如视频。 例如，从YouTube：

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/165e195bbb72381ee76a8b32d713532e035103100abaaf5407206d9b19f2fb2b)

# LaTeX

可以通过将数学内容用$$包住，来将LaTeX嵌入notebook中，然后将该单元格作为Markdown cell 运行。 例如，下面的 cell 是 `$
c = \ sqrt {a ^ 2 + b ^ 2}
$`，(左右应该是双dollar符号，但这里打双dollar，km就出错无法保存文章了==)但Notebook会呈现表达式。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/b133277ee6b025f084d17ba6530c8dbee5828128218e5f06c500b60a20ae52a3)

或者可以在python的输出中展示，请参阅：[here](http://stackoverflow.com/questions/13208286/how-
to-write-latex-in-ipython-notebook)

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/1ab247a3239eb110feac744d29a14b508b480fd248be81d5a84b75ad1efa0aec)

# 导出和发布 notebook

可以将Notebook导出为HTML，PDF，.py，.ipynb，Markdown和reST文件。 也可以将NB
[转换成幻灯片](http://ipython.org/ipython-doc/2/notebook/nbconvert.html)。
可以在Plotly上发布Jupyter notebook。 只需访问
[plot.ly](https://plot.ly/organize/home?create=notebook)并选择右上角的 `+ Create` 按钮。
选择 notebook 并上传Jupyter notebook（.ipynb）文件！ 上传的笔记本将存储在你的 [Plotly organize
folder ](https://plot.ly/organize) 中，并托管在一个唯一的链接，能快速和简单分享。下面是一些例子：

  * <https://plot.ly/~chelsea_lyn/14066>
  * <https://plot.ly/~notebook_demo/35>
  * <https://plot.ly/~notebook_demo/85>
  * <https://plot.ly/~notebook_demo/128>

# Publishing Dashboards

发布交互式图形的用户也可以使用 [Plotly’s dashboarding tool](
工具来绘制和拖放界面。 这些 dashboards 可以发布，嵌入和共享。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/f02fb26150e29cb3ed096d400966a1865d8e932ade120b81fb584a0b3efca445)

# Publishing Dash Apps

对于希望传播和生产Python应用程序的用户，[dash](https://github.com/plotly/dash)
是Flask，Socketio，Jinja，Plotly和 boiler plate CSS and
JS的集合，用于通过Python数据分析后端轻松创建数据可视化Web应用程序。

![](/image/shu_ju_ke_xue_gong_ju_jupyter_notebook_jiao_cheng_in_python/4958e8ac6d2be55c57144cdc9be3baa2e68843866085594f996647ac5b710856)

# Jupyter Gallery

对于更多Jupyter教程，请查看 [Plotly’s python
documentation](https://plot.ly/python/)：所有文档都是用jupyter notebook
编写的，可以自行下载并运行，或者查看 [user submitted examples!](https://plot.ly/ipython-
notebooks/)

