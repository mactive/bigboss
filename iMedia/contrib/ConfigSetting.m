//
//  ConfigSetting.m
//  iMedia
//
//  Created by Xiaosi Li on 11/27/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ConfigSetting.h"

@implementation ConfigSetting

+ (uint64_t)getDefaultConfig
{
    return CONFIG_PLUGGIN_FRIEND_RECOMMENDATION | CONFIG_PLUGGIN_SHAKE;
}

+ (uint64_t)enableConfig:(uint64_t)config withSetting:(uint64_t)setting
{
    return config | setting;
}

+ (uint64_t)disableConfig:(uint64_t)config withSetting:(uint64_t)setting
{
    return config & (!setting);
}

+ (BOOL)isSettingEnabled:(uint64_t)config withSetting:(uint64_t)setting
{
    return  ((config & setting) == setting);
}

@end
