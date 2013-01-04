//
//  ShakeAddressViewController.m
//  iMedia
//
//  Created by mac on 12-11-28.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeAddressViewController.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "AppNetworkAPIClient.h"
#import "ShakeDashboardViewController.h"
#import "SettingViewController.h"
#import "ShakeEntityViewController.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface ShakeAddressViewController ()<UITextFieldDelegate,UIAlertViewDelegate>
@property(nonatomic, strong) UIScrollView *baseView;
@property(nonatomic,strong)UILabel *noticeLabel;
@property(strong,nonatomic) UITextField *nameField;
@property(strong,nonatomic) UITextField *telField;
@property(strong,nonatomic) UITextField *addressField;
@property(strong, nonatomic) UIButton *regionButton;
@property(strong, nonatomic) UIButton *doneButton;
@property(strong, nonatomic)UITapGestureRecognizer *tapGestureRecognizer;
@property(strong, nonatomic) UITextField *handleField;
@property(strong, nonatomic)UIButton *closeButton;
@property(strong, nonatomic) UIAlertView *closeAlertView;
@end

@implementation ShakeAddressViewController

@synthesize baseView;
@synthesize noticeLabel;
@synthesize nameField;
@synthesize telField;
@synthesize addressField;
@synthesize regionButton;
@synthesize doneButton;
@synthesize priceType;
@synthesize tapGestureRecognizer;
@synthesize awardID;
@synthesize handleField;
@synthesize closeButton;
@synthesize closeAlertView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#define LOGO_HEIGHT 30
#define TEXTFIELD_X_OFFSET 25
#define TEXTFIELD_Y_OFFSET 15
#define TEXTFIELD_WIDTH 270
#define TEXTFIELD_HEIGHT 40

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"收货地址");
	// Do any additional setup after loading the view.
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 15, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:12.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    self.noticeLabel.text = T(@"请留下你的联系方式，我们将你中奖的商品快递给你");
    
    // nameField
    self.nameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.nameField.font = [UIFont systemFontOfSize:18.0];
    self.nameField.textColor = [UIColor grayColor];
    self.nameField.delegate = self;
    self.nameField.placeholder = T(@"你的姓名");
    self.nameField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.nameField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.nameField.layer.borderWidth  = 1.0f;
    self.nameField.layer.cornerRadius = 5.0f;
    self.nameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.nameField.textAlignment = UITextAlignmentCenter;
    
    // telfield
    self.telField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET *2 + TEXTFEILD_HEIGHT+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.telField.font = [UIFont systemFontOfSize:18.0];
    self.telField.textColor = [UIColor grayColor];
    self.telField.delegate = self;
    self.telField.placeholder = T(@"你的电话");
    self.telField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.telField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.telField.layer.borderWidth  = 1.0f;
    self.telField.layer.cornerRadius = 5.0f;
    self.telField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.telField.textAlignment = UITextAlignmentCenter;
    self.telField.keyboardType = UIKeyboardTypeNumberPad;
    
    // regionbutton
    self.regionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.regionButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*3+TEXTFIELD_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.regionButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.regionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.regionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.regionButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.regionButton setTitle:T(@"省/市(区)") forState:UIControlStateNormal];
    [self.regionButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.regionButton addTarget:self action:@selector(regionAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // addressField
    self.addressField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*3+TEXTFIELD_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.addressField.font = [UIFont systemFontOfSize:18.0];
    self.addressField.textColor = [UIColor grayColor];
    self.addressField.delegate = self;
    self.addressField.placeholder = T(@"详细地址");
    self.addressField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.addressField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.addressField.layer.borderWidth  = 1.0f;
    self.addressField.layer.cornerRadius = 5.0f;
    self.addressField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.addressField.textAlignment = UITextAlignmentCenter;
    
    
    // regionbutton
    self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.doneButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*4+TEXTFIELD_HEIGHT*4+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"完成") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(sendButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    
    // regionbutton
    self.closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.closeButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*5+TEXTFIELD_HEIGHT*6+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.closeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.closeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.closeButton setTitle:T(@"关闭") forState:UIControlStateNormal];
    [self.closeButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonPushed) forControlEvents:UIControlEventTouchUpInside];
    
    self.baseView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    self.baseView.backgroundColor = BGCOLOR;
    [self.baseView setContentSize:CGSizeMake(self.view.frame.size.width, 300)];
    [self.baseView setScrollEnabled:YES];
    
    [self.baseView addSubview:self.noticeLabel];
    [self.baseView addSubview:self.nameField];
    [self.baseView addSubview:self.telField];
