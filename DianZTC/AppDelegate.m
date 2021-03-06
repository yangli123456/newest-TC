//
//  AppDelegate.m
//  DianZTC
//
//  Created by 杨力 on 4/5/2016.
//  Copyright © 2016 杨力. All rights reserved.
//

#import "AppDelegate.h"
#import "BatarSettingController.h"
#import "DBWorkerManager.h"
#import "YLVer_UpManager.h"
#import "NetManager.h"
#import "YLLoginView.h"
#import "BatarMainTabBarContoller.h"
#import "BatarLoginController.h"
#import "YLUploadToServer.h"
#import "YLNetObseverManager.h"
#import "BTAdverController.h"
#import "YLSocketManager.h"
#import "BatarManagerTool.h"
#import <JSPatchPlatform/JSPatch.h>

@interface AppDelegate ()<YLNetObseverDelegate>

@property (nonatomic,strong) YLUploadToServer * uploadManager;
@property (nonatomic,strong) NetManager * netManager;
@property (nonatomic,strong) YLSocketManager * socketManager;

@end

@implementation AppDelegate

@synthesize uploadManager = _uploadManager;
@synthesize netManager = _netManager;

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UploadOrders object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:SwitchSerser object:nil];
}

-(void)batarNetChange:(BatarNetChangeType)type{
    
    switch (type) {
        case BatarNetNotFound:
            //            [[TKAlertCenter defaultCenter]postAlertWithMessage:@"无网络"];
            break;
        case BatarNetChangedUnknow:
            //            [[TKAlertCenter defaultCenter]postAlertWithMessage:@"未知网络"];
            break;
        case BatarNetChangeWifi:
            //            [[TKAlertCenter defaultCenter]postAlertWithMessage:@"当前网络是Wifi状态"];
            //            [self netAccess];
            break;
        case BatarNetChangeWWAN:
            //            [[TKAlertCenter defaultCenter]postAlertWithMessage:@"当前网络是流量状态"];
            //            [self netAccess];
            break;
        default:
            break;
    }
}

-(void)netAccess{
    //与服务器建立长连接
    if(CUSTOMERID){
        NSString *socketUrl = [NSString stringWithFormat:ConnectWithServer,[_netManager getIPAddress]];
        YLSocketManager *socketManager = [YLSocketManager shareSocketManager];
        [socketManager createSocket:socketUrl delegate:self];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NetManager * manager = [NetManager shareManager];
    _netManager = manager;
    //    //请求广告页参数数据，并缓存在本地
    //    [_netManager bt_saveAdvertiseInfo];
    
    // 启动图片延时: 1秒
    //    [NSThread sleepForTimeInterval:3];
    
    //网络变化的代理设置
    [YLNetObseverManager shareInstanceWithDelegate:self];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(uploadDataToServer) name:UploadOrders object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(switchServer) name:SwitchSerser object:nil];
    
    //如果用户登录，就判断本地是否还有，有则上传，没有，则不管
    [self uploadToServer];
    
    //改变缓存策略
    [self changeCacheStyle];
    
    //检测版本更新
    [self checkUpdated];
    
    //上传app版本
    [_netManager sendAppVersionToService];
    
    //基础设置
    [self setApperance];
    
    //设置根视图
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    if([NetManager batar_getAllServers].count>0&&HasLogined){
        
        NSDictionary * info = [_netManager bt_getAdvertiseControlInfo];
        if([_netManager bt_getAdvertiseInfo]&&[info[@"isopen"]integerValue]==1){
            
            BTAdverController * adverVc = [[BTAdverController alloc]init];
            self.window.rootViewController = adverVc;
        }else{
            BatarMainTabBarContoller * mainVc = [BatarMainTabBarContoller sharetabbarController];
            self.window.rootViewController = mainVc;
        }
        
        if(CUSTOMERID){
            
            //与服务器建立长连接
            NSString *socketUrl = [NSString stringWithFormat:ConnectWithServer,[_netManager getIPAddress]];
            YLSocketManager *socketManager = [YLSocketManager shareSocketManager];
            [socketManager createSocket:socketUrl delegate:self];
        }else{
            //清空"待确认"订单角标
            [BatarManagerTool caculateDatabaseOrderCar];
        }
    }else{
        BatarLoginController * loginVc = [[BatarLoginController alloc]init];
        self.window.rootViewController = loginVc;
    }
    
    //进行热修复
    [JSPatch startWithAppKey:@"d00a7e86e7a9e8ea"];
    
    //本地测试下
//    [JSPatch testScriptInBundle];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}


#pragma YLSocketDelegate
-(void)ylWebSocketDidOpen:(SRWebSocket *)webSocket{
    
    NSString * str = [NSString stringWithFormat:@"{\"\cmd\"\:%@,\"\message\"\:\"\%@\"\}",@"2",CUSTOMERID];
    [webSocket send:str];
}

-(void)ylSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    //    NSLog(@"从Tabbar的入口进入--->%@",message);
    
    message = (NSString *)message;
    if([message containsString:@"ok"]){
        
        //获取订单状态信息
        NSString * str = [NSString stringWithFormat:@"{\"\cmd\"\:%@,\"\message\"\:\"\%@\"\}",@"0",CUSTOMERID];
        [webSocket send:str];
        
    }else if([message containsString:@"logined"]){
        
        webSocket.delegate = nil;
        webSocket = nil;
        [kUserDefaults removeObjectForKey:CustomerID];
        [[NSNotificationCenter defaultCenter]postNotificationName:ServerMsgNotification object:nil];
        AppDelegate * app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UIAlertController * alertVc = [UIAlertController alertControllerWithTitle:@"提示:" message:@"该客户编号已在其他地方登陆" preferredStyle:UIAlertControllerStyleAlert];
        [app.window.rootViewController presentViewController:alertVc animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alertVc dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    }
}

-(void)switchServer{
    
    // NSLog(@"切换了服务器");
    [_uploadManager batar_stop];
    [_uploadManager batar_saveStop];
    [self uploadToServer];
    
    //切换服务器就清空本地搜索历史记录
    [_netManager cleanHistorySearch];
}

-(void)uploadToServer{
    
    if(CUSTOMERID){
        [DBWorkerManager order_judgeLocalOrder:^(BOOL local) {
            if(local){
                dispatch_async(dispatch_get_main_queue(), ^{
                    _uploadManager = [YLUploadToServer shareUploadToServer];
                    [_uploadManager batar_start];
                });
            }
        }];
        
        [DBWorkerManager save_judgeLocalOrder:^(BOOL local) {
            if(local){
                dispatch_async(dispatch_get_main_queue(), ^{
                    _uploadManager = [YLUploadToServer shareUploadToServer];
                    [_uploadManager batar_saveStart];
                });
            }
        }];
    }
}

-(void)setApperance{
    
    [[UINavigationBar appearance]setFrame:CGRectMake(0, 20, self.window.width, 100)];
    [[UINavigationBar appearance]setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance]setTitleTextAttributes:@{NSForegroundColorAttributeName:TEXTCOLOR,NSFontAttributeName:[UIFont systemFontOfSize:17*S6]}];
}

