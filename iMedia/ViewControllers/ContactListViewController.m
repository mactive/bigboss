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
#import "Me.h"
#import "Channel.h"
#import "Me.h"
#import "Identity.h"
#import "ConversationsController.h"
#import "AddFriendController.h"
#import "AddFriendByIDController.h"
#import <QuartzCore/QuartzCore.h>
#import "pinyin.h"
#import "POAPinyin.h"
#import "AppNetworkAPIClient.h"
#import "UIImageView+AFNetworking.h"
#import "ProfileMeController.h"
#import <CoreData/NSFetchedResultsController.h>
#import "CuteData.h"
#import "ContactTableViewCell.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
#define ROW_HEIGHT  60.0

@interface ContactListViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *filteredListContent;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *barButton;
@property (nonatomic, strong) UIButton *addButton;

@end

@implementation ContactListViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize filteredListContent;
@synthesize searchController;
@synthesize searchBar;
@synthesize barButton;
@synthesize addButton;


- (id)initWithStyle:(UITableViewStyle)style andManagementContext:(NSManagedObjectContext *)context
{
    self = [super initWithStyle:style];
    if (self) {
        _managedObjectContext = context;
/*        _orderPrinciple = [NSArray arrayWithObjects:@"#", @"Z", @"Y", @"X", @"W", @"V", @"U", @"T", @"S", @"R",
                                   @"Q", @"P", @"O", @"N", @"M", @"L", @"K", @"J", @"I", @"H", @"G", @"F", @"E", @"D",
                                   @"C", @"B", @"A", @"&", nil];
        _indexArray = [NSArray arrayWithObjects:@"&", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",
                           @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X",
                           @"Y", @"Z", @"#", nil];*/
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
        
        self.addButton = [[UIButton alloc] init];
        self.addButton.frame=CGRectMake(0, 0, 50, 29);
        [self.addButton setBackgroundImage:[UIImage imageNamed: @"barbutton_add.png"] forState:UIControlStateNormal];
        [self.addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.addButton];
        
        [self.navigationItem setHidesBackButton:YES];


    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popViewControllerAnimated:NO];
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
//    [self dismissViewControllerAnimated:YES completion:^{
//        //
//    }];
    
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[self appDelegate].mainMenuViewController conversationAction];
    if (obj) {
        [[self appDelegate].mainMenuViewController.conversationController chatWithIdentity:obj];
    }
    
//    [[self appDelegate].mainMenuViewController conversationActionWithBlock:^(id responseObject) {
//        if (obj) {
//            [[self appDelegate].mainMenuViewController.conversationController chatWithIdentity:obj];
//        }
//    }];
    
   

}

- (void)add:(id)sender {
    AddFriendByIDController *controller  = [[AddFriendByIDController alloc]initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View Life Cycles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"联系人");

    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        [XFox logError:@"CRITICAL_ERROR" message:@"Contact List DB fetch error" error:error];
    }

    self.view.backgroundColor = BGCOLOR;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

    // restore search settings if they were saved in didReceiveMemoryWarning.
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 50)]; // frame has no effect.
    self.searchBar.delegate = self;
    self.searchBar.tintColor = RGBCOLOR(170, 170, 170);
    self.searchBar.showsCancelButton = NO;
    
    self.tableView.tableHeaderView = self.searchBar;
    
    self.searchController = [[UISearchDisplayController alloc]
                                            initWithSearchBar:self.searchBar
                                            contentsController:self ];
    
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;

    self.filteredListContent = [[NSMutableArray alloc] init];

}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark searchbar delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
    NSArray *allObjects = [self.fetchedResultsController fetchedObjects];
    for (int i = 0 ; i< [allObjects count]; i++  ) {
        
        Identity * obj = [allObjects objectAtIndex:i];
        
        NSRange range = [obj.displayName rangeOfString:searchText];
        
        if (range.location != NSNotFound)
        {
            [self.filteredListContent addObject:obj];
        }
//        NSComparisonResult result = [obj.displayName compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];

    }
		
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchController.searchBar scopeButtonTitles] objectAtIndex:[self.searchController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchController.searchBar text] scope:
     [[self.searchController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Add Romove user then refresh
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)contentChanged
{
    [self.tableView reloadData];
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

////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    Identity* identity;
    
    if (tableView == self.searchController.searchResultsTableView){
        identity = [self.filteredListContent objectAtIndex:indexPath.row];
    }else{
        identity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }

    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[ContactTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setNewInentity:identity];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* _section_view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, self.view.frame.size.width, 20)];
    
    UIImageView *_section_bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contactSectionHeader.png"]];
    [_section_bg setFrame:_section_view.bounds];
    
    NSString* _section = [[[contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL] objectAtIndex:section];
    UILabel* _section_text = [[UILabel alloc] initWithFrame:CGRectMake( 10, 0, 50, 20)];
    _section_text.textColor = [UIColor whiteColor];
    _section_text.textAlignment = NSTextAlignmentLeft;
    _section_text.font = [UIFont boldSystemFontOfSize:15.0];
    _section_text.shadowOffset = CGSizeMake(0, 1);
    _section_text.shadowColor = [UIColor grayColor];
    _section_text.backgroundColor = [UIColor clearColor];
    
    if (section == 0) {
        _section = T(@"频道");
    } 
    _section_text.text = [NSString stringWithFormat:@"%@", _section];
    
    [_section_view addSubview:_section_bg];
    [_section_view addSubview:_section_text];
    return _section_view;
}*/


