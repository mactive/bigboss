//
//  ChatListViewController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ConversationsController.h"
#import "ChatDetailController.h"
#import "AppDelegate.h"
#import "Message.h"
#import "User.h"
#import "Channel.h"
#import "Conversation.h"
#import "AppDefs.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "UIImageView+AFNetworking.h"
#import "XMPPNetworkCenter.h"
#import "AppNetworkAPIClient.h"
#import "FriendRequest.h"
#import "ModelHelper.h"
#import "Pluggin.h"
#import "ServerDataTransformer.h"
#import "FriendRequestListViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define ROW_HEIGHT 60

#define NAME_TAG 1
#define TIME_TAG 2
#define IMAGE_TAG 3
#define SUMMARY_TAG 4
#define TIME_ICON_TAG 5
#define BADGE_TAG 6

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 150.0

#define RIGHT_COLUMN_OFFSET 250.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 14.0
#define LABEL_HEIGHT 25.0
#define MESSAGE_LABEL_HEIGHT 15.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH_OFFEST 16.0
#define BADGE_WIDTH 16.0

@interface ConversationsController ()
{
    ChatDetailController *_detailController;
}
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong,nonatomic)NSIndexPath *editingIndexPath;
// Notication to receive new message
- (void)newMessageReceived:(NSNotification *)notification;

@end

@implementation ConversationsController
@synthesize titleLabel;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize editingIndexPath;
@synthesize unreadMessageCount;
@synthesize chatDetailController = _detailController;
@synthesize friendRequestArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Chat";
        self.tableView.rowHeight = ROW_HEIGHT;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _detailController = [[ChatDetailController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newMessageReceived:)
                                                     name:NEW_MESSAGE_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(friendRequestReceived:)
                                                     name:NEW_FRIEND_NOTIFICATION object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}



- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = self.managedObjectContext;
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Conversation"
		                                          inManagedObjectContext:moc];
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"lastMessageSentDate" ascending:NO];
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:30];
		
		_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:nil
		                                                                          cacheName:nil];
		[_fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![_fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return _fetchedResultsController;
}

/*
 NSFetchedResultsController delegate methods to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] forIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


#pragma mark - Table view data source
////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[self fetchedResultsController] sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
 	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChatCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Table edit and delete

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    NSLog(@"Clicked delete"); 
    NSLog(@"%@",[[self.fetchedResultsController objectAtIndexPath:indexPath] class]);
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Conversation *deleteRow = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:deleteRow];
//        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{    
    [super setEditing:editing animated:animated];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.editingIndexPath];
    UILabel *label = (UILabel *)[cell viewWithTag:TIME_TAG];
//    UIImageView *imageView = [cell viewWithTag:TIME_ICON_TAG];
    
    if (editing) {
        NSLog(@"editing");
        [label setHidden:YES];
//        [imageView setHidden:YES];
        
    } else {
        NSLog(@"end editing");
        [label setHidden:NO];
//        [imageView setHidden:NO];
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    NSLog(@"you slided");
    self.editingIndexPath = indexPath;
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return  T(@"Delete");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{ 
    return (interfaceOrientation == UIInterfaceOrientationPortrait); 
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation* conv = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (conv.type == IdentityTypePlugginFriendRequest) {
        FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
        controller.friendRequestArray = self.friendRequestArray;
        [self.navigationController pushViewController:controller animated:YES];
        conv.unreadMessagesCount = 0;
        [self updateUnreadBadge];

    } else {
        _detailController.conversation = conv;
        _detailController.managedObjectContext = self.managedObjectContext;
        [_detailController setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:_detailController animated:YES];

    }
}

- (void)chatWithIdentity:(id)obj
{
    if ([obj isKindOfClass:[User class]]) {
        User* user = obj;
        NSSet *convs = user.inConversations;
        NSEnumerator *enumerator = [convs objectEnumerator];
        Conversation *obj ;
        BOOL conversationFound = NO;
        while (obj = [enumerator nextObject]) {
            if ([obj.attendees count] == 1) {
                _detailController.conversation = obj;
                conversationFound = YES;
                break;
            }
        }
    
        if (conversationFound == NO) {
            _detailController.conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
            [_detailController.conversation addAttendeesObject:user];
            _detailController.conversation.type = ConversationTypeSingleUserChat;
        }
    } else if ([obj isKindOfClass:[Channel class]]) {
        Channel *channel = obj;
        if ([channel.ownedConversations count] == 0) {
            Conversation *conv = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
            conv.type = ConversationTypeMediaChannel;
            [channel addOwnedConversationsObject:conv];
        }
        Conversation *conv = [channel.ownedConversations anyObject];
        _detailController.conversation = conv;

    }
    
    _detailController.managedObjectContext = self.managedObjectContext;
    [self.navigationController popToRootViewControllerAnimated:NO];
    [_detailController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:_detailController animated:YES];
}

#pragma mark -
#pragma mark Configuring table view cells



- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    cell.backgroundView = cellBgView;
    
    UIImageView *cellBgSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_highlighted.png"]];
    cell.selectedBackgroundView =  cellBgSelectedView;
    /*
     Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
    */
	UILabel *label;
	CGRect rect;
    
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);

    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = IMAGE_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [cell.contentView addSubview:avatarImage];


	// Create a label for the user name.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    label.highlighted = YES;
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];
	[cell.contentView addSubview:label];

	// Create a label for the message.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, ROW_HEIGHT - (IMAGE_SIDE / 2.0), MIDDLE_COLUMN_WIDTH, MESSAGE_LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(157, 157, 157);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];

    
	// Create a icon for the rect.
    rect = CGRectMake(RIGHT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0 + 5 , 15, 15);
    UIImageView *timeIconView = [[UIImageView alloc] initWithFrame:rect];
    timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
    timeIconView.tag = TIME_ICON_TAG;


    // Create a label for the time.
	rect = CGRectMake(RIGHT_COLUMN_OFFSET + 18, (ROW_HEIGHT - IMAGE_SIDE) / 2.0 + 5, RIGHT_COLUMN_WIDTH, 15.0);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TIME_TAG;
	label.font = [UIFont systemFontOfSize:12.0];
	label.textAlignment = UITextAlignmentLeft;
	label.textColor = RGBCOLOR(140, 140, 140);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];

    
    // Create a label for the badge.
	rect = CGRectMake(LEFT_COLUMN_OFFSET+LEFT_COLUMN_WIDTH+3, 2 ,BADGE_WIDTH ,BADGE_WIDTH );
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = BADGE_TAG;
	label.font = [UIFont boldSystemFontOfSize:9.0f];
	label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = RGBCOLOR(237, 28, 36);
    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:7.0];
    [label.layer setBorderColor:[UIColor whiteColor].CGColor];
    [label.layer setBorderWidth:2.0f];
    label.shadowColor = RGBACOLOR(0, 0, 0, 0.3);
    label.shadowOffset = CGSizeMake(0, 1);
    
    [cell.contentView addSubview:label];
