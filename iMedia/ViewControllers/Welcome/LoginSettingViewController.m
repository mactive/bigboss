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
#import "AppNetworkAPIClient.h"

@interface LoginSettingViewController ()<UITextFieldDelegate>

@property(strong, nonatomic)Me *me;
@property(strong, nonatomic)UILabel *displayNameLabel;
@property(strong, nonatomic)UILabel *genderLabel;
@property(strong, nonatomic)UITextField *displayNameField;
@property(strong, nonatomic)UIButton *welcomeButton;
@property(strong, nonatomic)UILabel *welcomeLabel;
@property(strong, nonatomic)UILabel *noticeLabel;

@property(strong, nonatomic)UISegmentedControl *genderControl;


@property(strong, nonatomic) NSDictionary *genderTitleDict;
@property(strong, nonatomic) NSArray *genderTitleValue;
@property(strong, nonatomic) NSArray *genderTitleKey;

@end

@implementation LoginSettingViewController

@synthesize displayNameLabel;
@synthesize genderLabel;
@synthesize displayNameField;
@synthesize welcomeButton;
@synthesize me;
@synthesize welcomeLabel;
@synthesize noticeLabel;

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

#define LOGO_HEIGHT 20
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
    self.welcomeLabel.numberOfLines = 2;
    self.welcomeLabel.shadowColor = [UIColor blackColor];
    self.welcomeLabel.shadowOffset = CGSizeMake(0, 1);
    self.welcomeLabel.text = T(@"请设置昵称和性别");
    [self.view addSubview:self.welcomeLabel];
    
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:14.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    self.noticeLabel.text = T(@"性别一旦选定,不可以更改");
    
    [self.view addSubview:self.noticeLabel];
    
    
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
    self.displayNameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [self.view addSubview:self.displayNameField];
    
        
    
    self.genderTitleDict = [ServerDataTransformer sexDict];
    self.genderTitleValue = [self.genderTitleDict allValues];
    self.genderTitleKey = [self.genderTitleDict allKeys];
    self.genderControl = [[UISegmentedControl alloc]initWithItems:self.genderTitleValue];
    self.genderControl.frame = CGRectMake(TEXTFIELD_OFFSET , LABEL_HEIGHT*2+LOGO_HEIGHT-5, TEXTFIELD_WIDTH, 40);
    self.genderControl.selectedSegmentIndex = -1; //设置默认选择项索引
    [self.genderControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];

    
    [self.genderControl setImage:[UIImage imageNamed:@"gender_male.png"] forSegmentAtIndex:0];
    [self.genderControl setImage:[UIImage imageNamed:@"gender_female.png"] forSegmentAtIndex:1];

    [self.view addSubview:self.genderControl];

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
    [[AppNetworkAPIClient sharedClient] uploadMe:self.me withBlock:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)segmentAction:(UISegmentedControl *)seg
{
    NSInteger Index = seg.selectedSegmentIndex;
    self.me.gender = [self.genderTitleKey objectAtIndex:Index];
    NSLog(@"Index %i %@", Index,self.me.gender);
    
    self.me.displayName = self.displayNameField.text;
    
    
    if ([self.me.gender length] != 0 && [self.me.displayName length] != 0 )
    {        
        [self.welcomeButton setHidden:NO];
        [self.welcomeButton setAlpha:0.3];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5];
        [self.welcomeButton setAlpha:1];
        [self.welcomeButton addTarget:self action:@selector(welcomeAction) forControlEvents:UIControlEventTouchUpInside];
        [UIView commitAnimations];
        
    }else{
        [self.welcomeButton setHidden:NO];
        [self.welcomeButton setAlpha:0.3];
    }
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.displayNameField isEqual:textField]) {
        
        self.me.displayName = self.displayNameField.text;

        if ([self.me.gender length] != 0 && [self.me.displayName length] != 0 )
        {
            
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
