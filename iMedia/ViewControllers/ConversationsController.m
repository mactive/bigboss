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
#import "ConversationTableViewCell.h"
#import "DDLog.h"
#import "ConversationTableViewCell.h"
#import "ConvenienceMethods.h"
#import  <AudioToolbox/AudioServices.h>
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
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
#define BADGE_WIDTH 20.0

@interface ConversationsController ()
{
    ChatDetailController *_detailController;
    SystemSoundID  _newMessageSoundID;
    NSLock*         _lock;
}
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong,nonatomic)NSIndexPath *editingIndexPath;
@property(strong, nonatomic)UIButton *barButton;
@property(strong, nonatomic)UIButton *sidemenuButton;
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
@synthesize sidemenuButton;
@synthesize barButton;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _detailController = [[ChatDetailController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newMessageReceived:)
                                                     name:NEW_MESSAGE_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(friendRequestReceived:)
                                                     name:NEW_FRIEND_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkChangeReceived:)
                                                     name:AFNetworkingReachabilityDidChangeNotification object:nil];

        // playsound
        NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"sms-received" withExtension:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &_newMessageSoundID);
        _lock = [[NSLock alloc] init];
        
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
        
//        self.sidemenuButton = [[UIButton alloc] init];
//        self.sidemenuButton.frame=CGRectMake(0, 0, 50, 29);
//        [self.sidemenuButton setBackgroundImage:[UIImage imageNamed: @"barbutton_sidemenu.png"] forState:UIControlStateNormal];
//        [self.sidemenuButton addTarget:self action:@selector(sidemenuAction) forControlEvents:UIControlEventTouchUpInside];
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.sidemenuButton];
    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popToRootViewControllerAnimated:NO];
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
    
    self.view.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
    
    self.title = T(@"消息");
    self.tableView.rowHeight = ROW_HEIGHT;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUnreadBadgeWithLog:NO];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
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
        {
            ConversationTableViewCell *c1 = [tableView cellForRowAtIndexPath:indexPath];
            Conversation *conv = anObject;
            c1.data = conv;
            break;
            //            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] forIndexPath:indexPath];

        }
            
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
        
    Conversation *conv = [[self fetchedResultsController] objectAtIndexPath:indexPath];

    ConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[ConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }else{
    }
    cell.data = conv;
    return cell;
}


#pragma mark - Table edit and delete

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    DDLogVerbose(@"Clicked delete"); 
    DDLogVerbose(@"%@",[[self.fetchedResultsController objectAtIndexPath:indexPath] class]);
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
    
    ConversationTableViewCell *cell = (ConversationTableViewCell *)[self.tableView cellForRowAtIndexPath:self.editingIndexPath];
    
    if (editing) {
        DDLogVerbose(@"editing");
        [cell setNewTimeShow:NO];
        
    } else {
        DDLogVerbose(@"end editing");
        [cell setNewTimeShow:YES];
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    DDLogVerbose(@"you slided");
    self.editingIndexPath = indexPath;
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return  T(@"删除");
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
        // init data only when it is used
        if (self.friendRequestArray == nil) {
            [self initFriendRequestDictFromDB];
        }
        controller.friendRequestArray = self.friendRequestArray;
        [self.navigationController pushViewController:controller animated:YES];
        conv.unreadMessagesCount = 0;
        [self updateUnreadBadgeWithLog:NO];

    } else {
        
        if (conv.type == IdentityTypeChannel && conv.unreadMessagesCount > 0) {
            //频道 并且有未读消息的才用
            [XFox logEvent:EVENT_CHANNEL_READ withParameters:[NSDictionary dictionaryWithObjectsAndKeys:conv.ownerEntity.guid,@"guid", nil]];
        }

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
            [user addOwnedConversationsObject:_detailController.conversation];
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
    [_detailController setHidesBottomBarWhenPushed:YES];
//    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.navigationController pushViewController:_detailController animated:YES];
}

#pragma mark -
#pragma mark Configuring table view cells

