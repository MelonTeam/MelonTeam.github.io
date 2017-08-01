---
layout: post
title: "SpriteKit动画小游戏"
date: 2017-07-30 20:30:00 +0800
categories: ios
author: ericxwli
tags: spritekit
---

* content
{:toc}



## Spritekit简介

Spritekit是苹果IOS7中引入的一个2D游戏引擎框架，可以实现各种动画效果，在这之前业界比较优秀的游戏引擎是cocos2d，支持场景切换、精灵和精灵表单、动作、动画和特性、物理碰撞、视差滚动等等，可以说SpriteKit是cocos2d的IOS的内置实现，两者所支持的特性基本一致，对于苹果开发者来说前者更加容易上手，本文将通过一个demo实例来初步探索和学习spritekit。
<!--more-->

## 工程配置

首先我们来创建一个spritekit的hello
wrold吧，第一步新建工程，xcode已经提供了Spritekit的模板，我们选择game，创建名字为SpritekitDemo。这里简单说一下，游戏一般有横屏或者竖屏，这里只要在工程设定的General表情中进行勾选即可，这样游戏就可以强制为横屏或者竖屏。

![](/image/spritekit_dong_hua_xiao_you_xi/af6b8a3b07454b91ab88320fbb75ea8668ff6e3e8c84daa5b1555cf5ce4d100d)

![](/image/spritekit_dong_hua_xiao_you_xi/85cde664c82a95d38ccc803c54035d96e0fb6f3a84bc08968ad92f3f4790d3e6)

## Hello Spritekit模板

直接编译运行上面创建的工程，我们会看到下面的画面，没点击画面时会出现不同颜色并旋转的小方框，这就是一个简单的游戏动画效果，我们简单分析下hello
spritekit模板来了解spritekit的一个大致框架。

![](/image/spritekit_dong_hua_xiao_you_xi/7e8306778f89a8e4649017e0f256d27666bc63ef2cbc249adf11f0c14104d118)

在demo工程中我们会看到xcode直接为我们写好的两个类`GameViewController` `GameScene`

    
    
    - (void)viewDidLoad {
        [super viewDidLoad];
    
        // Load the SKScene from 'GameScene.sks'
        GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
    
        // Set the scale mode to scale to fit the window
        scene.scaleMode = SKSceneScaleModeAspectFill;
    
        SKView *skView = (SKView *)self.view;
    
        // Present the scene
        [skView presentScene:scene];
    
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
    }



GameViewController是demo的rootviewcontroller，在打开视图前创建了一个SKScene，设置了scene的适配属性，将根视图创建为SKView，调用了presentScene方法来呈现了GameScene。我们接着看看GameScene是什么东东？

    
    
    - (void)didMoveToView:(SKView *)view {
        // Setup your scene here
    
        // Get label node from scene and store it for use later
        _label = (SKLabelNode *)[self childNodeWithName:@"//helloLabel"];
    
        _label.alpha = 0.0;
        [_label runAction:[SKAction fadeInWithDuration:2.0]];
    
        CGFloat w = (self.size.width + self.size.height) * 0.05;
    
        // Create shape node to use during mouse interaction
        _spinnyNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(w, w) cornerRadius:w * 0.3];
        _spinnyNode.lineWidth = 2.5;
    
        [_spinnyNode runAction:[SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:1]]];
        [_spinnyNode runAction:[SKAction sequence:@[
                                                    [SKAction waitForDuration:0.5],
                                                    [SKAction fadeOutWithDuration:0.5],
                                                    [SKAction removeFromParent],
                                                    ]]];
    }

在GameScene中创建了一个SKLabelNode，而这个node展示的就是Hello，World！字样，并且调用了runAction，执行了改变透明的渐变为1的SKAction，呈现了hello
world出现的动画。

