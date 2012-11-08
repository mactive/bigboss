//
//  FeedBackViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-8.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "FeedBackViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface FeedBackViewController ()<UITextViewDelegate>

@property(strong, nonatomic)UISegmentedControl *feedBackSegment;
@property(strong, nonatomic)UITextView *feedBackTextView;
@property(strong, nonatomic)NSArray *feedBackTitleArray;
@property(strong, nonatomic)UIButton *feedBackButton;
@property(strong, nonatomic)UILabel *noticeLabel;

@end

@implementation FeedBackViewController

@synthesize feedBackSegment;
@synthesize feedBackTextView;
@synthesize feedBackTitleArray;
@synthesize feedBackButton;
@synthesize noticeLabel;

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
    
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 10, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    self.noticeLabel.text = T(@"感谢您使用春水堂，您可以在此留下改进的意见建议。");
    
    
    self.feedBackTitleArray = [[NSArray alloc]initWithObjects:T(@"意见"), T(@"商务咨询"),T(@"Bug"), nil];
    
    self.feedBackSegment = [[UISegmentedControl alloc]initWithItems:self.feedBackTitleArray];
    self.feedBackSegment.frame = CGRectMake(60 , 20, 200, 40);
    self.feedBackSegment.selectedSegmentIndex = -1; //设置默认选择项索引
    [self.feedBackSegment addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    
    
    self.feedBackTextView = [[UITextView alloc] initWithFrame:CGRectMake(20 , 60, 280 , 150)];
    [self.feedBackTextView.layer setMasksToBounds:YES];
    [self.feedBackTextView.layer setCornerRadius:5.0];
    [self.feedBackTextView.inputView setFrame:CGRectMake(20, 10, 240, 60)];
    self.feedBackTextView.font = [UIFont systemFontOfSize:14.0];
    self.feedBackTextView.textColor = [UIColor blackColor];
    self.feedBackTextView.backgroundColor = [UIColor whiteColor];
    self.feedBackTextView.delegate = self;
    
    self.feedBackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.feedBackButton setFrame:CGRectMake(10, 160, 300, 40)];
    [self.feedBackButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.feedBackButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.feedBackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.feedBackButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.feedBackButton setTitle:T(@"提交") forState:UIControlStateNormal];
    [self.view addSubview:self.feedBackButton];
    
    [self.view addSubview:self.noticeLabel];
    [self.view addSubview:self.feedBackSegment];
    [self.view addSubview:self.feedBackTextView];
    [self.view addSubview:self.feedBackButton];

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
