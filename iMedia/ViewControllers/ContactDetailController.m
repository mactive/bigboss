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
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "ImageRemote.h"
#import "MBProgressHUD.h"
#import "AFImageRequestOperation.h"
#import "AppNetworkAPIClient.h"
#import "NSDate+timesince.h"

@interface ContactDetailController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

@property(strong, nonatomic) UIActionSheet *reportActionsheet;

- (NSString *)getGender;
- (NSString *)getAgeStr;
- (NSString *)getLastGPSUpdatedTimeStr;
- (NSString *)getSignature;
- (NSString *)getCareer;
- (NSString *)getHometown;
- (NSString *)getSelfIntroduction;
- (NSString *)getNickname;

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
@synthesize albumArray = _albumArray;
@synthesize albumViewController;

@synthesize statusView;
@synthesize snsView;
@synthesize infoArray;
@synthesize infoDescArray;
@synthesize infoView;
@synthesize infoTableView;
@synthesize actionView;
@synthesize reportActionsheet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.albumViewController = [[AlbumViewController alloc] init];
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
//    [self initSNSView];
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
    
    if (self.user != nil) {
        self.albumArray = [[NSMutableArray alloc] initWithArray:[self.user getOrderedNonNilImages]];
        
        for (int i = 0; i< [self.albumArray count]; i++) {
            albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            ImageRemote* remote = [self.albumArray objectAtIndex:i];
            
            [[AppNetworkAPIClient sharedClient] loadImage:remote.imageThumbnailURL withBlock:^(UIImage *image, NSError *error) {
                if (image) {
                    [albumButton setImage:image forState:UIControlStateNormal];
                }
            }];

            [albumButton setFrame:CGRectMake(VIEW_ALBUM_OFFSET * (i%4*2 + 1) + VIEW_ALBUM_WIDTH * (i%4), VIEW_ALBUM_OFFSET * (floor(i/4)*2+1) + VIEW_ALBUM_WIDTH * floor(i/4), VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH)];
            [albumButton.layer setMasksToBounds:YES];
            [albumButton.layer setCornerRadius:3.0];
            albumButton.tag = i;
            
            [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.albumView addSubview:albumButton];
        }
    } else {
        self.albumArray = [NSMutableArray arrayWithCapacity:8];
                           
        NSMutableDictionary *imageURLDict = [[NSMutableDictionary alloc] initWithCapacity:8];
        for (int i = 1; i <=8; i++) {
            NSString *key = [NSString stringWithFormat:@"avatar%d", i];
            NSString *url = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:key];
            if (url != nil && ![url isEqualToString:@""]) {
                [imageURLDict setValue:url forKey:[NSString stringWithFormat:@"%d", i]];
            }
        }
        NSMutableDictionary *imageThumbnailURLDict = [[NSMutableDictionary alloc] initWithCapacity:8];
        for (int i = 1; i <=8; i++) {
            NSString *key = [NSString stringWithFormat:@"thumbnail%d", i];
            NSString *url = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:key];
            if (url != nil && ![url isEqualToString:@""]) {
                [imageThumbnailURLDict setValue:url forKey:[NSString stringWithFormat:@"%d", i]];
            }
        }
        for (int i = 1; i <= 8 ; i++) {
            NSString *key = [NSString stringWithFormat:@"%d", i];
            if ([imageURLDict objectForKey:key] != nil && [imageThumbnailURLDict objectForKey:key] != nil) {
                NSString* imageThumbnailURL = [imageThumbnailURLDict objectForKey:key];
                albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                
                [[AppNetworkAPIClient sharedClient] loadImage:imageThumbnailURL withBlock:^(UIImage *image, NSError *error) {
                    if (image) {
                        [albumButton setImage:image forState:UIControlStateNormal];
                    }
                }];
                
                int pos = i - 1;
                [albumButton setFrame:CGRectMake(VIEW_ALBUM_OFFSET * (pos%4*2 + 1) + VIEW_ALBUM_WIDTH * (pos%4), VIEW_ALBUM_OFFSET * (floor(pos/4)*2+1) + VIEW_ALBUM_WIDTH * floor(pos/4), VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH)];
                [albumButton.layer setMasksToBounds:YES];
                [albumButton.layer setCornerRadius:3.0];
                albumButton.tag = i;
                [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.albumView addSubview:albumButton];                
                [self.albumArray setObject:[imageURLDict objectForKey:key] atIndexedSubscript:(i-1)];
            } else {
                [self.albumArray setObject:@"" atIndexedSubscript:(i-1)];
            }
        }
    }
    
    
    [self.contentView addSubview:self.albumView];
    
}