另一个_spinnyNode被创建未一个带圆角的正方形，并执行了两个Action，一个是1秒内旋转360度的重复动作，一个是消失的动作序列，并在点击的时候调用addchlid方法将这个节点加入到了场景中

    
    
    - (void)touchDownAtPoint:(CGPoint)pos {
        SKShapeNode *n = [_spinnyNode copy];
        n.position = pos;
        n.strokeColor = [SKColor greenColor];
        [self addChild:n];
    }



呈现了点击出现旋转渐变消失的小方块。

至此我们可以大致了解到了spritekit运行的一个大致框架：SpriteKit是基于Scene(场景)来组织的动画的，每个SKView(用来显示)中可以渲染和管理一个SKScene，每个Scene中可以装载多个Node，Node通过执行action来展示不同动作。

SKNode的几大子类包括:

SKSpriteNode(用于绘制精灵纹理);

SKVideoNode（用于播放视频）；

SKLabelNode(用于渲染文本）；

SKShapeNode(用于渲染基于Core Graphics路径的形状）；

SKEmitterNode（用于创建和渲染粒子系统);

SKCropNode(用于使用遮罩来裁剪子节点）；

SKEffectNode（用于在子节点上使用Core Image滤镜）。

在了解了基本的运行原理后，接下来我们准备来创建自己的小游戏，游戏内容就是一个打飞机的故事，己方英雄通过射出自己的子弹来击爆迎面而来的敌机。

## 加入英雄Node

正如前所说Node是装载在Scene中的，所以我们在刚在的didMoveToView中添加我们heroNode。

    
    
    - (void)didMoveToView:(SKView *)view {
        _heroNode = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"hero"] size:CGSizeMake(40, 40)];
        _heroNode.position = CGPointMake(self.size.width/2, _heroNode.size.height/2);
        [self addChild:_heroNode];
    }



1.`spriteNodeWithTextur:size:`方法可以简单的传入Node的纹理和尺寸来初始化英雄Node，texture可以`textureWithImageNamed`方法获得一个图片的纹理，也可以传入自定义的texture。

2.Node的position是指该Node的中心位置，在设置位置时，这里注意Spritekit中的坐标系和OPENGL的坐标系是一致的，都是屏幕左下角为起始点(0,0)。

最后通过addChild方法就将我们的英雄Node加入到场景中了，效果图：

![](/image/spritekit_dong_hua_xiao_you_xi/fb7c08b6ad605a0251a37b85f0c150d4eb88f97c4063abd38203fdd57b78e411)

英雄需要能够移动才能有效击杀敌机，所以我们通过手指在屏幕点击和移动时，调整英雄的位置，让其随着手指的移动而移动。

    
    
    - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        for (UITouch *t in touches)
        {
            _heroNode.position = [t locationInNode:self];
        }
     }
    
        - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
        for (UITouch *t in touches)
        {
            _heroNode.position = [t locationInNode:self];
        }
    }
    - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
        for (UITouch *t in touches)
        {
            _heroNode.position = [t locationInNode:self];
        }
    }
    - (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
        for (UITouch *t in touches)
        {
            _heroNode.position = [t locationInNode:self];
        }
    }



## 加入敌机

我们的英雄是要击射敌机的，而且是随机而来的敌机，连续不断，冲向英雄，所以我们加一个方法addEnemy来创造敌机。

    
    
    - (void)addEnemy {
        SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"hero"] size:CGSizeMake(40, 40)];
    
        //设定敌机的出现位置横坐标随机randomX
        CGSize winSize = self.size;
        int minX = enemy.size.width / 2;
        int maxX = winSize.width - enemy.size.width/2;
        int rangeX = maxX - minX;
        int randomX = (arc4random() % rangeX) + minX;
    
        //设置敌机初始位置并添加敌机进场景
        enemy.position = CGPointMake(randomX,winSize.height + enemy.size.height/2);
        [self addChild:enemy];
    
        //设定敌机飞向英雄的时间，随机来控制不同的敌机飞行速度
        int minDuration = 2.0;
        int maxDuration = 4.0;
        int rangeDuration = maxDuration - minDuration;
        int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
        //执行敌机从起始点飞向英雄的动作
        SKAction *actionMove = [SKAction moveTo:CGPointMake(randomX,enemy.size.height/2)
                                       duration:actualDuration];
        SKAction *actionMoveDone = [SKAction runBlock:^{
            [enemy removeFromParent];
            [self.enemys removeObject:enemy];
    
        }];
        [enemy runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
    
        [self.enemys addObject:enemy];
    }



