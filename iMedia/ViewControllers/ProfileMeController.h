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

@property (strong, nonatomic) Me *me;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end


