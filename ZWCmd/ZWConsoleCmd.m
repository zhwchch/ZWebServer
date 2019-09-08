//
//  ZWConsoleCmd.m
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWConsoleCmd.h"
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWHtmlDefine.h"

@implementation ZWConsoleCmd
+ (void)load {
    [[ZWebServer sharedInstance] addKey:@"/console" method:@"GET" routeBlock:^(RouteRequest *request,   RouteResponse *response){
        NSString *html = [NSString stringWithFormat:[htmlHeader copy], @"iOS远程实时日志" , consoleScriptHtml];
        [response respondWithString:html];
    }];
}
@end
