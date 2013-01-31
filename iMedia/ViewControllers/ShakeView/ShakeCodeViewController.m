//
//  ShakeCodeViewController.m
//  iMedia
//
//  Created by mac on 12-11-27.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeCodeViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "Information.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface ShakeCodeViewController ()
{
}

@property(nonatomic, strong) UILabel *noticeLabel;
@property(nonatomic, strong) UILabel *codeLabel;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) NSMutableArray *codeArray;

@end

@implementation ShakeCodeViewController

@synthesize noticeLabel;
@synthesize codeLabel;
@synthesize saveButton;
@synthesize codeString;
@synthesize codeArray;
@synthesize managedObjectContext;

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
    self.title = T(@"恭喜你");
	// Do any additional setup after loading the view.
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 25, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    // codeLabel
    self.codeLabel = [[UILabel alloc]initWithFrame:CGRectMake(60, 75, 200, 50)];
    [self.codeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.codeLabel setBackgroundColor:RGBCOLOR(5, 150, 210)];
    [self.codeLabel setFont:[UIFont fontWithName:@"Courier New" size:26.0f]];
    self.codeLabel.textAlignment = NSTextAlignmentCenter;
    self.codeLabel.textColor = [UIColor whiteColor];
    self.codeLabel.layer.cornerRadius = 10.0f;
    
    //    saveButton
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 160, 275, 40)];
    [self.saveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [self.saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.saveButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.saveButton setTitle:T(@"保存到 设置->优惠码备忘录") forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveCodeAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.codeLabel];
    [self.view addSubview:self.saveButton];
    [self.view addSubview:self.noticeLabel];
    
    [self refreshCode];
    
}

- (void)refreshCode
{
    self.noticeLabel.text = T(@"这是你的中奖code，请你去官方网站兑换");
    if ([codeString length] > 0 && codeString!= nil) {
        self.codeLabel.text = self.codeString;
        
        // get and set
        self.codeArray = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)[[NSUserDefaults standardUserDefaults] objectForKey:@"codeArray"]];
        [self.codeArray addObject:self.codeString];
        NSArray *tmp_array = [[NSArray alloc]initWithArray:self.codeArray];
        [[NSUserDefaults standardUserDefaults] setObject:tmp_array forKey:@"codeArray"];
        
        
    }else{
        self.codeLabel.text = T(@"code有错误");
    }
    
}

- (void)saveCodeAction:(id)sender {
    
    Information *info = [NSEntityDescription insertNewObjectForEntityForName:@"Information" inManagedObjectContext:self.managedObjectContext];
    
    [info setName:@"Wincode"];
    [info setType:WinnerCodeFromShake];
    [info setCreatedOn:[NSDate date]];
    [info setValue:self.codeString];
    
    NSError *error;
    if(![self.managedObjectContext save:&error]){
        DDLogVerbose(@"Save ERROR");
    }
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = T(@"存储成功");
    hud.detailsLabelText = T(@"请到 设置->优惠码备忘录 查看");
    hud.detailsLabelText = T(@"返回上一层");
    [hud showAnimated:YES whileExecutingBlock:^{
        sleep(2);
    } completionBlock:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
