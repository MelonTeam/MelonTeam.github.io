---
layout: post
title: "封装内嵌UICollectionView和UIPageControl的ScrollView"
date: 2017-07-31 20:44:00 +0800
categories: ios
author: justinsong
tags: UICollectionView UIScrollView UIPageControl iOS
---

* content
{:toc}



在需求中涉及到一个比较通用的控件，ScrollView里面嵌入CollectionView，封装一下，后面再有相同交互不用重复造轮子。

##### 一。交互样式
<!--more-->

控件交互：  

![](/image/feng_zhuang_nei_qian_uicollectionview_he_uipagecontrol_de_scrollview/f3143f1bcdede6a0071f474045db873c3fbc4cddc7d0a1e5380d49991fe0f9d9)  

[ ]

如下类似样式都可以复用同一控件:  

![](/image/feng_zhuang_nei_qian_uicollectionview_he_uipagecontrol_de_scrollview/8ac66ad82b25f8550cad81f16c8403d76d8105a091e015e2d96f32831e8a0a71)  

[ ]

  

![](/image/feng_zhuang_nei_qian_uicollectionview_he_uipagecontrol_de_scrollview/bdcf44cbaa5e7ff5018b84f3b07d429ecc7c999b6b2e107eeb0ed6ada10595f7)  

[ ]

##### 二。接口

  * 接口

init的时候传入view布局相关的TBCollectionViewParamsModel参数；拿到数据后调用setDataList传入数据，展示CollectionScrollView。

    
    
    @interface TBHorizontalItemListView : UIView
    
    - (instancetype)initWithFrame:(CGRect)frame collectionViewParamsModel:(TBCollectionViewParamsModel *)viewParams;
    
    - (void)setDataList:(NSArray*)listData;
    
    @end
    

  * 参数

    
    
    @interface TBCollectionViewParamsModel : NSObject
    @property (nonatomic, assign) CGSize itemSize;                  //collectionView的cell大小
    @property (nonatomic, assign) CGFloat minimumInteritemSpacing;  //collectionView的cell间水平间距
    @property (nonatomic, assign) CGFloat minimumLineSpacing;       //collectionView的cell间的竖直间距
    @end
    
    
    @interface TBCollectionDataListModel : NSObject
    @property (nonatomic, retain) NSArray *itemList;            //单个collectionView中的数据list
    @property (nonatomic, strong) Class cellClass;                  //单个collectionView中使用的cell类型, 需要实现TBCollectionViewCellProtocol
    @property (nonatomic, assign) int type;                         //扩展，暂时无用
    @end
    

##### 三。实现

![](/image/feng_zhuang_nei_qian_uicollectionview_he_uipagecontrol_de_scrollview/8e5869243dd63a46a331529885ede0cc0a75391c5b40b10ee3f3a51ca3cf3ccd)  

[ ]

UICollectionViewUICollectionViewUICollectionViewUICollectionView

  * 灰色的是容器`View`
  * 紫色的是`UIScrollView`
  * 蓝色的是`UICollectionView`
  * 红色的是`UICollectionViewCell`
  * 下方小点点是`TBScrollPageControl`

关键代码：

根据setDataList传入的数据创建CollectionView并为其布局

    
    
    - (void)initCollectionViews
    {
        _bgScrollView.contentSize = CGSizeMake(TBHorizontalItemListViewWidth * _listData.count, 0);
    
        CGFloat x_offset = 0;
        for (NSInteger i = 0; i < _listData.count; i++)
        {
            UICollectionViewFlowLayout *flowLayout = [self getCollectionViewFlowLayout:_viewParams];
    
            CGRect frame = CGRectMake(x_offset + 23 / 2, 20, TBHorizontalItemListViewWidth - 23, 199);
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
            collectionView.tag = 100+i;
            collectionView.dataSource = self;
            collectionView.delegate = self;
            collectionView.alwaysBounceHorizontal = NO;
            collectionView.alwaysBounceVertical = YES;
            collectionView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.showsVerticalScrollIndicator = NO;
            collectionView.scrollEnabled = NO;
            collectionView.backgroundColor = [UIColor blueColor];
            [_bgScrollView addSubview:collectionView];
    
            Class cellClass = [_listData objectAtIndex:i].cellClass;
            NSString *identifier = [NSString stringWithFormat:@"ItemLandscapeCollectionCellIdentifier_%ld",(long)collectionView.tag];
            [collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    
            x_offset += TBHorizontalItemListViewWidth;
            [collectionView reloadData];
        }
        [self layoutIfNeeded];
    }
    

CollectionView的代理：

    
    
    #pragma mark - UICollectionDataSource
    
    - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        return _viewParams.itemSize;
    }
    
    - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
    {
        NSInteger groupIndex = collectionView.tag - 100;
        return _listData[groupIndex].itemList.count;
    }
    
    - (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        /**取数据*/
        NSInteger groupIndex = collectionView.tag - 100;
        TBCollectionDataListModel *listModel = _listData[groupIndex];
        id itemModel = listModel.itemList[indexPath.row];
    
        /**创建cell&&赋值*/
        NSString *identifier = [NSString stringWithFormat:@"ItemLandscapeCollectionCellIdentifier_%ld",collectionView.tag];
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        if ([cell respondsToSelector:@selector(setModel:)])
        {
            [cell setModel:itemModel];
        }
    
        return cell;
    }
    

