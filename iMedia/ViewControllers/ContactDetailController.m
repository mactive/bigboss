//
//  ContactDetailController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ContactDetailController.h"
#import "User.h"
#import "Channel.h"
#import "ChatWithIdentity.h"
#import "ModelHelper.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
#import <QuartzCore/QuartzCore.h>
#import "AlbumViewController.h"

@interface ContactDetailController ()

@end

@implementation ContactDetailController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;
@synthesize deleteUserButton;
@synthesize reportUserButton;
@synthesize nameLabel = _nameLabel;
@synthesize user =_user;
@synthesize delegate = _delegate;
@synthesize jsonData;
@synthesize contentView;

@synthesize albumView;
@synthesize albumArray;
@synthesize albumViewController;

@synthesize statusView;
@synthesize snsView;
@synthesize infoArray;
@synthesize infoDescArray;
@synthesize infoView;
@synthesize infoTableView;
@synthesize actionView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_OFFSET 2.5

#define VIEW_PADDING_LEFT 12
#define VIEW_ALBUM_HEIGHT 160
#define VIEW_STATUS_HEIGHT 15
#define VIEW_SNS_HEIGHT 30
#define VIEW_ACTION_HEIGHT 41
#define VIEW_UINAV_HEIGHT 44

#define VIEW_COMMON_WIDTH 296

- (void)loadView
{
    [super loadView];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT)];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, 600)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);

    
    [self initAlbumView];
    [self initStatusView];
    [self initSNSView];
    [self initInfoView];
    [self initActionView];
    
    [self.view addSubview:self.contentView];

}
////////////////////////////////////////////////////////////////////////////////
#pragma mark -  ablum view
////////////////////////////////////////////////////////////////////////////////

- (void)initAlbumView
{
    self.albumView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, VIEW_ALBUM_HEIGHT)];
    UIImageView *albumViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_image_bg.png"]];
    [self.albumView addSubview:albumViewBg];
    
    UIButton *albumButton;
    
    self.albumArray = [[NSArray alloc] initWithObjects:
                       @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png",
                       @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png",nil ];
    for (int i = 0; i< [albumArray count]; i++) {
        albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [albumButton setImage:[UIImage imageNamed:[albumArray objectAtIndex:i] ] forState:UIControlStateNormal];
        [albumButton setFrame:CGRectMake(VIEW_ALBUM_OFFSET * (i%4*2 + 1) + VIEW_ALBUM_WIDTH * (i%4), VIEW_ALBUM_OFFSET * (floor(i/4)*2+1) + VIEW_ALBUM_WIDTH * floor(i/4), VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH)];
        [albumButton.layer setMasksToBounds:YES];
        [albumButton.layer setCornerRadius:3.0];
        albumButton.tag = i;
        [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.albumView addSubview:albumButton];
    }
    
    [self.contentView addSubview:self.albumView];
    
}

- (void)albumClick:(UIButton *)sender
{
    self.albumViewController = [[AlbumViewController alloc] init];
    self.albumViewController.albumArray = self.albumArray;
    [self.albumViewController setHidesBottomBarWhenPushed:YES];
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:self.albumViewController animated:YES];
    NSLog(@"%d",sender.tag);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - status view
////////////////////////////////////////////////////////////////////////////////


- (void)initStatusView
{
    self.statusView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + 12, VIEW_COMMON_WIDTH, 15)];
    
    // Create a label icon for the sex.
    UIImageView* sexView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"sex_female_bg.png"]];
    [sexView setFrame:CGRectMake(0, 0, 40, 15)];
    
    UILabel* sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 15, 15)];
    [sexLabel setBackgroundColor:[UIColor clearColor]];
    sexLabel.text  = @"18";
    [sexLabel setFont:[UIFont systemFontOfSize:12.0]];
    [sexLabel setTextColor:[UIColor whiteColor]];
    [sexView addSubview:sexLabel];
    
    
    // Create a label icon for the time.
    UIImageView *timeIconView = [[UIImageView alloc] initWithFrame:CGRectMake(210, 0 , 15, 15)];
    timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
    
    UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 0 ,60, 15)];
	timeLabel.font = [UIFont systemFontOfSize:12.0];
	timeLabel.textAlignment = UITextAlignmentLeft;
	timeLabel.textColor = RGBCOLOR(140, 140, 140);
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.text  = @"6 hours ago";
    [timeLabel sizeToFit];
    
    // Create a label icon for the time.
    UIImageView *locationIconView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 0 , 15, 15)];
    locationIconView.image = [UIImage imageNamed:@"location_icon.png"];
    
    UILabel* locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(158, 0 ,40, 15)];
	locationLabel.font = [UIFont systemFontOfSize:12.0];
	locationLabel.textAlignment = UITextAlignmentLeft;
	locationLabel.textColor = RGBCOLOR(140, 140, 140);
    locationLabel.backgroundColor = [UIColor clearColor];
    locationLabel.text  = @"200M";
    [locationLabel sizeToFit];
    
    // add to the statusView
    [self.statusView addSubview:sexView];
    [self.statusView addSubview:timeIconView];
	[self.statusView addSubview:timeLabel];
    [self.statusView addSubview:locationIconView];
	[self.statusView addSubview:locationLabel];
    
    [self.contentView addSubview: self.statusView];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - sns view