- (void)newMessageReceived:(NSNotification *)notification
{
    Conversation *conv = [notification object];
    conv.unreadMessagesCount += 1;
    
    [self updateUnreadBadgeWithLog:YES];
    
    if (self.unreadMessageCount == 1) {
#warning 应该只在localnoticafation 的时候响 用户自己打开不应该响
        AudioServicesPlayAlertSound (_newMessageSoundID);
    }

    // present local notification if not active
    [ConvenienceMethods presentDefaultLocalNotificationForNewUserActionWithBadgeNumber:self.unreadMessageCount];
    
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
    
    if ([self appDelegate].friendRequestPluggin == nil) {
        [self appDelegate].friendRequestPluggin = [[ModelHelper sharedInstance] findFriendRequestPluggin];
    }
    
    [_lock lock];
    Conversation* conv = nil;
    if ([[self appDelegate].friendRequestPluggin.ownedConversations count] > 0) {
        conv = [[self appDelegate].friendRequestPluggin.ownedConversations anyObject];
    } else {
        conv =  [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
        conv.type = ConversationTypePlugginFriendRequest;
        conv.ownerEntity = [self appDelegate].friendRequestPluggin;
    }
    [_lock unlock];
    
    NSString* fromJid = [notification object];
    BOOL exists = false;
    for (int i = 0; i < [self.friendRequestArray count]; i++) {
        FriendRequest *request = [self.friendRequestArray objectAtIndex:i];
        if ([request.requesterEPostalID isEqualToString:fromJid] &&
            (request.state == FriendRequestUnprocessed)) {
            exists = YES;
        }
    }

    if (!exists) {
        NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: fromJid, @"jid", @"2", @"op", nil];
        
        [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            DDLogVerbose(@"friend request - get user %@ data received", fromJid);
            
            NSString* type = [responseObject valueForKey:@"type"];
            if ([type isEqualToString:@"user"]) {
                // filter off duplicates
                BOOL checkAgain = false;
                for (int i = 0; i < [self.friendRequestArray count]; i++) {
                    FriendRequest *request = [self.friendRequestArray objectAtIndex:i];
                    if ([request.requesterEPostalID isEqualToString:fromJid] &&
                        (request.state == FriendRequestUnprocessed)) {
                        checkAgain = YES;
                    }
                }
                if (!checkAgain) {
                    FriendRequest *newFriendRequest = [[ModelHelper sharedInstance] newFriendRequestWithEPostalID:fromJid andJson:responseObject];
                    [[self appDelegate] saveContextInDefaultLoop];
                    [self.friendRequestArray addObject:newFriendRequest];
                    conv.unreadMessagesCount += 1;
                    
                    [ConvenienceMethods presentDefaultLocalNotificationForNewUserActionWithBadgeNumber:self.unreadMessageCount];
                    
                    [XFox logEvent:EVENT_FRIEND_REQUEST withParameters:[NSDictionary dictionaryWithObjectsAndKeys:newFriendRequest.guid, @"guid", nil]];
                    
                    conv.lastMessageSentDate = [NSDate date];
                    conv.lastMessageText = [NSString stringWithFormat:@"%@请求加你为好友", [ServerDataTransformer getNicknameFromServerJSON:responseObject]];
                    
                    [self contentChanged];
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"error received: %@", error);
        }];
    }
}

- (void)networkChangeReceived:(NSNotification *)notification
{
    NSNumber *status = (NSNumber *)[notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem];
    if (status.intValue == AFNetworkReachabilityStatusReachableViaWiFi || status.intValue == AFNetworkReachabilityStatusReachableViaWWAN) {
        self.title = T(@"消息");
    } else {
        self.title = T(@"消息(未连接)");
    }

}

- (void)updateUnreadBadgeWithLog:(BOOL)isLog
{
    NSArray *conversations = [[self fetchedResultsController] fetchedObjects];
    self.unreadMessageCount = 0;
    for (int i = 0 ; i < [conversations count] ; i++) {
        Conversation *conv = (Conversation *)[conversations objectAtIndex:i];
        self.unreadMessageCount += conv.unreadMessagesCount;
        if (conv.unreadMessagesCount > 0 && isLog) {
            [XFox logEvent:EVENT_CHANNEL_UNREAD withParameters:[NSDictionary dictionaryWithObjectsAndKeys:conv.ownerEntity.guid,@"guid", nil]];
        }
    }
    
    [self appDelegate].unreadMessageCount = self.unreadMessageCount;

}

// just for main menu badge count
- (NSInteger)updateMainMenuUnreadBadge
{
    NSArray *conversations = [[self fetchedResultsController] fetchedObjects];
    self.unreadMessageCount = 0;
    for (int i = 0 ; i < [conversations count] ; i++) {
        Conversation *conv = (Conversation *)[conversations objectAtIndex:i];
        self.unreadMessageCount += conv.unreadMessagesCount;
    }
    return self.unreadMessageCount;
}

- (void)contentChanged
{
    [self updateUnreadBadgeWithLog:NO];
    [self.tableView reloadData];
}
@end
