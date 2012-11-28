//
//  ShakeAddressViewController.m
//  iMedia
//
//  Created by mac on 12-11-28.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeAddressViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface ShakeAddressViewController ()<UITextFieldDelegate,UIActionSheetDelegate>

@property(nonatomic, strong) UIScrollView *baseView;
@property(nonatomic,strong)UILabel *noticeLabel;
@property(strong,nonatomic) UITextField *nameField;
@property(strong,nonatomic) UITextField *telField;
@property(strong,nonatomic) UITextField *addressField;
@property(strong, nonatomic) UIButton *regionButton;
@property(strong, nonatomic) UIButton *doneButton;

@end

@implementation ShakeAddressViewController

@synthesize baseView;
@synthesize noticeLabel;
@synthesize nameField;
@synthesize telField;
@synthesize addressField;
@synthesize regionButton;
@synthesize doneButton;


@synthesize awardID;


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
    self.noticeLabel.text = T(@"请留下您的联系方式，我们将您中奖的商品快递给你");
    
    // nameField
    self.nameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.nameField.font = [UIFont systemFontOfSize:18.0];
    self.nameField.textColor = [UIColor grayColor];
    self.nameField.delegate = self;
    self.nameField.placeholder = T(@"您的姓名");
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
    self.telField.placeholder = T(@"您的电话");
    self.telField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.telField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.telField.layer.borderWidth  = 1.0f;
    self.telField.layer.cornerRadius = 5.0f;
    self.telField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.telField.textAlignment = UITextAlignmentCenter;
    
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
    self.addressField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET*4 + TEXTFIELD_HEIGHT*3+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
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
    [self.doneButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*5+TEXTFIELD_HEIGHT*5+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"完成") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.baseView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [self.baseView setContentSize:CGSizeMake(self.view.frame.size.width, 300)];
    [self.baseView setScrollEnabled:YES];
    
    [self.baseView addSubview:self.noticeLabel];
    [self.baseView addSubview:self.nameField];
    [self.baseView addSubview:self.telField];
    [self.baseView addSubview:self.regionButton];
    [self.baseView addSubview:self.addressField];
    [self.baseView addSubview:self.doneButton];
    
    
    [self.view addSubview:self.baseView];
    

}

#warning store data and init form the database

#warning 出现键盘的时候 点击键盘消失 或者scroll view

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    [self.baseView setFrame:CGRectMake(0, 0, 320, 150)];  
    if ([textField isEqual:self.addressField]) {
        [self.baseView setContentOffset:CGPointMake(0, 200) animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self.baseView setFrame:self.view.bounds];
    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];


    return [textField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
