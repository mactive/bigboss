//
//  AboutUsViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-8.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "AboutUsViewController.h"

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
    self.title = T(@"关于春水堂");
	// Do any additional setup after loading the view.
    self.usLogo = [[UIImageView alloc] initWithFrame:CGRectMake(50, 20, 220, 100)];
    [self.usLogo setImage:[UIImage imageNamed:@"oyeah_logo.png"]];
    
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
    self.usLabel.text = @"春水堂，中国情趣生活文化的倡导者，中国情趣用品行业的改良者，中国最具品牌影响力的情趣用品零售企业。以“情趣百变，真爱永恒”的经营理念，“绿色材质，人性设计”的产品采购核心原则，“以人为本，尊重原创”的人才引进理念，正在向中国情趣文化的领导者迈进。";
    
    
    
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
