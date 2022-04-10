#import "ANECompat.h"
#import <CoreML/CoreML.h>

#import "ANEClient+Intercept.h"
#import "AppleNeuralEngine/AppleNeuralEngine.h"

@class _ANEClient;

NSString* ANECompatStatusDescription(ANECompatStatus status) {
    switch (status) {
    case ANECompatStatus_Passed:
        return @"Fully compatible";
    case ANECompatStatus_Partial:
        return @"Partial compatibility";
    case ANECompatStatus_Failed:
        return @"Not compatible";
    default:
        return @"Error";
    }
}

@implementation ANECompatEvaluator

- (ANECompatStatus)evaluateModelAtURL:(NSURL *)url {
    if (url == nil || url.path == nil) {
        return ANECompatStatus_ReadError;
    }

    NSError* error = nil;
    NSURL* modelURL = url;
    if (![[url pathExtension] isEqual:@"mlmodelc"]) {
        modelURL = [MLModel compileModelAtURL:url error:&error];
        if (error != nil) {
            NSLog(@"Failed to compile mlmodel: %@", [error localizedDescription]);
            return ANECompatStatus_CompileError;
        }
    }

    MLModelConfiguration* config = [[MLModelConfiguration alloc] init];
    [config setComputeUnits: MLComputeUnitsAll];
    MLModel* model = [MLModel modelWithContentsOfURL:modelURL configuration:config error:&error];
    if (error != nil) {
        NSLog(@"Failed to load mlmodel: %@", [error localizedDescription]);
        return ANECompatStatus_ReadError;
    }

    return [self evaluateModel:model];
}

- (ANECompatStatus)evaluateModel:(MLModel *)model {
    NSError* error = nil;

    NSString* inputName = [[[[model modelDescription] inputDescriptionsByName] allKeys] firstObject];
    NSString* outputName = [[[[model modelDescription] outputDescriptionsByName] allKeys] firstObject];
    
    MLFeatureDescription* inputDescription = [[model modelDescription] inputDescriptionsByName][inputName];
    MLMultiArrayConstraint* inputConstraint = [inputDescription multiArrayConstraint];
    if (inputConstraint == nil) {
        NSLog(@"Something wrong with provided model. Input not multi array.");
        return ANECompatStatus_InputError;
    }

    NSArray<NSNumber*>* inputShape = [inputConstraint shape];
    MLMultiArrayDataType inputType = [inputConstraint dataType];

    MLMultiArray* input = [[MLMultiArray alloc] initWithShape:inputShape
                                                     dataType:inputType
                                                        error:&error];
    [self fillMultiArrayWithDummyValues: input];
    MLDictionaryFeatureProvider* inputProvider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:@{inputName: input}
                                                                                                   error:&error];

    if (error != nil) {
        NSLog(@"Error while initializing dictionary provider: %@", error.localizedDescription);
        return ANECompatStatus_OtherError;
    }

    dispatch_once_t reportResultOnce = 0;
    __block ANECompatStatus interceptorReturnValue = ANECompatStatus_Failed;
    [_ANEClient swizzleInterceptorWithInputName:inputName outputName:outputName logOutputDirURL:nil callback:^(BOOL result){
        dispatch_once(&reportResultOnce, ^{
            interceptorReturnValue = (result) ? ANECompatStatus_Passed : ANECompatStatus_Partial;
            NSLog(@"ANEClient callback with status: %d", interceptorReturnValue);
        });
    }];

    [model predictionFromFeatures:inputProvider 
                          options:[[MLPredictionOptions alloc] init] 
                            error:&error];
    [_ANEClient removeInterceptorIfNeeded];
    if (error != nil) {
        NSLog(@"Error while running prediction: %@", error.localizedDescription);
        return ANECompatStatus_PredictError;
    }

    NSLog(@"Completed with status: %@ (%d)", ANECompatStatusDescription(interceptorReturnValue), interceptorReturnValue);

    return interceptorReturnValue;
}

- (void)fillMultiArrayWithDummyValues:(MLMultiArray *) array {
    NSUInteger totalElemCount = 1;
    NSUInteger channelCount = [[array.shape lastObject] unsignedIntegerValue]; 
    for (NSNumber* n in array.shape) {
        totalElemCount *= [n unsignedIntegerValue];
    }

    NSUInteger value = 1; 
    for (NSUInteger i = 0; i < totalElemCount; i++) {
        [array setObject: @((float) value) atIndexedSubscript: i];
        value = ((value + 1) % (channelCount + 1));
        if (value == 0) {
            value++;
        }
    }
}

@end 
