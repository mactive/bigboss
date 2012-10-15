//
//  ChatWithIdentity.h
//  iMedia
//
//  Created by Xiaosi Li on 10/15/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ChatWithIdentityDelegate <NSObject>
@optional
- (void)viewController:(UIViewController *)viewController didChatIdentity:(id)obj;

@end
