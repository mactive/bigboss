//
//  AppNetworkAPIClient.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AFHTTPClient.h"

//@class Channel;

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyJIDPassword;
extern NSString *const kXMPPmyPassword;
extern NSString *const kXMPPmyUsername;


@interface AppNetworkAPIClient : AFHTTPClient

+ (AppNetworkAPIClient *)sharedClient;

//- (void)updateChannelInfo:(Channel *)channel withBlock:(void (^)(NSError *error))block;

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id responseObject, NSError *error))block;
@end
