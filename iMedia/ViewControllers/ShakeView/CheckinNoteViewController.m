//
//  CheckinNoteViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-23.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "CheckinNoteViewController.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "NSDate-Utilities.h"
#import "ShakeCodeViewController.h"
#import "ShakeEntityViewController.h"
#import "ShakeViewController.h"
#import "ServerDataTransformer.h"

#define ROW_HEIGHT 50

@interface CheckinNoteViewController ()
{
    SystemSoundID _completeSound;
}
@property(nonatomic, strong)NSArray *dataArray;
@property(nonatomic, strong)UIView *noticeView;
@property(nonatomic, strong)UILabel *noticeLabel;
@property(nonatomic, readwrite)NSInteger checkinDays;
@property(nonatomic, readwrite)BOOL isTodayChecked;
@property(nonatomic, strong)NSString *agg;

@end

@implementation CheckinNoteViewController
@synthesize dataArray;
@synthesize noticeView;
@synthesize noticeLabel;
@synthesize checkinDays;
@synthesize isTodayChecked;
@synthesize shakeInfo;
@synthesize managedObjectContext;
@synthesize agg;

#define DESC_TAG 10
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

NSInteger intSort(id num1, id num2, void *context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

    self.title = T(@"连续签到奖励");
    [self initNoticeView];
    // get from parent info
    
    NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"message_3" withExtension:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &_completeSound);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self populateData];
}


- (void)populateData
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载信息");
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[AppNetworkAPIClient sharedClient]getCheckinInfoWithBlock:^(id responseObject, NSError *error) {
        if (responseObject) {
            [HUD hide:YES];
            NSDictionary *responseDict = responseObject;
            NSDictionary *item = [[NSDictionary alloc]init];
            NSMutableArray *tempArray = [[NSMutableArray alloc]init];
            NSMutableArray *allKeyArray = [NSMutableArray arrayWithArray:[responseDict allKeys]];
            for (int k = 0; k < [allKeyArray count]; k++) {
                if ([[allKeyArray objectAtIndex:k] isEqualToString:@"agg"]) {
                    [allKeyArray removeObjectAtIndex:k];
                }
            }
            
            NSArray *keyArray = [allKeyArray sortedArrayUsingFunction:intSort context:NULL];
            
            for (int j = 0;  j< [keyArray count]; j++) {
                NSString * KEY = [keyArray objectAtIndex:j];
                item = [[NSDictionary alloc]initWithObjectsAndKeys:KEY,@"day",[responseDict objectForKey:KEY] ,@"reward", nil];
                [tempArray addObject:item];
            }
            self.dataArray  = tempArray;
            self.agg = [ServerDataTransformer getStringObjFromServerJSON:responseObject byName:@"agg"];
            
            [self refreshNoticeView];
            
            [self.tableView reloadData];
        }else{
            [HUD hide:YES];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误,无法获取信息") andHideAfterDelay:1];
        }
    }];

}


- (void)refreshNoticeView
{
    self.checkinDays = [self.shakeInfo.daysContinued integerValue];
    if ([self.shakeInfo.lastShakeDate isToday]) {
        self.isTodayChecked = YES;
    }else{
        self.isTodayChecked = NO;
    }
    
    
    NSString * noticeString = @"";
    NSString * checkInSum = @"";
    if (self.isTodayChecked == NO) {
        noticeString = T(@"你今天还没签到呢.");
    }else{
        noticeString = T(@"你今天已经签到过了.");
    }

    if (self.checkinDays == 0) {
        noticeString = T(@"还没签到过,摇动手机签到.");
    }else{
        noticeString = [NSString stringWithFormat:T(@"你已经连续签到 %i 天,看看都能获得那些奖品吧."), self.checkinDays ];
    }
    
    if (StringHasValue(self.agg)) {
        checkInSum = [NSString stringWithFormat:T(@"已经有 %@ 人签到过了."), self.agg ];
    }
    
    self.noticeLabel.text = [NSString stringWithFormat:@"%@ \n%@",noticeString,checkInSum];
}


