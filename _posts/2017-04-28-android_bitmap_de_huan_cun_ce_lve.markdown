---
layout: post
title: "android bitmap的缓存策略"
date: 2017-04-28 12:39:00
categories: android
author: kueeniechen
tags: android bitmap
---

* content
{:toc}


      不论是android还是ios设备，流量对于用户而言都是宝贵的。在没有wifi的场景下，如果加载批量的图片消耗用户过多流量，被其知晓，又要被念叨一波~ <img src="/image/android_bitmap_de_huan_cun_ce_lve/0e7533339eb300c1948b6eab511c562d45eedfa01d50ddd17e5ffad5c2b79709" border="0"/> 如何避免消耗过多的流量呢？当程序第一次从网络加载图片后，就将其缓存到移动设备上，这样再次使用这个图片时，就不用再次从网络上下载为用户节省了流量。

<!--more-->

       目前常用的一种缓存算法是<strong>lru</strong>（least recently used），它的核心思想是当缓存满了，会优先淘汰近期最少使用的缓存对象。采用lru算法的缓存有两种：lrucache和disklrucache，lrucache主要用于实现内存缓存，disklrucache则用于存储设备缓存。

## 1.lrucache

     lrucache是api level 12提供的一个泛型类，它内部采用一个linkedhashmap以强引用的方式存储外界的缓存对象，提供了get和put方法来完成缓存的获取和添加操作，当缓存满了，lrucache会remove掉较早使用的缓存对象，然后再添加新的对象。

     过去实现内存缓存的常用做法是使用softreference或者使用weakreference，但是并不推荐这种做法，从api level 9以后，gc强制回收掉soft、weak引用，从而导致这些缓存并没有任何效率的提升。

<strong>lrucache的实现原理：</strong>

      根据lru的算法思想，我们需要一种数据结构来快速定位哪个对象是最近访问的，哪个对象是最长时间未访问的，lrucache选择的是linkedhashmap这个数据结构，它是一个双向循环链表。来瞅一眼linkedhashmap的构造函数：

```
/** 初始化linkedhashmap

     * 第一个参数：initialcapacity，初始大小

     * 第二个参数：loadfactor，负载因子=0.75f

     * 第三个参数：accessorder=true，基于访问顺序；accessorder=false，基于插入顺序<br/>**/

   public linkedhashmap(int initialcapacity, float loadfactor, boolean accessorder) {

       super(initialcapacity, loadfactor);

       init();

       this.accessorder = accessorder;

    }
```

       所以在lrucache中应该选择accessorder = true，当我们调用put、get方法时，linkedhashmap内部会将这个item移动到链表的尾部，即在链表尾部是最近刚刚使用的item，链表头部就是最近最少使用的item。当缓存空间不足时，可以remove头部结点释放缓存空间。

<strong>下面举例lrucache的典型使用姿势</strong>：

```
int maxmemory = (int) (runtime.getruntime().maxmemory() / 1024);

int cachesize = maxmemory / 8;

mmemorycache = new lrucache<string bitmap="">(cachesize) {

    @override

    protected int sizeof(string key, bitmap bitmap) {

        return bitmap.getrowbytes() * bitmap.getheight() / 1024;

    }

};

 <br/>// 向 lrucache 中添加一个缓存对象

private void addbitmaptomemorycache(string key, bitmap bitmap) {

    if (getbitmapfrommemcache(key) == null) {

        mmemorycache.put(key, bitmap);

    }

}



//获取一个缓存对象

private bitmap getbitmapfrommemcache(string key) {

    return mmemorycache.get(key);

}</string>
```

     上述示例代码中，总容量的大小是当前进程的可用内存的八分之一（官方推荐是八分之一哈，你们可以自己视情况定），sizeof（）方法计算了bitmap的大小，sizeof方法默认返回的是你缓存item数目，源码中直接return 1（这里的源码比较简单，可以自己看看~）。

     如果你需要cache中某个值释放，可以重写entryremoved（）方法，这个方法会在元素被put或者remove的时候调用，源码默认是空实现。**重写entryremoved（）方法还可以实现二级内存缓存，进一步提高性能**。思路如下：重写entryremoved（），把删除掉的item，再次存入另一个linkedhashmap中。这个数据结构当做二级缓存，每次获得图片的时候，按照一级缓存 、二级缓存、sdcard、网络的顺序查找，找到就停止。

## 2.disklrucache

       当我们需要存大量图片的时候，我们指定的缓存空间可能很快就用完了，lrucache会频繁地进行trimtosize操作将最近最少使用的数据remove掉，但是hold不住过会又要用这个数据，又从网络download一遍，为此有了disklrucache，它可以保存这些已经下载过的图片。当然，从磁盘读取图片的时候要比内存慢得多，并且应该在非ui线程中载入磁盘图片。disklrucache顾名思义，实现存储设备缓存，即磁盘缓存，它通过将缓存对象写入文件系统从而实现缓存效果。

ps: 如果缓存的图片经常被使用，可以考虑使用contentprovider。

<strong>disklrucache的实现原理：</strong>

