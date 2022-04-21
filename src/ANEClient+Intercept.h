#import <Foundation/Foundation.h>

@class _ANEClient;
@class _ANEModel;
@class _ANERequest;

@interface NSObject (ANEClientInterceptor)
+ (void)swizzleInterceptorWithInputs:(NSArray<NSString*>*)inputs outputs:(NSArray<NSString*>*)outputs logOutputDirURL:(NSURL*)logOutputDirURL;
+ (void)getInterceptedResultsFullForwardPass:(BOOL*)fullForwardPass anyForwardPass:(BOOL*)anyForwardPass;
+ (void)removeInterceptorIfNeeded;
- (BOOL)doEvaluateModelWithInterceptor:(_ANEModel *)model options:(NSDictionary *)options request:(_ANERequest *)request qos:(dispatch_qos_class_t)qos error:(NSError**)errorPtr;
@end