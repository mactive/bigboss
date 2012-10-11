//
//  AppNetworkAPIClient.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AFHTTPClient.h"

@interface AppNetworkAPIClient : AFHTTPClient

+ (AppNetworkAPIClient *)sharedClient;

@end
