@interface _ANERequest : NSObject

@property (copy) id completionHandler;
@property (nonatomic, readonly) NSArray *inputArray;
@property (nonatomic, readonly) NSArray *inputIndexArray;
@property (nonatomic, readonly) NSArray *outputArray;
@property (nonatomic, readonly) NSArray *outputIndexArray;
@property (nonatomic, readonly) NSArray *perfStatsArray;
@property (nonatomic, readonly, copy) NSNumber *procedureIndex;

+ (id)requestWithInputs:(id)arg1 inputIndices:(id)arg2 outputs:(id)arg3 outputIndices:(id)arg4 perfStats:(id)arg5 procedureIndex:(id)arg6;
+ (id)requestWithInputs:(id)arg1 inputIndices:(id)arg2 outputs:(id)arg3 outputIndices:(id)arg4 procedureIndex:(id)arg5;
+ (id)requestWithInputs:(id)arg1 inputIndices:(id)arg2 outputs:(id)arg3 outputIndices:(id)arg4 weightsBuffer:(id)arg5 perfStats:(id)arg6 procedureIndex:(id)arg7;
+ (id)requestWithInputs:(id)arg1 inputIndices:(id)arg2 outputs:(id)arg3 outputIndices:(id)arg4 weightsBuffer:(id)arg5 procedureIndex:(id)arg6;

- (id)completionHandler;
- (id)description;
- (id)initWithInputs:(id)arg1 inputIndices:(id)arg2 outputs:(id)arg3 outputIndices:(id)arg4 weightsBuffer:(id)arg5 perfStats:(id)arg6 procedureIndex:(id)arg7;
- (id)inputArray;
- (id)inputIndexArray;
- (id)outputArray;
- (id)outputIndexArray;
- (id)perfStats;
- (id)perfStatsArray;
- (id)procedureIndex;
- (void)setCompletionHandler:(id)arg1;
- (void)setPerfStats:(id)arg1;
- (bool)validate;
- (id)weightsBuffer;

@end
