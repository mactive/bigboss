//
//  ConversationsController.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface ConversationsController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) int unreadMessageCount;

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

- (void)chatWithIdentity:(id)obj;
- (void)contentChanged;
@end
