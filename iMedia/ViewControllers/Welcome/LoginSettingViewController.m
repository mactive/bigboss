//
//  LoginSettingViewController.m
//  iMedia
//
//  Created by mac on 12-11-4.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "LoginSettingViewController.h"
#import "AppDelegate.h"
#import "Me.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"

@interface LoginSettingViewController ()<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property(strong, nonatomic)Me *me;
@property(strong, nonatomic)UILabel *displayNameLabel;
@property(strong, nonatomic)UILabel *genderLabel;
@property(strong, nonatomic)UITextField *displayNameField;
@property(strong, nonatomic)UIButton *genderButton;
@property(strong, nonatomic)UIPickerView *genderPicker;
@property(strong, nonatomic)UIButton *welcomeButton;
@property(strong, nonatomic)UILabel *welcomeLabel;


@property(strong, nonatomic) NSDictionary *genderTitleDict;
@property(strong, nonatomic) NSArray *genderTitleValue;
@property(strong, nonatomic) NSArray *genderTitleKey;

@end

@implementation LoginSettingViewController

@synthesize displayNameLabel;
@synthesize genderLabel;
@synthesize displayNameField;
@synthesize genderButton;
@synthesize genderPicker;
@synthesize welcomeButton;
@synthesize me;
@synthesize welcomeLabel;

@synthesize genderTitleDict;
@synthesize genderTitleKey;
@synthesize genderTitleValue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.me  = [self appDelegate].me;
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define LOGO_HEIGHT 10
#define LEFT_OFFSET 20
#define LABEL_WIDTH 120
#define LABEL_HEIGHT 50
#define TEXTFIELD_OFFSET 120
#define TEXTFIELD_WIDTH 180

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BGCOLOR;
	// Do any additional setup after loading the view.
    self.title = T(@"设置初始信息");
    
    self.welcomeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0 , 320, 44)];
    [self.welcomeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.welcomeLabel setBackgroundColor:RGBCOLOR(62, 67, 76)];
    [self.welcomeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.welcomeLabel.textColor = [UIColor whiteColor];
    self.welcomeLabel.shadowColor = [UIColor blackColor];
    self.welcomeLabel.shadowOffset = CGSizeMake(0, 1);
    self.welcomeLabel.text = T(@"请设置昵称和性别");
    [self.view addSubview:self.welcomeLabel];
    
    self.displayNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(LEFT_OFFSET, LABEL_HEIGHT+LOGO_HEIGHT, LABEL_WIDTH, 30)];
    [self.displayNameLabel setBackgroundColor:[UIColor clearColor]];
    [self.displayNameLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.displayNameLabel setTextColor:[UIColor grayColor]];
    self.displayNameLabel.shadowColor = [UIColor whiteColor];
    self.displayNameLabel.shadowOffset = CGSizeMake(0, 1);
    self.displayNameLabel.text = T(@"姓名");
    self.displayNameLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.displayNameLabel];
    
    self.genderLabel = [[UILabel alloc]initWithFrame:CGRectMake(LEFT_OFFSET, LABEL_HEIGHT*2+LOGO_HEIGHT, LABEL_WIDTH, 30)];
    [self.genderLabel setBackgroundColor:[UIColor clearColor]];
    [self.genderLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.genderLabel setTextColor:[UIColor grayColor]];
    self.genderLabel.shadowColor = [UIColor whiteColor];
    self.genderLabel.shadowOffset = CGSizeMake(0, 1);
    self.genderLabel.text = T(@"性别");
    self.genderLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.genderLabel];
        
    self.displayNameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET , LABEL_HEIGHT+LOGO_HEIGHT, TEXTFIELD_WIDTH, 30)];
    self.displayNameField.font = [UIFont systemFontOfSize:14.0];
    [self.displayNameField setBorderStyle:UITextBorderStyleRoundedRect];
    self.displayNameField.textColor = [UIColor grayColor];
    self.displayNameField.backgroundColor = [UIColor whiteColor];
    self.displayNameField.delegate = self;
    self.displayNameField.returnKeyType = UIReturnKeyNext;
    self.displayNameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.displayNameField];
    
    self.genderButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.genderButton setFrame:CGRectMake(TEXTFIELD_OFFSET , LABEL_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, 30)];
    [self.genderButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.genderButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.genderButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.genderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    [self initWithGender];
    
    [self.view addSubview:self.genderButton];
    
    self.genderTitleDict = [ServerDataTransformer sexDict];
    self.genderTitleValue = [self.genderTitleDict allValues];
    self.genderTitleKey = [self.genderTitleDict allKeys];
    
    
    
    self.welcomeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.welcomeButton setFrame:CGRectMake(10, 160, 300, 40)];
    [self.welcomeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.welcomeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.welcomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.welcomeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.welcomeButton setAlpha:0.3];
    [self.welcomeButton setTitle:T(@"欢迎来到春水堂") forState:UIControlStateNormal];
    [self.view addSubview:self.welcomeButton];
    
    
    self.displayNameField.text = self.me.displayName;

    
}

