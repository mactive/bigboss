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


@interface ContactDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate,UIActionSheetDelegate>
{
    User  *_user;
    id    jsonData;
}
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) id   jsonData;


@property (strong, nonatomic) id <ChatWithIdentityDelegate> delegate;

@end

