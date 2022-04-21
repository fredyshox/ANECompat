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
    ANECompatStatus interceptorReturnValue = ANECompatStatus_Failed;

    NSDictionary<NSString *, MLFeatureDescription *>* inputsByName = [[model modelDescription] inputDescriptionsByName];
    NSDictionary<NSString *, MLFeatureDescription *>* outputsByName = [[model modelDescription] outputDescriptionsByName];
    NSArray<NSString *>* allInputs = [inputsByName allKeys];
    NSArray<NSString *>* allOutputs = [outputsByName allKeys];
    NSMutableDictionary<NSString *, MLFeatureValue *>* inputFeatures = [NSMutableDictionary new];

    NSLog(@"Model inputs: %@, outputs: %@", allInputs, allOutputs);
    for (NSString* inputKey in inputsByName) {
        MLFeatureDescription* inputDescription = inputsByName[inputKey];
        MLFeatureValue* dummyValue = [self dummyFeatureProviderForFeature:inputDescription];
        if (dummyValue == nil) {
            NSLog(@"MLFeatureType %ld is not supported", inputDescription.type);
            return ANECompatStatus_InputError;
        }

        inputFeatures[inputKey] = dummyValue;
    }
    
    MLDictionaryFeatureProvider* inputProvider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:inputFeatures error:&error];
    if (error != nil) {
        NSLog(@"Error while initializing dictionary provider: %@", error.localizedDescription);
        return ANECompatStatus_OtherError;
    }

    [_ANEClient swizzleInterceptorWithInputs:allInputs outputs:allOutputs logOutputDirURL:_logDirURL];

    [model predictionFromFeatures:inputProvider 
                          options:[[MLPredictionOptions alloc] init] 
                            error:&error];

    BOOL fullPass = false, anyPass = false;
    [_ANEClient getInterceptedResultsFullForwardPass:&fullPass anyForwardPass:&anyPass];
    if (fullPass) {
        interceptorReturnValue = ANECompatStatus_Passed;
    } else if (anyPass) {
        interceptorReturnValue = ANECompatStatus_Partial;
    }

    [_ANEClient removeInterceptorIfNeeded];
    if (error != nil) {
        NSLog(@"Error while running prediction: %@", error.localizedDescription);
        return ANECompatStatus_PredictError;
    }

    NSLog(@"Completed with status: %@ (%d)", ANECompatStatusDescription(interceptorReturnValue), interceptorReturnValue);

    return interceptorReturnValue;
}

- (MLFeatureValue*)dummyFeatureProviderForFeature:(MLFeatureDescription*)description {
    if (description.type == MLFeatureTypeMultiArray) {
        MLMultiArray* array = [self dummyMultiArrayInputWithConstraint:description.multiArrayConstraint];
        return [MLFeatureValue featureValueWithMultiArray:array];
    } else if (description.type == MLFeatureTypeImage) {
        CVPixelBufferRef buffer = [self dummyImageInpytWithConstraint:description.imageConstraint];
        return [MLFeatureValue featureValueWithPixelBuffer:buffer];
    } else if (description.type == MLFeatureTypeInt64) {
        return [MLFeatureValue featureValueWithInt64:0];
    } else if (description.type == MLFeatureTypeDouble) {
        return [MLFeatureValue featureValueWithDouble:0.0];
    } else if (description.type == MLFeatureTypeString) {
        return [MLFeatureValue featureValueWithString:@"hello world"];
    } else {
        // TODO MLFeatureTypeSequence, MLFeatureTypeDictionary
        return nil;
    }
}

- (MLMultiArray*)dummyMultiArrayInputWithConstraint:(MLMultiArrayConstraint *)constraint {
    if (constraint == nil) {
        NSLog(@"Provided MLMultiArrayConstraint is nil. Possible that model does not accept multiarray");
        return nil;
    }

    NSError* error = nil;
    NSArray<NSNumber*>* inputShape = [constraint shape];
    MLMultiArrayDataType inputType = [constraint dataType];
    MLMultiArray* array = [[MLMultiArray alloc] initWithShape:inputShape
                                                    dataType:inputType
                                                    error:&error];
    if (error != nil) {
        NSLog(@"Error while creating dummy multiarray: %@", error);
        return nil;
    }

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

    return array;
}

- (CVPixelBufferRef)dummyImageInpytWithConstraint:(MLImageConstraint*)constraint {
    if (constraint == nil) {
        NSLog(@"Provided MLImageConstraint is nil. Possible that model does not accept image");
        return nil;
    }

    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(
        NULL, constraint.pixelsWide, constraint.pixelsHigh, 
        constraint.pixelFormatType, NULL, &pixelBuffer
    );

    return pixelBuffer;
}

@end 
