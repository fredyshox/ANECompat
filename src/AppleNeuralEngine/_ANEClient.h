@interface _ANEClient : NSObject

+ (id)sharedConnection;
+ (id)sharedPrivateConnection;

- (bool)beginRealTimeTask;
- (bool)compileModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (bool)compiledModelExistsFor:(id)arg1;
- (bool)compiledModelExistsMatchingHash:(id)arg1;
- (id)conn;
- (bool)doEvaluateDirectWithModel:(id)arg1 options:(id)arg2 request:(id)arg3 qos:(unsigned int)arg4 error:(id*)arg5;
- (bool)doLoadModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (bool)doUnloadModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (bool)echo:(id)arg1;
- (bool)endRealTimeTask;
- (bool)evaluateRealTimeWithModel:(id)arg1 options:(id)arg2 request:(id)arg3 error:(id*)arg4;
- (bool)evaluateWithModel:(id)arg1 options:(id)arg2 request:(id)arg3 qos:(unsigned int)arg4 error:(id*)arg5;
- (id)initWithRestrictedAccessAllowed:(bool)arg1;
- (bool)loadModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (bool)loadRealTimeModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (id)priorityQ;
- (void)purgeCompiledModel:(id)arg1;
- (void)purgeCompiledModelMatchingHash:(id)arg1;
- (bool)unloadModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;
- (bool)unloadRealTimeModel:(id)arg1 options:(id)arg2 qos:(unsigned int)arg3 error:(id*)arg4;

@end
