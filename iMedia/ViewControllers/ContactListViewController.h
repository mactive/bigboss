//
//  ContactListViewController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ChatWithIdentity.h"

@class Identity;

@interface ContactListViewController : UITableViewController <NSFetchedResultsControllerDelegate, ChatWithIdentityDelegate,UISearchBarDelegate,UISearchDisplayDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


- (void)contentChanged;
- (id)initWithStyle:(UITableViewStyle)style andManagementContext:(NSManagedObjectContext *)context;


@end



