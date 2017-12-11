---
layout: post
title: "google cloud--穷人也能玩深度学习"
date: 2017-08-31 02:03:00 +0800
categories: ai
author: parrzhang
tags: tensorflow 深度学习 google gcloud
---

* content
{:toc}

| 导语 想玩深度学习但是没钱更新电脑配置怎么办？google
cloud，只要1美元，只要1美元，300美元赠金带回家！365天免费使用，让你轻松入门深度学习！是的，你没有听错，只要1美元，只要1美元，买1赠300，还在犹豫什么，机不可失，失不再来，赶紧掏出你的电脑抢购吧！

# 背景

<!--more-->
由于深度学习计算量大，常常会遇到一个训练跑几小时甚至1天多的情况。一段时间后，你肯定会有升级电脑的想法。而其中很重要的一块是gpu运算需要一块好显卡。

但是当我看看价钱，再看看信用卡账单，我觉得人穷还是应该多忍忍。

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/eedc732c8ed8abafdf19dfe18ff10cccc598ae9bba544557cf3273dd673691da)

我以前还不幸上了农企的船，而目前主流的深度学习框架都是使用cuda，用opencl的速度大部分时候比直接跑cpu还慢。所以如果看完后有同学觉得自己装机更方便的话记住不要买amd的显卡（当然好像土豪也不会买amd的显卡...），另外不差钱的推荐上双TITAN
X

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/dff1227f0506ad5a8be63d9be24155bbb456c91ea9b79ce7dbacdc14f941b1e3)

#

# 介绍

前段时间听richardcliu介绍，google cloud现在有优惠，充值1美元赠送300美元，最多可使用1年。用了之后觉得价格挺公道的。

google cloud有专门的ml-engine（machine learning
engine）模块，可以直接用来跑tensorflow，不用像虚拟机一样开关机。只需要根据需要指定配置就行。收费分为训练收费和预测收费两种：

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/f634ce80729d983f4a7c70eb455ae1ec63adfbbc9ef98ddc3cc8c3db8dc053a7)![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/e86f62f2de7766465a88b08f7803f0d063b675143e389face82442a6e11a2e1d)

这里意思是如果进行模型训练，那么每个训练单位1小时0.49美元（美国服务器）。有5中配置可供选择（[具体介绍](https://cloud.google.com
/ml-engine/reference/rest/v1/projects.jobs#scaletier
)），每种占用的训练单位不同。比如如果选用STANDARD_1就是1小时4.9美元。如果是执行预测任务是每1000次预测0.1美元，plus会员按每小时0.4美元收费（升级plus不要钱，就是会在帐号没钱的时候自动扣信用卡的钱）。

使用google cloud有个好处就是完全不占用本地电脑资源，需要跑的时候扔个命令让google
cloud跑就是，而且不阻塞自己的其它任何工作。跑的过程中生成的数据全部都会存储在存储分区中。

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/964c61ff31c241d06fabde95c4b9898111e39fef4658957d5fea62987d11ce80)

#

# 安装和配置

以mac安装做说明，包括之后的示例也以mac为准。

1.安装python 2.7，gcloud目前只支持python2.x。

2.更新pip

    
    
    pip install -U pip

如果安装的tensorflow不是基于python2.7的，那么再安装一个基于python 2.7的tensorflow

_tensorflow
1.3之后的版本tensorboard和tensorflow分开了，写这篇文章的时候刚把tensorflow从1.2.1更新到了1.3，独立的tensorboard一直跑不了，就先用1.2.1版本说明好了_

    
    
    pip install tensorflow==1.2.1  
    

这个版本的tensorflow不是用来跑代码的，是用来之后把代码提交到google cloud运行前检查语法的。

