//
//  ZWLogCmd.m
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWLogCmd.h"
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWHtmlDefine.h"
#import "ZWLogger.h"

@implementation ZWLogCmd
+ (void)load {
    [[ZWebServer sharedInstance] addKey:@"/logs" method:@"GET" routeBlock:^(RouteRequest *request,   RouteResponse *response){

        NSArray<NSString *> *array = ZWLogPaths();
        
        NSString *item = @"";
        for (NSString *obj in array) {
            item = [item stringByAppendingFormat:[itemTag copy], request.url.absoluteString, obj, obj];
        }
        NSString *html = [NSString stringWithFormat:[htmlHeader copy], @"iOS日志", item];
        
        [response respondWithString:html];
    }];
    
    [[ZWebServer sharedInstance] addKey:@"/logs/*" method:@"GET" routeBlock:^(RouteRequest *request,   RouteResponse *response){
        NSString *url = request.url.absoluteString;
        NSRange range = [url rangeOfString:@"/logs/"];
        if (range.location > 0) {
            url = [url substringFromIndex:range.location + range.length];
        }
        
        [response respondWithString:ZWLogFile(url) encoding:NSUnicodeStringEncoding];
        
    }];
}
@end