- (void)welcomeAction
{
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:YES];
//    [[self appDelegate] startMainSession];
}

- (void)initWithGender
{
    if (![self.me.gender isEqualToString:@""] && [self.me.gender length] !=0) {
        [self.genderButton setTitle:[[ServerDataTransformer sexDict] objectForKey:self.me.gender] forState:UIControlStateNormal];
    }else{
        [self.genderButton setTitle:T(@"设置") forState:UIControlStateNormal] ;
        [self.genderButton addTarget:self action:@selector(settingGender) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - settingGender
/////////////////////////////////////////////////////////////////////////////////////

- (void)settingGender
{
    [self.displayNameField resignFirstResponder];
    self.genderPicker = [[UIPickerView alloc]init ];
    self.genderPicker.delegate = self;
    [self.genderPicker setFrame:CGRectMake(0, 280, 320, 200)];
    self.genderPicker.showsSelectionIndicator = YES;
    
    if (![self.me.gender isEqualToString:@""] && self.me.gender != nil) {
        NSInteger index =  [self.genderTitleKey indexOfObject:self.me.gender];
        [self.genderPicker selectRow:index inComponent:0 animated:YES];
    }else{
        [self.genderPicker selectRow:0 inComponent:0 animated:YES];
    }
    
    [self.view addSubview:self.genderPicker];
    
    
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - uipickerview delegate
/////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger result = 0;
    if ([pickerView isEqual:self.genderPicker]) {
        result = 1;
    }
    return result;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger result = 0;
    if ([pickerView isEqual:self.genderPicker]) {
        result = [self.genderTitleKey count];
    }
    return result;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString* result = @"";
    if ([pickerView isEqual:self.genderPicker]) {
        result = [self.genderTitleValue objectAtIndex:row];
    }
    return result;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([pickerView isEqual:self.genderPicker]) {
        self.genderButton.titleLabel.text = [self.genderTitleValue objectAtIndex:row];
        self.me.gender = [self.genderTitleKey objectAtIndex:row];
        self.me.displayName = self.displayNameField.text;

        
        if ([self.me.gender length] != 0 && [self.me.displayName length] != 0 )
        {
//            [self.genderPicker removeFromSuperview];

                [self.welcomeButton setHidden:NO];
                [self.welcomeButton setAlpha:0.3];
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.5];
                [self.welcomeButton setAlpha:1];
                [self.welcomeButton addTarget:self action:@selector(welcomeAction) forControlEvents:UIControlEventTouchUpInside];
                [UIView commitAnimations];
                            
        }else{
            [self.welcomeButton setHidden:YES];
        }
        
    }
    

}



#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.displayNameField isEqual:textField]) {
        
        self.me.displayName = self.displayNameField.text;

        if ([self.me.gender length] != 0 && [self.me.displayName length] != 0 )
        {
//            [self.genderPicker removeFromSuperview];
            
                [self.welcomeButton setHidden:NO];
                [self.welcomeButton setAlpha:0.3];
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.5];
                [self.welcomeButton setAlpha:1];
                [self.welcomeButton addTarget:self action:@selector(welcomeAction) forControlEvents:UIControlEventTouchUpInside];
                [UIView commitAnimations];
        }else{
            [self.welcomeButton setHidden:YES];
        }
    }
    return [textField resignFirstResponder];

    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.displayNameField resignFirstResponder];
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([self.displayNameField isEqual:textField]) {
        self.me.displayName = self.displayNameField.text;
    }
    return [textField resignFirstResponder];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
