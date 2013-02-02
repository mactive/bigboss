//
//  ShakeDashboardViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-22.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeDashboardViewController.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "TrapezoidLabel.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "ShakeViewController.h"
#import "CheckinNoteViewController.h"
#import "ShakeInfo.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface ShakeDashboardViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    ShakeInfo     *_shakeInfo;
}

@property(nonatomic, strong) UIView *checkinView;
@property(nonatomic, strong) UIImageView *checkinImageView;
@property(nonatomic, strong) UILabel *checkinLabel;
@property(nonatomic, strong) UIButton *checkinButton;
@property(nonatomic, strong) UIButton *checkinOverlayButton;
@property(nonatomic, strong) UIView *checkinBottomLineView;

@property(nonatomic, strong) NSMutableArray *urlArray;
@property(nonatomic, strong) NSArray *dataArray;
@property(nonatomic, strong) NSMutableDictionary *shakeTimesDict;
@property(nonatomic, strong) UIImageView *replaceView;
@property(nonatomic, strong) UIImageView *inprogressImageView;
@property(nonatomic, strong) UIScrollView *baseView;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIButton *barButton;


@end

@implementation ShakeDashboardViewController

@synthesize managedObjectContext;
@synthesize checkinLabel;
@synthesize checkinView;
@synthesize checkinImageView;
@synthesize checkinButton;
@synthesize checkinOverlayButton;
@synthesize checkinBottomLineView;
@synthesize urlArray;
@synthesize dataArray;
@synthesize shakeTimesDict;
@synthesize replaceView;
@synthesize baseView;
@synthesize tableView;
@synthesize barButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // refresh button
        UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 29)];
        [button1 setBackgroundImage:[UIImage imageNamed: @"barbutton_refresh.png"] forState:UIControlStateNormal];
        [button1 addTarget:self action:@selector(populateData) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button1];
        
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


#define FIRST_TAG 0

#define ROW_HEIGHT 140
#define CHECKIN_HEIGHT 126

#define TITLE_TAG 1
#define SUBTITLE_TAG 2
#define IMAGE_TAG 3

#define TITLE_HEIGHT 20
#define SUBTITLE_HEIGHT 15
#define SUBTITLE_WIDTH 87

#define MAIN_FONT_SIZE 14.0
#define SUMMARY_FONT_SIZE 12.0


