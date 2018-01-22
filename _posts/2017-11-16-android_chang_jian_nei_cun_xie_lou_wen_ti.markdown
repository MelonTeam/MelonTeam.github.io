---
layout: post
title: "Android常见内存泄漏问题"
date: 2017-11-16 16:43:00 +0800
categories: android
author: vianhuang
tags: android内存泄漏
---

* content
{:toc}



  * 1\. handler导致的内存泄漏
  * 2\. 线程导致的内存泄漏
  * 3\. 单例导致内存泄漏
<!--more-->
  * 4.非静态内部类创建静态实例造成的内存泄漏
  * 5.InputMethodManager造成的内存泄漏

## 1\. handler导致的内存泄漏

  * **问题代码**
    
        public class SampleActivity extends Activity {
      private final Handler mLeakyHandler = new Handler() {
          [@Override]( "@Override" )
          public void handleMessage(Message msg) {
          }
      }
    
      [@Override]( "@Override" )
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          mLeakyHandler.postDelayed(new Runnable() {
              [@Override]( "@Override" )
              public void run() {
              }
          }, 1000 * 60 * 10);
          finish();
      }
    }
    

  * **问题分析**  
当activity
finish时，里面的延时消息在得到处理前，会一直保存在主线程的消息队列里持续10分钟。这条消息持有对handler的引用，而handler又持有对其外部类的引用。这条引用关系会一直保持直到消息得到处理，从而，这阻止了Activity被垃圾回收器回收。

  * **解决方案**  
_非静态内部类会持有外部类引用，而静态内部类不会持有对外部类的引用_。  
所以，我们可以把handler类放在单独的类文件中，或者使用静态内部类便可以避免泄漏。  
另外，如果想要在handler内部去调用所在的外部类Activity，那么可以在handler内部使用弱引用的方式指向所在Activity，这样不会导致内存泄漏。

  * **正确代码**
    
        public class SampleActivity extends Activity {
      private final MyHandler mHandler = new MyHandler(this);
    
      [@Override]( "@Override" )
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          mHandler.postDelayed(sRunnable, 1000 * 60 * 10);
          finish();
      }
    
      private static final Runnable sRunnable = new Runnable() {
          [@Override]( "@Override" )
          public void run() { 
          }
      };
    
      private static class MyHandler extends Handler {
          private final WeakReference mActivity;
    
          public MyHandler(SampleActivity activity) {
              mActivity = new WeakReference(activity);
          }
    
          [@Override]( "@Override" )
          public void handleMessage(Message msg) {
          }
      }
    }
    

  * **优化方案**  
这样避免了Activity泄漏，不过Looper线程的消息队列中还是可能会有待处理的消息，为避免浪费资源，我们在Activity的onDestroy时应该移除消息队列中的消息，handler.removeCallbacksAndMessages(null);

* * *

## 2\. 线程导致的内存泄漏

  * **问题代码**
    
        public class SampleActivity extends Activity {
    
      [@Override]( "@Override" )
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          mAsyncTask.execute();
          mThread.start();
          finish();
      }
    
      private final AsyncTask mAsyncTask = new AsyncTask() {
          [@Override]( "@Override" )
          protected Void doInBackground(Void... params) {
              SystemClock.sleep(10000);
              return null;
          }
      };
    
      private final Thread mThread = new Thread(new Runnable() {
          [@Override]( "@Override" )
          public void run() {
              SystemClock.sleep(10000);
          }
      });
    }
    

  * **问题分析**  
上面的AsyncTask和Runnable都是一个匿名内部类，所以它们对当前SampleActivity都持有引用。如果SampleActivity在销毁之前，异步任务还未完成，
那么将导致SampleActivity的内存资源无法回收，造成内存泄漏。

  * **解决方案**  
把AsyncTask和Runnable类放在单独的类文件中，或者使用静态内部类都可以避免泄漏。

  * **正确代码**
    
        public class SampleActivity extends Activity {
    
      [@Override]( "@Override" )
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          new Thread(new MyRunnable()).start();
          new MyAsyncTask(this).execute();
          finish();
      }
    
      static class MyAsyncTask extends AsyncTask<Void, Void, Void> {
          private WeakReference weakReference;
    
          public MyAsyncTask(Context context) {
              weakReference = new WeakReference<>(context);
          }
    
          [@Override]( "@Override" )
          protected Void doInBackground(Void... params) {
              SystemClock.sleep(10000);
              return null;
          }
      }
    
      static class MyRunnable implements Runnable{
          [@Override]( "@Override" )
          public void run() {
              SystemClock.sleep(10000);
          }
      }
    }
    

  * **优化方案**  
这样避免了Activity泄漏，当然在Activity
onDestory时最好能取消相应的任务，避免任务在后台执行浪费资源。AsyncTask的cancel()。

* * *

## 3\. 单例导致内存泄漏

  * **问题代码**
    
        public class AppManager {
      private static AppManager instance;
      private Context context;
      private AppManager(Context context) {
          this.context = context;
      }
    
      public static AppManager getInstance(Context context) {
          if (instance != null) {
              instance = new AppManager(context);
          }
          return instance;
      }
    }
    

  * **问题分析**  
_静态对象会在进程启动时被创建，进程结束时才销毁，所以静态实例的生命周期与所在进程一样长。_  
因为单例的静态特性使得单例的生命周期和所在进程的生命周期一样长，如果一个对象已经不需要使用了，而单例对象还持有该对象的引用，那么这个对象将不能被正常回收，这就导致了内存泄漏。  
如果传入的是Activity的Context，即使这个Activity退出也无法被回收，因为单例对象会长长久久地持有该Activity的引用。

  * **解决方案**  
