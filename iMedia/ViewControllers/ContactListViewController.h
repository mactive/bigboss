//
//  ContactListViewController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ContactDetailController.h"
#import "ChatWithIdentity.h"

@interface ContactListViewController : UITableViewController <ChatWithIdentityDelegate>
{
    NSFetchedResultsController *fetchedResultsController;
}


@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableDictionary* contacts_list_fix;
@property (strong, nonatomic) NSMutableArray* contacts_list;

- (void)addUser:(User *)userObject;
- (void)removeUser:(User *)userObject;
- (id)initWithStyle:(UITableViewStyle)style andManagementContext:(NSManagedObjectContext *)context;


@end