3.下载[google cloud sdk](https://cloud.google.com/sdk/docs/quickstart-mac-os-x
#before-you-begin)并解压

4.安装

    
    
    sh ./google-cloud-sdk/install.sh

 5.配置ml-engine。

a.创建一个新的云平台项目

[ https://console.cloud.google.com/cloud-resource-manager
](https://console.cloud.google.com/cloud-resource-manager )

b.启用付费

[https://support.google.com/cloud/answer/6293499#enable-billing
](https://support.google.com/cloud/answer/6293499#enable-billing )

c.启用机器学习api

<https://console.cloud.google.com/flows/enableapi>

6.初始化gcloud

    
    
    gcloud init

 然后会提示你登录，确认后会弹出登录页面，然后在弹出的网页选允许

    
    
    To continue, you must log in. Would you like to log in (Y/n)? Y

 选择项目，如果只有一个项目会默认帮你选择，选刚才那个创建的云平台项目（注意是填选择序号）。

    
    
    Pick cloud project to use:
     [1] [my-project-1]
     [2] [my-project-2]
     ...
     Please enter your numeric choice:

 选择默认区域，建议选us-east1，那里机器便宜,而且在运算时支持gpu

    
    
    Which compute zone would you like to use as project default?
     [1] [asia-east1-a]
     [2] [asia-east1-b]
     ...
     [14] Do not use default zone
     Please enter your numeric choice:

 全部设置完成后会有提示已经设置完成。

配置完成后可以用gcloud config list查看配置。更加详细的gcloud命令见

<https://cloud.google.com/sdk/gcloud/reference/ >

#

# 示例

## 准备数据

下载[示例代码](https://github.com/GoogleCloudPlatform/cloudml-
samples/archive/master.zip )，解压后进入estimator目录

    
    
    cd cloudml-samples-master/census/estimator

 mkdir data，将[数据](https://console.cloud.google.com/storage/browser/cloudml-
public/census/data)下载下来放在data里面。

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/96ba0b7a64c2bc239adce29ef5ab17dbc17c563394aaf710b80fb34a66308f31)

创建存储分区。如果是第一次使用，进入后会有配置引导。

[https://console.cloud.google.com/storage/browse](https://console.cloud.google.com/storage/browse
)

在命令行中设置BUCKET_NAME临时变量

    
    
    BUCKET_NAME="刚刚设置的存储分区"

 设置完成后可以通过echo命令查看是否正常设置

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/ccbc54fd8a203e8e5a8ebac2a69531f3028d15046549edd5069678358e3af5db)

设置REGION临时变量。值与刚刚创建BUCKET_NAME的区域相同。我的是us-east1

    
    
    REGION=us-east1

 将data文件夹上传到google cloud

    
    
    gsutil cp -r data gs://$BUCKET_NAME/data

 设置TRAIN_DATA和EVAL_DATA临时变量

    
    
    TRAIN_DATA=gs://$BUCKET_NAME/data/adult.data.csv
    EVAL_DATA=gs://$BUCKET_NAME/data/adult.test.csv

 把test.json也上传上去并且设置临时变量

    
    
    gsutil cp ../test.json gs://$BUCKET_NAME/data/test.json
    
    
    TEST_JSON=gs://$BUCKET_NAME/data/test.json

## 训练

这时候终于可以跑训练任务了。对于每次训练或者预测，都要取一个专门的名称标识。

    
    
    JOB_NAME=census_test_1

 指定输出地址。就是指定tensorflow代码在训练过程中生成的文件。

    
    
    OUTPUT_PATH=gs://$BUCKET_NAME/$JOB_NAME

 下面可以正式开始执行训练了

    
    
    gcloud ml-engine jobs submit training $JOB_NAME \
        --job-dir $OUTPUT_PATH \
        --runtime-version 1.2 \
        --module-name trainer.task \
        --package-path trainer/ \
        --region $REGION \
        --scale-tier STANDARD_1 \
        -- \
        --train-files $TRAIN_DATA \
        --eval-files $EVAL_DATA \
        --train-steps 1000 \
        --verbosity DEBUG  \
        --eval-steps 100

参数比较简单，熟悉tensorflow应该很好理解。scale-
tiler参数就是前面说到的执行任务机器配置，一共可以进行5种机器配置。其中custom配置需要自己写一个配置文件，通过加载配置文件来运行，不能直接将配置以命令行参数的方式添加

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/ec38255ea649890e54d1e4b29457ad9171ab7103b137fd98b7e167c75725b594)

