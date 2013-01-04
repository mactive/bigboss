//
//  ContactDetailController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;
@class AlbumViewController;
@class FriendRequest;

@interface ContactDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate,UIActionSheetDelegate>
{
    User  *_user;
    id    jsonData;
}
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) id   jsonData;
@property (strong, nonatomic) NSString *GUIDString; // When push from nearby guid is not in jsondata 
@property (strong, nonatomic) FriendRequest *request;

@end

