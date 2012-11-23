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

@interface ShakeViewController ()<MBProgressHUDDelegate>
{
    SystemSoundID completeSound;
    MBProgressHUD *HUD;
}

@property(nonatomic, strong) UIImageView *shakeImageView;
@property(nonatomic, strong) UIView *afterView;
@end

@implementation ShakeViewController
@synthesize shakeImageView;
@synthesize afterView;
@synthesize shakeData;

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
    
    
    self.afterView = [[UIView alloc] initWithFrame:CGRectMake(30, 30, 260, 320)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 260, 40)];
    label.text = T(@"你中奖了");
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:30.0];
    [self.afterView addSubview:label];
    
    [self.view addSubview:self.shakeImageView];        
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
                
    }
}

@end
