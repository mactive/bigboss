//
//  ConvenienceMethods.h
//  jiemo
//
//  Created by Li Xiaosi on 12/15/12.
//  Copyright (c) 2012 oyeah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConvenienceMethods : NSObject

+(void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated text:(NSString *)text andHideAfterDelay:(NSTimeInterval)delay;
+(void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated customView:(UIView *)customView text:(NSString *)text andHideAfterDelay:(NSTimeInterval)delay;
+(void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated text:(NSString *)text detail:(NSString *)detail andHideAfterDelay:(NSTimeInterval)delay;


// local notification
+(void)presentDefaultLocalNotificationForNewUserActionWithBadgeNumber:(NSInteger)number;
@end
