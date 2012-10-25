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


#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define ROW_HEIGHT 60

@interface ConversationsController ()
{
    ChatDetailController *_detailController;
}

// Notication to receive new message
- (void)newMessageReceived:(NSNotification *)notification;

@end

@implementation ConversationsController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;


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
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"lastMessageSentDate" ascending:YES];
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

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    NSLog(@"you slided");
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
    _detailController.conversation = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    _detailController.managedObjectContext = self.managedObjectContext;
    [_detailController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:_detailController animated:YES];
  
}

- (void)chatWithIdentity:(id)obj
{
    if ([obj isKindOfClass:[User class]]) {
        User* user = obj;
        NSSet *convs = user.conversations;
        NSEnumerator *enumerator = [convs objectEnumerator];
        Conversation *obj ;
        BOOL conversationFound = NO;
        while (obj = [enumerator nextObject]) {
            if ([obj.users count] == 1) {
                _detailController.conversation = obj;
                conversationFound = YES;
                break;
            }
        }
    
        if (conversationFound == NO) {
            _detailController.conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
            [_detailController.conversation addUsersObject:user];
        }
    } else if ([obj isKindOfClass:[Channel class]]) {
        Channel *channel = obj;
        if (channel.conversation == nil) {
            channel.conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:self.managedObjectContext];
        }
        _detailController.conversation = channel.conversation;

    }
    
    _detailController.managedObjectContext = self.managedObjectContext;
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.navigationController pushViewController:_detailController animated:YES];
}

#pragma mark -
#pragma mark Configuring table view cells

#define NAME_TAG 1
#define TIME_TAG 2
#define IMAGE_TAG 3
#define SUMMARY_TAG 4

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 150.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 14.0
#define LABEL_HEIGHT 25.0
#define MESSAGE_LABEL_HEIGHT 15.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH_OFFEST 16.0

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
    avatarImage.image = [UIImage imageNamed:@"face_2.png"];
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
	[cell.contentView addSubview:label];
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];

	// Create a label for the message.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, ROW_HEIGHT - (IMAGE_SIDE / 2.0), MIDDLE_COLUMN_WIDTH, MESSAGE_LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentCenter;
    label.textColor = RGBCOLOR(157, 157, 157);
    label.backgroundColor = RGBCOLOR(248, 248, 248);

    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:3.0];
	[cell.contentView addSubview:label];

    rect = CGRectMake(RIGHT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0 + 5 , 15, 15);
    UIImageView *timeIconView = [[UIImageView alloc] initWithFrame:rect];
    timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
    [cell.contentView addSubview:timeIconView];

    
    // Create a label for the time.
	rect = CGRectMake(RIGHT_COLUMN_OFFSET + 18, (ROW_HEIGHT - IMAGE_SIDE) / 2.0 + 5, RIGHT_COLUMN_WIDTH, 15.0);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TIME_TAG;
	label.font = [UIFont systemFontOfSize:12.0];
	label.textAlignment = UITextAlignmentLeft;
	[cell.contentView addSubview:label];
	label.textColor = RGBCOLOR(140, 140, 140);
    label.backgroundColor = [UIColor clearColor];
    
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
    NSEnumerator *enumerator = [conv.users objectEnumerator];
    User* anUser;
    while (anUser = [enumerator nextObject]) {
        label.text = [label.text stringByAppendingFormat:@"%@ ", anUser.displayName];
    }
    // set the last msg text
    label = (UILabel *)[cell viewWithTag:SUMMARY_TAG];
    label.text = conv.lastMessageText;
    [label sizeToFit];
    [label setFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width + SUMMARY_WIDTH_OFFEST, label.frame.size.height)];
	
	// Set the date
	label = (UILabel *)[cell viewWithTag:TIME_TAG];
	label.text = [conv.lastMessageSentDate timesince];
	
	// Set the image.
	UIImageView *imageView = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
	imageView.image = nil;
}    

- (void)newMessageReceived:(NSNotification *)notification
{
    [self.tableView reloadData];
}
@end