- (void)updateShakeInfo
{
    // get op 13
//    then set
//    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    HUD.delegate = self;
//    HUD.labelText = T(@"正在加载信息");
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[AppNetworkAPIClient sharedClient]sendCheckinMessageWithBlock:^(id responseObject, NSError *error) {
        if (responseObject) {
//            [HUD hide:YES];
//            [self MBPShow:T(@"今天签到成功")];

            NSDictionary *responseDict = responseObject;
            BOOL lucky = [[responseDict objectForKey:@"lucky"] boolValue];
            NSInteger bait_type = [[responseDict objectForKey:@"bait_type"] integerValue];

            // update database
            self.shakeInfo.daysContinued = [NSNumber numberWithInt:[[responseDict objectForKey:@"days"] intValue]];
            self.shakeInfo.lastShakeDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
            if (lucky) {

//                // 正在跳转页面
//                HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//                HUD.mode = MBProgressHUDModeText;
//                HUD.delegate = self;
//                HUD.labelText = T(@"恭喜你签到成功,并获得了奖品.");
//                [HUD showAnimated:YES whileExecutingBlock:^{
//                    // nothing
//                } completionBlock:^{
//                    sleep(2);
//                    [HUD hide:YES];
//                }];
                    // block begin ==========================
                    
                    if ( bait_type == BaitTypeCode) {
                        ShakeCodeViewController *controller = [[ShakeCodeViewController alloc]initWithNibName:nil bundle:nil];
                        controller.codeString = [responseDict objectForKey:@"code"];
                        controller.managedObjectContext = self.managedObjectContext;
                        [controller setHidesBottomBarWhenPushed:YES];
                        [self.navigationController pushViewController:controller animated:YES];
                        
                    }
                    if ( bait_type == BaitTypeFree || bait_type == BaitTypeDiscount) {
                        ShakeEntityViewController *controller = [[ShakeEntityViewController alloc]initWithNibName:nil bundle:nil];
                        controller.shakeData = responseDict;
                        controller.priceType = PriceTypeCheckin;
                        
                        
                        [controller setHidesBottomBarWhenPushed:YES];
                        [self.navigationController pushViewController:controller animated:YES];
                        
                    }
                    
                    // block end==========================
               

                
            }else{
                [self MBPShow:T(@"今天签到成功")];
                [self refreshNoticeView];

            }
            
            
        }else{
            //[HUD hide:YES];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误,无法获取信息") andHideAfterDelay:1];
        }
    }];

}




//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - init and refresh notice view
//////////////////////////////////////////////////////////////////////////////////////////////////
- (void)initNoticeView
{
    self.noticeView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, ROW_HEIGHT+20)];
    
    self.noticeView.backgroundColor = RGBCOLOR(235, 147, 109);
    
    UIImageView *checkinButtonImage = [[ UIImageView alloc]initWithFrame:CGRectMake(16, 16, 36, 36)];
    [checkinButtonImage setImage:[UIImage imageNamed:@"metro_icon_3.png"]];
    
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 5, 220, 60)];
    self.noticeLabel.numberOfLines = 0;
    self.noticeLabel.textColor = RGBCOLOR(255, 255, 255);
    self.noticeLabel.backgroundColor = [UIColor clearColor];
    self.noticeLabel.font = [ UIFont systemFontOfSize:14.0f];
    self.noticeLabel.textAlignment = NSTextAlignmentLeft;
    
    [self.noticeView addSubview:checkinButtonImage];
    [self.noticeView addSubview:self.noticeLabel];

    
    self.tableView.tableHeaderView = self.noticeView;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - shake view
//////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}
//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - shake and checkin
//////////////////////////////////////////////////////////////////////////////////////////////////

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        
        AudioServicesPlaySystemSound (_completeSound);
        
        if (self.isTodayChecked) {
            [self MBPShow:T(@"今天已经签过了")];
        }else {
            [self updateShakeInfo];
        }
    }
}

- (void)MBPShow:(NSString *)_string
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    UIImageView *custom =  [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"metro_icon_3.png"]];
    [custom setFrame:CGRectMake(0, 0, 50, 50)];
    HUD.customView = custom;
    HUD.removeFromSuperViewOnHide = YES;
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = _string;
    [HUD hide:YES afterDelay:1];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CheckinCell";
    
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

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
//    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
//    cell.backgroundView = cellBgView;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.textColor = RGBCOLOR(195, 70, 21);
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.layer.cornerRadius = 5.0f;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(100, 15, 200, 20)];
    label.tag = DESC_TAG;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    
    [cell.contentView addSubview:label];
    
    return  cell;
}
#define SUMMARY_WIDTH 200.0
#define LABEL_HEIGHT 20.0



- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"第 %@ 天" ,[data objectForKey:@"day"]];
    
    UILabel *signatureLabel = (UILabel *)[cell viewWithTag:DESC_TAG];
    CGFloat _labelHeight;

    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);

    CGSize signatureSize = [[data objectForKey:@"reward"] sizeWithFont:signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > LABEL_HEIGHT) {
        _labelHeight = 5.0;
    }else {
        _labelHeight = 15.0;
    }
    signatureLabel.text = [data objectForKey:@"reward"];
    signatureLabel.frame = CGRectMake(100 , _labelHeight, signatureSize.width, signatureSize.height);
    
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