- (void)albumClick:(UIButton *)sender
{

    self.albumViewController.albumArray = self.albumArray;
    self.albumViewController.albumIndex = sender.tag;
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
    self.statusView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + 15, VIEW_COMMON_WIDTH, 15)];
    
    // Create a label icon for the sex.
    NSString *gender = [self getGender];
    NSString* bgImgStr ;
    if ([gender isEqualToString:@"m"]) {
        bgImgStr = @"sex_male_bg.png";
    } else if ([gender isEqualToString:@"f"]) {
        bgImgStr = @"sex_female_bg.png";
    } else {
        bgImgStr = @"sex_unknown_bg.png";
    }
    
    UIImageView* sexView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:bgImgStr]];
    [sexView setFrame:CGRectMake(0, 0, 50, 20)];

    
    UILabel* sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 20, 20)];
    [sexLabel setBackgroundColor:[UIColor clearColor]];
    sexLabel.text  = [self getAgeStr];
    [sexLabel setFont:[UIFont systemFontOfSize:14.0]];
    [sexLabel setTextColor:[UIColor whiteColor]];
    [sexView addSubview:sexLabel];
    
    // horoscope
    UILabel* horoscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 0, 100, 20)];
    [horoscopeLabel setBackgroundColor:[UIColor clearColor]];
    [horoscopeLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [horoscopeLabel setShadowColor:[UIColor whiteColor]];
    [horoscopeLabel setShadowOffset:CGSizeMake(0, 1)];
    [horoscopeLabel setTextColor:RGBCOLOR(97, 97, 97)];
    [self.statusView addSubview:horoscopeLabel];
    
    
    if (self.user == nil) {
        NSDateFormatter * dateFormater = [[NSDateFormatter alloc]init];
        [dateFormater setDateFormat:@"yyyy-MM-dd"];
        NSDate *_date = [dateFormater dateFromString:[self.jsonData objectForKey:@"birthdate"]];
        horoscopeLabel.text = [_date horoscope];
    }else {
        horoscopeLabel.text = [self.user.birthdate horoscope];
    }
    
    
    
    // Create a label icon for the time.
    UIImageView *timeIconView = [[UIImageView alloc] initWithFrame:CGRectMake(210, 3 , 15, 15)];
    timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
    
    UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 0 ,60, 20)];
	timeLabel.font = [UIFont systemFontOfSize:12.0];
	timeLabel.textAlignment = UITextAlignmentLeft;
	timeLabel.textColor = RGBCOLOR(140, 140, 140);
    timeLabel.backgroundColor = [UIColor clearColor];
    if (self.user == nil) {
        NSDate *tmp = [ServerDataTransformer getLastGPSUpdatedFromServerJSON:self.jsonData];
        if (tmp == nil) {
            timeLabel.text = T(@"无时间");
        } else {
            timeLabel.text = [tmp timesinceAgo];
        }
    }else {
        if (self.user.lastGPSUpdated == nil) {
            timeLabel.text = T(@"无时间");
        } else {
            timeLabel.text = [self.user.lastGPSUpdated timesinceAgo];
        }
    }
    
    [timeLabel sizeToFit];
    
    // Create a label icon for the time.
    /*
    UIImageView *locationIconView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 0 , 15, 15)];
    locationIconView.image = [UIImage imageNamed:@"location_icon.png"];
    
    UILabel* locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(158, 0 ,40, 15)];
	locationLabel.font = [UIFont systemFontOfSize:12.0];
	locationLabel.textAlignment = UITextAlignmentLeft;
	locationLabel.textColor = RGBCOLOR(140, 140, 140);
    locationLabel.backgroundColor = [UIColor clearColor];
    locationLabel.text  = @"200M";
    [locationLabel sizeToFit];
    */ 
    
    // add to the statusView
    [self.statusView addSubview:sexView];
    [self.statusView addSubview:timeIconView];
	[self.statusView addSubview:timeLabel];