////////////////////////////////////////////////////////////////////////////////
- (void)initSNSView
{
    self.snsView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 20, VIEW_COMMON_WIDTH, VIEW_SNS_HEIGHT)];
    
    NSArray *buttonNames = [NSArray arrayWithObjects:@"weibo", @"wechat", @"kaixin", @"douban", nil];
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    UIImageView *snsIcon;
    for (int index = 0; index < _count; index++ ) {
        snsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [snsButton setFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 0, VIEW_COMMON_WIDTH / _count -1, VIEW_SNS_HEIGHT)];
        [snsButton setTitle:[buttonNames objectAtIndex:index] forState:UIControlStateNormal];
        [snsButton setTitleColor:RGBCOLOR(108, 108, 108) forState:UIControlStateNormal];
        snsButton.titleLabel.font = [UIFont systemFontOfSize:11.0];
        [snsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 0)];
        [snsButton.layer setMasksToBounds:YES];
        [snsButton.layer setCornerRadius:3.0];
        
        snsButton.backgroundColor = RGBCOLOR(255, 255, 255);
        [snsButton setBackgroundImage:[UIImage imageNamed:@"uibutton_bg_color.png"] forState:UIControlStateHighlighted];
        
        snsIcon = [[UIImageView alloc]initWithFrame:CGRectMake(5, 7.5, 15, 15)];
        [snsIcon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_icon_%@_c.png",[buttonNames objectAtIndex:index]]]];
        [snsButton addSubview:snsIcon];
        
        snsButton.tag = 1000 + index;
        [snsButton addTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.snsView addSubview:snsButton];
    }


    
    
    [self.contentView addSubview: self.snsView];

}

-(void)snsAction:(UIButton *)sender
{
    NSLog(@"Seg.selectedSegmentIndex:%d",sender.tag);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info view
////////////////////////////////////////////////////////////////////////////////
- (void)initInfoView
{
    self.infoView = [[UIView alloc] initWithFrame:
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + VIEW_SNS_HEIGHT + 30, self.view.frame.size.width, 400)];
    self.infoView.backgroundColor = [UIColor clearColor];
    
    self.infoArray = [[NSArray alloc] initWithObjects: @"签名",@"手机",@"职业",@"家乡",@"个人说明",nil ];    
    self.infoDescArray = [[NSArray alloc] initWithObjects:
                          @"夫和实生物，同则不继。以他平他谓之和故能丰长而物归之",
                          @"老莫  13899763487",
                          @"IT工程师",
                          @"山东 聊城",
                          @"我不是那个史上最牛历史老师！我们中国的教科书属于秽史，请同学们考完试抓紧把它们烧了，放家里一天，都脏你屋子。", nil];
    
    self.infoTableView = [[UITableView alloc]initWithFrame:self.infoView.bounds style:UITableViewStyleGrouped];
    self.infoTableView.dataSource = self;
    self.infoTableView.delegate = self;
    [self.infoTableView setBackgroundColor:[UIColor clearColor]];
    
    
    [self.infoView addSubview:self.infoTableView];
    
    [self.contentView addSubview:self.infoView];    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info table view
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.row == [self.infoArray count] -1 ){
        return 120.0;
    }else{
        return 44.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [infoArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    return cell;

}
#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    //    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.backgroundView.backgroundColor = RGBCOLOR(248, 248, 248);
    
    cell.selectedBackgroundView.backgroundColor =  RGBCOLOR(228, 228, 228);
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 70, 20)];
    titleLabel.text = [self.infoArray objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(155, 161, 172);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
//    cell.textLabel.text = [self.infoArray objectAtIndex:indexPath.row];
//    cell.textLabel.textColor = RGBCOLOR(155, 161, 172);

    // Create a label for the summary
    UILabel* descLabel;
	CGRect rect = CGRectMake( 80, 10, 210, 30);
	descLabel = [[UILabel alloc] initWithFrame:rect];
    descLabel.numberOfLines = 0;
	descLabel.font = [UIFont systemFontOfSize:13.0];
	descLabel.textAlignment = UITextAlignmentLeft;
    descLabel.textColor = RGBCOLOR(125, 125, 125);
    descLabel.backgroundColor = [UIColor clearColor];
    NSString *signiture = [self.infoDescArray objectAtIndex:indexPath.row];
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;

    CGSize signitureSize = [signiture sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signitureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = signiture;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signitureSize.width , signitureSize.height );

    
    if( indexPath.row == [self.infoArray count] -1 ){
        descLabel.frame = CGRectMake(20, _labelHeight + 25 , SUMMARY_WIDTH + 50 , signitureSize.height );
    }
    
    
    [cell.contentView addSubview:descLabel];

    return cell;
}




