//
//  ServerDataTransformer.m
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ServerDataTransformer.h"
#import "SBJson.h"


@interface ServerDataTransformer ()

+ (NSString *)convertNumberToStringIfNumber:(id)obj;
+(NSString *)getStringObjFromServerJSON:(NSString *)jsonData byName:(NSString *)name;

@end

@implementation ServerDataTransformer

+ (SBJsonParser *)sharedJSONParser {
    static SBJsonParser *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[SBJsonParser alloc] init];
    });
    
    return _sharedClient;
}


+ (NSString *)getNicknameFromServerJSON:(NSString *)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"nickname"];
}

+ (NSString *)getSignatureFromServerJSON:(NSString *)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"signature"];

}

+ (NSString *)getAvatarFromServerJSON:(NSString *)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"avatar"];

}

+ (NSString *)getGUIDFromServerJSON:(NSString *)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"guid"];
}
+ (NSString *)getGenderFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"gender"];
}
+ (NSString *)getSelfIntroductionFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"self_introduction"];
}
+ (NSString *)getCareerFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"career"];
}
+ (NSString *)getHometownFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"hometown"];
}
+ (NSString *)getCellFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"cell"];
}
+ (NSString *)getNodeFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"node_address"];
}
+ (NSString *)getCSContactIDFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"receive_jid"];
}
+ (NSString *)getEPostalIDFromServerJSON:(NSString *)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"jid"];
}
+ (NSString *)getChannelEPostalIDFromServerJSON:(NSString *)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"receive_jid"];
}
+ (NSString *)getRealNameFromServerJSON:(NSString *)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"true_name"];
}
+ (NSDate *)getBirthdateFromServerJSON:(NSString *)jsonData
{
    NSString *dateStr = [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"birthdate"];
    return [NSDate date];
}



+(NSString *)getStringObjFromServerJSON:(NSString *)jsonData byName:(NSString *)name
{
    return [self convertNumberToStringIfNumber:[jsonData valueForKey:name]];
}

+ (NSString *)convertNumberToStringIfNumber:(id)obj
{
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj stringValue];
    }
    return obj;
}

@end
