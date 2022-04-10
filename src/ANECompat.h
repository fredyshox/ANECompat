#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ANECompatStatus) {
    ANECompatStatus_Passed = 0,
    ANECompatStatus_Partial,
    ANECompatStatus_Failed,
    ANECompatStatus_ReadError,
    ANECompatStatus_CompileError,
    ANECompatStatus_InputError,
    ANECompatStatus_PredictError,
    ANECompatStatus_OtherError
};

NSString* ANECompatStatusDescription(ANECompatStatus status);

@interface ANECompatEvaluator : NSObject

- (ANECompatStatus)evaluateModelAtURL:(NSURL *)url;
- (ANECompatStatus)evaluateModel:(MLModel *)model;

@end 

NS_ASSUME_NONNULL_END