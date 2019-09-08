//
//  ZWMainCmd.m
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWMainCmd.h"
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWHtmlDefine.h"

@implementation ZWMainCmd
+ (void)load {
    [[ZWebServer sharedInstance] addKey:@"/" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        NSArray *array = @[@"status",
                           @"urls/",
                           @"logs",
                           @"console",
                           @"uis",
                           @"uig"];
        NSString *item = @"";
        for (NSString *obj in array) {
            item = [item stringByAppendingFormat:[itemTag copy], request.url.baseURL.absoluteString, obj, obj];
        }
        NSString *html = [NSString stringWithFormat:[htmlHeader copy],@"iOS命令浏览", item];
        
        [response respondWithString:html];
    }];
    
    [[ZWebServer sharedInstance] addKey:@"/status" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        [response respondWithString:@"iOS Device Is Online"];
    }];
}
@end
