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

@interface ShakeViewController ()<MBProgressHUDDelegate>
{
    SystemSoundID completeSound;
    MBProgressHUD *HUD;
}

@property(nonatomic, strong) UIImageView *shakeImageView;
@property(nonatomic, strong) UIView *afterView;
@property(nonatomic, readwrite) NSUInteger shakeTimes;
@property(nonatomic, readwrite) NSInteger passedMins;
@property(nonatomic, readwrite) BOOL isBegan;
@property(nonatomic, strong) UIView *shakeTimesView;
@property(nonatomic, strong) UILabel *shakeTimesLabel;
@property(nonatomic, strong) NSMutableDictionary* shakeTimesDict;
@end

@implementation ShakeViewController
@synthesize shakeImageView;
@synthesize afterView;
@synthesize shakeData;
@synthesize shakeTimes;
@synthesize passedMins;
@synthesize isBegan;
@synthesize shakeTimesView;
@synthesize shakeTimesLabel;
@synthesize shakeTimesDict;

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
    self.title = [self.shakeData objectForKey:@"promotion_name"];
    

        
    self.shakeTimesDict = [[NSMutableDictionary alloc]initWithDictionary:(NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:@"shakeTimesDict"]];
    self.shakeTimes = [[self.shakeTimesDict objectForKey:[self.shakeData objectForKey:@"promotion_id"]] intValue];

    
    // get Big Image
    NSURL * url = [NSURL URLWithString:[self.shakeData objectForKey:@"image"]];
    NSURLRequest *urlRequest = [[NSURLRequest alloc]initWithURL:url];
    self.shakeImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在加载");
    
    [self.shakeImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [self.shakeImageView setImage:image];
        [HUD hide:YES afterDelay:2];
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
    
    [self.view addSubview:self.shakeTimesView];
}

- (void)refreshShakeTimesView
{
    self.shakeTimesLabel.text = [NSString stringWithFormat:@"%i 次",self.shakeTimes];
    
    NSString *tmp = [NSString stringWithFormat:@"%i", self.shakeTimes];
    NSString *ttt = [self.shakeData objectForKey:@"promotion_id"];
    [self.shakeTimesDict setObject:tmp forKey:[self.shakeData objectForKey:@"promotion_id"]];
  
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSDate *updateDate = [dateFormatter dateFromString:[self.shakeData objectForKey:@"start_time"]];

    NSDate *now = [[NSDate alloc]initWithTimeIntervalSinceNow:0];
    self.passedMins = (NSInteger )[now minutesBeforeDate:updateDate];
    if (self.passedMins > 0) {
        [self MBPShow:T(@"活动还没开始! ")];
        self.isBegan = NO;
    }else{
        [self MBPShow:T(@"想得到么, 摇一摇! ")];
        self.isBegan = YES;
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
    [HUD hide:YES afterDelay:2];
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
        // your code
        NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"message_3" withExtension:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
        AudioServicesPlaySystemSound (completeSound);
        
#warning  send to server and get is getted
        BOOL getted = NO;
        
        if (getted) {
            [self MBPShow:T(@"恭喜你摇中了! ")];
#warning show the next button and push shake form view

            
        }else{
            self.shakeTimes +=1;
            [self refreshShakeTimesView];
            [self MBPShow:T(@"没有摇中,再摇一次")];
        }

        /*
        
        [UIView animateWithDuration:0.7f animations:^
         {
             [self.shakeImageView setAlpha:0];
         }
                         completion:^(BOOL finished)
         {
             [self.shakeImageView removeFromSuperview];
             [self.view addSubview:self.afterView];

         }
        ];
         */
                
    }
}

@end
