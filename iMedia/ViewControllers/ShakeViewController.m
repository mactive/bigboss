//
//  ShakeViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeViewController.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import "NSDate-Utilities.h"
#import <QuartzCore/QuartzCore.h>
#import "AppNetworkAPIClient.h"
#import "ShakeCodeViewController.h"
#import "ShakeEntityViewController.h"

@interface ShakeViewController ()<MBProgressHUDDelegate>
{
    SystemSoundID completeSound;
    MBProgressHUD *HUD;
}

@property(nonatomic, strong) UIImageView *shakeImageView;
@property(nonatomic, strong) UILabel *beginEndTimeLabel;
@property(nonatomic, strong) UIView *afterView;
@property(nonatomic, readwrite) NSUInteger shakeTimes;
@property(nonatomic, readwrite) NSInteger startedMins;
@property(nonatomic, readwrite) NSInteger endedMins;
@property(nonatomic, strong) UIView *shakeTimesView;
@property(nonatomic, strong) UILabel *shakeTimesLabel;
@property(nonatomic, strong) NSMutableDictionary* shakeTimesDict;

@property(nonatomic, readwrite)BOOL canShake; // 可不可以shake
@property(nonatomic, readwrite)BOOL isShaking;
@property(nonatomic, readwrite)BOOL noChance;

@end

@implementation ShakeViewController
@synthesize shakeImageView;
@synthesize beginEndTimeLabel;
@synthesize afterView;
@synthesize shakeData;
@synthesize shakeTimes;
@synthesize startedMins;
@synthesize endedMins;
@synthesize shakeTimesView;
@synthesize shakeTimesLabel;
@synthesize shakeTimesDict;
@synthesize canShake;
@synthesize isShaking;
@synthesize noChance;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [self.shakeData objectForKey:@"name"];
    self.isShaking = NO;
        
    self.shakeTimesDict = [[NSMutableDictionary alloc]initWithDictionary:(NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:@"shakeTimesDict"]];
    self.shakeTimes = [[self.shakeTimesDict objectForKey:[self.shakeData objectForKey:@"id"]] intValue];

    
    // get Big Image
    NSURL * url = [NSURL URLWithString:[self.shakeData objectForKey:@"image"]];
    NSURLRequest *urlRequest = [[NSURLRequest alloc]initWithURL:url];
    self.shakeImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    MBProgressHUD *HUD_t = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD_t.delegate = self;
    HUD_t.labelText = T(@"正在加载");
    
    [self.shakeImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [HUD_t hide:YES afterDelay:2];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        // 
    }];
    [self.shakeImageView setFrame:self.view.bounds];
    
     
    // after view
    self.afterView = [[UIView alloc] initWithFrame:CGRectMake(30, 30, 260, 320)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 260, 40)];
    label.text = T(@"你中奖了");
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:30.0];
    [self.afterView addSubview:label];
    
    [self.view addSubview:self.shakeImageView];
    // ShakeTimesView
    [self initShakeTimesView];    
}
//////////////////////////////////////////////////////
#pragma mark - 根据时间显示
//////////////////////////////////////////////////////

- (void)initShakeTimesView
{
    self.shakeTimesView = [[UIView alloc]initWithFrame:CGRectMake(210, -10, 140, 50)];
    self.shakeTimesView.backgroundColor = RGBCOLOR(47, 47, 47);
    self.shakeTimesView.layer.cornerRadius = 10;
    
    UIImageView *shakeIcon = [[UIImageView alloc]initWithFrame:CGRectMake(8, 15, 30, 30)];
    [shakeIcon setImage:[UIImage imageNamed:@"metro_icon_3.png"]];
    [self.shakeTimesView addSubview: shakeIcon];
    
    self.shakeTimesLabel = [[UILabel alloc]initWithFrame:CGRectMake(45, 18, 60, 24)];
    self.shakeTimesLabel.text = [NSString stringWithFormat:@"%i 次",self.shakeTimes];
    self.shakeTimesLabel.font = [UIFont systemFontOfSize:18];
    self.shakeTimesLabel.backgroundColor = [UIColor clearColor];
    self.shakeTimesLabel.textColor = [UIColor whiteColor];
    self.shakeTimesLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.shakeTimesView addSubview:self.shakeTimesLabel];
    
    //
    self.beginEndTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 180, 40)];
    self.beginEndTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.beginEndTimeLabel.font = [UIFont systemFontOfSize:12.0f];
    self.beginEndTimeLabel.textColor = [UIColor whiteColor];
    self.beginEndTimeLabel.numberOfLines = 2;
    self.beginEndTimeLabel.backgroundColor = RGBACOLOR(47, 47, 47, 0.5);

    [self.view addSubview:self.beginEndTimeLabel];
    [self.view addSubview:self.shakeTimesView];
}

