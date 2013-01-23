//
//  PrivacyViewController.m
//  jiemo
//
//  Created by meng qian on 12-12-20.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "PrivacyViewController.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h"
#import "Me.h"
#import "ConfigSetting.h"

@interface PrivacyViewController ()<UITextFieldDelegate>
@property(nonatomic,strong)UILabel *noticeLabel;
@property(strong,nonatomic) UITextField *passField;
@property(strong,nonatomic) UITextField *repassField;
@property(strong, nonatomic) UIButton *doneButton;
@property(strong, nonatomic) UIButton *cancelButton;

@end

@implementation PrivacyViewController
@synthesize passField;
@synthesize repassField;
@synthesize doneButton;
@synthesize cancelButton;

#define LOGO_HEIGHT 30
#define TEXTFIELD_X_OFFSET 25
#define TEXTFIELD_Y_OFFSET 15
#define TEXTFIELD_WIDTH 270
#define TEXTFIELD_HEIGHT 40
#define PASS_MAX_LENGTH 4

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
    self.title = T(@"隐私设置");
    self.view.backgroundColor = BGCOLOR;
	// Do any additional setup after loading the view.
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(65, 10, 250, 50)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:14.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.numberOfLines = 0;
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    self.noticeLabel.text = T(@"为大掌柜创建一个屏幕解锁密码，这样他人在借用你的手机时，无法打开大掌柜。");
    
    
    // passfield
    self.passField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET  + TEXTFEILD_HEIGHT+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.passField.font = [UIFont systemFontOfSize:18.0];
    self.passField.textColor = [UIColor grayColor];
    self.passField.delegate = self;
    self.passField.placeholder = T(@"你的4位密码");
    self.passField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.passField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.passField.layer.borderWidth  = 1.0f;
    self.passField.layer.cornerRadius = 5.0f;
    self.passField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passField.textAlignment = UITextAlignmentCenter;
    self.passField.keyboardType = UIKeyboardTypeNumberPad;
    self.passField.secureTextEntry = YES;
    
    // repassfield
    self.repassField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET *2 + TEXTFEILD_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.repassField.font = [UIFont systemFontOfSize:18.0];
    self.repassField.textColor = [UIColor grayColor];
    self.repassField.delegate = self;
    self.repassField.placeholder = T(@"再次输入4位密码");
    self.repassField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.repassField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.repassField.layer.borderWidth  = 1.0f;
    self.repassField.layer.cornerRadius = 5.0f;
    self.repassField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.repassField.textAlignment = UITextAlignmentCenter;
    self.repassField.keyboardType = UIKeyboardTypeNumberPad;
    self.repassField.secureTextEntry = YES;

    // regionbutton
    self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.doneButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*3+TEXTFIELD_HEIGHT*3+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"完成") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    // cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setFrame:CGRectMake(10, 20, 50, 30)];
    [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.cancelButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.cancelButton setTitle:T(@"取消") forState:UIControlStateNormal];
    [self.cancelButton setBackgroundColor:RGBCOLOR(77, 171, 220)];
    [self.cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.noticeLabel];
    [self.view addSubview:self.passField];
    [self.view addSubview:self.repassField];
    [self.view addSubview:self.doneButton];
    [self.view addSubview:self.cancelButton];
}


- (void)cancelButtonAction
{

    [self dismissModalViewControllerAnimated:YES];

}

- (void)doneButtonAction
{
    if (!StringHasValue(self.passField.text) && !StringHasValue(self.repassField.text) ) {
        [self dismissModalViewControllerAnimated:YES];
    }else{
        if ([self.passField.text length] == PASS_MAX_LENGTH && [self.passField.text length] == PASS_MAX_LENGTH && [self.passField.text isEqualToString:self.repassField.text] ) {
            
            [self appDelegate].me.config = [ConfigSetting enableConfig:[self appDelegate].me.config withSetting:CONFIG_PRIVACY_REQUIRED];
            [self appDelegate].me.privacyPass = self.repassField.text;
            [[self appDelegate] saveContextInDefaultLoop];
            [self dismissModalViewControllerAnimated:YES];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"输入有错误,请重新输入") andHideAfterDelay:1];
        }
    }

}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - uitextfield delegate
/////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    NSString * toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (self.passField == textField || self.repassField == textField)
    {
        if ([toBeString length] > PASS_MAX_LENGTH) {
            textField.text = [toBeString substringToIndex:PASS_MAX_LENGTH];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"超过最大字数不能输入了") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            return NO;
        }
  
    }
    return YES;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
