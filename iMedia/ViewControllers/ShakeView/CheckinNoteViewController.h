//
//  CheckinNoteViewController.h
//  iMedia
//
//  Created by meng qian on 12-11-23.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShakeInfo.h"

@interface CheckinNoteViewController : UITableViewController
@property(nonatomic, strong)ShakeInfo *shakeInfo;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;



@end
