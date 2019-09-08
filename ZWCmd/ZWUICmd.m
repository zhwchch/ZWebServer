//
//  ZWUICmd.m
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWUICmd.h"
#import "ZWebServer.h"
#import "RoutingHTTPServer.h"
#import "ZWHtmlDefine.h"
#import <UIKit/UIKit.h>
#import "ZWTools.h"

@implementation ZWUICmd
+ (void)load {
    
    [[ZWebServer sharedInstance] addKey:@"/uis" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        [self getUIDescription:response];
    }];
    
    [[ZWebServer sharedInstance] addKey:@"/uig" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        [self getUIGraph:response];
    }];
    
    [[ZWebServer sharedInstance] addKey:@"/uis/change" method:@"GET" routeBlock:^(RouteRequest *request, RouteResponse *response){
        //query string: obj=0x121e08c10&property=backgroundColor&value=UIColor.whiteColor
        NSDictionary *params = [ZWTools getQueryDict:request.url.query];
        NSLog(@"%@",params);
        id obj = [ZWTools getProperty:params[@"obj"]];
        NSString *propery = params[@"property"];
        NSString *value = [ZWTools getProperty:params[@"value"]];
        
        if (obj) {
            [obj setValue:value forKey:propery];
        }
        [self getUIDescription:response];
        
    }];
}

+ (void)getUIDescription:(RouteResponse *)response {
    void (^getUIs)(void) = ^() {
        NSString *str = [self enumViews:[UIApplication sharedApplication].keyWindow];
        NSLog(@"%@",str);
        NSString *html = [NSString stringWithFormat:[htmlHeader copy],@"iOS UI数据浏览", str];
        [response respondWithString:html];
    };
    [NSThread currentThread].isMainThread ? getUIs()
                                          : dispatch_sync(dispatch_get_main_queue(), getUIs);
}

+ (void)getUIGraph:(RouteResponse *)response {
    void (^getUIs)(void) = ^() {
        NSString *uis = [NSString stringWithFormat:@"[%@]",[self enumGraphViews:[UIApplication sharedApplication].keyWindow]];
        uis = [NSString stringWithFormat:[uiScriptHtml copy], uis];
        NSString *html = [NSString stringWithFormat:[htmlHeader copy],@"iOS UI浏览", uis];
        [response respondWithString:html];
    };
    [NSThread currentThread].isMainThread ? getUIs()
                                          : dispatch_sync(dispatch_get_main_queue(), getUIs);
}

+ (NSString *)enumViews:(UIView *)views {
    static int level = 0;
    NSString *viewStr = @"";
    for (int i = 0; i < level; ++i) {
        viewStr = [viewStr stringByAppendingString:@"&nbsp&nbsp&nbsp&nbsp"];
    }
    viewStr = [viewStr stringByAppendingString:views.description];
    viewStr = [viewStr stringByReplacingOccurrencesOfString:@"<" withString:@"【"];
    viewStr = [viewStr stringByReplacingOccurrencesOfString:@">" withString:@"】"];
    
    NSString *str = [NSString stringWithFormat:[itemTag copy],@"",@"", viewStr];
    
    if (views.subviews.count <= 0) {
        --level;
        return str;
    }
    
    for (UIView *view in views.subviews) {
        ++level;
        str = [str stringByAppendingString:[self enumViews:view]];
    }
    
    if (level > 0) --level;//最后一次不递减
    return str;
}


+ (NSString *)enumGraphViews:(UIView *)views {
    if (views.isHidden) return nil;
    CGRect r = views.frame;
    NSString *text;
    CGFloat fontSize = 0;
    int align = 0;
    if ([views isKindOfClass:[UILabel class]]
        || [views isKindOfClass:[UITextField class]]
        || [views isKindOfClass:[UITextView class]]) {
        text = [views valueForKey:@"text"];
        fontSize = [[views valueForKeyPath:@"font.pointSize"] floatValue];
        align = [[views valueForKey:@"textAlignment"] intValue];
        
    }
    NSString *className = NSStringFromClass([views class]);
    NSString *baseImg;
    if ([views isKindOfClass:[UIImageView class]]) {
        UIImage *img = [views valueForKey:@"image"];
        baseImg = [UIImagePNGRepresentation(img) base64EncodedStringWithOptions:0];
    }
    
    NSString *viewStr = [@"" stringByAppendingFormat:@"{class:'%@',top:%f,left:%f,width:%f,height:%f,text:'%@',fontSize:%f,textAlign:%d,image:'%@'}",className, r.origin.y, r.origin.x, r.size.width, r.size.height, text ?: @"null", fontSize, align, baseImg ?: @"null"];
    
    if (views.subviews.count <= 0) {
        return viewStr;
    }
    
    viewStr = [viewStr stringByAppendingString:@",["];
    for (int i = 0; i < views.subviews.count; ++i) {
        UIView *view = views.subviews[i];
        NSString *str = [self enumGraphViews:view];
        if (str) {
            viewStr = [viewStr stringByAppendingFormat:@"%@,",str];
        }
    }
    return [viewStr stringByAppendingString:@"]"] ;
}

@end
