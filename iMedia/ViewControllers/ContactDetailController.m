//
//  ContactDetailController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ContactDetailController.h"
#import "User.h"
#import "Me.h"
#import "Channel.h"
#import "ModelHelper.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
#import <QuartzCore/QuartzCore.h>
#import "AlbumViewController.h"
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "ImageRemote.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "AFImageRequestOperation.h"
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h"
#import "NSDate+timesince.h"
#import "WebViewController.h"

// request view
#import "FriendRequest.h"
#import "ModelHelper.h"
#import "ConversationsController.h"
#import "NSObject+SBJson.h"
#import "ContactListViewController.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif


@interface ContactDetailController ()
@property(strong, nonatomic) UIActionSheet *reportActionsheet;

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UITableView *infoTableView;

@property (strong, nonatomic) UIView *albumView;
@property (strong, nonatomic) UIView *statusView;
@property (strong, nonatomic) UIView *snsView;
@property (strong, nonatomic) UIView *infoView;
@property (strong, nonatomic) UIView *actionView;

@property (strong, nonatomic) UILabel *sexLabel;
@property (strong, nonatomic) UILabel *guidLabel;
@property (strong, nonatomic) UILabel *horoscopeLabel;
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UIButton *deleteUserButton;
@property (strong, nonatomic) UIButton *reportUserButton;
@property (strong, nonatomic) UILabel  *nameLabel;
@property (strong, nonatomic) UIButton *confirmButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *helloButton;
@property (strong, nonatomic) UIButton *friendReqestStateButton;
@property (strong, nonatomic) NSMutableArray *albumButtonArray;
@property (readwrite, nonatomic) NSUInteger albumCount;


// could contain ImageRemote object or NSString for url
@property (strong, nonatomic) NSMutableArray *albumArray;

@property (strong, nonatomic) NSArray *infoArray;
@property (strong, nonatomic) NSArray *infoDescArray;

- (NSString *)getGender;
- (NSString *)getAgeStr;
- (NSString *)getLastGPSUpdatedTimeStr;
- (NSString *)getSignature;
- (NSString *)getCareer;
- (NSString *)getHometown;
- (NSString *)getSinaWeiboID;
- (NSString *)getSelfIntroduction;
- (NSString *)getNickname;
- (NSString *)getAlwaysbeen;
- (NSString *)getInterest;
- (NSString *)getSchool;
- (NSString *)getCompany; 

@end

@implementation ContactDetailController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;
@synthesize deleteUserButton;
@synthesize reportUserButton;
@synthesize nameLabel = _nameLabel;
@synthesize user =_user;
@synthesize jsonData;
@synthesize contentView;

@synthesize albumView;
@synthesize albumArray = _albumArray;

@synthesize statusView;
@synthesize snsView;
@synthesize infoArray;
@synthesize infoDescArray;
@synthesize infoView;
@synthesize infoTableView;
@synthesize actionView;
@synthesize reportActionsheet;
@synthesize sexLabel;
@synthesize horoscopeLabel;
@synthesize timeLabel;
@synthesize guidLabel;
@synthesize GUIDString;
@synthesize request;
@synthesize confirmButton;
@synthesize cancelButton;
@synthesize friendReqestStateButton;
@synthesize helloButton;
@synthesize albumButtonArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_OFFSET 2.5

#define VIEW_PADDING_LEFT 12
#define VIEW_ALBUM_HEIGHT 160
#define VIEW_STATUS_HEIGHT 15
#define VIEW_SNS_HEIGHT 50
#define VIEW_ACTION_HEIGHT 44
#define VIEW_UINAV_HEIGHT 44

#define VIEW_COMMON_WIDTH 296
#define VIEW_INFO_HEIGHT 560

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT)];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, VIEW_INFO_HEIGHT + 290)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);
    
    self.title = [self getNickname];
    
    [self initStatusView];
    [self initInfoView]; // table view 
    
    [self initAlbumView];
    [self initSNSView];
    [self initActionView];
    
    [self.view addSubview:self.contentView];

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshStatusView];
    [self refreshSNSView];
    [self refreshAlbumView];

    [self updateButtonsBasedRequestState];
 
    [XFox logEvent:PAGE_CONTACT_DETAIL withParameters:[NSDictionary dictionaryWithObjectsAndKeys: self.user ? self.user.guid : self.GUIDString, @"guid", nil]];
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark -  ablum view
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when add album
/////////////////////////////////////////////////////////////////////////////////////////
#define MAX_ALBUN_COUNT 8
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_OFFSET 2.5

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % 4 * 2 + 1) + VIEW_ALBUM_WIDTH * (index % 4) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / 4) * 2 + 1) + VIEW_ALBUM_WIDTH * floor(index / 4);
    return  CGRectMake( x, y, VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH);
}

