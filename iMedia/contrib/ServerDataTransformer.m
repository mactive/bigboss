//
//  ServerDataTransformer.m
//  iMedia
//
//  Created by qian meng on 12-10-30.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ServerDataTransformer.h"

@implementation ServerDataTransformer

+ (NSString *)getNicknameFromServerJSON:(NSString *)jsonData
{
    NSString* name = [jsonData valueForKey:@"nickname"];
    if (name == nil || [name isEqualToString:@""]) {
        return @"placeholder for nil";
    }
}

+ (NSString *)getSignatureFromServerJSON:(NSString *)jsonData
{
    NSString* name = [jsonData valueForKey:@"signature"];
    if (name == nil || [name isEqualToString:@""]) {
        return @"A singnature no singed";
    }
}

+ (NSString *)getAvatarFromServerJSON:(NSString *)jsonData
{
    NSString* name = [jsonData valueForKey:@"avatar"];
    if (name == nil || [name isEqualToString:@""]) {
        return @"http://ww1.sinaimg.cn/bmiddle/48933ee4jw1dydaveb47tj.jpg";
    }
}

+ (NSDate *)getDateFromServerJSON:(NSString *)jsonData
{
    NSString* name = [jsonData valueForKey:@"birthdate"];
    if (name == nil || [name isEqualToString:@""]) {
        return [[NSDate alloc] initWithTimeIntervalSince1970:1320000000];
    }
}

@end
