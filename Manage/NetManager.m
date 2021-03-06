
//
//  CatagoryManager.m
//  DianZTC
//
//  Created by 杨力 on 19/7/2016.
//  Copyright © 2016 杨力. All rights reserved.
//

#import "NetManager.h"

@interface NetManager()<NSURLConnectionDataDelegate,NSURLConnectionDelegate>{
    
    NSURLConnection * connection;
}

@property (nonatomic,copy) NSString * history_search_content;
@property (nonatomic,copy) NSString * advertisePath;
@property (nonatomic,copy) NSString * advertiseImgPath;
@property (nonatomic,copy) NSString * cachePath;

@end


@implementation NetManager

+(instancetype)shareManager{
    
    static NetManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[NetManager alloc]init];
    });
    
    return manager;
}

-(instancetype)init{
    
    if(self = [super init]){
        
        //读取本地的plist文件
        self.plistPath = [NSString stringWithFormat:@"%@catagory.plist",LIBPATH];
        
        //缓存IP PORT
        self.ip_PortPath = [NSString stringWithFormat:@"%@ip_port.plist",LIBPATH];
        
        //广告页数据
        self.advertisePath = [NSString stringWithFormat:@"%@advertise.plist",LIBPATH];
        
        //首页数据缓存
        self.cachePath = [NSString stringWithFormat:@"%@cache%@.plist",LIBPATH,[self getScanDBMD5]];
        
        //广告页图片数据
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        self.advertiseImgPath = [path stringByAppendingPathComponent:@"advertiseImgPath"];
        
        /*搜索历史*/
        self.history_search_content = [NSString stringWithFormat:@"%@history_search",LIBPATH];
        
        self.dataArray = [NSMutableArray arrayWithContentsOfFile:self.plistPath];
        if(self.dataArray == nil){
            self.dataArray = [NSMutableArray arrayWithCapacity:0];
        }
    }
    return self;
}

-(void)downloadCatagoryData{
    
    @WeakObj(self);
    //写入数据
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    NSString * URLstring = [NSString stringWithFormat:CATAFGORYITEM,[self getIPAddress]];
    [manager GET:URLstring parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if(responseObject){
            
            //清空数据
            [selfWeak.dataArray removeAllObjects];
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:self.plistPath error:nil];
            
            //添加数据
            NSMutableDictionary * dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
            if(dict == nil)return ;
            NSArray * array1 = [dict objectForKey:@"category"];
            NSArray * array2 = [dict objectForKey:@"craft"];
            NSArray * array3 = [dict objectForKey:@"material"];
            NSArray * array4 = [dict objectForKey:@"shapes"];
            NSArray * array5 = [dict objectForKey:@"weight"];
            
            [selfWeak.dataArray addObject:array1];
            [selfWeak.dataArray addObject:array2];
            [selfWeak.dataArray addObject:array3];
            [selfWeak.dataArray addObject:array4];
            [selfWeak.dataArray addObject:array5];
            
            [selfWeak.dataArray writeToFile:self.plistPath atomically:YES];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

    }];
}

-(void)downloadDataWithUrl:(NSString *)url parm:(id)obj callback:(NetBlock)block{
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html",@"application/octet-stream",@"audio/wav",@"image/jpeg", nil];
    [manager GET:url parameters:obj progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        block(responseObject,nil);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        block(nil,error);
    }];
    manager = nil;
}

-(NSString *)getIPAddress{
    
    NSString * IP_port;
    IP_port = [NSString stringWithFormat:@"%@:%@",[kUserDefaults objectForKey:IPSTRING],[kUserDefaults objectForKey:PORTSTRING]];
    return IP_port;
}

-(void)checkIPCompareWithIP:(NSString *)ip port:(NSString *)port callback:(CheckIPBlock)block{
    
    self.checkBlock = block;
    NSString * ip_port = [NSString stringWithFormat:@"%@:%@",ip,port];
    NSString * checkUrl = [NSString stringWithFormat:BANNERURL,ip_port];
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:checkUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3.0];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
}

#pragma mark -保存正确的ip列表
-(void)saveCurrentIP:(NSString *)ip withPort:(NSString *)port{
    
    //缓存IP port
    NSMutableArray * ipArray = [NSMutableArray arrayWithContentsOfFile:self.ip_PortPath];
    if(ipArray == nil){
        ipArray = [NSMutableArray array];
    }
    NSDictionary * dict = @{ip:port};
    if(![ipArray containsObject:dict]){
        [ipArray addObject:dict];
        [ipArray writeToFile:self.ip_PortPath atomically:YES];
    }
}

