//
//  ConfigSetting.h
//  iMedia
//
//  Created by Xiaosi Li on 11/27/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONFIG_PLUGGIN_FRIEND_RECOMMENDATION    (1 << 0) // 0...00001
#define CONFIG_PLUGGIN_SHAKE                    (1 << 1) // 0...00010

@interface ConfigSetting : NSObject

+ (uint64_t) getDefaultConfig;

//
// Helper functions that returns the new config value
+ (uint64_t) enableConfig:(uint64_t)config withSetting:(uint64_t)setting;
+ (uint64_t) disableConfig:(uint64_t)config withSetting:(uint64_t)setting;
+ (BOOL) isSettingEnabled:(uint64_t)config withSetting:(uint64_t)setting;

@end