//    [self.baseView addSubview:self.regionButton]; // 先不做区域了
    [self.baseView addSubview:self.addressField];
    [self.baseView addSubview:self.doneButton];
    [self.baseView addSubview:self.closeButton];
    
    
    [self.view addSubview:self.baseView];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTaps:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    
}

- (void)closeButtonPushed
{
    self.closeAlertView = [[UIAlertView alloc]initWithTitle:T(@"放弃填写")
                                                    message:T(@"你将放弃这次机会,而且不能再参与这次摇一摇!")
                                                   delegate:self
                                          cancelButtonTitle:T(@"取消")
                                          otherButtonTitles:T(@"确定"), nil];
    [self.closeAlertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:self.closeAlertView]) {
        if (buttonIndex == 0){
            //cancel clicked ...do your action
        }else if (buttonIndex == 1){
            [self dismissModalViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelUploadAddress" object:nil];
        }
    }
}

- (void)handleTaps:(UIGestureRecognizer *)paramSender
{
    DDLogVerbose(@"handleTaps");
    [self.handleField resignFirstResponder];
    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载信息");
    
    [super viewWillAppear:animated];
    [[AppNetworkAPIClient sharedClient]getWinnerInfoWithBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        if (responseObject) {
            NSDictionary *responseDict = responseObject;
            self.nameField.text = [responseDict objectForKey:@"name"];
            self.telField.text = [responseDict objectForKey:@"phone"];
            self.addressField.text = [responseDict objectForKey:@"addr"];
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误,无法获取信息") andHideAfterDelay:1];
        }
    }];
}

- (void)sendButtonPushed:(id)sender
{
    [self.addressField resignFirstResponder];
    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    if (StringHasValue(self.nameField.text) && StringHasValue(self.telField.text) && StringHasValue(self.addressField.text)) {
        
        
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.labelText = T(@"发送中");
        
        NSString *priceTypeString = [NSString stringWithFormat:@"%i",self.priceType];
        
        [[AppNetworkAPIClient sharedClient]updateWinnerName:self.nameField.text andPhone:self.telField.text andPriceType:priceTypeString andAddress:self.addressField.text WithBlock:^(id responseObject, NSError *error) {
            [HUD hide:YES];
            if (error == nil) {
                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.labelText = T(@"发送成功");
                hud.mode = MBProgressHUDModeText;
                
                [hud showAnimated:YES whileExecutingBlock:^{
                    sleep(2);
                } completionBlock:^{
                    [hud removeFromSuperview];
                    //                // backto dashboard
                    //                NSArray *controllerArray =  self.navigationController.viewControllers;
                    //                for (int i=0; i< [controllerArray count]; i++) {
                    //                    UIViewController *tmp = [controllerArray objectAtIndex:i];
                    //                    if ([tmp isKindOfClass:[ShakeDashboardViewController class]]) {
                    //                        [self.navigationController popToViewController:tmp animated:YES];
                    //                        break;
                    //                    }
                    //                }
                    [self dismissModalViewControllerAnimated:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"doneUploadAddress" object:nil];
                    
                }];
                
            } else {
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"发送失败,请重试") andHideAfterDelay:2];
            }
        }];
        

    }else{
        [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"有没填写的项") andHideAfterDelay:2];
    }
}

#warning store data and init form the database

#warning 出现键盘的时候 点击键盘消失 或者scroll view

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    [self.baseView setFrame:CGRectMake(0, 0, 320, 150)];
    self.handleField  = textField;
    if ([textField isEqual:self.addressField]) {
        [self.baseView setContentOffset:CGPointMake(0, 150) animated:YES];
    }
    
    [self.view addGestureRecognizer:self.tapGestureRecognizer];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self.baseView setFrame:self.view.bounds];
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];

    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];
    return [textField resignFirstResponder];
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
