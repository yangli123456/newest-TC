//
//  SearchResultController.h
//  DianZTC
//
//  Created by 杨力 on 29/12/2016.
//  Copyright © 2016 杨力. All rights reserved.
//

#import "RootViewController.h"

@interface BatarResultController : RootViewController

@property (nonatomic,strong)  NSIndexPath * currentIndexPath;
@property (nonatomic,copy)    NSString * param;
@property (nonatomic,strong)  NSMutableArray * initialDataArray;

@end
