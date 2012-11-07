//
//  FunctionListViewController.h
//  iMedia
//
//  Created by Xiaosi Li on 10/29/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FunctionListViewController : UIViewController

@property (nonatomic, strong) NSMutableArray* friendRequestArray;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) int newFriendRequestCount;

@end
