
#import "ZWApiDataRecorder.h"
#import "ZWURLSessionDemux.h"
#import "ZWApiDataStorer.h"
#import <objc/runtime.h>


static NSString *kZWRecursiveRequestFlagProperty = @"com.zw.ApiDataRecorder";



NSArray *protocolClasses() {
    return @[[ZWApiDataRecorder class]];
}

__attribute__((constructor(1100))) void injectSessionProtocolClass() {
    [NSURLProtocol registerClass:NSClassFromString(@"APIDataRecorder")];

    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    Method method = class_getInstanceMethod(cls, @selector(protocolClasses));
    method_setImplementation(method, (IMP)protocolClasses);
}



@interface ZWApiDataRecorder () <NSURLSessionDataDelegate>
@property(nonatomic, strong) NSURLSessionTask *dataTask;
@property(nonatomic, strong) NSURLRequest *aRequest;
@property(nonatomic, strong) NSURLResponse *response;
@property(nonatomic, strong) NSMutableData *cacheData;

@end



static BOOL _useLocalData = NO;
static NSMutableArray *_allApiUrls = nil;
static ZWApiValidateRequest _validateRequest = nil;

@implementation ZWApiDataRecorder
//MARK: setter && getter

+ (void)setUseLocalData:(BOOL)useLocalData {
    _useLocalData = useLocalData;
}

+ (BOOL)useLocalData {
    return _useLocalData;
}

+ (void)setValidateRequest:(ZWApiValidateRequest)validateRequest {
    _validateRequest = validateRequest;
}

+ (ZWApiValidateRequest)validateRequest {
    return _validateRequest;
}

+ (NSMutableArray *)allApiUrls {
    if (!_allApiUrls) {
        _allApiUrls = [NSMutableArray array];
    }
    return _allApiUrls;
}

+ (void)addApiUrl:(NSString *)url {
    [_allApiUrls addObject:url];
}

//MARK: override

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if ([self propertyForKey:kZWRecursiveRequestFlagProperty inRequest:request]) {
        return NO;
    }
    
    if (_validateRequest && _validateRequest(request)) {
        NSLog(@"API data:%@",request.URL.absoluteString);
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    if ([ZWApiDataRecorder useLocalData]) {
        ZWApiDataModel *model = nil;
        //h5请求如果有跨域的时候，将会有连续两个请求发出，第一个是option的，会获取跨域信息，后一个才是实际的数据
        if ([self.request valueForHTTPHeaderField:@"access-control-request-headers"]) {
            NSArray<ZWApiDataModel *> *models = [[ZWApiDataStorer sharedStorer] twoDataModelWithURLString:self.request.URL.absoluteString];
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)models.firstObject.response;
            if (response.allHeaderFields[@"access-control-allow-headers"]) {
                model = models.firstObject;
            }
        } else {
            model = [[ZWApiDataStorer sharedStorer] dataModelWithURLString:self.request.URL.absoluteString];
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)model.response;
            if (response.allHeaderFields[@"access-control-allow-headers"]) {
                model = nil;
            }
        }
        
        if (model.response) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:model.data options:NSJSONReadingAllowFragments error:NULL];
            NSLog(@"Use APIDataModel:%@\n%@", model.response, json);
            
            [self.client URLProtocol:self didReceiveResponse:model.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            if (model.data.length > 0) {
                [self.client URLProtocol:self didLoadData:model.data];
            }
            [self.client URLProtocolDidFinishLoading:self];
            return;
        }

    }
    
    //如果不使用本地接口数据，则从网络下载，此时系统和网络缓存有效
    NSMutableURLRequest *request = [self.request mutableCopy];
    [[self class] setProperty:@YES forKey:kZWRecursiveRequestFlagProperty inRequest:request];
    
    NSLog(@"Request APIDataModel: %@", self.request.URL.absoluteString);
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setValue:@"" forHTTPHeaderField:@"If-None-Match"];
    //其要求回调必须在对应的runloop mode下
    NSMutableArray *calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    
    self.aRequest = request;
    self.dataTask = [[[self class] sharedDemux] dataTaskWithRequest:request delegate:self modes:calculatedModes];
    self.cacheData = [NSMutableData data];
    [self.dataTask resume];
    
    
}

- (void)stopLoading {
    
    if (self.dataTask != nil) {
        [self.dataTask cancel];
        self.dataTask = nil;
    }
}

#pragma mark ZWURLSessionDemux singlton

+ (ZWURLSessionDemux *)sharedDemux
{
    static dispatch_once_t  sOnceToken;
    static ZWURLSessionDemux *sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        config.protocolClasses = @[ self ];//如果使用自定义的session，NSURLSessionConfiguration protocolClasses要传入NSURLProtocol子类
        sDemux = [[ZWURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

#pragma mark NSURLSession delegate callbacks

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    if ([self client] != nil && [self dataTask] == task) {
        
        NSMutableURLRequest *redirectRequest = [newRequest mutableCopy];
        if ([[self class] propertyForKey:kZWRecursiveRequestFlagProperty inRequest:redirectRequest]) {
            [[self class] removePropertyForKey:kZWRecursiveRequestFlagProperty inRequest:redirectRequest];
        }
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
        [self.dataTask cancel];
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if ([self client] != nil && [self dataTask] == dataTask) {
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        completionHandler(NSURLSessionResponseAllow);
        self.response = response;
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if ([self client] != nil && [self dataTask] == dataTask) {
        [[self client] URLProtocol:self didLoadData:data];
        [self.cacheData appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didCompleteWithError:(NSError *)error
{
    if ([self client] != nil && [self dataTask] == dataTask) {
        if (error) {
            [[self client] URLProtocol:self didFailWithError:error];
        } else {

            NSHTTPURLResponse *response = (NSHTTPURLResponse *) [self response];
            if ([response isKindOfClass:[NSHTTPURLResponse class]] && response.statusCode >= 200 && response.statusCode < 300) {

                NSDictionary *json  = [NSJSONSerialization JSONObjectWithData:self.cacheData options:NSJSONReadingAllowFragments error:nil];
                NSLog(@"Do not use APIDataModel:%@\n%@",response, [json debugDescription]);
                [[ZWApiDataStorer sharedStorer] storeData:self.cacheData request:self.aRequest response:response];
            }
            [[self client] URLProtocolDidFinishLoading:self];
        }
    }
    
}
@end