#pragma mark -NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.checkBlock(response.textEncodingName,nil);
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    self.checkBlock(nil,error);
}

-(BOOL)checkOutIfHasCorrenctIp_port{
    
    NSString * str = [self getIPAddress];
    id obj = str;
    if([obj isKindOfClass:[NSNull class]]){
        return NO;
    }else{
        return YES;
    }
    
}

-(void)getNewestIp_PortWhenLoginFailed{
    
    NSArray * array = [[NSArray alloc]initWithContentsOfFile:self.ip_PortPath];
    NSDictionary * dict = [array lastObject];
    NSString * ipKey = [dict allKeys][0];
    [kUserDefaults setObject:ipKey forKey:IPSTRING];
    [kUserDefaults setObject:[dict objectForKey:ipKey] forKey:PORTSTRING];
}

-(void)sendAppVersionToService{
    
    NSString * ip = [self getIPAddress];
    NSString * urlStr = [NSString stringWithFormat:Send_VersionToService,ip];
    NSString * ID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSDictionary * dict = @{@"imei":ID,@"version":[Common appVersion]};
    [self downloadDataWithUrl:urlStr parm:dict callback:^(id responseObject, NSError *error) {
        //        NSLog(@"%@",error.description);
        //        NSLog(@"%@",responseObject);
    }];
}

-(void)saveSearchText:(NSString *)text{
    
    //缓存搜索历史记录
    NSMutableArray * historyArray = [NSMutableArray arrayWithContentsOfFile:self.history_search_content];
    if(historyArray == nil){
        historyArray = [NSMutableArray array];
    }
    
    NSMutableArray * newArray;
    if(![historyArray containsObject:text]){
        //        [historyArray addObject:text];
        [historyArray insertObject:text atIndex:0];
        //获取数组的最新10个数据
        if(historyArray.count>10){
            NSFileManager * fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:self.history_search_content error:nil];
            
            newArray = [NSMutableArray array];
            for(int i=0;i<10;i++){
                [newArray addObject:historyArray[i]];
            }
            [newArray writeToFile:self.history_search_content atomically:YES];
            return;
        }
        [historyArray writeToFile:self.history_search_content atomically:YES];
    }
}
-(NSMutableArray *)getSearchContent{
    
    return [[NSMutableArray alloc]initWithContentsOfFile:self.history_search_content];
}

-(void)cleanHistorySearch{
    
    NSFileManager * fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:self.history_search_content error:nil];
}

-(NSMutableArray *)getAllServers{
    
    //        NSFileManager * fm = [NSFileManager defaultManager];
    //        [fm removeItemAtPath:self.ip_PortPath error:nil];
    
    NSMutableArray * muArray = [NSMutableArray array];
    NSArray * array = [NSArray arrayWithContentsOfFile:self.ip_PortPath];
    for(NSDictionary * dict in array){
        NSString * key = [[dict allKeys]lastObject];
        NSString * value = [[dict allValues]lastObject];
        NSString * str = [NSString stringWithFormat:@"%@:%@",value,key];
        [muArray addObject:str];
    }
    return muArray;
}

+(void)batar_deleteServerWithIndex:(NSInteger)index{
    
    NetManager * manager = [NetManager shareManager];
    NSMutableArray * array = [NSMutableArray arrayWithContentsOfFile:manager.ip_PortPath];
    [array removeObjectAtIndex:index];
    [array writeToFile:manager.ip_PortPath atomically:YES];
}

+(NSMutableArray *)batar_getAllServers{
    
    NetManager * manager = [NetManager shareManager];
    return [manager getAllServers];
}


+(void)judgeCoderWithCode:(NSString *)code Type:(CoderTypeBlock)block{
    
    NetManager * manager = [NetManager shareManager];
    NSString * url = [NSString stringWithFormat:CODETYPE,[manager getIPAddress]];
    NSDictionary * dict = @{@"key":code};
    [manager downloadDataWithUrl:url parm:dict callback:^(id responseObject, NSError *error) {
        
        NSArray * array = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        if(array.count==0){
            //不存在
            block(CoderTypeFailCoder);
        }else if(array.count == 1){
            block(CoderTypeAccurateType);
        }else{
            block(CoderTypeInaccurateType);
        }
    }];
}