详细的ml-engine命令参数参考

<https://cloud.google.com/sdk/gcloud/reference/ml-engine/>

运行完之后会提示运行成功，并且返回当前任务状态。

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/a15e6c454706bbf194ebfa1c7eef4c93bf0eb4a871c29dfa4e43d4234bd453e9)

之后可以随时查看当前任务状态

    
    
    gcloud ml-engine jobs describe ${your job name}

 也可以进入[可视化页面](https://console.cloud.google.com/mlengine/jobs)查看，下图是运行结束后的作业截图

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/0274c7d2da2d85e817807974d896ca97391c1f214c4999ec8ac293c2c30e9c21)

也可以随时查看，搜索日志

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/20667745b2999be447a233f84502caece80aba670a573d159f852ab55cea0c59)

运行的中间数据存储在存储空间中。

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/4ef45e97638f246e2144e1f91044b1c3793c9c88e94dfe770241f04408decc21)

同时google cloud也支持tensorboard，使用很简单

    
    
    python -m tensorflow.tensorboard --logdir=$OUTPUT_PATH

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/1137906b186f95445c8dc2a2d455e2c4fcdf57700ffb109b1042886f8a2b5087)

## 生成模型

创建临时变量

    
    
    MODEL_NAME=test

创建模型

    
    
    gcloud ml-engine models create $MODEL_NAME --regions=$REGION

找到对应的这个时间戳

    
    
    gsutil ls -r $OUTPUT_PATH/export

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/686ca30f21a090f1cd213267b1bb69228afbdc61fab884c087cb443e3473faf3)

    
    
    MODEL_BINARIES=$OUTPUT_PATH/export/Servo/{你的时间戳}/

生成模型

    
    
    gcloud ml-engine versions create v1 \
    --model $MODEL_NAME \
    --origin $MODEL_BINARIES \
    --runtime-version 1.2

生成的模型也可以直接通过网页查看

<https://console.cloud.google.com/mlengine/models>

## 预测

设置预测任务临时变量

    
    
    JOB_NAME=census_test_prediction
    
    
    OUTPUT_PATH=gs://$BUCKET_NAME/$JOB_NAME

 进行预测

    
    
    gcloud ml-engine jobs submit prediction $JOB_NAME \
    --model $MODEL_NAME \
    --version v1 \
    --data-format TEXT \
    --region $REGION \
    --input-paths $TEST_JSON \
    --output-path $OUTPUT_PATH/predictions

 与训练任务类似，预测任务也可以查看任务的执行情况，日志以及返回数据。

执行完成后可以查看预测结果

    
    
    gsutil cat $OUTPUT_PATH/predictions/prediction.results-00000-of-00001

![](/image/google_cloud__qiong_ren_ye_neng_wan_shen_du_xue_xi/8f90ecc50072be37333c091ed4b01ed2f9dfc768174048a1246e7e5e523f2c80)

#

# 总结

google
cloud对于自家的tensorflow支持可以算的上完美。如果学习的是其它深度学习框架则需要使用传统云服务器的方式，开虚拟机去跑任务。不管怎么样，1美元返300美元还是相当有吸引力的。

至于300美元用完之后怎么办，由于google
cloud只需要google账号，不需要身份认证，猥琐一点是可以再注册个账号继续使用赠送服务。不过最好还是祝愿看到文章的你我，到那个时候能够有钱自己装机或者直接继续享受google
cloud服务。

# 参考资料

<https://cloud.google.com/ml-engine/docs/>

