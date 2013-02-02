//
//  ServerDataTransformer.m
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ServerDataTransformer.h"
#import "SBJson.h"
#import "AppDefs.h"

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
                         T(@"男"),   @"m",
                         T(@"女"),   @"f",
                         nil];
    });
    
    return _sharedClient;
}


+ (NSString *)getNicknameFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"nickname"];
}

+ (NSString *)getSignatureFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"signature"];

}

+ (NSString *)getAvatarFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"avatar"];

}
+ (NSString *)getThumbnailFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"thumbnail"];
}
+ (NSString *)getGUIDFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"guid"];
}
+ (NSString *)getGenderFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"gender"];
}
+ (NSString *)getSelfIntroductionFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"self_introduction"];
}
+ (NSString *)getCareerFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"career"];
}
+ (NSString *)getHometownFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"hometown"];
}
+ (NSString *)getSinaWeiboIDFromServerJSON:(id)jsonData
{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"sina_weibo_id"];
}
+ (NSString *)getAlwaysbeenFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"alwaysbeen"];
}
+ (NSString *)getInterestFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"interest"];
}
+ (NSString *)getSchoolFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"school"];
}
+ (NSString *)getCompanyFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"company"];
}
+ (NSString *)getCellFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"cell"];
}
+ (NSString *)getNodeFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"node_address"];
}
+ (NSString *)getCSContactIDFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"receive_jid"];
}
+ (NSString *)getEPostalIDFromServerJSON:(id)jsonData {
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"jid"];
}
+ (NSString *)getChannelEPostalIDFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"receive_jid"];
}
+ (NSString *)getRealNameFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"true_name"];
}
+ (NSDate *)getBirthdateFromServerJSON:(id)jsonData
{
    NSString *dateStr = [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"birthdate"];
    NSDate *date = [self dateFromNSDateStr:dateStr];
/*    if (date == nil) {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }else{
        return date;
    }*/
    return date;
}
+ (NSDate *)getLastGPSUpdatedFromServerJSON:(id)jsonData
{
    NSString *dateStr = [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"last_gps_updated"];
    return [self dateFromNSDatetimeStr:dateStr];
}

// Company

+ (NSString *)getCompanyIDFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"cid"];
}
+ (NSString *)getServerbotJIDFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"serverbot_jid"];
}
+ (NSString *)getCompanyNameFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"company_name"];
}
+ (NSString *)getLogoFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"logo"];
}
+ (NSString *)getEmailFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"email"];
}
+ (NSString *)getWebsiteFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"website"];
}
+ (NSString *)getDescriptionFromServerJSON:(id)jsonData{
    return [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"description"];
}
+ (NSNumber *)getPrivateFromServerJSON:(id)jsonData{
    NSString *privateString = [ServerDataTransformer getStringObjFromServerJSON:jsonData byName:@"private"];
    if ([privateString isEqualToString:@"False"] || [privateString isEqualToString:@"0"]) {
        return [NSNumber numberWithBool:NO];
    }else if ([privateString isEqualToString:@"True"] || [privateString isEqualToString:@"1"]){
        return [NSNumber numberWithBool:YES];
    }else{
        return [NSNumber numberWithBool:NO];
    }
}

+(NSString *)getStringObjFromServerJSON:(id)jsonData byName:(id)name
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