lrucache采用的是linkedhashmap这种数据结构来保存缓存中的对象，那么对于disklrucache呢？由于数据是缓存在本地文件中，相当于是持久保存的一个文件，即使app kill掉，这些文件还在滴。so ,,,,, 到底是啥？disklrucache也是采用linekedhashmap这种数据结构，但是不够，需要加持buff<img src="/image/android_bitmap_de_huan_cun_ce_lve/89c02b529f1d1a9c5a4ea73b0fba99d23e61a50a632ef0c3a3888dd1a22631a9" border="0"/>，日志文件。日志文件可以看做是一块“内存”，map中的value只保存文件的简要信息，对缓存文件的所有操作都会记录在日志文件中。

<strong>disklrucache的初始化：</strong>

下面是disklrucache的创建过程：

```
private static final long disk_cache_size = 1024 * 1024 * 50; //50mb 

    

    file diskcachedir = getdiskcachedir(mcontext, "bitmap");

    if (!diskcachedir.exists()) {

        diskcachedir.mkdirs();

    }



    if (getusablespace(diskcachedir) > disk_cache_size) {

        try {

            mdisklrucache = disklrucache.open(diskcachedir, 1, 1,

                    disk_cache_size);

        } catch (ioexception e) {

            e.printstacktrace();

        }

    }
```

       瞅了一眼，可以知道重点在open（）函数，其中第一个参数表示文件的存储路径，缓存路径可以是sd卡上的缓存目录，具体是指/sdcard/android/data/package_name/cache，package_name表示当前应用的包名，当应用被卸载后， 此目录会一并删除掉。如果你希望应用卸载后，这些缓存文件不被删除，可以指定sd卡上其他目录。第二个参数表示应用的版本号，一般设为1即可。第三个参数表示单个结点所对应数据的个数，一般设为1。第四个参数表示缓存的总大小，比如50mb，当缓存大小超过这个设定值后，disklrucache会清除一些缓存保证总大小不会超过设定值。

<strong>disklrucache的数据缓存与获取缓存：</strong>

数据缓存操作是借助disklrucache.editor类完成的，editor表示一个缓存对象的编辑对象。

```
new thread(new runnable() {  

    @override  

    public void run() {  

        try {  

            string imageurl = "http://d.url.cn/myapp/qq_desk/friendprofile_def_cover_001.png";  

            string key = hashkeyfordisk(imageurl);  //md5对url进行加密，这个主要是为了获得统一的16位字符

            disklrucache.editor editor = mdisklrucache.edit(key);  //拿到editor，往journal日志中写入dirty记录

            if (editor != null) {  

                outputstream outputstream = editor.newoutputstream(0);  

                if (downloadurltostream(imageurl, outputstream)) {  //downloadurltostream方法为下载图片的方法，并且将输出流放到outputstream

                    editor.commit();  //完成后记得commit()，成功后，再往journal日志中写入clean记录

                } else {  

                    editor.abort();  //失败后，要remove缓存文件，往journal文件中写入remove记录

                }  

            }  

            mdisklrucache.flush();  //将缓存操作同步到journal日志文件，不一定要在这里就调用

        } catch (ioexception e) {  

            e.printstacktrace();  

        }  

    }  

}).start();
```

     上述示例代码中，每次调用edit（）方法时，会返回一个新的editor对象，通过它可以得到一个文件输出流；调用commit（）方法将图片写入到文件系统中，如果失败，通过abort（）方法进行回退。

     而获取缓存和缓存的添加过程类似，将url转换为key，然后通过disklrucache的get方法得到一个snapshot对象，接着通过snapshot对象得到缓存的文件输入流。有了文件输入流，bitmap就get到了。

```
    bitmap bitmap = null;

    string key = hashkeyformurl(url);

    disklrucache.snapshot snapshot = mdisklrucache.get(key);

    if (snapshot != null) {

        fileinputstream fileinputstream = (fileinputstream)snapshot.getinputstream(disk_cache_index);

        filedescriptor filedescriptor = fileinputstream.getfd();

        bitmap = mimageresizer.decodesampledbitmapfromfiledescriptor(filedescriptor,

                reqwidth, reqheight);

        ......

    }
```

<strong>disklrucache优化思考：</strong>

       disklrucache是基于日志文件的，每次对缓存文件操作都需要进行日志记录，我们可以不用日志文件，在第一次构造disklrucache时，直接从程序访问缓存目录下的文件，并将每个缓存文件的访问时间作为初始值记录在map中的value值，每次访问或保存缓存都更新相应key对应的缓存文件的访问时间，避免了频繁地io操作。

## 3. 缓存策略对比与总结
- lrucache是android中已经封装好的类，disklrucache需要导入相应的包才可以使用。

- 可以在ui线程中直接使用lrucache；使用disklrucache时，由于缓存或者获取都需要对本地文件进行操作，因此要在子线程中实现。

- lrucache主要用于内存缓存，当app kill掉的时候，缓存也跟着没了；而disklrucache主要用于存储设备缓存，app kill掉的时候，缓存还在。

- lrucache的内部实现是linkedhashmap，对于元素的添加或获取用put、get方法即可。而disklrucache是通过文件流的形式进行缓存，所以对于元素的添加或获取通过输入输出流来实现。


文章写得比较匆忙，如果有错别字或者理解错的，欢迎和楼主交流~谢谢<img src="/image/android_bitmap_de_huan_cun_ce_lve/cee05c0a2949cd3a1299965311cf724251959141cf037d6498fcd68ba1c1a0d8"/>
