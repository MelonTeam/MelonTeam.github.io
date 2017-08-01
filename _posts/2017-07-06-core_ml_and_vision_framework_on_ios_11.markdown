---
layout: post
title: "Core ML and Vision Framework on iOS 11"
date: 2017-07-06 10:02:00 +0800
categories: ios
author: rebootyang
tags: 机器学习 iOS COREML
---

* content
{:toc}

| 导语 机器学习和计算机视觉在 iOS 上虽然早已有了系统级的支持，但 WWDC 17 发布的 iOS 11
将它们的使用门槛大大降低。苹果提供了设计合理且容易上手的 API，让那些对基础理论知识一窍不通的门外汉也能玩转高大上的前沿科技，这是苹果一贯的风格。

这是一篇 WWDC 2017 Session 506，608，703 和 710 的学习笔记，以及分享自己尝试写的 Demo [Core-ML-
Sample](https://github.com/yulingtianxia/Core-ML-Sample)。
<!--more-->

![](/image/core_ml_and_vision_framework_on_ios_11/fd5fdcbb102e6f389ebbde1abc0ae933b1b705e4ca42dcb6f0f6c96e2737ae0e)

## Core ML

### 简介

Core ML 大大降低了开发者在苹果设备上使用机器学习技术预测模型的门槛和成本。苹果制定了自己的模型文件格式，统一的格式和全新的 API 设计使得
Core ML 支持苹果生态下多个平台。

![](/image/core_ml_and_vision_framework_on_ios_11/8900e53442265cb8fac5a3db6af5242aab594cd161f8641a7d5609ae886d1fe6)

将数据经过预处理后输入 MLMODEL 文件，输出为模型的预测结果。使用 Core ML
只需要很少的代码就可以构建起一个机器学习的应用。只需关注代码即可，无需关注模型的定义，网络的构成。这跟以前写 MPS
代码时构成了强烈的反差：开发者需要写大量 MPS 代码用于构建和描述一个完整的网络，而加载的文件仅仅是模型的权重而已。MLMODEL
文件包含了权重和模型结构等信息，并可以自动生成相关的代码，节省开发者大量时间。

![](/image/core_ml_and_vision_framework_on_ios_11/8f9ad95057a23104f748a82cc6e0043106bad0ec7e3b7c3159126c139dc27ea9)

### Model 转换工具

苹果提供了一个 Python 工具，可以将业内一些常用的机器学习框架导出的 Model 转成 MLMODEL 文件。代码会编译成可执行二进制文件，而
MLMODEL 会编译成 Bundle 文件，在代码文件中可以直接调用 MLMODEL 生成的类，这些都是需要 Xcode 9
做支撑，也就是说，现阶段并不支持动态下发 MLMODEL 文件。Core ML 的预测过程全都在客户端进行，保证用户隐私不会泄露。

![](/image/core_ml_and_vision_framework_on_ios_11/5744a5d00d4a39ee4fd047140eafe569039f06d8fabf591b556e262f0687fb57)

Core ML 支持 DNN,RNN,CNN,SVM,Tree ensembles,Generalized linear models,Pipeline
models 等，对应的模型转换工具 [Core ML Tools](https://pypi.python.org/pypi/coremltools)
也支持了一些常用机器学习框架模型的转换。虽然目前没有直接支持 Google 的 TensorFlow，但可以使用 Keras
曲线救国。`coremltools` 已经开源，并提供可拓展性的底层接口，可以编写适配其他机器学习框架模型的转换工具。

![](/image/core_ml_and_vision_framework_on_ios_11/806b278de27952c6dca98e18c9c03526542bcf06068b7a0b18336c2251ccaac1)

MLMODEL 文件中还包含了很多元数据，比如作者，License，输入输出的描述文字。这些元数据都可以通过 `coremltools`
的接口进行设置。`coremltools`
上手很简单，可以查看完整详细的[使用文档](https://pythonhosted.org/coremltools/)。

把 MLMODEL 文件拖拽到 Xcode 工程中后，记得要勾选对应的 target，这样 Xcode 才会自动生成对应的代码。生成的类名就是
MLMODEL 文件名，输入和输出的变量名和类型也可以在 Xcode 中查看：

![](/image/core_ml_and_vision_framework_on_ios_11/70af172449d15a445d44a3003bfc2ad9330d2185d28b23acd1e36a77d6c59a2f)

### 底层计算性能

Core ML 的底层是 Accelerate BNNS 和 MPS，并可以根据实际情况进行无缝切换。比如在处理图片的场景下使用 MPS，处理文字场景下使用
Accelerate，甚至可以在同一个 model 的不同层使用不同的底层技术来预测。Vision 和 NLP 可以结合 Core ML 一起使用。Core
ML 对硬件做了性能优化，而且支持的模型种类更多，开发者不用关注底层的一些细节，苹果全都封装好了。

![](/image/core_ml_and_vision_framework_on_ios_11/4db8ca8d075c365441448ecea5e903e4c1509cd254fb4243794cb63ce18a4269)

当然，这些也都是建立在 MPS 更新的基础上，MPS 在 iOS 11 中拓展了支持向量和矩阵的数据结构 `MPSVector` 与
`MPSMatrix`，以及它们之间相乘的 API。而且提供了更多的神经网络类型（比如 RNN
等），在卷积神经网络中也提供了更多种类的卷积核，用于满足更多特殊场景。

![](/image/core_ml_and_vision_framework_on_ios_11/543f73f4e58ffc338734ecac864360a7751147f7e174a6464903847954c0e16b)

苹果在 Metal 2 中补充 MPS 大量功能的同时，也提供了用于描述神经网络结构的语言：Neural Network Graph
API。使用它可以极大简化代码逻辑，代码量缩减到以前的四分之一（以 Inception V3 为例）。并且使用 NN Graph API 可以并行使用
CPU 和 GPU。这种图语言跟主流的分布式机器学习框架的使用很像：先用简单的 Python
语言描述好网络结构，定义好输入输出格式，然后一次性提交到后端去执行。后端对底层性能做了很多细节优化，然而开发者完全不用关心这些。新增的
`MPSNNGraph` 提供了异步接口使得 CPU 不用再等待 GPU 的执行结果，性能也得到提升。

Metal 2 使用 MPS 进行图像处理的性能也得到了提升，在不同的设备上大约提升了百分之二十多。

### Demo: 数据预处理

[Core-ML-Sample](https://github.com/yulingtianxia/Core-ML-Sample) 使用了 Core ML
和 Vision 技术实现对摄像头拍摄的图像实时预测物体种类。因为图像来源是摄像头，所以需要将 `CMSampleBuffer` 转成
`CVPixelBuffer`。因为 Xcode 9 已经生成好了代码，直接调用 `Inceptionv3` 类的 `prediction`
方法即可完成预测。生成的 `Inceptionv3Output` 类含有 `classLabel` 和 `classLabelProbs`
两个属性，可以获取预测的分类标签名以及每种标签的可能性。可以点击 Xcode Model View 中 Model Class
的生成源码箭头来查看这些类的信息。

    
    
    let inceptionv3model = Inceptionv3()
    
    func handleImageBufferWithCoreML(imageBuffer: CMSampleBuffer) {
       guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
           return
       }
       do {
           let prediction = try self.inceptionv3model.prediction(image: self.resize(pixelBuffer: pixelBuffer)!)
           DispatchQueue.main.async {
               if let prob = prediction.classLabelProbs[prediction.classLabel] {
                   self.predictLabel.text = "\(prediction.classLabel) \(String(describing: prob))"
               }
           }
       }
       catch let error as NSError {
           fatalError("Unexpected error ocurred: \(error.localizedDescription).")
       }
    }
    

在 Xcode Model View 中可以看到 Inceptionv3 模型的输入图片为
`Image`，所以需要对摄像头采集到的图像进行预处理。我的转换流程是：`CVPixelBuffer->CVPixelBuffer->CIImage->CIImage(resized)->CVPixelBuffer`。最后一步
`CIImage` 转 `CVPixelBuffer` 是通过 `CIContext` 渲染完成。

    
    
    /// resize CVPixelBuffer
    ///
    /// - Parameter pixelBuffer: CVPixelBuffer by camera output
    /// - Returns: CVPixelBuffer with size (299, 299)
    func resize(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
       let imageSide = 299
       var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
       let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
       ciImage = ciImage.applying(transform).cropping(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
       let ciContext = CIContext()
       var resizeBuffer: CVPixelBuffer?
       CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
       ciContext.render(ciImage, to: resizeBuffer!)
       return resizeBuffer
    }
    

除了图片需要预处理外，其他数据可能也需要预处理。这需要看训练的模型的输入是什么形式，比如分析一段文本所表达的情绪是开心还是沮丧，可能需要写个预处理程序统计词频，然后输入到训练好的模型中进行预测。

### 总结

  * Model 极速集成
  * 支持多种数据类型
  * 硬件优化
  * 适配主流机器学习框架

## Vision

### 应用场景

  1. 人脸检测：支持检测笑脸、侧脸、局部遮挡脸部、戴眼镜和帽子等场景，可以标记出人脸的矩形区域
  2. 人脸特征点：可以标记出人脸和眼睛、眉毛、鼻子、嘴、牙齿的轮廓，以及人脸的中轴线
  3. 图像配准
  4. 矩形检测
  5. 二维码/条形码检测
  6. 文字检测
  7. 目标跟踪：脸部，矩形和通用模板

### Vision 使用姿势

将各种功能的 Request 提供给一个 RequestHandler，Handler 持有图片信息，并将处理结果分发给每个 Request 的
completion Block 中。可以从 `results` 属性中得到 Observation 数组，然后进行更新 UI 等操作。因为
completion Block 所执行的队列跟 perform request 的队列相同，所以更新 UI 时记得使用主队列。

Vision
操作流水线分为两类：分析图片和跟踪队列。可以使用图片检测出的物体或矩形结果（Observation）来作为跟踪队列请求（Request）的参数。

![](/image/core_ml_and_vision_framework_on_ios_11/1d8f721616e23140b7094682f4c14206207c668b1df2a80e0444076854b1774b)

![](/image/core_ml_and_vision_framework_on_ios_11/cac97183653878e7dc12f0fefe7161527097201809d71e96371e9da1469d52eb)

Vision 支持的图片数据类型：

  * `CVPixelBufferRef`
  * `CGImageRef`
  * `CIImage`
  * `NSURL`
  * `NSData`

这几乎涵盖了 iOS 中图片相关的 API，很实用很强大。

Vision 有三种 resize 图片的方式，无需使用者再次裁切缩放

  * `VNImageCropAndScaleOptionCenterCrop`
  * `VNImageCropAndScaleOptionScaleFit`
  * `VNImageCropAndScaleOptionScaleFill`

Vision 与 iOS 上其他几种带人脸检测功能框架的对比：

![](/image/core_ml_and_vision_framework_on_ios_11/88920a6b7f37f95f67df0c2960253e0067a253b80021c38147d83d4812103dea)

### Demo: 与 Core ML 集成

Core ML 具有更好的性能，Vision 可为其提供图片处理的流程。Core ML 生成的代码中含有 `MLModel` 类型的 `model`
对象，可以用它初始化 `VNCoreMLModel` 对象，这样就将 Core ML 的 Model 集成进 Vision 框架中了：

    
    
    private var requests = [VNRequest]()
    
    func setupVision() {
       guard let visionModel = try? VNCoreMLModel(for: inceptionv3model.model) else {
           fatalError("can't load Vision ML model")
       }
       let classificationRequest = VNCoreMLRequest(model: visionModel) { (request: VNRequest, error: Error?) in
           guard let observations = request.results else {
               print("no results:\(error!)")
               return
           }
    
           let classifications = observations[0...4]
               .flatMap({ $0 as? VNClassificationObservation })
               .filter({ $0.confidence > 0.2 })
               .map({ "\($0.identifier) \($0.confidence)" })
           DispatchQueue.main.async {
               self.predictLabel.text = classifications.joined(separator: "\n")
           }
       }
       classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
    
       self.requests = [classificationRequest]
    }
    

上面的代码实现了 Vision 的工作流，并在 completion Block 中对预测结果进行了处理：从 top5 中筛选可能性大于 0.2
的结果，并转成文本描述。因为所有结果的可能性总和为 1，所以最终的结果不会达到 5 个，实际测试中其实结果往往只有 1-2 个。

对摄像头传入的每帧图片进行预测。虽然 Vision 帮我们完成了预处理等流程上的工作，但是需要我们传入一些额外的信息。

    
    
    func handleImageBufferWithVision(imageBuffer: CMSampleBuffer) {
       guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
           return
       }
    
       var requestOptions:[VNImageOption : Any] = [:]
    
       if let cameraIntrinsicData = CMGetAttachment(imageBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
           requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
       }
    
       let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.exifOrientationFromDeviceOrientation, options: requestOptions)
       do {
           try imageRequestHandler.perform(self.requests)
       } catch {
           print(error)
       }
    }
    

需要向图片传入 EXIF Orientation 信息：

    
    
    /// only support back camera
    var exifOrientationFromDeviceOrientation: Int32 {
       let exifOrientation: DeviceOrientation
       enum DeviceOrientation: Int32 {
           case top0ColLeft = 1
           case top0ColRight = 2
           case bottom0ColRight = 3
           case bottom0ColLeft = 4
           case left0ColTop = 5
           case right0ColTop = 6
           case right0ColBottom = 7
           case left0ColBottom = 8
       }
       switch UIDevice.current.orientation {
       case .portraitUpsideDown:
           exifOrientation = .left0ColBottom
       case .landscapeLeft:
           exifOrientation = .top0ColLeft
       case .landscapeRight:
           exifOrientation = .bottom0ColRight
       default:
           exifOrientation = .right0ColTop
       }
       return exifOrientation.rawValue
    }
    

### 总结

  * Vision 是一个关于计算机视觉的顶层新框架。
  * 一个界面，多重跟踪检测
  * 集成 Core ML 轻松使用自己的 model

## 感受

苹果为开发者带来了炫酷的功能，并且这些示例很有针对性，更实用。Vision
更像是一个工具库，对一些高频场景进行了封装，比如人脸、条形码、矩形和文字等，这些基于底层 API 封装的高级功能可以帮助开发者很快地完成老板的功能。而
Core ML 给出的 Model 也很有代表性，贴近实际应用场景，很容易激发开发者使用的热情。我想这正是苹果最擅长的，把复杂的事情简单化，提供极易上手的
Demo，并循序渐进，给予开发者更高深的玩法，不失拓展性和定制化。

`coremltools` 肯定还存在一些兼容性问题，并且会随着各大机器学习框架的更新而不断更新，我想这也是为何苹果将其开源的原因吧。使用 python
也更方便维护，而且主流的机器学习框架都是用 python 作为前端语言。

Core ML 功能强大，支持的模型种类很多。与此同时，MPS 在 iOS 11
也得到了升级，新增的数据类型更方便使用。总之其实还是新增了对底层数据和算法的封装，然后 Core ML
在此基础上又进行了一层高级的封装。可以看出苹果这一年在底层下的功夫确实不少，在这之后才有了更强大更全面的 API。我预测在这之后 Core ML
还会有更多的模型得到支持，Vision 也会加入更丰富的应用场景。

如果苹果能够发挥硬件上性能的优势，可能在以后还会演示出更炫酷的 Demo，比如视频实时防抖的处理，更牛逼的滤镜效果。对高性能计算和 GPU
图像处理感兴趣的话，推荐看下 Metal 2 相关的 Session，尤其是 Session 608。

同时也会发现苹果在机器学习的道路上避开了各个训练框架的锋芒，尤其是最近大红大紫的 Google
TensorFlow。它选择另辟蹊径，在移动端模型预测性能优化和低成本接入的道路上另辟蹊径，充分发挥自身平台的优势。毕竟在移动端训练模型意义较小，还是交给服务端比较合理。

