
#import <Foundation/Foundation.h>

typedef BOOL(^ZWApiValidateRequest)(NSURLRequest *request);

@interface ZWApiDataRecorder : NSURLProtocol
@property(nonatomic, class) BOOL useLocalData;
@property(nonatomic, class, readonly) NSMutableArray *allApiUrls;
@property(nonatomic, class) ZWApiValidateRequest validateRequest;

@end
