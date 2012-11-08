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
#import "Me.h"
#import "ConversationsController.h"
#import "AddFriendController.h"
#import "AddFriendByIDController.h"
#import "UINavigationBar+Background.h"
#import <QuartzCore/QuartzCore.h>
#import "pinyin.h"
#import "POAPinyin.h"
#import "AppNetworkAPIClient.h"
#import "UIImageView+AFNetworking.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
#define ROW_HEIGHT  60.0

@interface ContactListViewController ()

@property (strong, nonatomic) NSMutableDictionary* contacts_list_fix;
@property (strong, nonatomic) NSMutableArray* contacts_list;
@property (strong, nonatomic) NSMutableArray* channelList;

@end

@implementation ContactListViewController

@synthesize managedObjectContext;
@synthesize contacts_list_fix;
@synthesize contacts_list;

- (id)initWithStyle:(UITableViewStyle)style andManagementContext:(NSManagedObjectContext *)context
{
    self = [super initWithStyle:style];
    if (self) {
        self.managedObjectContext = context;
        self.title = T(@"Contacts");
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ADD" style:UIBarButtonItemStyleDone target:self action:@selector(add:)];
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
    AddFriendByIDController *controller  = [[AddFriendByIDController alloc]initWithNibName:nil bundle:nil];
//    AddFriendController *controller = [[AddFriendController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:controller animated:YES];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View Life Cycles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeData];
}

- (void) initializeData
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Identity"
                                                         inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(state = %d)", IdentityStateActive];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    self.contacts_list = [[NSMutableArray alloc] initWithArray:array];
    [self SerializeContacts:self.contacts_list Filter:nil];

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Add Romove user then refresh
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)contentChanged
{
    [self initializeData];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.contacts_list_fix count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    NSString* _section = [[[self.contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL] objectAtIndex:sectionIndex];
    return [[self.contacts_list_fix objectForKey:_section] count];	
}

NSInteger SortIndex(id char1, id char2, void* context)
{
    NSUInteger _char1_location = [NAMEFIRSTLATTER rangeOfString:[char1 substringToIndex:1]].location;
    NSUInteger _char2_location = [NAMEFIRSTLATTER rangeOfString:[char2 substringToIndex:1]].location;
    if (_char1_location < _char2_location) {
        return NSOrderedAscending;
    } else if (_char1_location > _char2_location) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    
    // Configure the cell...
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark POApinyin
////////////////////////////////////////////////////////////////////////////////////
- (void)SerializeContacts:(NSMutableArray *)contacts Filter:(NSString *)filter
{
    NSMutableArray* _section_temp = [NSMutableArray array];
	for (int i = 0; i < 27; i++) {
        [_section_temp addObject:[NSMutableArray array]];
    }
    
    for (int i = 0; i < [contacts count]; i++) {
        Identity *identity = [contacts objectAtIndex:i];
        if ([identity isKindOfClass:[Me class]]) {
            // don't display me
            continue;
        }
        
        // 频道 不去写入排序
        
        if ([identity isKindOfClass:[Channel class]]) {
            [[_section_temp objectAtIndex:0] addObject:identity];
        } else {
            NSLog(@"%@",[identity class]);
            NSString* _pinyin = [POAPinyin quickConvert:identity.displayName];
            NSString* _section = nil;
            NSUInteger _first_letter;
            
            if (_pinyin == nil || [_pinyin isEqualToString:@""]) {
                _first_letter = 26;
            } else {
                _section = [[NSString stringWithFormat:@"%c", [_pinyin characterAtIndex:0] ] uppercaseString];
                
                // if the section is
                if ([_section isEqualToString:@"0"]) {
                    _first_letter = 26;
                }else{
                    _first_letter = [NAMEFIRSTLATTER rangeOfString:[_section substringToIndex:1]].location;
                }
            }
            
            
            if (_first_letter != NSNotFound) {
                            [[_section_temp objectAtIndex:_first_letter] addObject:identity];
            }
        }

    }
    
    self.contacts_list_fix = [[NSMutableDictionary alloc] init];
    
	for (int i = 0; i < 27; i++) {
        if ([[_section_temp objectAtIndex:i] count] > 0) {
            NSLog(@"user %d count %d", i,[[_section_temp objectAtIndex:i] count]);
            [self.contacts_list_fix setObject:[_section_temp objectAtIndex:i] forKey:[[NAMEFIRSTLATTER substringFromIndex:i] substringToIndex:1]];
        }
    }

    
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuring table view cells
////////////////////////////////////////////////////////////////////////////////////
#define NAME_TAG 1
#define SNS_TAG 20
#define AVATAR_TAG 3
#define SUMMARY_TAG 4

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 100.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SNS_SIDE 15.0
#define SUMMARY_WIDTH_OFFEST 30.0
#define SUMMARY_WIDTH 80.0

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];    
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    cell.backgroundView = cellBgView;
    
    UIImageView *cellBgSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_highlighted.png"]];
    cell.selectedBackgroundView =  cellBgSelectedView;
    
    UILabel *label;
    CGRect rect;
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
	CGRect snsRect;
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = AVATAR_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [cell.contentView addSubview:avatarImage];
    
    // Create a label for the user name.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];
    
    // set avatar
    NSMutableArray *snsArray = [[NSMutableArray alloc] init];
    UIImageView *snsImage;
    
    for(int i=0;i<[snsArray count];i++)  
    {  
        snsRect = CGRectMake(MIDDLE_COLUMN_OFFSET + MIDDLE_COLUMN_WIDTH + (SNS_SIDE + 3)* i, (ROW_HEIGHT - SNS_SIDE) / 2.0, SNS_SIDE, SNS_SIDE);
        snsImage = [[UIImageView alloc] initWithFrame:snsRect];
        snsImage.tag = SNS_TAG + i;

        [cell.contentView addSubview:snsImage];
    }
    
    
    // Create a label for the summary
	rect = CGRectMake(self.view.frame.size.width - SUMMARY_WIDTH - SUMMARY_WIDTH_OFFEST , (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, SUMMARY_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentCenter;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.backgroundColor = RGBCOLOR(236, 238, 240);
    
    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:3.0];
	[cell.contentView addSubview:label];    
    
    return  cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    NSString* _section = [[[self.contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL] objectAtIndex:indexPath.section];
    NSArray* _contacts = [contacts_list_fix objectForKey:_section];
        
    const Identity* identity = [_contacts objectAtIndex:indexPath.row];
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);

    
    // set the avatar
    UIImageView *imageView;
    NSString *_nameString;
    CGFloat _labelHeight;
    
    //set avatar
    imageView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
//    [imageView setImage:identity.thumbnailImage];
    [imageView setImageWithURL:[NSURL URLWithString:identity.thumbnailURL] placeholderImage:nil];
    
    //set sns icon
    NSMutableArray *snsArray = [[NSMutableArray alloc] init];
    for (int i =0; i< [snsArray count]; i++) {
        imageView = (UIImageView *)[cell viewWithTag:SNS_TAG + i];
    
        if ([[snsArray objectAtIndex:i] isEqual:@"weibo"]) {
            imageView.image = [UIImage imageNamed:@"sns_icon_weibo.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"douban"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_douban.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"wechat"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_wechat.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"kaixin"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_kaixin.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"renren"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_renren.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"tmweibo"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_tmweibo.png"];
        }
    }

    // set the name text
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    NSString *signature = @"";
    if ([identity isKindOfClass:[User class]]) {
        User *user = (User *)identity;
        _nameString = user.displayName;
        signature = user.signature;
        
    } else if ([identity isKindOfClass:[Channel class]]) {
        Channel *channel = (Channel *)identity;
        _nameString = channel.displayName;
        signature = channel.selfIntroduction;
    } else if ([identity isKindOfClass:[Me class]]) {
        Me *me = (Me *)identity;
        _nameString = me.displayName;
        signature = me.signature;
    }
    
    CGSize labelSize = [_nameString sizeWithFont:nameLabel.font constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (labelSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, _labelHeight, labelSize.width, labelSize.height);
    nameLabel.text = _nameString;
        
    // set the user signature
    UILabel *signatureLabel = (UILabel *)[cell viewWithTag:SUMMARY_TAG];
    
    CGSize signatureSize = [signature sizeWithFont:signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    signatureLabel.text = signature;
    signatureLabel.frame = CGRectMake(280 - signatureSize.width - SUMMARY_PADDING, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    
    if ([signature length] == 0 || signature == nil ) {
        [signatureLabel removeFromSuperview];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 15.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* _section_view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, self.view.frame.size.width, 15)];
    
    UIImageView *_section_bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contactSectionHeader.png"]];
    [_section_bg setFrame:_section_view.bounds];
    
    NSString* _section = [[[contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL] objectAtIndex:section];
    UILabel* _section_text = [[UILabel alloc] initWithFrame:CGRectMake( 10, 0, 50, 15)];
    _section_text.textColor = [UIColor whiteColor];
    _section_text.textAlignment = NSTextAlignmentLeft;
    _section_text.font = [UIFont boldSystemFontOfSize:14.0];
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

/////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
/////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
//    id obj =  [[self fetchedResultsController] objectAtIndexPath:indexPath];
    NSString* _section = [[[self.contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL] objectAtIndex:indexPath.section];
    NSArray* _contacts = [contacts_list_fix objectForKey:_section];
    
    //    id obj  =  [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    id obj = [_contacts objectAtIndex:indexPath.row];
    
    // Update local data with latest server info
    [[AppNetworkAPIClient sharedClient] updateIdentity:(Identity *)obj withBlock:nil];
    
    if ([obj isKindOfClass:[User class]]) {
        ContactDetailController *detailViewController = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
        [detailViewController setHidesBottomBarWhenPushed:YES];
        detailViewController.user = obj;
        detailViewController.delegate = self;
        
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *newarr=[[contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL];
    return newarr;
}

-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSArray *newarr=[[contacts_list_fix allKeys] sortedArrayUsingFunction:SortIndex context:NULL];

    return [newarr indexOfObject:title];
}
  


@end
