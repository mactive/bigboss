//
//  ServerDataTransformer.h
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerDataTransformer : NSObject

+ (NSString *)getNicknameFromServerJSON:(id)jsonData;
+ (NSString *)getSignatureFromServerJSON:(id)jsonData;
+ (NSString *)getAvatarFromServerJSON:(id)jsonData;
+ (NSString *)getThumbnailFromServerJSON:(id)jsonData;
+ (NSString *)getGUIDFromServerJSON:(id)jsonData;
+ (NSString *)getGenderFromServerJSON:(id)jsonData;
+ (NSString *)getSelfIntroductionFromServerJSON:(id)jsonData;
+ (NSString *)getCareerFromServerJSON:(id)jsonData;
+ (NSString *)getHometownFromServerJSON:(id)jsonData;
+ (NSString *)getAlwaysbeenFromServerJSON:(id)jsonData;
+ (NSString *)getInterestFromServerJSON:(id)jsonData;
+ (NSString *)getSchoolFromServerJSON:(id)jsonData;
+ (NSString *)getCompanyFromServerJSON:(id)jsonData;
+ (NSString *)getSinaWeiboIDFromServerJSON:(id)jsonData;
+ (NSString *)getCellFromServerJSON:(id)jsonData;
+ (NSString *)getNodeFromServerJSON:(id)jsonData;
+ (NSString *)getCSContactIDFromServerJSON:(id)jsonData;
+ (NSString *)getChannelEPostalIDFromServerJSON:(id)jsonData;
+ (NSString *)getEPostalIDFromServerJSON:(id)jsonData;
+ (NSString *)getRealNameFromServerJSON:(id)jsonData;
+ (NSDate *)getBirthdateFromServerJSON:(id)jsonData;
+ (NSDate *)getLastGPSUpdatedFromServerJSON:(id)jsonData;
// company
+ (NSString *)getCompanyIDFromServerJSON:(id)jsonData;
+ (NSString *)getServerbotJIDFromServerJSON:(id)jsonData;
+ (NSString *)getCompanyNameFromServerJSON:(id)jsonData;
+ (NSString *)getLogoFromServerJSON:(id)jsonData;
+ (NSString *)getEmailFromServerJSON:(id)jsonData;
+ (NSString *)getWebsiteFromServerJSON:(id)jsonData;
+ (NSString *)getDescriptionFromServerJSON:(id)jsonData;
+ (NSNumber *)getPrivateFromServerJSON:(id)jsonData;

// static dict
+ (NSDictionary *)sexDict;

+ (NSString *)datetimeStrfromNSDate:(NSDate *)date;
+ (NSString *)dateStrfromNSDate:(NSDate *)date;
+ (NSDate *)dateFromNSDatetimeStr:(NSString *)dateStr;

+ (NSString *)getStringObjFromServerJSON:(id)jsonData byName:(NSString *)name;

@end
