//
//  ServerDataTransformer.h
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerDataTransformer : NSObject

+ (NSString *)getNicknameFromServerJSON:(NSString *)jsonData;
+ (NSString *)getSignatureFromServerJSON:(NSString *)jsonData;
+ (NSString *)getAvatarFromServerJSON:(NSString *)jsonData;
+ (NSString *)getThumbnailFromServerJSON:(NSString *)jsonData;
+ (NSString *)getGUIDFromServerJSON:(NSString *)jsonData;
+ (NSString *)getGenderFromServerJSON:(NSString *)jsonData;
+ (NSString *)getSelfIntroductionFromServerJSON:(NSString *)jsonData;
+ (NSString *)getCareerFromServerJSON:(NSString *)jsonData;
+ (NSString *)getHometownFromServerJSON:(NSString *)jsonData;
+ (NSString *)getCellFromServerJSON:(NSString *)jsonData;
+ (NSString *)getNodeFromServerJSON:(NSString *)jsonData;
+ (NSString *)getCSContactIDFromServerJSON:(NSString *)jsonData;
+ (NSString *)getChannelEPostalIDFromServerJSON:(NSString *)jsonData;
+ (NSString *)getEPostalIDFromServerJSON:(NSString *)jsonData;
+ (NSString *)getRealNameFromServerJSON:(NSString *)jsonData;
+ (NSDate *)getBirthdateFromServerJSON:(NSString *)jsonData;

// static dict
+ (NSDictionary *)sexDict;

+ (NSString *)datetimeStrfromNSDate:(NSDate *)date;
+ (NSString *)dateStrfromNSDate:(NSDate *)date;
+ (NSDate *)dateFromNSDatetimeStr:(NSString *)dateStr;

@end
