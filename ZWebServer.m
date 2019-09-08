
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWApiDataStorer.h"
#import "ZWLogger.h"
#import "WebSocket.h"
#import <UIKit/UIKit.h>
#import "ZWHtmlDefine.h"
#import "ZWApiDataRecorder.h"
#import "ZWApiUrlViewController.h"


@interface ZWebServer()
@property(nonatomic, strong) RoutingHTTPServer *server;
@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, strong) NSMutableDictionary *keyRoutes;

@property(nonatomic, assign) BOOL keepAlive;
@end

@implementation ZWebServer


+ (instancetype)sharedInstance {
    static ZWebServer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZWebServer alloc] init];
        instance.queue = dispatch_queue_create("com.zw.APIDataRecorder", DISPATCH_QUEUE_SERIAL);
        instance.keyRoutes = [NSMutableDictionary dictionary];
    });
    
    return instance;
}

- (void)setApiDataValidateChecker:(BOOL(^)(NSURLRequest *request))validateRequest {
    ZWApiDataRecorder.validateRequest = validateRequest;
}


- (void)startServing {
    if (self.keepAlive) return;
    
    [self startHttpServer];
    self.keepAlive = YES;
    dispatch_async(self.queue, ^{
        while (self.keepAlive && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            ;
        }
    });

}


- (void)stopServing {
    if (self.server.isRunning) {
        [self.server stop:YES];
    }
    self.keepAlive = NO;
}


- (void)startHttpServer {

    self.server = [[RoutingHTTPServer alloc] init];
    [self.server setRouteQueue:self.queue];
    [self.server setDefaultHeader:@"Server" value:@"ZW"];
    self.server.delegate = self;

    [self registerKeyRoute];
    
    BOOL success = NO;
    for (int port = 8080; port < 10000; ++port) {
        [self.server setPort:port];
        NSError *error;
        success = [self.server start:&error];
        if (success && !error) {
            NSLog(@"Success to start HTTP Server, port:%d",port);
            break;
        }
    }
    if (!success) {
        NSLog(@"Fail to start HTTP Server ");
    }
}


#pragma mark websocket message

//MARK:待实现
- (void)webSocketDidOpen:(WebSocket *)ws {
    
}

- (void)webSocket:(WebSocket *)ws didReceiveMessage:(NSString *)msg {
    NSLog(@"%@",msg);
}

- (void)webSocketDidClose:(WebSocket *)ws {
    
}

- (void)sendMessage:(NSString *)msg {
    for (WebSocket *ws in [self.server websockets]) {
        msg = [NSString stringWithFormat:@"%@%@%@",@"<pre>",msg, @"</pre>"];
        [ws sendMessage:msg];
    }
}

#pragma mark web url route

- (void)addKey:(NSString *)key method:(NSString *)method routeBlock:(RequestHandler)handle {
    if (!key || !method || !handle) return;
    @synchronized (self) {
        [self.keyRoutes setValue:@[method, handle] forKey:key];
    }
}

- (void)registerKeyRoute {
    @synchronized (self) {
        for (NSString *obj in self.keyRoutes.allKeys) {
            RequestHandler handler = [self.keyRoutes[obj] lastObject];
            NSString *method = [self.keyRoutes[obj] firstObject];
            [self.server handleMethod:method withPath:obj block:handler];
        }
    }
}


//跳转到接口数据浏览页面
- (void)gotoApiDataViewController:(UIViewController *)vc {
    UIViewController *detail = [ZWApiUrlViewController new];
    [vc.navigationController pushViewController:detail animated:YES];
}

@end

