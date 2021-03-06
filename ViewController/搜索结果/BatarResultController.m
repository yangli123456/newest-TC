//
//  SearchResultController.m
//  DianZTC
//
//  Created by 杨力 on 29/12/2016.
//  Copyright © 2016 杨力. All rights reserved.
//

#import "BatarResultController.h"
#import "SearchViewController.h"
#import "MySelectedOrderCell.h"
#import "DetailViewController.h"
#import "BatarShapeController.h"
#import "RecommandImageModel.h"
#import "ScanViewController.h"
#import "BatarResultModel.h"
#import "MJRefresh.h"
#import "NetManager.h"

#define CODECELL @"codeCell"
@interface BatarResultController()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIScrollViewDelegate>{
    NSInteger page;
}

@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray<BatarResultModel *>*dataArray;
@property (nonatomic,strong) UITextField * result_Tf;
@property (nonatomic,strong) UIButton * layoutBtn;
@property (nonatomic,strong) NSIndexPath * indexPath;

@end

@implementation BatarResultController

@synthesize tableView = _tableView;
@synthesize dataArray = _dataArray;
@synthesize result_Tf = _result_Tf;
@synthesize layoutBtn = _layoutBtn;

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;
    _layoutBtn.hidden = NO;
    if(![self.fatherVc isKindOfClass:[ScanViewController class]]){
        self.result_Tf.hidden = NO;
        [self batar_setNavibar:nil];
    }else{
        self.result_Tf.hidden = YES;
        [self batar_setNavibar:@"搜索结果"];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    _result_Tf.hidden = YES;
    _layoutBtn.hidden = YES;
}

-(void)viewDidLoad{
    
    [super viewDidLoad];
}

-(void)createView{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self batar_setLeftNavButton:@[@"return",@""] target:self selector:@selector(back) size:CGSizeMake(49/2.0*S6, 22.5*S6) selector:nil rightSize:CGSizeZero topHeight:12*S6];
    [self createTextfield];
    
    _layoutBtn = [Tools createNormalButtonWithFrame:CGRectMake(Wscreen-38*S6, 31, 22*S6, 22*S6) textContent:nil withFont:[UIFont systemFontOfSize:15*S6] textColor:TEXTCOLOR textAlignment:NSTextAlignmentRight];
    [_layoutBtn setImage:[UIImage imageNamed:@"shape_sel"] forState:UIControlStateNormal];
    [_layoutBtn setImage:[UIImage imageNamed:@"shape_sel"] forState:UIControlStateHighlighted];
    [self.navigationController.view addSubview:_layoutBtn];
    _layoutBtn.selected = NO;
    [_layoutBtn addTarget:self action:@selector(changeLayout) forControlEvents:UIControlEventTouchUpInside];
    
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, Wscreen, Hscreen-NAV_BAR_HEIGHT)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    //    [_tableView addHeaderWithTarget:self action:@selector(headerAction)];
    [_tableView addFooterWithTarget:self action:@selector(footerAction)];
    [self headerAction];
}

-(void)changeLayout{
    
    BatarShapeController * shapeVc = [[BatarShapeController alloc]initWithController:[ScanViewController new]];
    shapeVc.param = self.param;
    shapeVc.currentIndexPath = self.currentIndexPath;
    shapeVc.initialDataArray = self.dataArray;
    [self.navigationController pushViewController:shapeVc animated:NO];
    [self removeNaviPushedController:self];
}