- (void)refreshShakeTimesView
{
    self.shakeTimesLabel.text = [NSString stringWithFormat:@"%i 次",self.shakeTimes];
    
    NSString *tmp = [NSString stringWithFormat:@"%i", self.shakeTimes];
    NSString *ttt = [self.shakeData objectForKey:@"id"];
    [self.shakeTimesDict setObject:tmp forKey:[self.shakeData objectForKey:@"id"]];
  
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.beginEndTimeLabel.text = [NSString stringWithFormat:T(@"开始时间:%@  结束时间:%@"),
                                   [self.shakeData objectForKey:@"begin_time"],
                                   [self.shakeData objectForKey:@"end_time"]];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSDate *beginDate = [dateFormatter dateFromString:[self.shakeData objectForKey:@"begin_time"]];
    NSDate *endDate = [dateFormatter dateFromString:[self.shakeData objectForKey:@"end_time"]];

    NSDate *now = [[NSDate alloc]initWithTimeIntervalSinceNow:0];
    self.startedMins = (NSInteger )[now minutesBeforeDate:beginDate];
    self.endedMins = (NSInteger )[now minutesAfterDate:endDate];
    
    if (self.startedMins > 0) {
        [self MBPShow:T(@"活动还没开始! ")];
        self.canShake = NO;
    }else if(self.endedMins > 0){
        [self MBPShow:T(@"活动还没结束了! ")];
        self.canShake = NO;
    }
    else{
        [self MBPShow:T(@"想得到么, 摇一摇! ")];
        self.canShake = YES;
    }
    
}

- (void)MBPShow:(NSString *)_string
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    UIImageView *custom =  [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"metro_icon_3.png"]];
    [custom setFrame:CGRectMake(0, 0, 50, 50)];
    HUD.customView = custom;
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.delegate = self;
    HUD.labelText = _string;
    [HUD hide:YES afterDelay:1];

}


#pragma mark - 摇一摇动画效果

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
    NSDictionary *tmp_dict = [[NSDictionary alloc]initWithDictionary:self.shakeTimesDict];
    [[NSUserDefaults standardUserDefaults] setObject:tmp_dict forKey:@"shakeTimesDict"];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
 
        // request server
        if (self.isShaking == NO && self.canShake == YES) {
            // your code
            NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"message_3" withExtension:@"wav"];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
            AudioServicesPlaySystemSound (completeSound);
            
            if (self.noChance == YES){
                [self MBPShow:T(@"没有机会了")];
                NSLog(@"没有机会了");
            }else{
                [self getShakeInfoFromServer];
            }
            
        }else{
        }
        
    }
}

-(void)getShakeInfoFromServer
{
    self.isShaking = YES;
    [[AppNetworkAPIClient sharedClient]getShakeInfoWithBlock:^(id responseObject, NSError *error) {
        if (responseObject) {
            self.isShaking = NO;

            NSDictionary *responseDict = responseObject;
            BOOL lucky = [[responseDict objectForKey:@"lucky"] boolValue];
            NSInteger bait_type = [[responseDict objectForKey:@"bait_type"] integerValue];
            BOOL nochance = [[responseDict objectForKey:@"nochance"] boolValue];
            
            if (nochance == YES) {
                self.noChance = YES;
            }
            
            if (lucky && self.noChance == NO) {
                
//                // 正在跳转页面
//                HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//                HUD.mode = MBProgressHUDModeText;
//                HUD.delegate = self;
//                HUD.labelText = T(@"恭喜你摇中了,正在跳转页面.");
//                [HUD showAnimated:YES whileExecutingBlock:^{
//                    //
//                } completionBlock:^{
//                    sleep(2);
//                    [HUD hide:YES];
//                }];
                    // block begin ==========================
                    
                    if ( bait_type == BaitTypeCode) {
                        ShakeCodeViewController *controller = [[ShakeCodeViewController alloc]initWithNibName:nil bundle:nil];
                        controller.codeString = [responseDict objectForKey:@"code"];
                        [controller setHidesBottomBarWhenPushed:YES];
                        [self.navigationController pushViewController:controller animated:YES];
                        
                    }
                    if ( bait_type == BaitTypeFree || bait_type == BaitTypeDiscount) {
                        ShakeEntityViewController *controller = [[ShakeEntityViewController alloc]initWithNibName:nil bundle:nil];
                        controller.shakeData = responseDict;
                        controller.promotionImage = self.shakeImageView.image;
                        controller.priceType = PriceTypePromotion;

                        
                        
                        [controller setHidesBottomBarWhenPushed:YES];
                        [self.navigationController pushViewController:controller animated:YES];
                        
                    }
                    
                    // block end==========================
                    
                
                                
                
                
                
            }else{
                self.shakeTimes +=1;
                [self refreshShakeTimesView];
                [self MBPShow:T(@"没有摇中,再摇一次")];
            }
            
            
        }else{
            self.isShaking = NO;
            [self MBPShow:T(@"网络错误,无法获取信息")];
        }
    }];
}

@end