- (void) initShakeData
{
    if (_shakeInfo == nil) {
        NSManagedObjectContext *moc = self.managedObjectContext;
        NSEntityDescription *entityDescription = [NSEntityDescription
                                                  entityForName:@"ShakeInfo" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        NSError *error = nil;
        NSArray *array = [moc executeFetchRequest:request error:&error];
        
        if ([array count] == 0)
        {
            _shakeInfo = [NSEntityDescription insertNewObjectForEntityForName:@"ShakeInfo" inManagedObjectContext:self.managedObjectContext];
        } else {
            _shakeInfo = [array objectAtIndex:0];
        }
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"摇一摇");
    _shakeInfo = nil;
    
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    self.tableView.scrollsToTop = YES;

    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    [self.view addSubview:self.tableView];
    

    [self initShakeData];
    
    // checkinView
    self.checkinView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, CHECKIN_HEIGHT)];
    self.checkinView.backgroundColor = RGBCOLOR(237, 223, 214);
    
    // checkinImageView
    self.checkinImageView = [[UIImageView alloc]initWithFrame:CGRectMake(90, 24, 128, 56)];
    [self.checkinImageView setImage:[UIImage imageNamed:@"checkin_image.png"]];
    [self.checkinView addSubview:self.checkinImageView];
    
    self.checkinBottomLineView = [[UIView alloc]initWithFrame:CGRectMake(0, CHECKIN_HEIGHT-1, 320, 1)];
    self.checkinBottomLineView.backgroundColor = RGBCOLOR(235, 147, 109);
    [self.checkinView addSubview:self.checkinBottomLineView];
    
    // checkButton
    UIImageView *checkinButtonImage = [[ UIImageView alloc]initWithFrame:CGRectMake(0, 1, 12, 12)];
    [checkinButtonImage setImage:[UIImage imageNamed:@"arraw_icon.png"]];
    
    self.checkinButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.checkinButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 13, 0, 0)];
    [self.checkinButton addSubview:checkinButtonImage];
    [self.checkinButton setTitle:T(@"点击进入摇一摇签到") forState:UIControlStateNormal];
    [self.checkinButton setTitleColor:RGBCOLOR(195, 70, 21) forState:UIControlStateNormal];
    self.checkinButton.backgroundColor = [UIColor clearColor];
    self.checkinButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.checkinButton.layer.cornerRadius = 5.0f;
    self.checkinButton.frame = CGRectMake(95, 100, 130, 14);
    [self.checkinView addSubview:self.checkinButton];
    
    
    // Create a label for the subtitle.
    TrapezoidLabel *subTitle =[[TrapezoidLabel alloc] initWithFrame:CGRectMake(0, 0, SUBTITLE_WIDTH, SUBTITLE_HEIGHT)];
    subTitle.textColor = [UIColor whiteColor];
    subTitle.numberOfLines = 1;
    subTitle.backgroundColor = [UIColor clearColor];
    subTitle.bgColor = RGBCOLOR(195, 70, 21);
    subTitle.text = T(@"摇一摇签到");
    [self.checkinView addSubview:subTitle];
    
    // overlay button
    self.checkinOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.checkinOverlayButton.backgroundColor = [UIColor clearColor];
    self.checkinOverlayButton.enabled = YES;
    [self.checkinOverlayButton setFrame:self.checkinView.bounds];
    [self.checkinOverlayButton addTarget:self action:@selector(checkinAction) forControlEvents:UIControlEventTouchUpInside];
    [self.checkinView addSubview:self.checkinOverlayButton];
    
//    self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, CHECKIN_HEIGHT)];
//    [self.tableView.tableHeaderView addSubview:self.checkinView];
    
    // did load populate
    [self populateData];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ShakeDashboard";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuring table view cells