-(void)createData{
    
    NetManager * manager = [NetManager shareManager];
    NSString * URLstring = [NSString stringWithFormat:SEARCHURL,[manager getIPAddress]];
//    self.param = [self.param stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    self.param = [self.param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString * str = [NSString stringWithFormat:@"%@?key=%@&",URLstring,self.param];
    NSString * pageStr = [NSString stringWithFormat:@"%zi",page];
    NSString * urlStr = [NSString stringWithFormat:@"%@page=%@&size=%@",str,pageStr,@"100"];
    
    [manager downloadDataWithUrl:urlStr parm:nil callback:^(id responseObject, NSError *error) {
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSArray * array = dict[@"page"];
        if(page == 0){
            [self.dataArray removeAllObjects];
        }
        
        if(array.count == 0){
            [self showAlertViewWithTitle:@"未找到更多产品信息"];
        }
        
        for(NSDictionary * dict in array){
            BatarResultModel * model = [[BatarResultModel alloc]initWithDictionary:dict error:nil];
            [self.dataArray addObject:model];
        }
        [_tableView reloadData];
        [_tableView headerEndRefreshing];
        [_tableView footerEndRefreshing];
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MySelectedOrderCell * cell = [tableView dequeueReusableCellWithIdentifier:CODECELL];
    if(cell == nil){
        cell = [[MySelectedOrderCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CODECELL];
    }
    
    BatarResultModel * model = self.dataArray[indexPath.row];
    [cell configResultCellWithModel:model];
    cell.select_btn.hidden = YES;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 102.5*S6;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DetailViewController * detailVc = [[DetailViewController alloc]initWithController:self];
    detailVc.index = self.dataArray[indexPath.row].number;
    [self pushToViewControllerWithTransition:detailVc withDirection:@"left" type:NO];
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    self.currentIndexPath = indexPath;
}

-(void)headerAction{
    
    if(self.initialDataArray.count>0){
        
        [self getInitialData];
        [self.tableView reloadData];
        [self changeScrollPosition];
        [self.tableView headerEndRefreshing];
        [self.tableView footerEndRefreshing];
        [self.initialDataArray removeAllObjects];
        return;
    }
    page = 0;
    [self createData];
}

#pragma mark - 改变偏移位置
-(void)changeScrollPosition{
    
    if(self.currentIndexPath.row%2){
        self.indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row+6 inSection:self.currentIndexPath.section];
    }else{
        self.indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row/2 inSection:self.currentIndexPath.section];
    }
    [_tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

-(void)getInitialData{
    
    [self.dataArray removeAllObjects];
    for(RecommandImageModel * initialModel in self.initialDataArray){
        BatarResultModel * model = [[BatarResultModel alloc]init];
        model.number = initialModel.number;
        model.name = initialModel.name;
        model.image = initialModel.img;
        [self.dataArray addObject:model];
    }
}

-(void)footerAction{
    page ++;
    [self createData];
}

-(void)createTextfield{
    
    CGFloat tf_Y;
    if(IS_IPHONE == IS_IPHONE_5||IS_IPHONE == IS_IPHONE_4_OR_LESS){
        tf_Y = 62/2.0;
    }else if(IS_IPHONE == IS_IPHONE_6){
        tf_Y = 57/2.0;
    }else if (IS_IPHONE == IS_IPHONE_6P){
        tf_Y = 53/2.0;
    }
    self.result_Tf = [[UITextField alloc]initWithFrame:CGRectMake((33+49+33)/2.0*S6, 8.0*S6, 262.5*S6, tf_Y*S6)];
    [self.result_Tf resignFirstResponder];
    self.result_Tf.backgroundColor = [UIColor whiteColor];
    self.result_Tf.layer.cornerRadius = 5*S6;
    self.result_Tf.clipsToBounds = YES;
    UIView * leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,10*S6 , 55/2.0*S6)];
    self.result_Tf.leftView = leftView;
    self.result_Tf.clearButtonMode = UITextFieldViewModeAlways;
    self.result_Tf.leftViewMode =UITextFieldViewModeAlways;
    self.result_Tf.placeholder = @"输入您想要的宝贝";
    self.result_Tf.returnKeyType = UIReturnKeySearch;
    [self.navigationController.navigationBar addSubview:self.result_Tf];
    self.result_Tf.userInteractionEnabled = YES;
    //改变输入框placeholder的字体大小和颜色
    [self.result_Tf setValue:RGB_COLOR(153, 153, 153, 1) forKeyPath:@"_placeholderLabel.textColor"];
    self.result_Tf.font = [UIFont systemFontOfSize:14*S6];
    //改变输入框输入时字体的颜色
    self.result_Tf.delegate = self;
    self.result_Tf.textColor = RGB_COLOR(153, 153, 153, 1);
    self.result_Tf.font = [UIFont systemFontOfSize:14*S6];
    self.result_Tf.layer.borderWidth = 1.0*S6;
    self.result_Tf.layer.borderColor = [RGB_COLOR(76, 66, 41, 1)CGColor];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)back{
    [self popToViewControllerWithDirection:@"right" type:NO];
}

-(NSMutableArray *)dataArray{
    
    if(!_dataArray){
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

@end
