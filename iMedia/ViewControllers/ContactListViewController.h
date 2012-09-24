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

@interface ContactListViewController : UITableViewController <NSFetchedResultsControllerDelegate, ChatWithUserDelegate>
{
    NSFetchedResultsController *fetchedResultsController;
}


@end


