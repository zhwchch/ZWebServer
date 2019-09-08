#import "ZWURLProtocolHelper.h"

#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>


@implementation ZWURLProtocolHelper

+ (NSString *)MD5:(NSString *)string {
    if (!string) {
        return @"";
    }
    const char *cstr = [string cStringUsingEncoding:NSUTF8StringEncoding];
    Byte result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG) strlen(cstr), result);

    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X"
            @"%02X%02X%02X%02X"
            @"%02X%02X%02X%02X"
            @"%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

+ (NSString *)cachePath {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return cachePath;
}

//判断数据是不是图片
+ (BOOL)isImageWithData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
        case 0xFF: //"image/jpeg";
        case 0x89: //"image/png";
        case 0x47: //"image/gif";
        case 0x49:
        case 0x4D: //"image/tiff";
            return [UIImage imageWithData:data] ? YES : NO;
        case 0x52:
            if ([data length] < 12) {
                return NO;
            }

            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return YES;
            }

            return NO;
    }
    return NO;
}

+ (NSString *)imageType {
    return @"|jpeg|jpg|gif|png|tiff|tif|webp|";
}

@end
