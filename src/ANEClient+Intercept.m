#import "ANEClient+Intercept.h"
#import <IOSurface/IOSurface.h>
#import <objc/runtime.h>

#import "AppleNeuralEngine/AppleNeuralEngine.h"
#import "IOSurface+Description.h"

static char InterceptorKey;

@interface _ANEInterceptor: NSObject 
@property (readonly, nonatomic, strong) NSString* inputName;
@property (readonly, nonatomic, strong) NSString* outputName; 
@property (nonatomic, strong, nullable) NSURL* logOutputDirURL;
- (instancetype)initWithInput:(NSString*)input output:(NSString*)output callback:(_ANEInterceptorCallback)callback;
- (void)notifyWithResult:(BOOL)result;
@end

@implementation _ANEInterceptor {
    _ANEInterceptorCallback _callback;
}

- (instancetype)initWithInput:(NSString*)input output:(NSString*)output callback:(_ANEInterceptorCallback)callback {
    self = [super init];
    if (self) {
        _inputName = input;
        _outputName = output;
        _callback = callback;
    }
    
    return self;
}

- (void)notifyWithResult:(BOOL)result {
    _callback(result);
}
@end

@implementation NSObject (ANEClientInterceptor)
- (BOOL)doEvaluateModelWithInterceptor:(_ANEModel *)model options:(NSDictionary *)options request:(_ANERequest *)request qos:(dispatch_qos_class_t)qos error:(NSError**)errorPtr {
    NSLog(@"Intercepted evaluation of model with key: %@", [model key]);
    _ANEInterceptor* interceptor = objc_getAssociatedObject([self class], &InterceptorKey);
    NSError* error = nil;

    if (interceptor.logOutputDirURL != nil && [[request inputArray] count] != 0) {
        NSURL* inputLogFileURL = [interceptor.logOutputDirURL URLByAppendingPathComponent:@"input_0"];

        IOSurfaceRef surface = (IOSurfaceRef)[[[request inputArray] firstObject] ioSurface]; // get input io surface from _ANEIOSurfaceObject
        void* bytes = IOSurfaceGetBaseAddress(surface);
        size_t size = IOSurfaceGetAllocSize(surface);
        NSData* data = [NSData dataWithBytes:bytes length: size];
        [data writeToURL:inputLogFileURL atomically:NO];

        NSLog(@"Input surface: %@", IOSurfaceDescription(surface));
    }

    NSData* keyData = [[model key] dataUsingEncoding: NSUTF8StringEncoding];
    NSDictionary* parsedKey = [NSJSONSerialization JSONObjectWithData: keyData options: 0 error: &error];
    if (error != nil || parsedKey == nil) {
        NSLog(@"Unable to parse model key!");
    } else {
        NSArray<NSString*>* inputKeys = [parsedKey[@"inputs"] allKeys];
        NSArray<NSString*>* outputKeys = [parsedKey[@"outputs"] allKeys];
        BOOL inputValid = inputKeys.count == 1 && [inputKeys containsObject: interceptor.inputName];
        BOOL outputValid = outputKeys.count == 1 && [outputKeys containsObject: interceptor.outputName];
        [interceptor notifyWithResult: inputValid && outputValid];
    }

    // call yourself, but as implementations are exchanged this is original implementation
    BOOL result = [self doEvaluateModelWithInterceptor: model options: options request: request qos: qos error: errorPtr];
    if (interceptor.logOutputDirURL != nil && [[request outputArray] count] != 0) {
        NSURL* outputLogFileURL = [interceptor.logOutputDirURL URLByAppendingPathComponent:@"output_0"];

        IOSurfaceRef surface = (IOSurfaceRef)[[[request outputArray] firstObject] ioSurface]; // get input io surface from _ANEIOSurfaceObject
        void* bytes = IOSurfaceGetBaseAddress(surface);
        size_t size = IOSurfaceGetAllocSize(surface);
        NSData* data = [NSData dataWithBytes:bytes length: size];
        [data writeToURL:outputLogFileURL atomically:NO];

        NSLog(@"Output surface: %@", IOSurfaceDescription(surface));
    }

    return result;
}

+ (void)swizzleInterceptorWithInputName:(NSString*)inputName outputName:(NSString*)outputName logOutputDirURL:(NSURL*)logOutputDirURL callback:(_ANEInterceptorCallback)callback {
    Class class = [self class];

    SEL originalSelector = @selector(doEvaluateDirectWithModel:options:request:qos:error:);
    SEL swizzledSelector = @selector(doEvaluateModelWithInterceptor:options:request:qos:error:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);

    _ANEInterceptor* interceptor = [[_ANEInterceptor alloc] initWithInput: inputName 
                                                                   output: outputName 
                                                                 callback: callback];
    interceptor.logOutputDirURL = logOutputDirURL;
    objc_setAssociatedObject(class, &InterceptorKey, interceptor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)removeInterceptorIfNeeded {
    Class class = [self class];
    if (objc_getAssociatedObject(class, &InterceptorKey) == nil) {
        // nothing to do swizzling was not performed
        return;
    }

    SEL originalSelector = @selector(doEvaluateDirectWithModel:options:request:qos:error:);
    SEL swizzledSelector = @selector(doEvaluateModelWithInterceptor:options:request:qos:error:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    // exchange implementations once again, back to the original form
    method_exchangeImplementations(originalMethod, swizzledMethod);

    objc_removeAssociatedObjects(class);
}
@end