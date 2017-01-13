//
//  BatarCarController.m
//  DianZTC
//
//  Created by 杨力 on 26/12/2016.
//  Copyright © 2016 杨力. All rights reserved.
//

#import "BatarCarController.h"
#import "DBWorkerManager.h"
#import "MySelectedOrderCell.h"
#import "YLShoppingCarBottom.h"
#import "DetailViewController.h"
#import "YLLoginView.h"
#import "YLOrdersController.h"




#define CELL @"CARCell"

@interface BatarCarController()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) DBWorkerManager * manager;

@property (nonatomic,strong) NSMutableArray * dataArray;
@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray * selectedArray;
@property (nonatomic,strong) YLShoppingCarBottom * carBottom;
@property (nonatomic,strong) YLLoginView * loginView;

@end

@implementation BatarCarController

@synthesize carBottom = _carBottom;
@synthesize loginView = _loginView;

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AddShoppingCar object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    if([self.fatherVc isKindOfClass:[DetailViewController class]]){
        self.tabBarController.tabBar.hidden = YES;
    }else{
        self.tabBarController.tabBar.hidden = NO;
    }
    [self createBottom];
}

-(void)viewDidLoad{
    
    [super viewDidLoad];
    
    [self batar_setNavibar:@"购物车"];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateList) name:AddShoppingCar object:nil];
}

-(void)updateView{
    [self getData];
}

-(void)updateList{
    [self getData];
}

-(void)createView{
    
    self.navigationItem.hidesBackButton = YES;
    
    YLOrdersController * ylOrderController = [[YLOrdersController alloc]init];
    [self.view addSubview:ylOrderController];
    
    //底部控制
    [ylOrderController clickBottomBtn:^(NSInteger tag) {
        
        switch (tag) {
            case 0://回到首页
            {
                FirstViewController * firstVc = [[FirstViewController alloc]initWithController:self];
                [self pushToViewControllerWithTransition:firstVc withDirection:@"left" type:NO];
            }
                break;
            case 1://我的订单
            {
                
            }
                break;
            case 2://删除购物单
                [self deleteOrder];
                break;
            case 3://确认订单
            {
                [self confirmOrder];
            }
                break;
            default:
                break;
        }
    }];
    
    
    if([self.fatherVc isKindOfClass:[DetailViewController class]]){
        
        [self batar_setLeftNavButton:@[@"return",@""] target:self selector:@selector(back) size:CGSizeMake(49/2.0*S6, 22.5*S6) selector:nil rightSize:CGSizeZero topHeight:12*S6];
    }
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, Wscreen, Hscreen-40.5*S6-TABBAR_HEIGHT)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    [self createBottom];
    [self getData];
}

-(void)back{
    
    [self popToViewControllerWithDirection:@"right" type:NO];
}

-(void)createBottom{
    
    YLShoppingCarBottom * bottomView = [YLShoppingCarBottom shareCarBottom];
    _carBottom = bottomView;
    bottomView.selectAllBtn.selected = NO;
    [self.view addSubview:bottomView];
    
    if([self.fatherVc isKindOfClass:[DetailViewController class]]){
        bottomView.deleteBtn.hidden = YES;
        bottomView.confirmBtn.hidden = YES;
    }else{
        bottomView.deleteBtn.hidden = NO;
        bottomView.confirmBtn.hidden = NO;
    }
    
    [YLShoppingCarBottom clickShoppingCar:^(NSInteger index) {
        if(index == 0){
            if(_carBottom.selectAllBtn.selected){
                //全选
                for(DBSaveModel * model in self.dataArray){
                    [self addOrderModel:model];
                }
            }else{
                //取消全选
                for(DBSaveModel * model in self.dataArray){
                    [self deleteOrderModel:model];
                }
            }
            [self.tableView reloadData];
        }else if(index == 1){
            //删除产品
            [self deleteOrder];
        }else{
            //确认订单
            [self confirmOrder];
        }
    }];
}

-(void)confirmOrder{
    //确认选购
    if(CUSTOMERID){
        //直接上传到服务器
        
    }else{
        YLLoginView * loginView = [[YLLoginView alloc]initWithVC:self.app.window withVc:self];
        [self.app.window addSubview:loginView];
        [loginView clickCancelBtn:^{
            
        }];
    }
}

-(void)deleteOrder{
    
    if(self.selectedArray.count==0){
        [self showAlertViewWithTitle:@"暂未选择任何产品!"];
        return ;
    }
    //删除
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction * delete = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if(CUSTOMERID){
            [self removeOrders:YES];
        }else{
            [self removeOrders:NO];
        }
    }];
    //修改按钮
    [delete setValue:[UIColor redColor] forKey:@"titleTextColor"];
    [controller addAction:cancel];
    [controller addAction:delete];
    [self presentViewController:controller animated:YES completion:nil];
    
}

-(void)removeOrders:(BOOL)islogged{
    
    DBWorkerManager * dbManager = [DBWorkerManager shareDBManager];
    if(islogged){
        //删除服务端订单
        
        
        
    }else{
        //删除本地订单
        [self.dataArray removeObjectsInArray:self.selectedArray];
        for(DBSaveModel * model in self.selectedArray){
            [dbManager order_cleanDBDataWithNumber:model.number];
        }
    }
    _carBottom.selectAllBtn.selected = NO;
    [self.tableView reloadData];
}

-(void)getData{
    
    [self.selectedArray removeAllObjects];
    WEAKSELF(WEAKSS);
    if(CUSTOMERID){
        
        //服务器获取数据
        
    }else
    {
        //本地购物车获取数据
        [self.manager createOrderDB];
        [self.manager order_getAllObject:^(NSMutableArray *dataArray) {
            WEAKSS.dataArray = dataArray;
            [WEAKSS.tableView reloadData];
        }];

    }
    
}

#pragma mark -表格代理方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MySelectedOrderCell * cell = [tableView dequeueReusableCellWithIdentifier:CELL];
    if(cell == nil){
        cell = [[MySelectedOrderCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL];
    }
    
    DBSaveModel * model = self.dataArray[indexPath.row];
    [cell configCellWithModel:model];
    
    __block typeof(self)weakSelf = self;
    [cell clickSelectedOrderBlock:^(UIButton *btn) {
        if(btn.selected){
            [weakSelf addOrderModel:model];
        }else{
            [weakSelf deleteOrderModel:model];
        }
    }];
    
    return cell;
}

-(void)addOrderModel:(DBSaveModel *)model{
    
    if(![self.selectedArray containsObject:model]){
        
        model.selected = YES;
        [self.selectedArray addObject:model];
        if(self.selectedArray.count == self.dataArray.count){
            _carBottom.selectAllBtn.selected = YES;
        }
    }
}

-(void)deleteOrderModel:(DBSaveModel *)model{
    
    model.selected = NO;
    [self.selectedArray removeObject:model];
    _carBottom.selectAllBtn.selected = NO;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 102.5*S6;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
}

-(DBWorkerManager *)manager{
    
    if(_manager == nil){
        _manager = [DBWorkerManager shareDBManager];
    }
    return _manager;
}

-(NSMutableArray *)selectedArray{
    
    if(!_selectedArray){
        _selectedArray = [NSMutableArray array];
    }
    return _selectedArray;
}

@end
