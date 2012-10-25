//
//  ShakeViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeViewController.h"

@interface ShakeViewController ()

@end

@implementation ShakeViewController
@synthesize shakeImageView;
@synthesize afterView;

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
    
    self.view.backgroundColor = RGBCOLOR(69, 74, 82);
    self.shakeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shake_view.png"]];
    [self.shakeImageView setFrame:CGRectMake(30, 30, 260, 320)];
    
    
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
