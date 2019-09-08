

#import "ZWLogger.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"
#import "ZWebServer.h"

const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation ZWLogFormatter
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setLocale:[NSLocale currentLocale]];
    });
    
    NSTimeInterval timeValue = [logMessage.timestamp timeIntervalSince1970];
    NSString * timeString = [NSString stringWithFormat:@"%.0f",(timeValue - (NSInteger)timeValue) * 1000000];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeValue];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    NSString *log = [NSString stringWithFormat:@"%@.%@ %@ [line:%lu] %@", dateString, timeString, logMessage.function, (unsigned long)logMessage.line, logMessage.message];
    
    
    /*1、同一次log，本函数可能会被多次调用（由DDLog的allLoggers数量决定）
      2、我们需要在每一次log的时候调用sendMessage，把log信息发给客户端，那么就需要过滤掉重复的调用
      3、这里我使用__builtin_return_address获取本函数调用方的retrun address，可以了解调用方的调用地址
         从而确定是否是同一个类在调用（并不关心是哪一个类），这种方式比较简单
      4、当然还有其他办法可以解决，比如使用logMessage的地址集合，但Set，Dict，HashTable等直接装对象的强引用或者弱引用都容易crash
     */
    if (__has_builtin(__builtin_return_address)) {
        static void *oneLoggerAddress;
        if (!oneLoggerAddress) {
            oneLoggerAddress = __builtin_return_address(0);
        }
        if (oneLoggerAddress == __builtin_return_address(0)) {
            [[ZWebServer sharedInstance] sendMessage:log];
        }
    }
    
    return log;
}
@end

static DDFileLogger *ZWLogFileLogger = nil;

__attribute__((constructor(1010))) static void ZWLoggerInit()  {
    
    ZWLogFormatter *formatter = [ZWLogFormatter new];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    
    // 添加DDFileLogger，你的日志语句将写入到一个文件中，默认路径在沙盒的Library/Caches/Logs/目录下，文件名为bundleid+空格+日期.log。
    ZWLogFileLogger = [[DDFileLogger alloc] init];
    ZWLogFileLogger.rollingFrequency = 60 * 60 * 1;
    ZWLogFileLogger.maximumFileSize = 1024 * 1024;
    ZWLogFileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [ZWLogFileLogger setLogFormatter:formatter];
    
    [DDLog addLogger:ZWLogFileLogger];
    
    ZWLogVerbose(@"\n\n###########################################################"
                 @"\n                          APP开始运行\n"
                 @"###########################################################\n\n");
}

NSArray<NSString *>* ZWLogPaths() {
    return ZWLogFileLogger.logFileManager.sortedLogFilePaths;
}

NSString *ZWLogFile(NSString *filePath) {
    /*
     +    URL 中+号表示空格                      %2B
     空格  URL中的空格可以用+号或者编码             %20
     /    分隔目录和子目录                        %2F
     ?    分隔实际的URL和参数                     %3F
     %    指定特殊字符                           %25
     #    表示书签                              %23
     &    URL中指定的参数间的分隔符               %26
     =    URL中指定参数的值                      %3D
     
     这里只需要替换空格
     */
    filePath = [filePath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSString *string = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    return string;
}