/////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
/////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id obj;
    if (self.tableView == tableView) {
        obj =  [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else if (self.searchController.searchResultsTableView == tableView) {
        obj = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    
    
    // Update local data with latest server info
    [[AppNetworkAPIClient sharedClient] updateIdentity:(Identity *)obj withBlock:nil];
    
    if ([obj isKindOfClass:[User class]]) {
        ContactDetailController *detailViewController = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];        
        [detailViewController setHidesBottomBarWhenPushed:YES];
        detailViewController.user = (User *)obj;
        detailViewController.GUIDString = [(User *)obj guid];
        
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else if ([obj isKindOfClass:[Me class]]) {
        ProfileMeController *controller = [[ProfileMeController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];        
    } else if ([obj isKindOfClass:[Channel class]]) {
        ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
        [controller setHidesBottomBarWhenPushed:YES];
        controller.channel = obj;
        controller.delegate = self;
        [self.navigationController pushViewController:controller animated:YES];
    }
    
       
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark - right section index 
/////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchController.searchResultsTableView == tableView) {
        return 1;
    } else {
        return [[self.fetchedResultsController sections] count];
    }
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.searchController.searchResultsTableView == tableView) {
        return [self.filteredListContent count];
    } else {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchController.searchResultsTableView == tableView) {
        return T(@"搜索");
    } else {
        NSString* sectionName = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
        unichar nameChar = [sectionName characterAtIndex:0];
        if (nameChar >= 'A' && nameChar <= 'Z') {
            return sectionName;
        } else if (nameChar == '@') {
            return T(@"频道");
        } else {
            return @"#";
        }
    }

    
}

#warning NEED disable editing here
/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the managed object.
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error;
        if (![context save:&error]) {
 
             //Replace this implementation with code to handle the error appropriately.
             
             //abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
 
            DDLogVerbose(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
*/

#pragma mark -
#pragma mark Table view editing


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}


#pragma mark -
#pragma mark Fetched results controller

/*
 Returns the fetched results controller. Creates and configures the controller if necessary.
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Identity" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *authorDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sectionName" ascending:YES];
    NSSortDescriptor *titleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:authorDescriptor, titleDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(state = %d)", IdentityStateActive];
    [fetchRequest setPredicate:predicate];
    
    // Create and initialize the fetch results controller.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"sectionName" cacheName:@"identity"];
    _fetchedResultsController.delegate = self;
    
    // Memory management.

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
            ContactTableViewCell *c1 = [tableView cellForRowAtIndexPath:indexPath];
            Identity *identity = anObject;
            [c1 setNewInentity:identity];
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath forTableView:tableView];
            break;
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


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *sections = [self fetchedResultsController].sections ;
    NSMutableArray *indexTitles = [NSMutableArray arrayWithCapacity:[sections count]];
    [sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id <NSFetchedResultsSectionInfo> sectionInfo = obj;
        if ([sectionInfo.name isEqualToString:@"@"]) {
            [indexTitles setObject:@"&" atIndexedSubscript:idx];
        } else if ([sectionInfo.name isEqualToString:@"["]) {
            [indexTitles setObject:@"#" atIndexedSubscript:idx];
        } else {
            [indexTitles setObject:sectionInfo.name atIndexedSubscript:idx];
        }
    }];
    
    return indexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}


@end
