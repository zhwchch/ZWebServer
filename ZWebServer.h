

#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"
#import "ZWLogger/ZWLogger.h"
#define ZWLog(frmt, ...) ZWLogVerbose(frmt, ##__VA_ARGS__)

@class UIViewController;
/**
  本项目使用苹果官方开源的RoutingHTTPServer（https://opensource.apple.com下OS X Server）
  RoutingHTTPServer会引用第三方库CocoaLumberjack和CocoaAsyncSocket，比较坑！！！如果项目中
  本就引入以上库就需要将本项目中对应的.m文件移除才能使用。
 
  本项目中不得不修改了HTTPConnection.m文件中的webSocketForURI方法和replyToHTTPRequest方法，
  坑爹的苹果没有处理WebSocket（在发现是WebSocket时创建了连接，但是立刻又释放了），也没有任何协议、
  回调或者子类来实现，只能修改源码。
 */

@interface ZWebServer : NSObject
+ (instancetype)sharedInstance;
- (void)startServing;
- (void)stopServing;
- (void)sendMessage:(NSString *)msg;

- (void)addKey:(NSString *)key method:(NSString *)method routeBlock:(RequestHandler)handle;
- (void)setApiDataValidateChecker:(BOOL(^)(NSURLRequest *request))validateRequest;

//跳转到接口数据浏览页面
- (void)gotoApiDataViewController:(UIViewController *)vc;
@end
