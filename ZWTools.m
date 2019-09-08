//
//  ZWTools.m
//  ZWebServer
//
//  Created by Wei on 2018/10/19.
//  Copyright © 2018年 Wei. All rights reserved.
//

#import "ZWTools.h"
#define OBJC_POINTER_MASK (0x0000000FFFFFFFF8) // MACH_VM_MAX_ADDRESS 0x1000000000

@implementation ZWTools
+ (NSDictionary *)getQueryDict:(NSString *)query {
    NSArray *queryArr = [query componentsSeparatedByString:@"&"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *obj in queryArr) {
        NSArray *arr = [obj componentsSeparatedByString:@"="];
        if (arr.count > 1) {
            [dict setObject:arr.lastObject forKey:arr.firstObject];
        }
    }
    return [dict copy];
}
+ (NSInteger)numberWithString:(NSString *)string {

    const char *ch = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSUInteger number;
    sscanf(ch, "%lx", &number);
    return (NSInteger)number;
}


+ (id)getValidateAddress:(NSString *)address {
    if (![address hasPrefix:@"0x"]) return nil;
    
    NSUInteger a = [self numberWithString:address];
    void *aPtr = (void *)a;
    if (!(~OBJC_POINTER_MASK & a)) {//TaggedPointer或者无效地址不处理
        __autoreleasing id o = (__bridge id)aPtr;
        return o;
    }
    return nil;
}

+ (id)getProperty:(NSString *)chainProperty {
    if(chainProperty.length <= 0) return nil;
    
    NSArray *chains = [chainProperty componentsSeparatedByString:@"."];
    if (chains.count == 1) return [self getValidateAddress:chainProperty];
    if (chains.count > 1) {
        id obj = [self getValidateAddress:chains.firstObject];
        if (!obj) obj = NSClassFromString(chains.firstObject);

        for (int i = 1; i < chains.count; ++i) {
            obj = [obj valueForKey:chains[i]];
        }
        return obj;
    }
    return nil;
}
@end
