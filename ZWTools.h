//
//  ZWTools.h
//  ZWebServer
//
//  Created by Wei on 2018/10/19.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZWTools : NSObject
+ (NSDictionary *)getQueryDict:(NSString *)query;
+ (id)getValidateAddress:(NSString *)address;
+ (id)getProperty:(NSString *)chainProperty;
@end

NS_ASSUME_NONNULL_END