1.敌机是从英雄所在对面位置飞来，首先确定一个敌机对面出现的横向坐标范围，再随机从这个范围中设定敌机位置。

2.控制敌机不同的飞行速度，是通过敌机飞向英雄动作的总时长不同来实现。

3.SKAction的sequence方法是允许我们执行多个动作，这里我们执行了敌机飞向英雄的动作和消失的动作。

编译运行后只出现了一个敌机，但是这样是不够的，我们再通过执行两个动作来源源不断的生成敌机

    
    
    SKAction *actionAddEnemy = [SKAction runBlock:^{
            [self addEnemy];
    }];
    SKAction *actionWaitNextEnemy = [SKAction waitForDuration:1];
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[actionAddEnemy,actionWaitNextEnemy]]]];



runBlock方法可以创建已个动作的代码块，这里执行了创建敌机方法，然后再等待1秒再次创建敌机，一直循环。

![](/image/spritekit_dong_hua_xiao_you_xi/ecc7dfc2dc992bb8e2b476c59ebd4e256c252d2b215ce466eac3a4d6a19b9e9a)

## 发射子弹

英雄会每隔一段时间会射出一发子弹，即创建一个子弹node并渲染，这样就涉及到这个定时器怎么设置，spritekit是游戏引擎，所以大多数情况下画面是不断变化的，SKView需要循环不断的进行每帧重绘。

在每一帧开始时，SKScene会调用`-update：`方法，参数currentTime是当前时间，在该方法中我们可以进行一些刷新的逻辑，或者让node执行action等。所以我们可以在每隔几帧让英雄射出一发子弹来实现子弹发射效果。

    
    
    - (void)shot
    {
        SKSpriteNode* bulletNode = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"hero"] size:CGSizeMake(2, 2)];;
        bulletNode.position = CGPointMake(_heroNode.position.x, _heroNode.position.y + _heroNode.size.height/2);
        [self addChild:bulletNode];
        SKAction *actionMove = [SKAction moveTo:CGPointMake(bulletNode.position.x,self.size.height + bulletNode.size.height)
                                       duration:1];
        SKAction *actionMoveDone = [SKAction runBlock:^{
            [bulletNode removeFromParent];
        }];
        [bulletNode runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
        [self.bullets addObject:bulletNode];
    }
    -(void)update:(CFTimeInterval)currentTime {
        // Called before each frame is rendered
    
        static int tempNum=0;
        if (tempNum>20)
        {
            [self shot];
            tempNum=0;
        }
        tempNum++;
    }



1.和之前创建Node一样，这里我们创建一个子弹Node，设置其初始位置。

2.将子弹从初始位置移动到敌机底边，并设置所用时间来控制子弹速度。

3.每隔20帧发射一次子弹

![](/image/spritekit_dong_hua_xiao_you_xi/5c4bae7342b3a586a5932598acccb2efe4c9c64a78eb6fc9ed1dd8c138082202)

## 碰撞检测

子弹发射了，但是不能击毁敌机，所以这里我们要做的是在子弹和敌机碰撞时，将他们都进行销毁移除场景，那么我们在什么时机去进行碰撞检测呢？这里我们简单介绍一下spritekit的每一帧周期运转：

1.每一帧开始都会先调用`-update：`，如前面所讲我们可以在这里让Node执行action

2.执行update后开始执行所有的action。

3.action执行结束后，`-didEvaluateActions`将被调用，可以对Node进行调整