//    [cell.contentView addSubview:timeIconView];
	return cell;
}


- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    /*
	 Cache the formatter. Normally you would use one of the date formatter styles (such as NSDateFormatterShortStyle), but here we want a specific format that excludes seconds.
	 */
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"h:mm a"];
	}
    
    Conversation *conv = [[self fetchedResultsController] objectAtIndexPath:indexPath];

   	UILabel *label;
	
	// Set the conv name.
	label = (UILabel *)[cell viewWithTag:NAME_TAG];
    label.text = @"";
    if (conv.type == ConversationTypePlugginFriendRequest) {
        label.text = conv.ownerEntity.displayName;
    } else if (conv.type == ConversationTypeMediaChannel) {
        label.text = conv.ownerEntity.displayName;
    } else if (conv.type == ConversationTypeSingleUserChat) {
        User* anUser = [conv.attendees anyObject];
        label.text = [label.text stringByAppendingFormat:@"%@ ", anUser.displayName];
    } else {
        DDLogError(@"FIX: unhandled conversation type");
    }
    
    // set the last msg text
    label = (UILabel *)[cell viewWithTag:SUMMARY_TAG];
    label.text = conv.lastMessageText;
    
	// Set the date
	label = (UILabel *)[cell viewWithTag:TIME_TAG];
	label.text = [conv.lastMessageSentDate timesince];
    
    // set badge
    label = (UILabel *)[cell viewWithTag:BADGE_TAG];
    if (conv.unreadMessagesCount == 0) {
        [label removeFromSuperview];
    }else{
        label.text = [NSString stringWithFormat:@"%i",conv.unreadMessagesCount];
//        [label setFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y, [label.text length]*16, label.frame.size.height)];
    }

	// Set the image.
	UIImageView *imageView = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
    if (conv.type == ConversationTypePlugginFriendRequest) {
        [imageView setImage:conv.ownerEntity.thumbnailImage];
    } else if (conv.type == ConversationTypeMediaChannel) {
        if (conv.ownerEntity.thumbnailImage) {
            [imageView setImage:conv.ownerEntity.thumbnailImage];
        } else {
            [[AppNetworkAPIClient sharedClient] loadImage:conv.ownerEntity.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                if (image) {
                    conv.ownerEntity.thumbnailImage = image;
                    [imageView setImage:conv.ownerEntity.thumbnailImage];
                } else {
                    [imageView setImage:[UIImage imageNamed:@"placeholder_company.png"]];
                }
            }];
        }
    } else if (conv.type == ConversationTypeSingleUserChat) {
        User *user = [conv.attendees anyObject];
        if (user.thumbnailImage) {
            [imageView setImage:user.thumbnailImage];
        } else {
            [[AppNetworkAPIClient sharedClient] loadImage:user.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                if (image) {
                    user.thumbnailImage = image;
                    [imageView setImage:user.thumbnailImage];
                } else {
                    [imageView setImage:[UIImage imageNamed:@"placeholder_user.png"]];
                }
            }];
        }
    } else {
        DDLogError(@"FIX: unhandled conversation type");
    }    
}

