//
//  ConvenienceMethods.m
//  jiemo
//
//  Created by Li Xiaosi on 12/15/12.
//  Copyright (c) 2012 oyeah. All rights reserved.
//

#import "ConvenienceMethods.h"
#import "MBProgressHUD.h"

@implementation ConvenienceMethods

+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated text:(NSString *)text andHideAfterDelay:(NSTimeInterval)delay
{
    [ConvenienceMethods showHUDAddedTo:view animated:animated text:text detail:nil andHideAfterDelay:delay];
}

+(void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated text:(NSString *)text detail:(NSString *)detail andHideAfterDelay:(NSTimeInterval)delay
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:view animated:animated];
    HUD.mode = MBProgressHUDModeText;
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = text;
    HUD.detailsLabelText = detail;
    [HUD hide:animated afterDelay:delay];
}

+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated customView:(UIView *)customView text:(NSString *)text andHideAfterDelay:(NSTimeInterval)delay
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:view animated:animated];
    HUD.customView = customView;
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = text;
    [HUD hide:animated afterDelay:delay];
}


+ (void)presentDefaultLocalNotificationForNewUserActionWithBadgeNumber:(NSInteger)number
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Ok";
        localNotification.applicationIconBadgeNumber = number;
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.alertBody = [NSString stringWithFormat:T(@"你收到了一条新信息")];
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}
@end
