//
//  ContactDetailController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChatWithUserDelegate;
@class User;

@interface ContactDetailController : UIViewController
{
    User  *_user;
}

@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UILabel  *nameLabel;

@property (strong, nonatomic) User *user;

@property (strong, nonatomic) id <ChatWithUserDelegate> delegate;

@end

@protocol ChatWithUserDelegate <NSObject>

- (void)contactDetailController:(ContactDetailController *)contactDetailController didChatUser:(User *)user;

@end