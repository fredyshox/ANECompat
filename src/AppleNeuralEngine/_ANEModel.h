@interface _ANEModel : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic) unsigned long long intermediateBufferHandle;
@property (nonatomic, readonly, copy) NSString *key;
@property (nonatomic, readonly) NSURL *modelURL;
@property (nonatomic) unsigned int perfStatsMask;
@property (nonatomic) unsigned long long programHandle;
@property (nonatomic) BOOL queueDepth;
@property (nonatomic) unsigned long long state;
@property (nonatomic, readonly) unsigned long long string_id;

+ (id)modelAtURL:(id)arg1 key:(id)arg2;
+ (id)modelAtURL:(id)arg1 key:(id)arg2 modelAttributes:(id)arg3;
+ (bool)supportsSecureCoding;

- (id)description;
- (void)encodeWithCoder:(id)arg1;
- (unsigned long long)hash;
- (id)initWithCoder:(id)arg1;
- (id)initWithModelAtURL:(id)arg1 key:(id)arg2 modelAttributes:(id)arg3 standardizeURL:(bool)arg4;
- (unsigned long long)intermediateBufferHandle;
- (bool)isEqual:(id)arg1;
- (bool)isEqualToModel:(id)arg1;
- (id)key;
- (id)keyForBundleID:(id)arg1;
- (id)modelAttributes;
- (id)modelURL;
- (unsigned int)perfStatsMask;
- (id)program;
- (unsigned long long)programHandle;
- (BOOL)queueDepth;
- (void)resetOnUnload;
- (void)setIntermediateBufferHandle:(unsigned long long)arg1;
- (void)setModelAttributes:(id)arg1;
- (void)setPerfStatsMask:(unsigned int)arg1;
- (void)setProgram:(id)arg1;
- (void)setProgramHandle:(unsigned long long)arg1;
- (void)setQueueDepth:(BOOL)arg1;
- (void)setState:(unsigned long long)arg1;
- (unsigned long long)state;
- (unsigned long long)string_id;
- (void)updateModelAttributes:(id)arg1 state:(unsigned long long)arg2;
- (void)updateModelAttributes:(id)arg1 state:(unsigned long long)arg2 programHandle:(unsigned long long)arg3 intermediateBufferHandle:(unsigned long long)arg4 queueDepth:(BOOL)arg5;

@end
