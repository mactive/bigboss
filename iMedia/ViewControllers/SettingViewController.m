//
//  SettingViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "SettingViewController.h"
#import "ProfileMeController.h"
#import "RequestViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Me.h" 
#import "AppDelegate.h"
#import "RateViewController.h"

@interface SettingViewController () 

@property(nonatomic, strong) UITableView *settingTableView;
@property(nonatomic, strong) UIButton *loginButton;

@property(nonatomic, strong) NSArray *settingTitleArray;
@property(nonatomic, strong) UIButton *logoutButton;
@property (strong, nonatomic) Me *me;
@property (nonatomic, strong) UIImageView *myAvatar;

@end



@implementation SettingViewController

@synthesize settingTableView;
@synthesize loginButton;
@synthesize settingTitleArray;
@synthesize managedObjectContext;
@synthesize logoutButton;
@synthesize me;
@synthesize myAvatar;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.me = [self appDelegate].me ;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thumbnailChanged:)
                                                     name:THUMBNAIL_IMAGE_CHANGE_NOTIFICATION object:self.me];
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)loadView{
    [super loadView];
//    UIImageView *tabbarBgView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigationBar_bg.png"]];
//    [self.navigationController.navigationBar insertSubview:tabbarBgView atIndex:1];
//    [self.navigationController.navigationBar setBackgroundColor:[UIColor blackColor]];
    CGRect imageRect = CGRectMake(220, 5,  50, 50);
    self.myAvatar = [[UIImageView alloc] initWithFrame:imageRect];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"个人设置",nil],
                              [[NSArray alloc] initWithObjects:@"App精品推荐", nil],
                              [[NSArray alloc] initWithObjects:@"去春水堂打个分吧",@"帮助与反馈",@"关于春水堂", nil],
                              nil ];
    //,@"我的相册",@"新浪微博",@"微信朋友圈"
    
    CGRect rect = CGRectMake(0, 0, 320, 370);
    self.settingTableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStyleGrouped];
    self.settingTableView.dataSource = self;
    self.settingTableView.delegate = self;

    [self.view addSubview:self.settingTableView];
    
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
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    cell.backgroundView.backgroundColor = RGBCOLOR(86, 184, 225);
    
    NSUInteger labelY = 12;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        // Create an image view for the quarter image
        CALayer *avatarLayer = [self.myAvatar layer];
        [avatarLayer setMasksToBounds:YES];
        [avatarLayer setCornerRadius:5.0];
        [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
        [self.myAvatar setImage:self.me.thumbnailImage];
        [cell.contentView addSubview:self.myAvatar];
        labelY = 20;
    }
    
    if (indexPath.section == 1 || (indexPath.section ==2 && indexPath.row == 0) ) {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, labelY, 140, 20)];
    titleLabel.text = [[self.settingTitleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(77, 77, 77);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0 && indexPath.section == 0 ) {
        ProfileMeController *profileMeController = [[ProfileMeController alloc] initWithNibName:nil bundle:nil];
        profileMeController.managedObjectContext = self.managedObjectContext;
        
        [self.navigationController pushViewController:profileMeController animated:YES];
    }
    
    if (indexPath.row == 0 && indexPath.section == 2 ) {
        RateViewController *rateViewController = [[RateViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController presentModalViewController:rateViewController animated:YES];
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