////////////////////////////////////////////////////////////////////////////////
#pragma mark - action view
////////////////////////////////////////////////////////////////////////////////
- (void)initActionView
{
    self.actionView = [[UIView alloc] initWithFrame:
                       CGRectMake(0, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT, self.view.frame.size.width, VIEW_ACTION_HEIGHT)];
    
    UIImageView *actionViewBg = [[UIImageView alloc]initWithFrame:self.actionView.bounds];
    [actionViewBg setImage:[UIImage imageNamed:@"profile_tabbar_bg.png"]];
    [self.actionView addSubview:actionViewBg];
    
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 6, 93.5f, 29.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.actionView addSubview:self.sendMsgButton];
    
    self.reportUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP + 210.0f, 6, 93.5f, 29.0f)];
    [self.reportUserButton setTag:3];
    [self.reportUserButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
    [self.reportUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.reportUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.reportUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.reportUserButton setTitle:NSLocalizedString(@"Report", nil) forState:UIControlStateNormal];
    [self.reportUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn3.png"] forState:UIControlStateNormal];
    [self.actionView addSubview:self.reportUserButton];
    
    // Now set content. Either user or jsonData must have value
    if (self.user == nil) {
        self.title = [jsonData valueForKey:@"jid"];
        [self.sendMsgButton setTitle:NSLocalizedString(@"Add friend", nil) forState:UIControlStateNormal];
        [self.sendMsgButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn2.png"] forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(addFriendButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        self.title = self.user.displayName;
        [self.sendMsgButton setTitle:NSLocalizedString(@"Send Msg", nil) forState:UIControlStateNormal];
        [self.sendMsgButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn1.png"] forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.deleteUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP+105.0f, 6, 93.5f, 29.0f )];
        [self.deleteUserButton setTag:2];
        [self.deleteUserButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
        [self.deleteUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.deleteUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [self.deleteUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
        [self.deleteUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn4.png"] forState:UIControlStateNormal];
        [self.deleteUserButton setTitle:NSLocalizedString(@"BlockUser", nil) forState:UIControlStateNormal];
        [self.deleteUserButton addTarget:self action:@selector(deleteUserButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionView addSubview:self.deleteUserButton];
    }
    
    [self.view addSubview:self.actionView];
}




- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

-(void)sendMsgButtonPushed:(id)sender
{
    [self.delegate viewController:self didChatIdentity:self.user];
}

-(void)addFriendButtonPushed:(id)sender
{
    NSLog(@"addFriendButtonPushed %@", jsonData);
    
    NSString *userJid = [jsonData valueForKey:@"jid"];

    User *newUser = [ModelHelper findUserWithEPostalID:userJid inContext:self.managedObjectContext];
    
    if (newUser == nil) {
        newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    }
    
    NSLog(@"NewUSer %@",newUser);
    
    if (newUser.state.intValue != IdentityStateActive) {
        [ModelHelper populateUser:newUser withJSONData:jsonData];
        newUser.state = [NSNumber numberWithInt:IdentityStatePendingAddFriend];
        NSLog(@"userJid %@",userJid);

        [[XMPPNetworkCenter sharedClient] addBuddy:userJid withCallbackBlock:nil];
    }
}

-(void)deleteUserButtonPushed:(id)sender
{
    self.user.state = [NSNumber numberWithInt:IdentityStatePendingRemoveFriend];
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.user.ePostalID withCallbackBlock:nil];
}

@end
