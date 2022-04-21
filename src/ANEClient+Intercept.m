#import "ANEClient+Intercept.h"
#import <IOSurface/IOSurface.h>
#import <objc/runtime.h>

#import "AppleNeuralEngine/AppleNeuralEngine.h"
#import "IOSurface+Description.h"

static char InterceptorKey;

@interface _ANEInterceptor: NSObject 
@property (readonly, nonatomic, strong) NSArray<NSString*>* inputNodes;
@property (readonly, nonatomic, strong) NSArray<NSString*>* outputNodes; 
@property (readwrite, nonatomic, strong) NSMutableSet<NSString*>* visitedNodes;
@property (readwrite, nonatomic, strong) NSMutableSet<NSString*>* toBeVisitedNodes;
@property (nonatomic, strong, nullable) NSURL* logOutputDirURL;
- (instancetype)initWithInputs:(NSArray<NSString*>*)inputs outputs:(NSArray<NSString*>*)outputs;
- (BOOL)modelStatusFullForwardPass;
- (BOOL)modelStatusAnyForwardPass;
@end

@implementation _ANEInterceptor

- (instancetype)initWithInputs:(NSArray<NSString*>*)inputs outputs:(NSArray<NSString*>*)outputs {
    self = [super init];
    if (self) {
        _inputNodes = inputs;
        _outputNodes = outputs;
        _visitedNodes = [NSMutableSet new];
        _toBeVisitedNodes = [NSMutableSet new];

        [_toBeVisitedNodes addObjectsFromArray:inputs];
    }
    
    return self;
}

- (BOOL)modelStatusFullForwardPass {
    BOOL toBeVisitedIsEmpty = _toBeVisitedNodes.count == 0;
    BOOL visitedContainsAllOutputNodes = true;
    for (NSString* node in _outputNodes) {
        visitedContainsAllOutputNodes = visitedContainsAllOutputNodes && [_visitedNodes containsObject:node];
    }

    return toBeVisitedIsEmpty && visitedContainsAllOutputNodes;
}

- (BOOL)modelStatusAnyForwardPass {
    BOOL visitedNodesInInitialState = _visitedNodes.count == 0;
    BOOL toBeVisitedInInitialState = _toBeVisitedNodes.count == _outputNodes.count;
    if (toBeVisitedInInitialState) {
        for (NSString* node in _outputNodes) {
            toBeVisitedInInitialState = toBeVisitedInInitialState && [_toBeVisitedNodes containsObject:node];
        }
    }

    return !visitedNodesInInitialState || !toBeVisitedInInitialState;
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

    NSData* keyData = [[model key] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* parsedKey = [NSJSONSerialization JSONObjectWithData:keyData options:0 error:&error];
    if (error != nil || parsedKey == nil) {
        NSLog(@"Unable to parse model key!");
    } else {
        NSArray<NSString*>* inputKeys = [parsedKey[@"inputs"] allKeys];
        NSArray<NSString*>* outputKeys = [parsedKey[@"outputs"] allKeys];
        for (NSString* outputNode in outputKeys) {
            if (![interceptor.outputNodes containsObject:outputNode]) {
                [interceptor.toBeVisitedNodes addObject:outputNode];
            }
            [interceptor.visitedNodes addObject:outputNode];
        }
        for (NSString* inputNode in inputKeys) {
            if ([interceptor.toBeVisitedNodes containsObject:inputNode]) {
                [interceptor.toBeVisitedNodes removeObject:inputNode];
            }
        }
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

+ (void)getInterceptedResultsFullForwardPass:(BOOL*)fullForwardPass anyForwardPass:(BOOL*)anyForwardPass {
    Class class = [self class];
    _ANEInterceptor* interceptor = objc_getAssociatedObject(class, &InterceptorKey);
    if (interceptor == nil) {
        // interceptor removed or never attached
        return;
    }

    *fullForwardPass = [interceptor modelStatusFullForwardPass];
    *anyForwardPass = [interceptor modelStatusAnyForwardPass];
}

+ (void)swizzleInterceptorWithInputs:(NSArray<NSString*>*)inputs outputs:(NSArray<NSString*>*)outputs logOutputDirURL:(NSURL*)logOutputDirURL {
    Class class = [self class];

    SEL originalSelector = @selector(doEvaluateDirectWithModel:options:request:qos:error:);
    SEL swizzledSelector = @selector(doEvaluateModelWithInterceptor:options:request:qos:error:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);

    _ANEInterceptor* interceptor = [[_ANEInterceptor alloc] initWithInputs:inputs outputs:outputs];
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