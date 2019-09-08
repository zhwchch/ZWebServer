
#import <Foundation/Foundation.h>

@interface ZWApiDataModel : NSObject
@property(nonatomic, strong) NSData *data;
@property(nonatomic, strong) NSURLRequest *request;
@property(nonatomic, strong) NSURLResponse *response;
@end


@interface ZWApiDataStorer : NSObject
+ (instancetype)sharedStorer;

- (void)storeData:(NSData *)cacheData request:(NSURLRequest *)request response:(id)response;

- (NSArray<NSString *> *)allDataUrls;
- (NSArray<ZWApiDataModel *> *)dataWithURLString:(NSString *)urlString;
- (NSArray<ZWApiDataModel *> *)dataWithURLString:(NSString *)urlString index:(NSInteger *)index;
- (NSArray<ZWApiDataModel *> *)twoDataModelWithURLString:(NSString *)urlString;
- (ZWApiDataModel *)dataModelWithURLString:(NSString *)urlString;

- (void)setDefaultDataWithURLString:(NSString *)urlString index:(NSInteger)index;

@end
