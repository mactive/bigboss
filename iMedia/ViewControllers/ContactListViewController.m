//
//  ContactListViewController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ContactListViewController.h"
#import "AppDelegate.h"
#import "ContactDetailController.h"
#import "ChannelViewController.h"
#import "User.h"
#import "Channel.h"
#import "ConversationsController.h"
#import "AddFriendController.h"
#import "UINavigationBar+Background.h"
#import <QuartzCore/QuartzCore.h>

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
#define ROW_HEIGHT  60.0


@interface ContactListViewController ()

@end

@implementation ContactListViewController

@synthesize managedObjectContext;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Contacts";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewController:(UIViewController *)viewController didChatIdentity:(id)obj
{
    [self dismissModalViewControllerAnimated:YES];
    
    if (obj) {
        [self.tabBarController setSelectedIndex:0];
        [[self appDelegate].conversationController chatWithIdentity:obj];
    }    

}

- (void)add:(id)sender {
    AddFriendController *controller = [[AddFriendController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:controller animated:YES];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View Life Cycles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
        
		NSManagedObjectContext *moc = self.managedObjectContext;
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Identity"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(state = %d)", IdentityStateActive];
        
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:30];
		[fetchRequest setPredicate:predicate];
        
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:nil
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[[self tableView] reloadData];
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
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    
    // Configure the cell...
    id obj  =  [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if ([obj isKindOfClass:[User class]]) {
        User *user = obj;
	
        cell.textLabel.text = user.displayName;
        cell.detailTextLabel.text = user.name;
    } else if ([obj isKindOfClass:[Channel class]]) {
        Channel *channel = obj;
        cell.textLabel.text = channel.node;
        cell.detailTextLabel.text = channel.ePostalID;
    }
    
    return cell;
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuring table view cells
////////////////////////////////////////////////////////////////////////////////////
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 180.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 14.0
#define LABEL_HEIGHT 25.0
#define MESSAGE_LABEL_HEIGHT 15.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH_OFFEST 16.0

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];    
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    cell.backgroundView = cellBgView;
    
    UIImageView *cellBgSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_highlighted.png"]];
    cell.selectedBackgroundView =  cellBgSelectedView;
    
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
    
    return  cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 15.0;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
  
    id obj =  [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if ([obj isKindOfClass:[User class]]) {
        ContactDetailController *detailViewController = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
        detailViewController.user = obj;
        detailViewController.delegate = self;
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else if ([obj isKindOfClass:[Channel class]]) {
        ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
        controller.channel = obj;
        controller.delegate = self;
        [self.navigationController pushViewController:controller animated:YES];
    }
    
       
}

@end
