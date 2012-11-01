//
//  ProfileMeController.h
//  iMedia
//
//  Created by qian meng on 12-10-28.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PassValueDelegate.h"

@class Me;
@class AlbumViewController;

@interface ProfileMeController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,PassValueDelegate>
{
    
}


@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UITableView *infoTableView;

@property (strong, nonatomic) UIView *albumView;
@property (strong, nonatomic) UIView *statusView;
@property (strong, nonatomic) UIView *snsView;
@property (strong, nonatomic) UIView *infoView;

@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UIButton *deleteUserButton;
@property (strong, nonatomic) UIButton *reportUserButton;
@property (strong, nonatomic) UILabel  *nameLabel;

@property (strong, nonatomic) Me *me;
@property (strong, nonatomic) UIBarButtonItem *editProfileButton;

@property (strong, nonatomic) NSMutableArray *albumArray;
@property (strong, nonatomic) NSArray *infoArray;
@property (strong, nonatomic) NSMutableArray *infoDescArray;
@property (strong, nonatomic) AlbumViewController* albumViewController;

@property (strong, nonatomic) UIButton *addAlbumButton;
@property (readwrite, nonatomic) NSUInteger albumCount;

@end


