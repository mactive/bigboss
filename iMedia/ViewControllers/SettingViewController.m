//
//  SettingViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "SettingViewController.h"
#import "ProfileMeController.h"
#import <QuartzCore/QuartzCore.h>
#import "Me.h" 
#import "AppDelegate.h"
#import "RateViewController.h"
#import "FeedBackViewController.h"
#import "AboutUsViewController.h"
#import "ModelHelper.h"
#import "ShakeCodeViewController.h"
#import "ShakeAddressViewController.h"
#import "MemoViewController.h"
#import "FeedBackViewController.h"
#import "PrivacyViewController.h"
#import "ConfigSetting.h"

@interface SettingViewController ()<UIActionSheetDelegate,UIAlertViewDelegate>

@property(nonatomic, strong) UIActionSheet *logoutActionsheet;
@property(nonatomic, strong) UITableView *settingTableView;
@property(nonatomic, strong) UIButton *loginButton;
@property(nonatomic, strong) UISwitch *privacySwitch;
@property(nonatomic, strong) UIAlertView *privacyAlert;
@property(nonatomic, strong) NSArray *settingTitleArray;
@property (strong, nonatomic) Me *me;
@property (nonatomic, strong) UIImageView *myAvatar;
@property(nonatomic, strong) UIButton *barButton;
@end



@implementation SettingViewController

@synthesize logoutActionsheet;
@synthesize settingTableView;
@synthesize loginButton;
@synthesize settingTitleArray;
@synthesize managedObjectContext;
@synthesize me;
@synthesize myAvatar;
@synthesize privacySwitch;
@synthesize privacyAlert;
@synthesize barButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.me = [self appDelegate].me ;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thumbnailChanged:)
                                                     name:THUMBNAIL_IMAGE_CHANGE_NOTIFICATION object:self.me];
        
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)dealloc
{
    NotificationsUnobserve();
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)loadView{
    [super loadView];

    CGRect imageRect = CGRectMake(220, 5,  50, 50);
    self.myAvatar = [[UIImageView alloc] initWithFrame:imageRect];
    self.myAvatar.contentMode = UIViewContentModeScaleToFill;
    self.myAvatar.clipsToBounds = YES;

    CALayer *avatarLayer = [self.myAvatar layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"个人设置",nil],
                              [[NSArray alloc] initWithObjects:@"隐私保护",@"优惠码备忘录", nil],
                              [[NSArray alloc] initWithObjects:@"去大掌柜打个分吧",@"帮助与反馈",@"关于大掌柜", nil],
                              [[NSArray alloc] initWithObjects:@"退出登录",nil],
                              nil ];
    //,@"我的相册",@"新浪微博",@"微信朋友圈"
    
    self.settingTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.settingTableView.dataSource = self;
    self.settingTableView.delegate = self;

    [self.view addSubview:self.settingTableView];

    self.privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(210, 10, 50, 20)];
    [self.privacySwitch addTarget:self action:@selector(privacyChanged) forControlEvents:UIControlEventValueChanged];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    if([ConfigSetting isSettingEnabled:self.me.config withSetting:CONFIG_PRIVACY_REQUIRED]){
        [self.privacySwitch setOn:YES animated:NO];
    }else{
        [self.privacySwitch setOn:NO animated:NO];
    }
    
    [self.myAvatar setImage:self.me.thumbnailImage];
}

- (void)privacyChanged{
    if (self.privacySwitch.on) {
        PrivacyViewController *controller = [[PrivacyViewController alloc]initWithNibName:nil bundle:nil];
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController presentModalViewController:controller animated:YES];
    }else{
        self.privacyAlert = [[UIAlertView alloc]initWithTitle:T(@"取消隐私保护")
                                                        message:T(@"即将解除隐私保护.请注意保护你的隐私.不要将手机轻易借给他人.")
                                                       delegate:self
                                              cancelButtonTitle:T(@"取消")
                                              otherButtonTitles:T(@"确定"), nil];
        [self.privacyAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:self.privacyAlert]) {
        if (buttonIndex == 0){
            //cancel clicked ...do your action
            [self.privacySwitch setOn:YES animated:NO];
        }else if (buttonIndex == 1){
            self.me.config = [ConfigSetting disableConfig:[self appDelegate].me.config withSetting:CONFIG_PRIVACY_REQUIRED];
            self.me.privacyPass = nil;
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 60;
    }else{
        return 44.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.settingTitleArray count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.settingTitleArray objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    return cell;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableViewCellWithReuseIdentifier
////////////////////////////////////////////////////////////////////////////////

#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    
    
    NSUInteger labelY = 12;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        // Create an image view for the quarter image
        [cell.contentView addSubview:self.myAvatar];
        labelY = 20;
    }
    
    if (indexPath.section == 1 || (indexPath.section ==2 && indexPath.row == 0) || (indexPath.section ==3 && indexPath.row == 0) ) {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, labelY, 280, 20)];
    titleLabel.text = [[self.settingTitleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(77, 77, 77);
    titleLabel.backgroundColor = [UIColor clearColor];
    
    if (indexPath.row ==0 && indexPath.section == 3) {
        cell.backgroundColor = RGBCOLOR(160, 8, 8);
        titleLabel.textColor = RGBCOLOR(255, 255, 255);
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
    }
    
    [cell addSubview:titleLabel];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        [cell addSubview:self.privacySwitch];
        [cell setSelectionStyle:UITableViewCellEditingStyleNone];
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0 && indexPath.section == 0 ) {
        ProfileMeController *profileMeController = [[ProfileMeController alloc] initWithNibName:nil bundle:nil];
        profileMeController.managedObjectContext = self.managedObjectContext;
        [profileMeController setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:profileMeController animated:YES];
    }
    
    
    if (indexPath.row == 1 && indexPath.section == 1 ) {
        MemoViewController *controller = [[MemoViewController alloc]initWithNibName:nil bundle:nil];
        controller.managedObjectContext = self.managedObjectContext;
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
        //        [self.navigationController presentModalViewController:controller animated:YES];
    }
    
    if (indexPath.row == 0 && indexPath.section == 2 ) {
        // 打分 评价
        NSString *str = [NSString stringWithFormat:
                         @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d",
                         M_APPLEID ];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    }
    if (indexPath.row == 1 && indexPath.section == 2 ) {
        FeedBackViewController *controller = [[FeedBackViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    if (indexPath.row == 2 && indexPath.section == 2 ) {
        AboutUsViewController *controller = [[AboutUsViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    if (indexPath.row == 0 && indexPath.section == 3 ) {
        [self logoutAction];
    }

}
/////////////////////////////////////////////
#pragma mark - logout
////////////////////////////////////////////

- (void)logoutAction
{
    self.logoutActionsheet = [[UIActionSheet alloc]
                              initWithTitle:T(@"程序内所有数据都将被删除")
                              delegate:self
                              cancelButtonTitle:T(@"取消")
                              destructiveButtonTitle:T(@"退出登录")
                              otherButtonTitles:nil];
    self.logoutActionsheet.actionSheetStyle = UIActionSheetStyleDefault;
    [self.logoutActionsheet showFromRect:self.view.bounds inView:self.view animated:YES];
}


/////////////////////////////////////////////
#pragma mark - uiactionsheet delegate 
////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 && [self.logoutActionsheet isEqual:actionSheet] ) {
        [[self appDelegate] clearSession];
        [[ModelHelper sharedInstance] clearAllObjects];
        
        [[self appDelegate] startIntroSession];
    }

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

- (void)thumbnailChanged:(NSNotification *)notification
{
    [self.myAvatar setImage:self.me.thumbnailImage];
}

@end