- (void)initAlbumView
{
    self.albumView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, VIEW_ALBUM_HEIGHT)];
    UIImageView *albumViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_image_bg.png"]];
    [self.albumView addSubview:albumViewBg];
    
    UIButton *albumButton;
    self.albumButtonArray = [[NSMutableArray alloc] init];

    for (int i = 0; i< MAX_ALBUN_COUNT; i++) {
        albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [albumButton setFrame:[self calcRect:i]];
        [albumButton.layer setMasksToBounds:YES];
        [albumButton.layer setCornerRadius:3.0];
        albumButton.tag = i ;
        
        [self.albumView addSubview:albumButton];
        [self.albumButtonArray addObject:albumButton];
    }
    
    [self.contentView addSubview:self.albumView];
    
}

- (void)refreshAlbumView
{
    self.albumCount = 0;
    // 从我的联系人进来
    if (self.user != nil) {
        NSArray *avatars = [[NSMutableArray alloc] initWithArray:[self.user getOrderedImages]];
        self.albumArray = [[NSMutableArray alloc]init];
        for (int i = 0; i< [avatars count]; i++) {
            ImageRemote* avatar = [avatars objectAtIndex:i];
            
            if (StringHasValue(avatar.imageThumbnailURL) && StringHasValue(avatar.imageURL)) {
                UIButton *albumButton = [self.albumButtonArray objectAtIndex:self.albumCount];
                
                [[AppNetworkAPIClient sharedClient] loadImage:avatar.imageThumbnailURL withBlock:^(UIImage *image, NSError *error){
                    if (image) {
                        [albumButton setImage:image forState:UIControlStateNormal];
                    }}];
                
                [albumButton setHidden:NO];
#warning  avatar can't pass to albumView so use avatar.imageURl
                [self.albumArray setObject:avatar.imageURL atIndexedSubscript:self.albumCount];
                [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
                self.albumCount += 1;
            }else{
                int index = [avatars count] - (i - self.albumCount) - 1;
                UIButton *albumButton = [self.albumButtonArray objectAtIndex:index];
                [albumButton setHidden:YES];
            }
        }
    }
    // 从附近的人进来
    else{
        self.albumArray = [NSMutableArray arrayWithCapacity:MAX_ALBUN_COUNT];
        NSMutableDictionary *imageURLDict = [[NSMutableDictionary alloc] initWithCapacity:MAX_ALBUN_COUNT];
        NSMutableDictionary *imageThumbnailURLDict = [[NSMutableDictionary alloc] initWithCapacity:MAX_ALBUN_COUNT];
        for (int i = 1; i <= MAX_ALBUN_COUNT; i++) {
            NSString *avatarKey = [NSString stringWithFormat:@"avatar%d", i];
            NSString *avatarUrl = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:avatarKey];
            if (avatarUrl != nil && ![avatarUrl isEqualToString:@""]) {
                [imageURLDict setValue:avatarUrl forKey:[NSString stringWithFormat:@"%d", i]];
            }
            
            NSString *thumbnailKey = [NSString stringWithFormat:@"thumbnail%d", i];
            NSString *thumbnailUrl = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:thumbnailKey];
            if (thumbnailUrl != nil && ![thumbnailUrl isEqualToString:@""]) {
                [imageThumbnailURLDict setValue:thumbnailUrl forKey:[NSString stringWithFormat:@"%d", i]];
            }
        }
        
        for (int i = 1; i <= 8 ; i++) {
            NSString *key = [NSString stringWithFormat:@"%d", i];
            NSString* imageThumbnailURL = [imageThumbnailURLDict objectForKey:key];
            UIButton *albumButton = [self.albumButtonArray objectAtIndex:i-1];

            if ( StringHasValue([imageURLDict objectForKey:key]) && StringHasValue([imageThumbnailURLDict objectForKey:key]) ) {
                [[AppNetworkAPIClient sharedClient] loadImage:imageThumbnailURL withBlock:^(UIImage *image, NSError *error) {
                    if (image) {
                        [albumButton setImage:image forState:UIControlStateNormal];
                    }
                }];
                [self.albumArray setObject:[imageURLDict objectForKey:key] atIndexedSubscript:(i-1)];
                
                [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
                [albumButton setHidden:NO];
            }else{
                [self.albumArray setObject:@"" atIndexedSubscript:(i-1)];
                [albumButton setHidden:YES];
            }
        
        }
    }
}

