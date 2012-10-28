//
//  SettingViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "SettingViewController.h"
#import "ProfileMeController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

@synthesize settingTableView;
@synthesize loginButton;
@synthesize settingTitleArray;
@synthesize settingDescArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView{
    [super loadView];
    UIImageView *tabbarBgView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigationBar_bg.png"]];
    [self.navigationController.navigationBar insertSubview:tabbarBgView atIndex:1];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor blackColor]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"个人信息",@"我的相册",@"新浪微博",@"微信朋友圈", nil],
                              [[NSArray alloc] initWithObjects:@"去给翼石打个分吧",@"帮助与反馈",@"关于翼石",@"App精品推荐", nil],
                              nil ];
    
    
    self.settingDescArray = [[NSArray alloc] initWithObjects:
                          @"夫和实生物，同则不继。以他平他谓之和故能丰长而物归之",
                          @"老莫  13899763487",
                          @"IT工程师",
                          @"山东 聊城",
                          @"我不是那个史上最牛历史老师！我们中国的教科书属于秽史，请同学们考完试抓紧把它们烧了，放家里一天，都脏你屋子。", nil];
    
    self.settingTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.settingTableView.dataSource = self;
    self.settingTableView.delegate = self;
//    [self.settingTableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.settingTableView];
    
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
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
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    cell.backgroundView.backgroundColor = RGBCOLOR(248, 248, 248);
    
    cell.selectedBackgroundView.backgroundColor =  RGBCOLOR(228, 228, 228);
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 140, 20)];
    titleLabel.text = [[self.settingTitleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(77, 77, 77);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
    //    cell.textLabel.text = [self.infoArray objectAtIndex:indexPath.row];
    //    cell.textLabel.textColor = RGBCOLOR(155, 161, 172);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && indexPath.section == 0 ) {
        ProfileMeController *profileMeController = [[ProfileMeController alloc] initWithNibName:nil bundle:nil];
//        [profileMeController setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:profileMeController animated:YES];
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

@end
