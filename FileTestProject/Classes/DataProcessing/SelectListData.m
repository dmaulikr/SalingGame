#import "SelectListData.h"
@implementation SelectListDic
{
	NSMutableDictionary *_data;
}

-(instancetype)initWithByteBuffer:(ByteBuffer *)buffer
{
	self = [self init];
	if (self) {
		int amount = [buffer readInt];
		_data = [NSMutableDictionary new];
		for (int i = 0; i < amount; ++i) {
			SelectListData *data = [[SelectListData alloc] initWithByteBuffer:buffer];
			[_data setObject:data forKey:data.selectId];
		}
	}
	return self;
}

-(SelectListData *)getSelectListById:(NSString *)selectId
{
	return [_data objectForKey:selectId];
}

-(NSDictionary *)getDictionary
{
	return _data;
}

@end

@implementation SelectListData

-(instancetype)initWithByteBuffer:(ByteBuffer *)buffer
{
	self = [self init];
	if (self) {
		_selectId = [buffer readString];
		_label = [buffer readString];
		_conditionList = [buffer readString];
	}
	return self;
}

@end