//    [self.statusView addSubview:locationIconView];
//	[self.statusView addSubview:locationLabel];
    
    [self.contentView addSubview: self.statusView];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - sns view
////////////////////////////////////////////////////////////////////////////////
- (void)initSNSView
{
    self.snsView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 24, VIEW_COMMON_WIDTH, VIEW_SNS_HEIGHT)];
    
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
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 15, self.view.frame.size.width, 400)];
    self.infoView.backgroundColor = [UIColor clearColor];
    
    self.infoArray = [[NSArray alloc] initWithObjects: @"签名",@"职业",@"家乡",@"个人说明",nil ];    
    self.infoDescArray = [[NSArray alloc] initWithObjects:
                          [self getSignature],
                          [self getCareer],
                          [self getHometown],
                          [self getSelfIntroduction],
                          nil];
    
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
    NSString *signature = [self.infoDescArray objectAtIndex:indexPath.row];
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;

    CGSize signatureSize = [signature sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = signature;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );

    
    if( indexPath.row == [self.infoArray count] -1 ){
        descLabel.frame = CGRectMake(20, _labelHeight + 25 , SUMMARY_WIDTH + 50 , signatureSize.height );
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
    
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 6, 94.0f, 29.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.actionView addSubview:self.sendMsgButton];
    
    self.reportUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP + 210.0f, 6, 94.0f, 29.0f)];
    [self.reportUserButton setTag:3];
    [self.reportUserButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
    [self.reportUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.reportUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.reportUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.reportUserButton setTitle:T(@"举报") forState:UIControlStateNormal];
    [self.reportUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn3.png"] forState:UIControlStateNormal];
    [self.reportUserButton addTarget:self action:@selector(reportAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.reportUserButton];
    
    // Now set content. Either user or jsonData must have value
    self.title = [self getNickname];
    if (self.user == nil) {
        [self.sendMsgButton setTitle:T(@"添加") forState:UIControlStateNormal];
        [self.sendMsgButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn2.png"] forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(addFriendButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        [self.sendMsgButton setTitle:T(@"发送") forState:UIControlStateNormal];
        [self.sendMsgButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn1.png"] forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.deleteUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP+105.0f, 6, 94.0f, 29.0f )];
        [self.deleteUserButton setTag:2];
        [self.deleteUserButton.titleLabel setFont:[UIFont systemFontOfSize:TINY_FONT_HEIGHT]];
        [self.deleteUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.deleteUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [self.deleteUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
        [self.deleteUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn4.png"] forState:UIControlStateNormal];
        [self.deleteUserButton setTitle:T(@"删除") forState:UIControlStateNormal];
        [self.deleteUserButton addTarget:self action:@selector(deleteUserButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionView addSubview:self.deleteUserButton];
    }
    
    [self.view addSubview:self.actionView];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when report
/////////////////////////////////////////////////////////////////////////////////////////

- (void)reportAction:(UIButton *)sender
{
    self.reportActionsheet = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:T(@"取消")
                            destructiveButtonTitle:nil
                            otherButtonTitles:T(@"举报用户"),nil];
    self.reportActionsheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.reportActionsheet showFromTabBar:[[self tabBarController] tabBar]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 ) {
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        HUD.mode = MBProgressHUDModeText;
        HUD.labelText = T(@"举报成功");
        [HUD hide:YES afterDelay:2];
    }
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

    User *newUser = [[ModelHelper sharedInstance] findUserWithEPostalID:userJid];
    
    if (newUser == nil) {
        newUser = [[ModelHelper sharedInstance] createNewUser];
    }
    
    NSLog(@"NewUSer %@",newUser);
    
    if (newUser.state.intValue != IdentityStateActive) {
        [[ModelHelper sharedInstance] populateIdentity:newUser withJSONData:jsonData];
        newUser.state = [NSNumber numberWithInt:IdentityStatePendingAddFriend];
        NSLog(@"userJid %@",userJid);

        [[XMPPNetworkCenter sharedClient] addBuddy:userJid withCallbackBlock:nil];
    }
}

-(void)deleteUserButtonPushed:(id)sender
{
    self.user.state = [NSNumber numberWithInt:IdentityStatePendingRemoveFriend];
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在发送");
    
    [HUD hide:YES afterDelay:2];
    
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.user.ePostalID withCallbackBlock:^(NSError *error) {

        if (error == nil) {
            [HUD hide:YES];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.delegate = self;
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = T(@"删除成功");
            [HUD hide:YES afterDelay:2];
            
            [self.navigationController popViewControllerAnimated:YES];
            
        }else{
            [HUD hide:YES];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.delegate = self;
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = T(@"未删除成功");
            [HUD hide:YES afterDelay:2];
        }
    }];
}

///////////////////////////////////////////////////////////////////////////////
// Getter help to get data from either user or jsonData
////////////////////////////////////////////////////////////////////////////////
- (NSString *)getGender
{
    if (self.user == nil) {
        return [ServerDataTransformer getGenderFromServerJSON:self.jsonData];
    } else if (self.user.gender != nil){
        return self.user.gender;
    } else {
        return @"";
    }
}

- (NSString *)getAgeStr
{
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //unsigned int unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comps ;
    if (self.user == nil) {
        comps = [gregorian components:NSYearCalendarUnit fromDate:[ServerDataTransformer getBirthdateFromServerJSON:self.jsonData]  toDate:now  options:0];
    } else {
        comps = [gregorian components:NSYearCalendarUnit fromDate:self.user.birthdate  toDate:now  options:0];
    }
    return [NSString stringWithFormat:@"%d", comps.year];
}

- (NSString *)getLastGPSUpdatedTimeStr
{
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int unitFlags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents *comps ;
    if (self.user == nil) {
        comps = [gregorian components:unitFlags fromDate:[ServerDataTransformer getLastGPSUpdatedFromServerJSON:self.jsonData]  toDate:now  options:0];
    } else {
        comps = [gregorian components:unitFlags fromDate:self.user.lastGPSUpdated  toDate:now  options:0];
    }
    if (comps.day == 1) {
        return [NSString stringWithFormat:@"%d day ago", comps.day];
    } else if (comps.day > 1) {
        return [NSString stringWithFormat:@"%d days ago", comps.day];
    } else if (comps.hour == 1) {
        return [NSString stringWithFormat:@"%d hour ago", comps.hour];
    } else if (comps.hour > 1) {
        return [NSString stringWithFormat:@"%d hours ago", comps.hour];
    } else if (comps.minute == 1) {
        return [NSString stringWithFormat:@"%d minute ago", comps.minute];
    } else if (comps.minute > 0) {
        return [NSString stringWithFormat:@"%d minutes ago", comps.minute];
    } else {
        return T(@"now");
    }
}
- (NSString *)getSignature
{
    if (self.user != nil && self.user.signature != nil) {
        return self.user.signature;
    } else if (self.jsonData != nil) {
        return [ServerDataTransformer getSignatureFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getCareer
{
    if (self.user != nil && self.user.career != nil) {
        return self.user.career;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getCareerFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getHometown
{
    if (self.user != nil && self.user.hometown != nil) {
        return self.user.hometown;
    } else if (self.jsonData != nil) {
        return [ServerDataTransformer getHometownFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getSelfIntroduction
{
    if (self.user != nil && self.user.selfIntroduction != nil) {
        return self.user.selfIntroduction;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getSelfIntroductionFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getNickname
{
    // if nickname is not available, use guid instead
    if (self.user != nil) {
        if (self.user.displayName == nil || [self.user.displayName isEqualToString:@""]) {
            return self.user.guid;
        } else {
            return self.user.displayName;
        }
    } else {
        NSString *nickname = [ServerDataTransformer getNicknameFromServerJSON:self.jsonData];
        if (StringHasValue(nickname)) {
            return nickname;
        } else {
            return [ServerDataTransformer getGUIDFromServerJSON:self.jsonData];
        }
    }
}

@end
