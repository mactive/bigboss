//
//  ServerDataTransformer.m
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ServerDataTransformer.h"
#import "SBJson.h"

#define DATETIME_FORMATE @"yyyy-MM-dd hh:mm:ss"
#define DATE_FORMATE @"yyyy-MM-dd"

@interface ServerDataTransformer ()

+ (NSString *)convertNumberToStringIfNumber:(id)obj;


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

+ (NSDictionary *)sexDict {
    static NSDictionary *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[NSDictionary alloc] initWithObjectsAndKeys:
                         T(@"男滴"),   @"m",
                         T(@"女滴"),   @"f",
                         nil];
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
+ (NSString *)getThumbnailFromServerJSON:(NSString *)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"thumbnail"];
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
    NSDate *date = [self dateFromNSDateStr:dateStr];
    if (date == nil) {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }else{
        return date;
    }
}
+ (NSDate *)getLastGPSUpdatedFromServerJSON:(NSString *)jsonData
{
    NSString *dateStr = [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"last_gps_updated"];
    return [self dateFromNSDatetimeStr:dateStr];
}



+(NSString *)getStringObjFromServerJSON:(NSString *)jsonData byName:(NSString *)name
{
    id obj = [jsonData valueForKey:name];
    if (obj == nil) return @"";
    
    return [self convertNumberToStringIfNumber:obj];
}

+ (NSString *)convertNumberToStringIfNumber:(id)obj
{
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj stringValue];
    }
    return obj;
}

+ (NSDate *)dateFromNSDatetimeStr:(NSString *)dateStr
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATETIME_FORMATE];
    });
    
    return [dateFormatter dateFromString:dateStr];
}
+ (NSDate *)dateFromNSDateStr:(NSString *)dateStr
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMATE];
    });
    
    return [dateFormatter dateFromString:dateStr];
}


+ (NSString *)datetimeStrfromNSDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATETIME_FORMATE];
    });
    
    if (date == nil) {
        return @"";
    } else {
        return [dateFormatter stringFromDate:date];
    }
}

+ (NSString *)dateStrfromNSDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMATE];
    });
    
    if (date == nil) {
        return @"";
    } else {
        return [dateFormatter stringFromDate:date];
    }

}

@end
