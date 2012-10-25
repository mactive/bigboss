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
    UIImageView* shakeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shake_view.png"]];
    [shakeView setFrame:CGRectMake(30, 30, 260, 320)];
    [self.view addSubview:shakeView];
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"glass" ofType:@"wav"];
//	AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnimations) name:@"shake" object:nil];     
    
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
        
    }
}

@end
