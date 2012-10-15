//
//  AppNetworkAPIClient.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AFHTTPClient.h"

//@class Channel;

@interface AppNetworkAPIClient : AFHTTPClient

+ (AppNetworkAPIClient *)sharedClient;

//- (void)updateChannelInfo:(Channel *)channel withBlock:(void (^)(NSError *error))block;

@end
