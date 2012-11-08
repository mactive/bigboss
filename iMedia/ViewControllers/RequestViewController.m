//
//  RequestViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-29.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "RequestViewController.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "UIImageView+AFNetworking.h"
#import "XMPPNetworkCenter.h"
#import "UIImageView+AFNetworking.h"
#import "ServerDataTransformer.h"
#import "AppDelegate.h"
#import "FunctionListViewController.h"
#import "ModelHelper.h"
#import "ContactListViewController.h"
#import "MBProgressHUD.h"
#import "NSObject+SBJson.h"

@interface RequestViewController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    id  _localJSONDataDict;
}

@property(nonatomic, strong) UIView * requestView;
@property(nonatomic, strong) UILabel * titleLabel;
@property(nonatomic, strong) UILabel * timeLabel;
@property(nonatomic, strong) UIView * contentView;
@property(nonatomic, strong) UIButton * confirmButton;
@property(nonatomic, strong) UIButton * cancelButton;

@end

@implementation RequestViewController

@synthesize requestView;
@synthesize titleLabel;
@synthesize timeLabel;
@synthesize contentView;
@synthesize confirmButton;
@synthesize cancelButton;
@synthesize request;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"好友请求");
    self.view.backgroundColor = BGCOLOR;
    NSLog(@"%@",self.request);

    NSDate * date = self.request.requestDate;
    _localJSONDataDict = [self.request.userJSONData JSONValue];
    
    NSString* title = [ServerDataTransformer getNicknameFromServerJSON:_localJSONDataDict];
    if (title == nil || [title isEqualToString:@""]) {
        title = [ServerDataTransformer getGUIDFromServerJSON:_localJSONDataDict];
    }
	// Do any additional setup after loading the view.
    
    self.requestView = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 300,300)];
    [self.requestView setBackgroundColor:[UIColor whiteColor]];
    [self.requestView.layer setMasksToBounds:YES];
    [self.requestView.layer setCornerRadius:10.0];
    
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 250, 20)];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	self.titleLabel.textAlignment = UITextAlignmentLeft;
    self.titleLabel.textColor = RGBCOLOR(107, 107, 107);
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.text = [[NSString alloc] initWithFormat:@" %@  %@",title, T(@"请求加你为好友") ];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, 250, 20)];
	self.timeLabel.font = [UIFont boldSystemFontOfSize:14.0];
	self.timeLabel.textAlignment = UITextAlignmentLeft;
    self.timeLabel.textColor = RGBCOLOR(153, 153, 153);
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.text = [date timesince];
    
    [self initContentView];
    
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 200, 275, 40)];
    [self.confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.confirmButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    if (request.state == FriendRequestDeclined) {
        [self.confirmButton setTitle:T(@"已拒绝") forState:UIControlStateNormal];
    } else if (request.state == FriendRequestApproved) {
        [self.confirmButton setTitle:T(@"已添加") forState:UIControlStateNormal];
    } else {
        [self.confirmButton setTitle:T(@"加为好友") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(confirmRequest) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.confirmButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    
    
    if (request.state == FriendRequestUnprocessed) {
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 250, 275, 40)];
        [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.cancelButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        [self.cancelButton setTitle:T(@"拒绝请求") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
        [self.requestView addSubview:self.cancelButton];
    }
    
    [self.requestView addSubview:self.titleLabel];
    [self.requestView addSubview:self.timeLabel];
    [self.requestView addSubview:self.confirmButton];
    
    
    
    [self.view addSubview:self.requestView];
}

- (void)initContentView
{
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(15, 70, 270, 100)];
    self.contentView.backgroundColor = RGBCOLOR(235, 235, 235);
    [self.contentView.layer setMasksToBounds:YES];
    [self.contentView.layer setCornerRadius:5.0];
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 75, 75)];
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
//    avatarImage setImage:
    [avatarImage setImageWithURL:[NSURL URLWithString:[ServerDataTransformer getThumbnailFromServerJSON:_localJSONDataDict]]];
    [self.contentView addSubview:avatarImage];

    
    UILabel *label;
    label = [[UILabel alloc] initWithFrame:CGRectMake(100, 10, 170, 20)];
	label.font = [UIFont boldSystemFontOfSize:14.0];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(127, 127, 127);
    label.backgroundColor = [UIColor clearColor];
    label.text = [ServerDataTransformer getNicknameFromServerJSON:_localJSONDataDict];
    [self.contentView addSubview:label];

    label = [[UILabel alloc] initWithFrame:CGRectMake(100, 30, 170, 60)];
	label.font = [UIFont boldSystemFontOfSize:12.0];
    label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.text = [ServerDataTransformer getSignatureFromServerJSON:_localJSONDataDict];
    [self.contentView addSubview:label];   

    [self.requestView addSubview:self.contentView];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mask - button action
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)confirmRequest
{
    self.request.state = FriendRequestApproved;
    [[ModelHelper sharedInstance] createActiveUserWithFullServerJSONData:_localJSONDataDict];
    [[XMPPNetworkCenter sharedClient] acceptPresenceSubscriptionRequestFrom:self.request.requesterEPostalID andAddToRoster:YES];
    [[self appDelegate].contactListController contentChanged];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = T(@"确认成功");
    [HUD hide:YES afterDelay:2];
}

- (void)cancelRequest
{
    self.request.state = FriendRequestDeclined;
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.request.requesterEPostalID withCallbackBlock:nil];
    [[XMPPNetworkCenter sharedClient] rejectPresenceSubscriptionRequestFrom:self.request.requesterEPostalID];

    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.mode = MBProgressHUDModeText;
    HUD.labelText = T(@"取消成功");
    [HUD hide:YES afterDelay:2];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self appDelegate].functionListController.newFriendRequestCount = 0;
    [self appDelegate].functionListController.tabBarItem.badgeValue = nil ;
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

@end