-(void)changeCacheStyle{
    
    //SDImageCache默认是利用NSCache存储资源，也就是利用内存。设置不使用内存就行
    [[SDImageCache sharedImageCache] setShouldCacheImagesInMemory:NO];
    [[SDImageCache sharedImageCache] setShouldDecompressImages:NO];
    [[SDWebImageDownloader sharedDownloader] setShouldDecompressImages:NO];
}

-(void)checkUpdated{
    
    YLVer_UpManager * manager = [[YLVer_UpManager alloc]init];
    [manager compareVersionWithPlist:^(BOOL isupdated) {
        NSString * alertStr;
        UIAlertAction * action1;
        UIAlertAction * action2;
        if(isupdated){
            alertStr = @"当前为最新版本";
        }else{
            alertStr = @"检测到新版本";
            action1 = [UIAlertAction actionWithTitle:@"暂不更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            action2 = [UIAlertAction actionWithTitle:@"现在去更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:IOS_APPURL]];
            }];
        }
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:alertStr preferredStyle:UIAlertControllerStyleAlert];
        if(isupdated){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alertController dismissViewControllerAnimated:YES completion:nil];
            });
        }else{
            [alertController addAction:action1];
            [alertController addAction:action2];
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

-(void)uploadDataToServer{
    
    _uploadManager = [YLUploadToServer shareUploadToServer];
    [_uploadManager batar_start];//上传本地购物车
    [_uploadManager batar_saveStart];//上传本地收藏夹
}

-(void)reStartUpload{
    
    if(_uploadManager.isClosed){
        [_uploadManager batar_start];
    }
    
    if(_uploadManager.save_isClosed){
        [_uploadManager batar_saveStart];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    //1.取消当前任务
    [[SDWebImageManager sharedManager]cancelAll];
    
    //2.清空缓存
    [[SDWebImageManager sharedManager].imageCache cleanDisk];
    
    [[SDWebImageManager sharedManager].imageCache clearDisk];
    [[SDWebImageManager sharedManager].imageCache clearMemory];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    //继续上传
    //    [self reStartUpload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //继续上传
    [self reStartUpload];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    //继续上传
    //    [self reStartUpload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //继续上传
    //    [self reStartUpload];
    [JSPatch sync];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //停止上传
    //    [self reStartUpload];
}


@end