- (void)albumClick:(UIButton *)sender
{
    AlbumViewController* albumViewController = [[AlbumViewController alloc] init];
    albumViewController.albumArray = self.albumArray;
    albumViewController.albumIndex = sender.tag;
    [albumViewController setHidesBottomBarWhenPushed:YES];
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:albumViewController animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - status view
////////////////////////////////////////////////////////////////////////////////
- (void)initStatusView
{
    self.statusView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + 10, VIEW_COMMON_WIDTH, 15)];
    
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

    
    self.sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 20, 20)];
    [self.sexLabel setBackgroundColor:[UIColor clearColor]];
    [self.sexLabel setFont:[UIFont systemFontOfSize:14.0]];
    [self.sexLabel setTextColor:[UIColor whiteColor]];
    [sexView addSubview:sexLabel];
    
    // horoscope
    self.horoscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(55, 0, 100, 20)];
    [self.horoscopeLabel setBackgroundColor:[UIColor clearColor]];
    [self.horoscopeLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [self.horoscopeLabel setShadowColor:[UIColor whiteColor]];
    [self.horoscopeLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.horoscopeLabel setTextColor:RGBCOLOR(97, 97, 97)];
    
    self.guidLabel = [[UILabel alloc]initWithFrame:CGRectMake(200, 0, 100, 20)];
    [self.guidLabel setBackgroundColor:[UIColor clearColor]];
    [self.guidLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [self.guidLabel setShadowColor:[UIColor whiteColor]];
    [self.guidLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.guidLabel setTextColor:RGBCOLOR(97, 97, 97)];
    
    // add to the statusView
    [self.statusView addSubview:self.horoscopeLabel];
    [self.statusView addSubview:sexView];
    [self.statusView addSubview:self.guidLabel];

    [self.contentView addSubview: self.statusView];
}

- (void)refreshStatusView 
{
    // guid
    self.guidLabel.text  = [ NSString stringWithFormat:@" %@: %@",T(@"ID"), self.GUIDString];
    
    // horoscope
    if (self.user == nil) {
        NSDateFormatter * dateFormater = [[NSDateFormatter alloc]init];
        [dateFormater setDateFormat:@"yyyy-MM-dd"];
        NSDate *_date = [dateFormater dateFromString:[self.jsonData objectForKey:@"birthdate"]];
        if (_date != nil) {
            self.horoscopeLabel.text = [_date horoscope];
        }
    }else {
        if (self.user.birthdate) {
            self.horoscopeLabel.text = [self.user.birthdate horoscope];
        }
    }
    
    //age
    self.sexLabel.text  = [self getAgeStr];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - sns view
////////////////////////////////////////////////////////////////////////////////
- (void)initSNSView
{
    self.snsView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + VIEW_INFO_HEIGHT, VIEW_COMMON_WIDTH, VIEW_SNS_HEIGHT*2)];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 20)];
    titleLabel.text = T(@"社交认证");
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.backgroundColor = [UIColor clearColor];
    [self.snsView addSubview:titleLabel];
    
    NSArray *buttonNames = [NSArray arrayWithObjects:@"新浪微博",  nil]; //@"wechat", @"kaixin", @"douban",
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    UILabel *snsLabel;

    for (int index = 0; index < _count; index++ ) {
        snsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        snsButton.enabled = YES;
        [snsButton setFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 30, VIEW_COMMON_WIDTH / 3, VIEW_SNS_HEIGHT)];
        [snsButton setTitleColor:RGBCOLOR(108, 108, 108) forState:UIControlStateNormal];
        snsButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [snsButton.layer setMasksToBounds:YES];
        [snsButton.layer setCornerRadius:3.0];
        snsButton.backgroundColor = RGBCOLOR(255, 255, 255);
        [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i.png",index]] forState:UIControlStateNormal];
        
        snsButton.tag = 1000 + index;
        
        snsLabel = [[UILabel alloc] initWithFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 30+VIEW_SNS_HEIGHT, VIEW_COMMON_WIDTH / 3, 20)];
        snsLabel.text = [buttonNames objectAtIndex:index];
        snsLabel.textAlignment = UITextAlignmentCenter;
        snsLabel.textColor = [UIColor blackColor];
        snsLabel.backgroundColor = [UIColor clearColor];
        snsLabel.font = [UIFont systemFontOfSize:14];
    
        [self.snsView addSubview:snsLabel];
        [self.snsView addSubview:snsButton];
        
    }
    
    [self.contentView addSubview: self.snsView];
    
}

