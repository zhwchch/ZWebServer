

#import <Foundation/Foundation.h>

/**
 * 本类直接从苹果的CustomHTTPProtocol的demo移植过来，
 * 1、需要注意的问题是：session的回调代理队列并发个数最好为1
 * 2、如果使用自定义的session，NSURLSessionConfiguration protocolClasses要传入NSURLProtocol子类;
 * 3、最重要的一点，以下回调：
 *  -URLProtocol:wasRedirectedToRequest:redirectResponse:
 *  -URLProtocol:didReceiveResponse:cacheStoragePolicy:
 *  -URLProtocol:didLoadData:
 *  -URLProtocolDidFinishLoading:
 *  -URLProtocol:didFailWithError:
 *  -URLProtocol:didReceiveAuthenticationChallenge:
 *  -URLProtocol:didCancelAuthenticationChallenge:
 *  必须要和NSURLProtocol和startLoading在同一线程中回调
 *
 * 4、其要求回调必须在对应的runloop mode下
 *  其他关于NSURLProtocol+UIWebView+NSSession需要注意的，请参考苹果官方的CustomHTTPProtocol
 */
@interface ZWURLSessionDemux : NSObject
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration;

@property (atomic, copy,   readonly ) NSURLSessionConfiguration *   configuration;
@property (atomic, strong, readonly ) NSURLSession *                session;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;

@end
