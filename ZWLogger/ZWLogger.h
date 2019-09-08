

#import <Foundation/Foundation.h>

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"

#ifdef __cplusplus
extern "C" {
#endif
    
extern const int ddLogLevel;
    
extern NSArray<NSString *>* ZWLogPaths(void);
extern NSString* ZWLogFile(NSString *filePath);
    
#ifdef __cplusplus
};
#endif

#define ZWLogError(frmt, ...)    LOG_C_MAYBE(NO, ddLogLevel, LOG_FLAG_ERROR, 1, frmt, ##__VA_ARGS__)
#define ZWLogWarn(frmt, ...)     LOG_C_MAYBE(NO, ddLogLevel, LOG_FLAG_WARN, 1, frmt, ##__VA_ARGS__)
#define ZWLogInfo(frmt, ...)     LOG_C_MAYBE(NO, ddLogLevel, LOG_FLAG_INFO,1, frmt, ##__VA_ARGS__)
#define ZWLogVerbose(frmt, ...)  LOG_MAYBE(NO, ddLogLevel, LOG_FLAG_VERBOSE,1, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)



@interface ZWLogFormatter : NSObject <DDLogFormatter>
@end
