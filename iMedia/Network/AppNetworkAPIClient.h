//
//  AppNetworkAPIClient.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AFHTTPClient.h"

//@class Channel;
@class Me;
@class Avatar;

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyJIDPassword;
extern NSString *const kXMPPmyPassword;
extern NSString *const kXMPPmyUsername;

#define GET_CONFIG_PATH         @"/base/getconfig"
#define LOGIN_PATH              @"/base/applogin"
#define GET_DATA_PATH           @"/base/getjsondata"
#define POST_DATA_PATH          @"/base/setdata"
#define IMAGE_SERVER_PATH       @"/upload/image"


@interface AppNetworkAPIClient : AFHTTPClient

+ (AppNetworkAPIClient *)sharedClient;

//- (void)updateChannelInfo:(Channel *)channel withBlock:(void (^)(NSError *error))block;

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)storeAvatar:(Avatar *)avatar forMe:(Me *)me andOrder:(int)sequence withBlock:(void (^)(id responseObject, NSError *error))block;
@end
