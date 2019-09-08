
#import "ZWApiDataStorer.h"
#import "ZWURLProtocolHelper.h"
#import <objc/runtime.h>

@interface ZWApiDataStorer ()
@property(strong, nonatomic) NSString *diskCachePath;
@property(strong, nonatomic) NSString *diskCacheList;
@property(strong, nonatomic) NSMutableSet *cacheList;
@property(strong, nonatomic) dispatch_queue_t ioQueue;
@property(strong, nonatomic) NSFileManager *fileManager;

@end

@implementation ZWApiDataStorer
- (instancetype)init {
    self = [super init];
    if (self) {
        _ioQueue = dispatch_queue_create("com.zw.APIDataRecorder", DISPATCH_QUEUE_SERIAL);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:@"APIDataRecorder"];
        _diskCacheList = [_diskCachePath stringByAppendingPathComponent:@"APIDataList"];
        
        _cacheList = [[self dataUrls] mutableCopy];
        if (!_cacheList) {
            _cacheList = [NSMutableSet set];
        }
        
        dispatch_sync(_ioQueue, ^{
            self.fileManager = [NSFileManager new];
        });
    }
    return self;
}

#pragma  mark - interface

+ (instancetype)sharedStorer {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (void)storeData:(NSData *)cacheData request:(NSURLRequest *)request response:(id)response {
    if (!request || !response) {
        return;
    }
    
    ZWApiDataModel *data = [[ZWApiDataModel alloc] init];
    data.data = [cacheData copy];
    data.request = request;
    data.response = response;
    
    NSString *urlString = data.response.URL.absoluteString;
    
    dispatch_async(_ioQueue, ^{
        if (![self.fileManager fileExistsAtPath:self.diskCachePath]) {
            [self.fileManager createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        NSMutableArray<ZWApiDataModel *> *models;
        NSString *cachePath = [self cacheFilePathWithURLString:urlString];
        if ([self.fileManager fileExistsAtPath:cachePath]) {
            
            models = [[self dataWithURLString:urlString attributes:NULL] mutableCopy];
            if (!models) {
                models = [@[] mutableCopy];
            }
            
            [models addObject:data];
            
        } else {
            models = [NSMutableArray array];
            [models addObject:data];
        }
        
        
        NSData *dataToWrite = [NSKeyedArchiver archivedDataWithRootObject:models];
        [self.fileManager createFileAtPath:cachePath contents:dataToWrite attributes:nil];
        
        [self.cacheList addObject:urlString];
        dataToWrite = [NSKeyedArchiver archivedDataWithRootObject:self.cacheList];
        [self.fileManager createFileAtPath:self.diskCacheList contents:dataToWrite attributes:nil];
        
    });
}

- (NSArray<NSString *> *)allDataUrls {
    return [_cacheList allObjects];
}


- (NSArray<ZWApiDataModel *> *)dataWithURLString:(NSString *)urlString {
    return [self dataWithURLString:urlString attributes:NULL];
}

- (NSArray<ZWApiDataModel *> *)dataWithURLString:(NSString *)urlString index:(NSInteger *)index{
    NSDictionary *attributes;
    
    NSArray<ZWApiDataModel *>* models = [self dataWithURLString:urlString attributes:&attributes];
    if (attributes && index) {
        NSString *indexString = [self getExtendedAttributeForKey:@"SelectedIndex" withPath:[self cacheFilePathWithURLString:urlString]];

        if (indexString) {
            *index = [indexString integerValue];
        } else {
            *index = models.count - 1;
        }
    }
    return models;
}


- (NSArray<ZWApiDataModel *> *)twoDataModelWithURLString:(NSString *)urlString {
    NSDictionary *attributes;
    NSArray<ZWApiDataModel *> *data = [self dataWithURLString:urlString attributes:&attributes];
    if (!data) return nil;
    
    NSString *indexString = [self getExtendedAttributeForKey:@"SelectedIndex" withPath:[self cacheFilePathWithURLString:urlString]];
    NSInteger index;
    if (indexString) {
        index = [indexString integerValue];
    } else {
        index = data.count - 1;
    }
    if (index >= 1) {
        return @[data[index-1],data[index]];
    } else {
        return @[data[index]];
    }
}

- (ZWApiDataModel *)dataModelWithURLString:(NSString *)urlString {
    NSArray<ZWApiDataModel *> *data = [self twoDataModelWithURLString:urlString];
    return data.lastObject;
}

- (void)setDefaultDataWithURLString:(NSString *)urlString index:(NSInteger)index {
    NSString *cachePath = [self cacheFilePathWithURLString:urlString];

    //修改SelectedIndex
    dispatch_async(_ioQueue, ^{
        [self setExtendedAttribute:[NSString stringWithFormat:@"%ld",(long)index] forKey:@"SelectedIndex" withPath:cachePath];
    });
}


#pragma mark - private

- (NSSet<NSString *> *)dataUrls {
    if (_cacheList) return _cacheList;
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_diskCacheList]];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSArray<ZWApiDataModel *> *)dataWithURLString:(NSString *)urlString attributes:(NSDictionary **)attributes{
    NSString *cachePath = [self cacheFilePathWithURLString:urlString];
    NSData *data = nil;
    if (cachePath) {
        data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:cachePath]];
    }
    if (!data) {
        return nil;
    }
    if (attributes) {
        *attributes = [_fileManager attributesOfItemAtPath:cachePath error:nil];
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSString *)cacheFilePathWithURLString:(NSString *)urlString {
    return [_diskCachePath stringByAppendingPathComponent:[ZWURLProtocolHelper MD5:urlString]];
}

- (BOOL)setExtendedAttribute:(NSString*)attribute forKey:(NSString*)key withPath:(NSString*)path{
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:attribute format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSError *error;
    BOOL sucess = [_fileManager setAttributes:@{@"NSFileExtendedAttributes":@{key:data}}
                                                   ofItemAtPath:path error:&error];
    return sucess;
}
- (id)getExtendedAttributeForKey:(NSString*)key withPath:(NSString*)path{
    NSError *error;
    NSDictionary *attributes = [_fileManager attributesOfItemAtPath:path error:&error];
    if (!attributes) {
        return nil;
    }
    NSDictionary *extendedAttributes = [attributes objectForKey:@"NSFileExtendedAttributes"];
    if (!extendedAttributes) {
        return nil;
    }
    NSData *data = [extendedAttributes objectForKey:key];
    
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
    
    return [plist description];
}
@end



@implementation ZWApiDataModel

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned int count;
    Ivar *ivar = class_copyIvarList([self class], &count);
    for (int i = 0; i < count; i++) {
        Ivar iv = ivar[i];
        const char *name = ivar_getName(iv);
        NSString *strName = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:strName];
        if (value) {
            [aCoder encodeObject:value forKey:strName];
        }
    }
    free(ivar);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        unsigned int count = 0;
        Ivar *ivar = class_copyIvarList([self class], &count);
        for (int i = 0; i < count; i++) {
            Ivar var = ivar[i];
            const char *keyName = ivar_getName(var);
            NSString *key = [NSString stringWithUTF8String:keyName];
            id value = [aDecoder decodeObjectForKey:key];
            if (value) {
                [self setValue:value forKey:key];
            }
        }
        free(ivar);
    }
    
    return self;
}

@end
