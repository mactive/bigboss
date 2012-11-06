//
//  StarViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-6.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "StarViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "Me.h"
#import "ServerDataTransformer.h"
#import "AppNetworkAPIClient.h"

@interface StarViewController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}
@property(strong, nonatomic)UILabel *welcomeLabel;
@property(strong, nonatomic)NSArray *starWordArray;
@property(strong, nonatomic)UIButton *starButton0;
@property(strong, nonatomic)UIButton *starButton1;
@property(strong, nonatomic)UIButton *starButton2;
@property(strong, nonatomic)UIButton *starButton3;
@property(strong, nonatomic)UIButton *starButton4;
@property(strong, nonatomic)NSMutableArray *buttonArray;
@property(strong, nonatomic)UILabel *noticeLabel;
@property(strong, nonatomic)UIButton *sendButton;
@property(strong, nonatomic)UIButton *cancelButton;


@end

@implementation StarViewController

@synthesize welcomeLabel;
@synthesize starWordArray;
@synthesize starButton0;
@synthesize starButton1;
@synthesize starButton2;
@synthesize starButton3;
@synthesize starButton4;
@synthesize buttonArray;
@synthesize noticeLabel;
@synthesize sendButton;
@synthesize cancelButton;
@synthesize conversionKey;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.starWordArray = [[NSArray alloc]initWithObjects:
                              @"1星 很糟糕!",
                              @"2星 不咋地!",
                              @"3星 还行吧!",
                              @"4星 嗯,不错!",
                              @"5星 非常好!",
                              nil];
        [self.view setFrame:CGRectMake(0, 200, 320, 300)];
    }
    return self;
}

#define BUTTON_WIDTH 50
#define BUTTON_PADDING 10
#define BUTTON_LEFT_OFFEST 20

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = RGBACOLOR(255, 255, 255, 1);
    
    self.noticeLabel.text = T(@"请点击星星");
    
    self.starButton0 = [[UIButton alloc] init];
    self.starButton1 = [[UIButton alloc] init];
    self.starButton2 = [[UIButton alloc] init];
    self.starButton3 = [[UIButton alloc] init];
    self.starButton4 = [[UIButton alloc] init];

    
    self.buttonArray = [[NSMutableArray alloc]init];
    [self.buttonArray addObject:self.starButton0];
    [self.buttonArray addObject:self.starButton1];
    [self.buttonArray addObject:self.starButton2];
    [self.buttonArray addObject:self.starButton3];
    [self.buttonArray addObject:self.starButton4];


    
    for (int index = 0; index < [self.buttonArray count]; index++) {
        UIButton *tmpButton = [self.buttonArray objectAtIndex:index];
        [tmpButton setFrame:CGRectMake(BUTTON_LEFT_OFFEST + (BUTTON_WIDTH+BUTTON_PADDING)*index , 200, BUTTON_WIDTH, BUTTON_WIDTH)];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"star_grey.png"] forState:UIControlStateNormal];
        [tmpButton setSelected:NO];
        tmpButton.tag = index;
        [tmpButton addTarget:self action:@selector(starAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:tmpButton];
    }
    
	// Do any additional setup after loading the view.
    self.welcomeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0 , 320, 44)];
    [self.welcomeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.welcomeLabel setBackgroundColor:RGBCOLOR(62, 67, 76)];
    [self.welcomeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.welcomeLabel.textColor = [UIColor whiteColor];
    self.welcomeLabel.numberOfLines = 1;
    self.welcomeLabel.shadowColor = [UIColor blackColor];
    self.welcomeLabel.shadowOffset = CGSizeMake(0, 1);
    self.welcomeLabel.text = T(@"请您对我的服务做出评价");
    [self.view addSubview:self.welcomeLabel];
	// Do any additional setup after loading the view.
    
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 130, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:20.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.text = T(@"请评价");
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    [self.view addSubview:self.noticeLabel];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 320, 275.0f, 40.0f)];
    [self.sendButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.sendButton setTitle:T(@"评价") forState:UIControlStateNormal];
    [self.sendButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.sendButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.sendButton];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 380, 275.0f, 40.0f)];
    [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.cancelButton setTitle:T(@"取消") forState:UIControlStateNormal];
    [self.cancelButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.cancelButton];


}

- (void)starAction:(UIButton *)sender
{
    UIButton *tmpButton = [self.buttonArray objectAtIndex:sender.tag];
    if (tmpButton.selected) {
        [tmpButton setSelected:NO];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"star_grey.png"] forState:UIControlStateNormal];
    }else{
        [tmpButton setSelected:YES];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"star.png"] forState:UIControlStateNormal];
    }
    
    for (int index = 0; index < [self.buttonArray count]; index++) {
        if (index <= sender.tag) {
            UIButton *tmpButton = [self.buttonArray objectAtIndex:index];
            [tmpButton setBackgroundImage:[UIImage imageNamed:@"star.png"] forState:UIControlStateNormal];
            [tmpButton setSelected:YES];
        }else{
            UIButton *tmpButton = [self.buttonArray objectAtIndex:index];
            [tmpButton setBackgroundImage:[UIImage imageNamed:@"star_grey.png"] forState:UIControlStateNormal];
            [tmpButton setSelected:NO];
        }
        
    }
    
    self.noticeLabel.text = [self.starWordArray objectAtIndex:sender.tag];

}

- (void)sendButtonPushed:(id)sender
{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    HUD.labelText = T(@"发送中");
    
    [HUD showAnimated:YES whileExecutingBlock:^{
        sleep(2);
        [HUD hide:YES];
    } completionBlock:^{
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.mode = MBProgressHUDModeText;
        HUD.labelText = T(@"评价成功");
        [HUD hide:YES afterDelay:1];
    }];

}

- (void)cancelButtonPushed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
