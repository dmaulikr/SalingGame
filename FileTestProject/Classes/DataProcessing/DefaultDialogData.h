#import <Foundation/Foundation.h>
#import "ByteBuffer.h"

@interface DefaultDialogData : NSObject

@property (nonatomic, readonly) NSString *dialogId;
@property (nonatomic, readonly) int npcType;
@property (nonatomic, readonly) int npcParameter;
@property (nonatomic, readonly) NSString *photoId;
@property (nonatomic, readonly) NSString *dialogName;
@property (nonatomic, readonly) NSString *backgroundId;

-(instancetype)initWithByteBuffer:(ByteBuffer *)buffer;

@end

@interface DefaultDialogDic : NSObject

-(instancetype)initWithByteBuffer:(ByteBuffer *)buffer;

-(DefaultDialogData *)getDefaultDialogById:(NSString *)dialogId;

-(NSDictionary *)getDictionary;

@end