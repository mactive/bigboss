//
//  ShakeEntityViewController.m
//  iMedia
//
//  Created by mac on 12-11-27.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeEntityViewController.h"
#import "MBProgressHUD.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "ShakeAddressViewController.h"

@interface ShakeEntityViewController ()

@property(nonatomic, strong) UILabel *noticeLabel;
@property(nonatomic, strong) UILabel *priceLabel;
@property(nonatomic, strong) UILabel *secondNoticeLabel;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) UIView *promotionView;
@property(nonatomic, strong) UIImageView *promotionImageView;

@end

@implementation ShakeEntityViewController
@synthesize noticeLabel;
@synthesize priceLabel;
@synthesize secondNoticeLabel;
@synthesize saveButton;
@synthesize promotionView;
@synthesize promotionImageView;
@synthesize promotionImage;

@synthesize merchandise_name;
@synthesize merchandise_sn;
@synthesize original_price;
@synthesize discount_price;
@synthesize description;


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
	// Do any additional setup after loading the view.
    
    self.title = T(@"恭喜你");
    self.view.backgroundColor = BGCOLOR;
	// Do any additional setup after loading the view.
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 25, 320, 15)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    // promotionView
    self.promotionView = [[UIView alloc]initWithFrame:CGRectMake(90, 55, 140, 170)];
    self.promotionView.backgroundColor = [UIColor whiteColor];
    self.promotionView.layer.shadowColor = [RGBACOLOR(0, 0, 0, 0.1) CGColor];
    self.promotionView.layer.shadowOffset = CGSizeMake(0, 5);
    // promotionImageView
    self.promotionImageView = [[UIImageView alloc]initWithFrame:CGRectMake(5, 5, self.promotionView.frame.size.width-10,  self.promotionView.frame.size.height-10)];
    [self.promotionView addSubview:self.promotionImageView];
    
    // priceLabel
    self.priceLabel = [[UILabel alloc]initWithFrame:CGRectMake(30,250, 260, 50)];
    self.priceLabel.numberOfLines = 0;
    self.priceLabel.font = [UIFont systemFontOfSize:18.0f];
    [self.priceLabel setTextAlignment:NSTextAlignmentCenter];
    self.priceLabel.textAlignment = NSTextAlignmentCenter;
    self.priceLabel.textColor =  RGBCOLOR(82, 82, 82);
    self.priceLabel.backgroundColor = [UIColor clearColor];
    self.priceLabel.shadowColor = [UIColor whiteColor];
    self.priceLabel.shadowOffset = CGSizeMake(0, 1);
    
    // secondNoticeLabel
    self.secondNoticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 310, 300, 20)];
    [self.secondNoticeLabel setTextAlignment:NSTextAlignmentCenter];
    self.secondNoticeLabel.font = [UIFont systemFontOfSize:14.0f];
    self.secondNoticeLabel.textAlignment = NSTextAlignmentCenter;
    self.secondNoticeLabel.textColor = RGBCOLOR(82, 82, 82);
    self.secondNoticeLabel.backgroundColor = [UIColor clearColor];
    self.secondNoticeLabel.shadowColor = [UIColor whiteColor];
    self.secondNoticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    // saveButton
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 332, 275, 40)];
    [self.saveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [self.saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.saveButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveCodeAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.priceLabel];
    [self.view addSubview:self.saveButton];
    [self.view addSubview:self.noticeLabel];
    [self.view addSubview:self.secondNoticeLabel];
    [self.view addSubview:self.promotionView];
    
    [self refreshCode];

}
//  填写获奖信息
- (void)saveCodeAction
{
    ShakeAddressViewController *controller = [[ShakeAddressViewController alloc]initWithNibName:nil bundle:nil];
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)refreshCode
{
    self.noticeLabel.text = [NSString stringWithFormat:T(@"你获得了 ' %@ ' "),self.merchandise_name];

    [self.promotionImageView setImage:self.promotionImage];
    
    if ([self.discount_price length ] > 0) {
        self.priceLabel.text = [NSString stringWithFormat:T(@"此商品原价 %@ 元, 你只需要付款 %@ 元 就可以得到他"),self.original_price,self.discount_price];
    }else{
        self.priceLabel.text = [NSString stringWithFormat:T(@"此商品原价 %@ 元, 您将免费获得. "),self.original_price];
    }
    
    self.secondNoticeLabel.text = T(@"系统已经为您自动下单, 配送方式为货到付款.");

    [self.saveButton setTitle:T(@"请填写快递信息") forState:UIControlStateNormal];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