////////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    CGRect rect;
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(0, 0, 320, ROW_HEIGHT);
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = IMAGE_TAG;
    avatarImage.contentMode = UIViewContentModeScaleAspectFit;

    [cell.contentView addSubview:avatarImage];
    
    // Create a label for the subtitle.
	rect = CGRectMake(0, 0, SUBTITLE_WIDTH, SUBTITLE_HEIGHT);
    TrapezoidLabel *subTitle =[[TrapezoidLabel alloc] initWithFrame:rect];
    subTitle.textColor = [UIColor whiteColor];
	subTitle.tag = SUBTITLE_TAG;
    subTitle.numberOfLines = 1;
    subTitle.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:subTitle];
    
    // Create a label for title
	rect = CGRectMake(0, ROW_HEIGHT- TITLE_HEIGHT, 320, TITLE_HEIGHT);
    UILabel * label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TITLE_TAG;
    label.numberOfLines = 1;
	label.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(255, 255, 255);
    label.backgroundColor = RGBACOLOR(0, 0, 0, 0.5);
    
	[cell.contentView addSubview:label];
    
    return  cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary * data = [self.dataArray objectAtIndex:indexPath.row];
    
    // set
    UIImageView *imageView;
    BOOL ISINPROGRESS = indexPath.row == 0 ? YES: NO; // 默认有一个正在进行的活动
    
    //set avatar
    imageView = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
    
    if (StringHasValue([data objectForKey:@"id"])) {
        NSURL *url = [NSURL URLWithString:[data objectForKey:@"thumbnail"]];
        [imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    }else{
        [imageView setImage:[UIImage imageNamed:@"shake_replace.png"]];
    }
    
    
    
    // set the subtitle text
    TrapezoidLabel *subTitle = (TrapezoidLabel *)[cell viewWithTag:SUBTITLE_TAG];
    if (ISINPROGRESS) {
        subTitle.text = T(@"正在进行的活动");
        subTitle.bgColor = RGBCOLOR(204, 31, 31);
    }else{
        subTitle.text = T(@"即将开始的活动");
        subTitle.bgColor = RGBCOLOR(100, 100, 100);
    }
    
    // title
    UILabel *title = (UILabel *)[cell viewWithTag:TITLE_TAG];    
    if (StringHasValue([data objectForKey:@"id"])) {
        title.text = [NSString stringWithFormat:@"  %@",[data objectForKey:@"name"]];
        [title setHidden:NO];
    }else{
//        title.text = [NSString stringWithFormat:@"  %@",T(@"暂时没有活动")];
        [title setHidden:YES];
    }
    
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *rowData = [self.dataArray objectAtIndex:indexPath.row];
    if ( StringHasValue([rowData objectForKey:@"id"]) ) {
        ShakeViewController *controller = [[ShakeViewController alloc]initWithNibName:nil bundle:nil];
        controller.shakeData = rowData;
        controller.managedObjectContext = self.managedObjectContext;
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}
//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - click actions
//////////////////////////////////////////////////////////////////////////////////////////
- (void)checkinAction
{
    CheckinNoteViewController *controller = [[CheckinNoteViewController alloc]initWithNibName:nil bundle:nil];
    [controller setHidesBottomBarWhenPushed:YES];
    controller.managedObjectContext = self.managedObjectContext;
    controller.shakeInfo = _shakeInfo;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)populateData
{
    self.urlArray  = [[NSMutableArray alloc]init];

    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载信息");
    
    self.shakeTimesDict = [[NSMutableDictionary alloc]init];
    
    // 先全部不显示
//    [self allButtonHide];

    [[AppNetworkAPIClient sharedClient]getShakeDashboardInfoWithBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        if (responseObject != nil) {
            NSDictionary *responseDict = responseObject;
            NSDictionary *inprogressDict = [responseDict objectForKey:@"inprogress"];
            NSDictionary *waitingDict = [responseDict objectForKey:@"waiting"];
 
            if (inprogressDict) {
                
                [self.urlArray addObject:inprogressDict];

                // set shaketime user default
                NSString *key = [inprogressDict objectForKey:@"id"];
                if ([[self.shakeTimesDict objectForKey:key] length] == 0) {
                    [self.shakeTimesDict setObject:@"" forKey:key];
                }
            }else{
                NSDictionary * emptyDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"inprogress",@"type", nil];
                [self.urlArray insertObject:emptyDict atIndex:FIRST_TAG];
            }
            
            if (waitingDict) {
                for (int j = 0; j < [waitingDict count]; j++) {
                    
                    NSDictionary *waitingItem = [waitingDict objectForKey:[NSString stringWithFormat:@"%i",j]];

                    // base in server time not local time
                    NSMutableDictionary *passValueItem = [[NSMutableDictionary alloc]initWithDictionary:waitingItem];
                    [passValueItem setValue:@"NO" forKey:@"server_began"];
                    
                    [self.urlArray addObject:passValueItem];
                    
                    // set shaketime user default
                    NSString *key = [waitingItem objectForKey:@"id"];
                    if ([[self.shakeTimesDict objectForKey:key] length] == 0) {
                        [self.shakeTimesDict setObject:@"" forKey:key];
                    }
                }
            }else{
                NSDictionary * emptyDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"waiting",@"type", nil];
                [self.urlArray insertObject:emptyDict atIndex:FIRST_TAG+1];
            }
            
            NSDictionary *tmp_dict = [[NSDictionary alloc]initWithDictionary:self.shakeTimesDict];
            [[NSUserDefaults standardUserDefaults] setObject:tmp_dict forKey:@"shakeTimesDict"];
            
            // 都有的时候才去掉替代显示
            if (inprogressDict != nil && waitingDict != nil) {
                [self.replaceView removeFromSuperview];
            }
            
            self.dataArray  = [[NSArray alloc]initWithArray:self.urlArray];
            DDLogVerbose(@"### %@",self.urlArray);
            
            [self.tableView reloadData];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.navigationController.view animated:YES text:T(@"网络错误,无法获取信息") andHideAfterDelay:1];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
