//
//  User.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "User.h"
#import "XMPPUserCoreDataStorageObject.h"

@implementation User

@synthesize xmpp_user_storageObj;

-(NSString *)displayName
{
    return self.xmpp_user_storageObj.displayName;
}

-(void)setDisplayName:(NSString *)name
{
    self.xmpp_user_storageObj.displayName = name;
}
@end
