//
//  Me.h
//  iMedia
//
//  Created by Xiaosi Li on 9/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User.h"


@interface Me : User

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;

@end