- (void)refreshSNSView
{
    NSArray *buttonNames = SNS_ARRAY;
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    for (int index = 0; index < _count; index++ ) {
        if ( StringHasValue([self getSinaWeiboID])){
            snsButton = (UIButton *)[self.snsView viewWithTag:index+1000];
            [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i_c.png",index]] forState:UIControlStateNormal];
            [snsButton addTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        }else{
            snsButton = (UIButton *)[self.snsView viewWithTag:index+1000];
            [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i.png",index]] forState:UIControlStateNormal];
        }
    }
}


-(void)snsAction:(UIButton *)sender
{
    WebViewController *controller = [[WebViewController alloc]initWithNibName:nil bundle:nil];
    controller.urlString = [NSString stringWithFormat:@"%@%@",@"http://weibo.cn/u/",[self getSinaWeiboID]];
    controller.title = T(@"用户微博");
    [self.navigationController pushViewController:controller animated:YES];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info view
////////////////////////////////////////////////////////////////////////////////
- (void)initInfoView
{
    self.infoView = [[UIView alloc] initWithFrame:
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 15, self.view.frame.size.width, VIEW_INFO_HEIGHT)];
    self.infoView.backgroundColor = [UIColor clearColor];
    
    self.infoArray = [[NSArray alloc] initWithObjects:
                      [[NSArray alloc] initWithObjects:T(@"签名"),nil],
                      [[NSArray alloc] initWithObjects:T(@"职业"), T(@"公司"),T(@"学校"),nil],
                      [[NSArray alloc] initWithObjects:T(@"兴趣爱好"),T(@"常出没的地方"),T(@"个人说明"),nil],
                      nil];
    
    self.infoDescArray = [[NSArray alloc] initWithObjects:
                          [[NSArray alloc] initWithObjects:[self getSignature],nil],
                          [[NSArray alloc] initWithObjects: [self getCareer], [self getCompany],[self getSchool],nil],
                          [[NSArray alloc] initWithObjects:[self getInterest],[self getAlwaysbeen],[self getSelfIntroduction],nil],
                          nil];
    
    self.infoTableView = [[UITableView alloc]initWithFrame:self.infoView.bounds style:UITableViewStyleGrouped];
    self.infoTableView.dataSource = self;
    self.infoTableView.delegate = self;
    self.infoTableView.backgroundView = nil;
    [self.infoTableView setBackgroundColor:[UIColor clearColor]];    
    
    [self.infoView addSubview:self.infoTableView];
    
    [self.contentView addSubview:self.infoView];    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info table view
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section ==2){
        if ( indexPath.row == 2) {
            return 120.0;
        }else{
            return 80.0;
        }
    }else if(indexPath.section ==0){
        return 60.0;
    }else{
        return 44.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }else if(section == 1){
        return 3;
    }else if(section == 2){
        return 3;
    }else{
        return 0;
    }
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
    NSArray *titleArray = (NSArray *)[self.infoArray objectAtIndex:indexPath.section];
    NSArray *descArray = (NSArray *)[self.infoDescArray objectAtIndex:indexPath.section];
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 70, 24)];
    titleLabel.text = [titleArray objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(155, 161, 172);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];

    // Create a label for the summary
    UILabel* descLabel;
	CGRect rect = CGRectMake( 80, 10, 210, 20);
	descLabel = [[UILabel alloc] initWithFrame:rect];
    descLabel.numberOfLines = 0;
	descLabel.font = [UIFont systemFontOfSize:13.0];
	descLabel.textAlignment = UITextAlignmentLeft;
    descLabel.textColor = RGBCOLOR(125, 125, 125);
    descLabel.backgroundColor = [UIColor clearColor];
    NSString *signature = [descArray objectAtIndex:indexPath.row];
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;

    CGSize signatureSize = [signature sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        if (indexPath.section == 0) {
            _labelHeight = 14.0;
        }else{
            _labelHeight = 6.0;
        }
    }else {
        if (indexPath.section == 0) {
            _labelHeight = 22.0;
        }else{
            _labelHeight = 14.0;
        }
    }
    descLabel.text = signature;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );

    
    if( indexPath.section == 2){
        titleLabel.frame = CGRectMake(20, 12, 150, 20);
        descLabel.frame = CGRectMake(10, 37 , SUMMARY_WIDTH + 50 , signatureSize.height );
    }else if(indexPath.section == 0 && indexPath.row == 0 ){
        titleLabel.frame = CGRectMake(20, 20, 150, 20);
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
    
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 5.0f, 94.0f, 34.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.sendMsgButton setTitle:T(@"发送") forState:UIControlStateNormal];
    [self.sendMsgButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn1.png"] forState:UIControlStateNormal];
    [self.sendMsgButton addTarget:self action:@selector(sendMsgRequest:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.sendMsgButton];
    
    self.helloButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 5.0f, 94.0f, 34.0f)];
    [self.helloButton setTag:6];
    [self.helloButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.helloButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.helloButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.helloButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.helloButton setTitle:T(@"打招呼") forState:UIControlStateNormal];
    [self.helloButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn2.png"] forState:UIControlStateNormal];
    [self.helloButton addTarget:self action:@selector(addFriendAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.helloButton];

    self.reportUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP + 210.0f, 5.0f, 94.0f, 34.0f)];
    [self.reportUserButton setTag:3];
    [self.reportUserButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.reportUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.reportUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.reportUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.reportUserButton setTitle:T(@"举报") forState:UIControlStateNormal];
    [self.reportUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn3.png"] forState:UIControlStateNormal];
    [self.reportUserButton addTarget:self action:@selector(reportAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.reportUserButton];
    
    self.deleteUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP+105.0f, 5.0f, 94.0f, 34.0f )];
    [self.deleteUserButton setTag:2];
    [self.deleteUserButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.deleteUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.deleteUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.deleteUserButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 18, 0, 0)];
    [self.deleteUserButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn4.png"] forState:UIControlStateNormal];
    [self.deleteUserButton setTitle:T(@"删除") forState:UIControlStateNormal];
    [self.deleteUserButton addTarget:self action:@selector(deleteUserAction:) forControlEvents:UIControlEventTouchUpInside];
     [self.actionView addSubview:self.deleteUserButton];
    
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 5.0f, 94.0f, 34.0f)];
    [self.confirmButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.confirmButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 0)];
    [self.confirmButton setTitle:T(@"加为好友") forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn5.png"] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(confirmRequest) forControlEvents:UIControlEventTouchUpInside];
    
    [self.actionView addSubview:self.confirmButton];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP+210.0f, 5.0f, 94.0f, 34.0f )];
    [self.cancelButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.cancelButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 0)];
    [self.cancelButton setTitle:T(@"拒绝请求") forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn4.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.cancelButton];
    
    self.friendReqestStateButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 5.0f, 94.0f, 34.0f)];
    [self.friendReqestStateButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.friendReqestStateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.friendReqestStateButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.friendReqestStateButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 0)];
    [self.actionView addSubview:self.friendReqestStateButton];

    
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
    [self.reportActionsheet showFromRect:self.view.bounds inView:self.view animated:YES];

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 ) {
        NSString* hisGUID = self.GUIDString;
        
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.labelText = T(@"正在发送");

        [[AppNetworkAPIClient sharedClient] reportID:hisGUID myID:[self appDelegate].me.guid type:@"p" description:@"用户举报，无具体描述" otherInfo:@"" withBlock:nil];
        
        self.user.state = IdentityStatePendingRemoveFriend;
                
        [[XMPPNetworkCenter sharedClient] removeBuddy:self.user.ePostalID withCallbackBlock:^(NSError *error) {
            [HUD hide:YES];  
            if (error == nil) {
                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.mode = MBProgressHUDModeText;
                hud.removeFromSuperViewOnHide = YES;
                hud.labelText = T(@"你已成功举报该用户");
                hud.detailsLabelText = T(@"我们将核对信息后尽快处理");
                                
                [hud showAnimated:YES whileExecutingBlock:^{
                    sleep(2);
                } completionBlock:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];

            }else{
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络问题，请稍候再试") andHideAfterDelay:2];
            }
        }];
        
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)addFriendAction:(id)sender
{
   DDLogInfo(@"addFriendAction %@", jsonData);
    
    
    NSString *userJid = [jsonData valueForKey:@"jid"];

    User *newUser = [[ModelHelper sharedInstance] findUserWithEPostalID:userJid];
    
    if (newUser == nil) {
        newUser = [[ModelHelper sharedInstance] createNewUser];
    }
    
    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请求已发送") andHideAfterDelay:2];

    if (newUser.state == IdentityStatePendingServerDataUpdate) {
        [[AppNetworkAPIClient sharedClient] updateIdentity:newUser withBlock:nil];
    } else if (newUser.state != IdentityStateActive) {
        [[ModelHelper sharedInstance] populateIdentity:newUser withJSONData:jsonData];
        newUser.state = IdentityStatePendingAddFriend;
    }
    
    // send sub request anyway - idempotent requests all the way
    [[XMPPNetworkCenter sharedClient] addBuddy:userJid withCallbackBlock:nil];
    
    [XFox logEvent:EVENT_ADD_FRIEND withParameters:[NSDictionary dictionaryWithObjectsAndKeys:newUser.guid, @"guid", nil]];
}