4.进行物理计算，在Node上添加了SKPhysicsBody的话就会参与这一阶段的物理计算，最后根据结果决定节点状态

5.在物理计算完成之后，会调用`-didSimulatePhysics`方法，在这个方法中依然可以进行Node的调整，写入游戏逻辑。

根据上面的想法，我们可以在update中简单计算子弹和敌机的位置来决定是否要销毁和移除他们。

    
    
    -(void)update:(CFTimeInterval)currentTime {
        // Called before each frame is rendered
    
        static int tempNum=0;
        if (tempNum>20)
        {
            [self shot];
            tempNum=0;
        }
        tempNum++;
    
        NSMutableArray *bulletsToDelete = [[NSMutableArray alloc] init];
        for (SKSpriteNode *bullet in self.bullets) {
    
            NSMutableArray *enemysToDelete = [[NSMutableArray alloc] init];
            for (SKSpriteNode *enemy in self.enemys) {
    
                if (CGRectIntersectsRect(bullet.frame, enemy.frame)) {
                    [enemysToDelete addObject:enemy];
                }
            }
    
            for (SKSpriteNode *enemy in enemysToDelete) {
                [self.enemys removeObject:enemy];
                [enemy removeFromParent];
                NSLog(@"被击毁了。。。。。。。。");
            }
    
            if (enemysToDelete.count > 0) {
                [bulletsToDelete addObject:bullet];
            }
        }
    
        for (SKSpriteNode *projectile in bulletsToDelete) {
            [self.bullets removeObject:projectile];
            [projectile removeFromParent];
        }
    }



## 场景切换

上面我们已经基本完成了打飞机的场景，但是在游戏中会有不同的关卡和不同的场景，这就涉及到两个场景直接的切换，我们这里以主界面场景切换到游戏场景为例来展示。
1.新建类`MainInterfaceScene`是`SKScene`的子类,创建两个`SKLabelNode`来进行文字提示。

    
    
    -(instancetype)initWithSize:(CGSize)size
    {
        if (self = [super initWithSize:size]) {
            self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
            //1 Add a result label to the middle of screen
            _resultLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
            _resultLabel.text = @"精彩打飞机";
            _resultLabel.fontSize = 30;
            _resultLabel.fontColor = [SKColor blackColor];
            _resultLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                               CGRectGetMidY(self.frame));
            [self addChild:_resultLabel];
    
            //2 Add a retry label below the result label
            _retryLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
            _retryLabel.text = @"开始游戏";
            _retryLabel.fontSize = 20;
            _retryLabel.fontColor = [SKColor blueColor];
            _retryLabel.position = CGPointMake(_resultLabel.position.x, _resultLabel.position.y * 0.8);
            //3 Give a name for this node, it will help up to find the node later.
            _retryLabel.name = @"retryLabel";
            [self addChild:_retryLabel];
        }
        return self;
    }



2.在点击开始游戏标签时将场景切换到GameScene，场景切换使用SKTransition来实现，可以指定切换的方向和动画时间

    
    
    -(void) changeToGameScene
    {
        GameScene *ms = [GameScene sceneWithSize:self.size];
        SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionRight duration:1.0];
        [self.scene.view presentScene:ms transition:reveal];
    }



3.在游戏中我们可以设定失败和胜利的条件来切换到游戏结束场景

    
    
    -(void) changeToGameScene
    {
        GameScene *ms = [GameScene sceneWithSize:self.size];
        SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionRight duration:1.0];
        [self.scene.view presentScene:ms transition:reveal];
    }



至此整个小游戏就创建完成，整个过程包括了游戏的一些基本流程，比如精灵的管理、交互的检测、场景切换等，
对spritekit的运行原理有了大致的掌握，当然一款真正的游戏比这个复杂多了，后续我们再可以进行不断的完善来使得场景更加丰富，其中不足之处还望指正。(附近中是demo源代码)

