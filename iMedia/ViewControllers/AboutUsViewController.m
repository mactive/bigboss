//
//  AboutUsViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-8.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "AboutUsViewController.h"
#import "AppDefs.h"
@interface AboutUsViewController ()

@property(strong, nonatomic)UIImageView *usLogo;
@property(strong, nonatomic)UILabel *usLabel;
@property(strong, nonatomic)UILabel *usVersion;
@end

@implementation AboutUsViewController

@synthesize usLogo;
@synthesize usLabel;
@synthesize usVersion;

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
    
    self.view.backgroundColor = BGCOLOR;
    self.title = T(@"关于大掌柜");
	// Do any additional setup after loading the view.
    self.usLogo = [[UIImageView alloc] initWithFrame:CGRectMake(50, 20, 200, 75)];
    [self.usLogo setImage:[UIImage imageNamed:@"logo.png"]];
    
    self.usVersion = [[UILabel alloc]initWithFrame:CGRectMake(20, 125, 280 , 20)];
    [self.usVersion setTextAlignment:NSTextAlignmentCenter];
    [self.usVersion setBackgroundColor:[UIColor clearColor]];
    [self.usVersion setFont:[UIFont systemFontOfSize:16.0]];
    self.usVersion.textColor = RGBCOLOR(47, 15, 63);
    self.usVersion.shadowColor = [UIColor whiteColor];
    self.usVersion.shadowOffset = CGSizeMake(0, 1);
    self.usVersion.text = [NSString stringWithFormat:T(@"版本号: %@"), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ];
    
    self.usLabel = [[UILabel alloc]initWithFrame:CGRectMake(40, 140, 240 , 200)];
    [self.usLabel setTextAlignment:NSTextAlignmentLeft];
    [self.usLabel setBackgroundColor:[UIColor clearColor]];
    [self.usLabel setFont:[UIFont systemFontOfSize:14.0]];
    self.usLabel.textColor = RGBCOLOR(84, 41, 103);
    self.usLabel.shadowColor = [UIColor whiteColor];
    self.usLabel.shadowOffset = CGSizeMake(0, 1);
    self.usLabel.numberOfLines = 0;
    self.usLabel.text = @"大掌柜，工具类的社交型应用。让工具不再单调乏味，让社交成为得力助手。\n\n- 拿出手机随时联系公司客服 \n- 一个应用，帮你同时联系多家客服 \n- 接收关注公司发布的最新动态 \n- 公司成员帮你找到志同道合的朋友 \n- 福利每天给你意想不到的惊喜  \n\n 大掌柜，让客服随行";
    
    [self.view addSubview:self.usLabel];
    [self.view addSubview:self.usLogo];
    [self.view addSubview:self.usVersion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
