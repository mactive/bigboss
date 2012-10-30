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
+ (NSDate *)getDateFromServerJSON:(NSString *)jsonData;


@end
