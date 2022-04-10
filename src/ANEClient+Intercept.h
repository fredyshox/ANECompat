#import <Foundation/Foundation.h>

@class _ANEClient;
@class _ANEModel;
@class _ANERequest;

typedef void (^_ANEInterceptorCallback)(BOOL);

@interface NSObject (ANEClientInterceptor)
+ (void)swizzleInterceptorWithInputName:(NSString*)inputName outputName:(NSString*)outputName logOutputDirURL:(NSURL*)logOutputDirURL callback:(_ANEInterceptorCallback)callback;
+ (void)removeInterceptorIfNeeded;
- (BOOL)doEvaluateModelWithInterceptor:(_ANEModel *)model options:(NSDictionary *)options request:(_ANERequest *)request qos:(dispatch_qos_class_t)qos error:(NSError**)errorPtr;
@end