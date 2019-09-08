#import <Foundation/Foundation.h>

@interface ZWURLProtocolHelper : NSObject
+ (NSString *)MD5:(NSString *)string;

+ (NSString *)cachePath;

+ (BOOL)isImageWithData:(NSData *)data;

+ (NSString *)imageType;
@end
