//
//  ContactDetailController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChatWithIdentityDelegate;
@class User;
@class AlbumViewController;


@interface ContactDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate>
{
    User  *_user;
    id    jsonData;
}
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UITableView *infoTableView;

@property (strong, nonatomic) UIView *albumView;
@property (strong, nonatomic) UIView *statusView;
@property (strong, nonatomic) UIView *snsView;
@property (strong, nonatomic) UIView *infoView;
@property (strong, nonatomic) UIView *actionView;

@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UIButton *deleteUserButton;
@property (strong, nonatomic) UIButton *reportUserButton;
@property (strong, nonatomic) UILabel  *nameLabel;

@property (strong, nonatomic) User *user;
@property (strong, nonatomic) id   jsonData;

@property (strong, nonatomic) NSArray *albumArray;
@property (strong, nonatomic) NSArray *infoArray;
@property (strong, nonatomic) NSArray *infoDescArray;
@property (strong, nonatomic) AlbumViewController* albumViewController;


@property (strong, nonatomic) id <ChatWithIdentityDelegate> delegate;

@end

