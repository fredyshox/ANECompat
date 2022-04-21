#import "ANECompat_CApi.h"
#import "ANECompat.h"

int test_ane_compatibility_coreml_model(char* mlmodelPath, char* logDir) {
    NSURL* modelURL = [NSURL fileURLWithPath: [NSString stringWithUTF8String: mlmodelPath]];
    NSURL* logDirURL = (logDir != NULL) ? [NSURL fileURLWithPath: [NSString stringWithUTF8String: logDir]] : nil;
    
    ANECompatEvaluator* evaluator = [[ANECompatEvaluator alloc] init];
    [evaluator setLogDirURL:logDirURL];
    return [evaluator evaluateModelAtURL:modelURL];
}