- (void)newMessageReceived:(NSNotification *)notification
{
    Conversation *conv = [notification object];
    conv.unreadMessagesCount += 1;
    
    self.unreadMessageCount += 1;
    
    self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", self.unreadMessageCount];
    [self.tableView reloadData];
}

- (void) initFriendRequestDictFromDB
{
    // Need to sort the returned value, because
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"FriendRequest" inManagedObjectContext:moc];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"requestDate" ascending:YES];
    NSArray *sortDescArray = [NSArray arrayWithObject:sortDesc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setSortDescriptors:sortDescArray];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    self.friendRequestArray = [NSMutableArray arrayWithArray:array];
}


- (void)friendRequestReceived:(NSNotification *)notification
{
    // init data only when it is used
    if (self.friendRequestArray == nil) {
        [self initFriendRequestDictFromDB];
    }
    
    NSArray *allConvs = _fetchedResultsController.fetchedObjects;
    Conversation* conv = nil;
    for (int i = 0; i < [allConvs count]; i++) {
        Conversation* aConv = [allConvs objectAtIndex:i];
        if (aConv.type == ConversationTypePlugginFriendRequest) {
            conv = aConv;
            break;
        }
    }
    
    if (conv == nil) {
        conv =  [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
        conv.type = ConversationTypePlugginFriendRequest;
        conv.ownerEntity = [self appDelegate].friendRequestPluggin;
    }
    
    NSString* fromJid = [notification object];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: fromJid, @"jid", @"2", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"friend request - get user %@ data received: %@", fromJid, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {
            // filter off duplicates
            BOOL exists = false;
            for (int i = 0; i < [self.friendRequestArray count]; i++) {
                FriendRequest *request = [self.friendRequestArray objectAtIndex:i];
                if ([request.requesterEPostalID isEqualToString:fromJid] &&
                    (request.state == FriendRequestUnprocessed)) {
                    exists = YES;
                }
            }
            if (!exists) {
                FriendRequest *newFriendRequest = [[ModelHelper sharedInstance] newFriendRequestWithEPostalID:fromJid andJson:responseObject];
                MOCSave(self.managedObjectContext);
                [self.friendRequestArray addObject:newFriendRequest];
            }
            
            conv.lastMessageSentDate = [NSDate date];
            conv.unreadMessagesCount += 1;
            conv.lastMessageText = [NSString stringWithFormat:@"%@请求加你为好友", [ServerDataTransformer getNicknameFromServerJSON:responseObject]];
            
            [self contentChanged];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
    }];
    
    
}

- (void)updateUnreadBadge
{
    NSArray *conversations = [_fetchedResultsController fetchedObjects];
    self.unreadMessageCount = 0;
    for (int i = 0 ; i < [conversations count] ; i++) {
        self.unreadMessageCount += ((Conversation *)[conversations objectAtIndex:i]).unreadMessagesCount;
    }
    
    if (self.unreadMessageCount > 0) {
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", self.unreadMessageCount];
    } else {
        self.tabBarItem.badgeValue = nil;
    }
}

- (void)contentChanged
{
    [self updateUnreadBadge];
    [self.tableView reloadData];
}
@end