-(void)bt_saveAdvertiseInfo{
    
    NSString * url = [NSString stringWithFormat:AdvertiseUrl,[self getIPAddress]];
    [self downloadDataWithUrl:url parm:nil callback:^(id responseObject, NSError *error) {
        if(error == nil){
            //保存本地
            /*
             action = "<null>";
             actiontype = 2;
             image = fafa5efeaf3cbe3b23b2748d13e629a1;
             isopen = 1;
             showtime = 2;
             */
            NSMutableDictionary * dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
            [NSKeyedArchiver archiveRootObject:dict toFile:self.advertisePath];
            //继续获取图片的二进制
            [self adertiseImg:dict[@"image"]];
        }else{
//            NSLog(@"%@",error.description);
            NSFileManager * fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:self.advertisePath error:nil];
            [fm removeItemAtPath:self.advertiseImgPath error:nil];
        }
    }];
}

-(void)adertiseImg:(NSString *)imgName{
    
    NSString * imgUrl = [NSString stringWithFormat:startImg,[self getIPAddress],imgName];
    [self downloadDataWithUrl:imgUrl parm:nil callback:^(id responseObject, NSError *error) {
        
//       BOOL isOk = [NSKeyedArchiver archiveRootObject:responseObject toFile:self.advertiseImgPath];
//        NSLog(@"isOk----%zi",isOk);
    }];
}

-(NSData *)bt_getAdvertiseInfo{
    
    NSData * imgData = [NSKeyedUnarchiver unarchiveObjectWithFile:self.advertiseImgPath];
    return imgData;
}

-(NSDictionary *)bt_getAdvertiseControlInfo{
    
    NSDictionary * info = [NSKeyedUnarchiver unarchiveObjectWithFile:self.advertisePath];
    return info;
}

+(void)bt_beginTabbarFirstCache:(NSString *)cacheName data:(id)data{
    
    NetManager *manager = [NetManager shareManager];
    //NSFileManager * m = [NSFileManager defaultManager];
    //[m removeItemAtPath:manager.cachePath error:nil];
    
    
    NSMutableArray * array = [NSMutableArray arrayWithContentsOfFile:manager.cachePath];
    if(!array){
        array = [NSMutableArray array];
    }
    
    NSDictionary * dict = @{cacheName:data};
    for(NSDictionary *dict in array){
        NSArray * keys = [dict allKeys];
        if([keys containsObject:cacheName]){
            [array removeObject:dict];
            break;
        }
    }
    [array addObject:dict];
    BOOL isCached = [array writeToFile:manager.cachePath atomically:YES];
    if(isCached){
        JFLog(@"%@",@"缓存成功");
    }else{
        JFLog(@"%@",@"缓存失败");
    }
}

+(BOOL)bt_exsitTabbarFirstCache:(NSString *)cacheName{
    
    NetManager *manager = [NetManager shareManager];
    NSMutableArray * array = [NSMutableArray arrayWithContentsOfFile:manager.cachePath];
    for(NSDictionary * dict in array){
        NSArray *keys = [dict allKeys];
        if([keys containsObject:cacheName]){
            return YES;
            break;
        }
    }
    return NO;
}

+(void)bt_getTabbarFirstCache:(NSString *)cacheName completion:(CacheBlock)block{
 
    NetManager *manager = [NetManager shareManager];
    NSMutableArray * array = [NSMutableArray arrayWithContentsOfFile:manager.cachePath];
    for(NSDictionary *dict in array){
        NSArray *keys = [dict allKeys];
        if([keys containsObject:cacheName]){
            block(dict[cacheName]);
            break;
        }
    }
}

-(NSString *)getScanDBMD5{
    
    NSArray * array = [[self getIPAddress]componentsSeparatedByString:@":"];
    NSString * str = [NSString stringWithFormat:@"%@%@",array[0],array[1]];
    NSArray * array2 = [str componentsSeparatedByString:@"."];
    NSMutableString * muStr = [NSMutableString string];
    [muStr appendString:@"YL"];
    for(NSString * str1 in array2){
        [muStr appendString:str1];
    }
    return muStr;
}
/**
 清空缓存
 */
+(void)bt_removeAllCache{
    
    NSError *error = nil;
    NetManager *manager = [NetManager shareManager];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:manager.cachePath error:&error];
    if(error){
        JFLog(@"%@",error.description);
    }
}

@end