-(void)deleteUserAction:(id)sender
{
    if (self.user.state != IdentityStateInactive) {
        self.user.state = IdentityStatePendingRemoveFriend;
    }
    
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在发送");
    
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.user.ePostalID withCallbackBlock:^(NSError *error) {
        [HUD hide:YES];
        if (error == nil) {
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"删除成功") andHideAfterDelay:2];
            [self.navigationController popViewControllerAnimated:YES];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误，请稍后重试") andHideAfterDelay:2];
        }
    }];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - request action view
////////////////////////////////////////////////////////////////////////////////

- (void)updateButtonsBasedRequestState
{
    // we have three views: 1) friend view; 2) stranger view (add a friend); 3) friend request action view
    // (approve friend request)
    
    if (self.user != nil && self.user.state == IdentityStateActive) {
        // friend view
        [self.sendMsgButton setHidden:NO];
        [self.deleteUserButton setHidden:NO];
        [self.reportUserButton setHidden:NO];
        [self.confirmButton setHidden:YES];
        [self.cancelButton setHidden:YES];
        [self.friendReqestStateButton setHidden:YES];
        [self.helloButton setHidden:YES];
    } else if (self.request != nil && self.request.state == FriendRequestUnprocessed) {
        // display approval & denial action
        [self.sendMsgButton setHidden:YES];
        [self.deleteUserButton setHidden:YES];
        [self.reportUserButton setHidden:YES];
        [self.confirmButton setHidden:NO];
        [self.cancelButton setHidden:NO];
        [self.friendReqestStateButton setHidden:YES];
        [self.helloButton setHidden:YES];
    } else if (self.request != nil && self.request.state != FriendRequestUnprocessed) {
        // display current friend state
        User* user = [[ModelHelper sharedInstance] findUserWithEPostalID:self.request.requesterEPostalID];
        if (user != nil && user.state == IdentityStateActive) {
            [self.sendMsgButton setHidden:NO];
            [self.deleteUserButton setHidden:NO];
            [self.reportUserButton setHidden:NO];
            [self.confirmButton setHidden:YES];
            [self.cancelButton setHidden:YES];
            [self.friendReqestStateButton setHidden:YES];
            [self.helloButton setHidden:YES];
        } else {
            [self.sendMsgButton setHidden:YES];
            [self.deleteUserButton setHidden:YES];
            [self.reportUserButton setHidden:YES];
            [self.confirmButton setHidden:YES];
            [self.cancelButton setHidden:YES];
            [self.friendReqestStateButton setHidden:NO];
            [self.helloButton setHidden:YES];
            
            if (self.request.state == FriendRequestApproved) {
                [self.friendReqestStateButton setTitle:T(@"已添加") forState:UIControlStateNormal];
                [self.friendReqestStateButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn5.png"] forState:UIControlStateNormal];
            } else {
                [self.friendReqestStateButton setTitle:T(@"已拒绝") forState:UIControlStateNormal];
                [self.friendReqestStateButton setBackgroundImage:[UIImage imageNamed:@"profile_tabbar_btn3.png"] forState:UIControlStateNormal];

            }
        }
    } else  {
        // display stranger
        [self.sendMsgButton setHidden:YES];
        [self.deleteUserButton setHidden:YES];
        [self.reportUserButton setHidden:NO];
        [self.confirmButton setHidden:YES];
        [self.cancelButton setHidden:YES];
        [self.friendReqestStateButton setHidden:YES];
        [self.helloButton setHidden:NO];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mask - button action
////////////////////////////////////////////////////////////////////////////////////////////////
-(void)sendMsgRequest:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[self appDelegate].tabController setSelectedIndex:1];
    
    if (self.user != nil) {
        [[self appDelegate].conversationController chatWithIdentity:self.user];
    } else {
        User* user = [[ModelHelper sharedInstance] findUserWithGUID:self.GUIDString];
        [[self appDelegate].conversationController chatWithIdentity:user];
    }
}

- (void)confirmRequest
{
    self.request.state = FriendRequestApproved;
    self.user = [[ModelHelper sharedInstance] createActiveUserWithFullServerJSONData:[self.request.userJSONData JSONValue]];
    [[XMPPNetworkCenter sharedClient] acceptPresenceSubscriptionRequestFrom:self.request.requesterEPostalID andAddToRoster:YES];
    [[self appDelegate].contactListController contentChanged];
    
    [self updateButtonsBasedRequestState];
}

- (void)cancelRequest
{
    self.request.state = FriendRequestDeclined;
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.request.requesterEPostalID withCallbackBlock:nil];
    [[XMPPNetworkCenter sharedClient] rejectPresenceSubscriptionRequestFrom:self.request.requesterEPostalID];
    
    [self updateButtonsBasedRequestState];
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
        NSDate *fromDate = [ServerDataTransformer getBirthdateFromServerJSON:self.jsonData];
        if (fromDate != nil) {
            comps = [gregorian components:NSYearCalendarUnit fromDate:fromDate  toDate:now  options:0];
        }else{
            return @"";
        }
    } else {
        if (self.user.birthdate != nil) {
            comps = [gregorian components:NSYearCalendarUnit fromDate:self.user.birthdate  toDate:now  options:0];
        }else{
            return @"";
        }
    }
    
    if (comps != nil) {
        return [NSString stringWithFormat:@"%d", comps.year];
    } else {
        return @"";
    }
    
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
        if(self.user.lastGPSUpdated != nil){
            comps = [gregorian components:unitFlags fromDate:self.user.lastGPSUpdated  toDate:now  options:0];
        }
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
- (NSString *)getSinaWeiboID
{
    if (self.user != nil && self.user.sinaWeiboID != nil) {
        return self.user.sinaWeiboID;
    } else if (self.jsonData != nil) {
        return [ServerDataTransformer getSinaWeiboIDFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getSchool
{
    if (self.user != nil && self.user.school != nil) {
        return self.user.school;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getSchoolFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getCompany
{
    if (self.user != nil && self.user.company != nil) {
        return self.user.company;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getCompanyFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}
- (NSString *)getAlwaysbeen
{
    if (self.user != nil && self.user.alwaysbeen != nil) {
        return self.user.alwaysbeen;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getAlwaysbeenFromServerJSON:self.jsonData];
    } else {
        return @"";
    }
}

- (NSString *)getInterest
{
    if (self.user != nil && self.user.interest != nil) {
        return self.user.interest;
    } else if (self.jsonData != nil){
        return [ServerDataTransformer getInterestFromServerJSON:self.jsonData];
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