找一个生命周期与单例生命周期一样长的Context传入，也就是ApplicationContext。

  * **正确代码**
    
        public class AppManager {
      private static AppManager instance;
      private Context context;
      private AppManager(Context context) {
          this.context = context.getApplicationContext();
      }
    
      public static AppManager getInstance(Context context) {
          if (instance != null) {
              instance = new AppManager(context);
          }
          return instance;
      }
    }
    

* * *

## 4.非静态内部类创建静态实例造成的内存泄漏

  * **问题代码**
    
        public class SampleActivity extends Activity {
      private static AnonymousInnerClass anonymousInnerClass = null;
    
      [@Override]( "@Override" )
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          if(anonymousInnerClass == null){
              anonymousInnerClass = new AnonymousInnerClass();
          }
      }
    
      class AnonymousInnerClass{
      }
    }
    

  * **问题分析**  
由于非静态内部类会持有外部类的引用，而又使用了该非静态内部类创建了一个静态的实例，也就意味着这个实例将持有SampleActivity的引用并且长长久久地存在与内存中，导致Activity的内存资源不能正常回收。

  * **解决方案**  
把AnonymousInnerClass类放在单独的类文件中，或者使用静态内部类都可以避免泄漏。

* * *

## 5.InputMethodManager造成的内存泄漏

  * **现象**  
InputMethodManager持有一Activity,导致该Activity无法回收。如果该Activity再次被打开，则旧的会释放掉，但新打开的会被继续持有无法释放回收。MAT显示Path
to gc如下:  

![](/image/android_chang_jian_nei_cun_xie_lou_wen_ti/84bae32dd546080e71560391995632dadeb0a2b8359501415477697997335159)

  * **解决方案**  
通过Java Reflection方法将InputMethodManager mLastSrvView置空，来达到剪短gc path的目的。

    
        public static void fixInputMethodManagerLeak() {
          InputMethodManager imm = (InputMethodManager) destContext.getSystemService(Context.INPUT_METHOD_SERVICE);
          if (imm == null) {
              return;
          }
    
          String [] arr = new String[]{"mCurRootView", "mServedView", "mNextServedView", "mLastSrvView"};
          Field f = null;
          Object obj_get = null;
          for (int i = 0;i < arr.length;i ++) {
              String param = arr[i];
              try{
                  f = imm.getClass().getDeclaredField(param);
                  if (f.isAccessible() == false) {
                      f.setAccessible(true);
                  }
                  obj_get = f.get(imm);
                  if (obj_get != null && obj_get instanceof View) {
                      View v_get = (View) obj_get;
                      f.set(imm, null);
                  }
              }catch(Throwable t){
                  t.printStackTrace();
              }
          }
      }
    

在Activity.onDestory()方法中执行以上方法即可解决。

    
        public  void onDestroy() {
      super.ondestroy();
      fixInputMethodManagerLeak(this);
    }
    

经过以上处理后，内存泄露是不存在了，但出现另外一个问题。事故现场复现的操作步骤为：  
Activity A界面，点击进入Activity
B界面，B有输入框，点击输入框后，没有输入法弹出。原因是InputMethodManager的关联View已经被上面的那段代码置空了。  
事故原因得从Activity间的生命周期方法调用顺序说起， 从Activity A进入Activity B，再回到Activity
A的生命周期方法的调用顺序是：

    
        A.onCreate()→A.onResume() 
    →A.onPause()→B.onCreate()→B.onResume()→A.onStop()
    →B.finish()→B.onPause()→A.onResume()→B.onStop()→B.onDestroy()
    

也就是说，Activity B已经创建并显示了，Activity
A这里执行onDestroy()将InputMethodManager的关联View置空了，导致输入法无法弹出。所以这儿的一个解决方案就是将fixInputMethodManagerLeak(this)挪到finish()方法中执行即可。  
还有一种解决方案是fixInputMethodManagerLeak(ContextdestContext)方法参数中将目标要销毁的Activity
A作为参数传参进去。在代码中，去获取InputMethodManager的关联View，通过View.getContext()与Activity
A进行对比，如果发现两者相同，就表示需要回收；如果两者不一样，则表示有新的界面已经在使用InputMethodManager了，直接不处理就可以了。

    
    
    public static void fixInputMethodManagerLeak(Context destContext) {
            if (destContext == null) {
                return;
            }
            InputMethodManager imm = (InputMethodManager) destContext.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm == null) {
                return;
            }
            String [] arr = new String[]{"mCurRootView", "mServedView", "mNextServedView", "mLastSrvView"};
            Field f = null;
            Object obj_get = null;
            for (int i = 0;i < arr.length;i ++) {
                String param = arr[i];
                try{
                    f = imm.getClass().getDeclaredField(param);
                    if (f.isAccessible() == false) {
                        f.setAccessible(true);
                    }
                    obj_get = f.get(imm);
                    if (obj_get != null && obj_get instanceof View) {
                        View v_get = (View) obj_get;
                        if (v_get.getContext() == destContext) { 
                            f.set(imm, null);
                        }
                    }
                }catch(Throwable t){
                    t.printStackTrace();
                }
            }
        }
    

> 造成内存泄漏的主要原因总结

> 静态对象会在进程启动时被创建，进程结束时才销毁，也就是说静态实例的生命周期与所在进程一样长。所以静态对象持有的Context只能是ApplicationContext或者其他Context的弱引用。
> 非静态内部类会持有外部类引用，而静态内部类不会持有对外部类的引用。

