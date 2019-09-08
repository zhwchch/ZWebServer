//
//  ZWApiCmd.m
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWApiCmd.h"
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWHtmlDefine.h"
#import "ZWApiDataStorer.h"

@implementation ZWApiCmd
+ (void)load {
    [[ZWebServer sharedInstance] addKey:@"/urls" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        NSArray<NSString *> *array = [[ZWApiDataStorer sharedStorer] allDataUrls];
        
        NSString *item = @"";
        for (NSString *obj in array) {
            item = [item stringByAppendingFormat:[itemTag copy], request.url.absoluteString, obj, obj];
        }
        NSString *html = [NSString stringWithFormat:[htmlHeader copy],@"iOS接口数据浏览", item];
        
        [response respondWithString:html];
    }];
    
    
    [[ZWebServer sharedInstance] addKey:@"/urls/*" method:@"GET" routeBlock:^(RouteRequest *request,   RouteResponse *response){
        NSString *url = request.url.absoluteString;
        NSRange range = [url rangeOfString:@"/urls/"];
        if (range.location > 0) {
            url = [url substringFromIndex:range.location + range.length];
        }
        
        NSArray<ZWApiDataModel *> *models = [[ZWApiDataStorer sharedStorer] dataWithURLString:url];
        NSString *string = @"";
        
        for (ZWApiDataModel *obj in models) {
            string = [string stringByAppendingFormat:@"%@\n", obj.request.description];
            string = [string stringByAppendingFormat:@"%@\n", obj.request.allHTTPHeaderFields.description];
            if (obj.request.HTTPBody) {
                NSDictionary *body = [NSJSONSerialization JSONObjectWithData:obj.request.HTTPBody options:NSJSONReadingAllowFragments error:nil];
                string = [string stringByAppendingFormat:@"%@\n\n\n",body.description];
            }
            string = [string stringByAppendingFormat:@"%@\n",obj.response.description];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:obj.data options:NSJSONReadingMutableLeaves error:nil];
            string = [string stringByAppendingFormat:@"%@\n\n%@\n\n",json.description, line];
        }
        
        [response respondWithString:string encoding:NSUnicodeStringEncoding];
        
    }];
}
@end
