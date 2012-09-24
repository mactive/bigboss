//
//  User.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>


@class XMPPUserCoreDataStorageObject;

@interface User : NSObject

@property (strong, nonatomic) XMPPUserCoreDataStorageObject *xmpp_user_storageObj;
@property (strong, nonatomic) NSString  *displayName;

@end
