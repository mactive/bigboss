//
//  FeedBackViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-8.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "FeedBackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "AppNetworkAPIClient.h"
#import "Me.h"
#import "AppDelegate.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface FeedBackViewController ()<UITextViewDelegate,UITextFieldDelegate>

@property(strong, nonatomic)UISegmentedControl *feedBackSegment;
@property(strong, nonatomic)UITextView *feedBackTextView;
@property(strong, nonatomic)NSArray *feedBackTitleArray;
@property(strong, nonatomic)UIButton *feedBackButton;
@property(strong, nonatomic)UILabel *noticeLabel;
@property(strong, nonatomic)UIScrollView *baseView;
@property(nonatomic, strong)NSString *segValue;
@property(strong, nonatomic)NSArray *titleArray;
@property(strong, nonatomic)UITextField *telField;
@property(strong, nonatomic)UITextField *emailField;

@property(strong, nonatomic) id handle;

@end

@implementation FeedBackViewController

@synthesize feedBackSegment;
@synthesize feedBackTextView;
@synthesize feedBackTitleArray;
@synthesize feedBackButton;
@synthesize noticeLabel;
@synthesize baseView;
@synthesize segValue;
@synthesize titleArray;
@synthesize telField;
@synthesize emailField;
@synthesize handle;

#define TEXTFIELD_X_OFFSET 20
#define TEXTFIELD_Y_OFFSET 15
#define TEXTFIELD_WIDTH 280
#define TEXTFIELD_HEIGHT 40

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
    
    self.title = T(@"帮助与反馈");
    // nameField
    self.emailField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , 100, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.emailField.font = [UIFont systemFontOfSize:18.0];
    self.emailField.textColor = [UIColor grayColor];
    self.emailField.delegate = self;
    self.emailField.placeholder = T(@"你的邮箱");
    self.emailField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.emailField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.emailField.layer.borderWidth  = 1.0f;
    self.emailField.layer.cornerRadius = 5.0f;
    self.emailField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.emailField.textAlignment = UITextAlignmentCenter;
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;

    
    // telfield
    self.telField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , 150, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
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
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET, 5, TEXTFIELD_WIDTH, 40)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:14.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    self.noticeLabel.numberOfLines = 0;
    self.noticeLabel.text = T(@"感谢你的使用和耐心，你可以在此留下:");
    
    // segment
    self.titleArray = [[NSArray alloc]initWithObjects:@"a",@"b", nil];
    self.feedBackTitleArray = [[NSArray alloc]initWithObjects:T(@"使用建议"),T(@"商务咨询"), nil];
    
    self.feedBackSegment = [[UISegmentedControl alloc]initWithItems:self.feedBackTitleArray];
    self.feedBackSegment.frame = CGRectMake(TEXTFIELD_X_OFFSET , 50, TEXTFIELD_WIDTH, 40);
    self.feedBackSegment.selectedSegmentIndex = -1; //设置默认选择项索引
    UIFont *font = [UIFont boldSystemFontOfSize:14.0f];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:UITextAttributeFont];

    [self.feedBackSegment setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.feedBackSegment addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    
    // feedBackTextView
    self.feedBackTextView = [[UITextView alloc] initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , 200, TEXTFIELD_WIDTH , 120)];
    [self.feedBackTextView.layer setMasksToBounds:YES];
    [self.feedBackTextView.layer setCornerRadius:5.0];
    [self.feedBackTextView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [self.feedBackTextView.layer setBorderWidth:1];
    [self.feedBackTextView.inputView setFrame:CGRectMake(20, 10, 240, 60)];
    self.feedBackTextView.font = [UIFont systemFontOfSize:14.0];
    self.feedBackTextView.textColor = [UIColor blackColor];
    self.feedBackTextView.backgroundColor = [UIColor whiteColor];
    self.feedBackTextView.delegate = self;
    
    self.feedBackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.feedBackButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET, 330, TEXTFIELD_WIDTH, 40)];
    [self.feedBackButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.feedBackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.feedBackButton setBackgroundImage:[UIImage imageNamed:@"button_blue_bg.png"] forState:UIControlStateNormal];
    [self.feedBackButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.feedBackButton setTitle:T(@"提交") forState:UIControlStateNormal];
    [self.feedBackButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.feedBackButton];
    
    self.baseView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    self.baseView.backgroundColor = BGCOLOR;
    self.baseView.scrollEnabled = YES;
    [self.baseView setContentSize:CGSizeMake(self.view.frame.size.width, 500)];
    [self.baseView setScrollEnabled:YES];
    self.baseView.delegate = self;

    
    [self.baseView addSubview:self.noticeLabel];
    [self.baseView addSubview:self.emailField];
    [self.baseView addSubview:self.telField];
    [self.baseView addSubview:self.feedBackSegment];
    [self.baseView addSubview:self.feedBackTextView];
    [self.baseView addSubview:self.feedBackButton];

    [self.view addSubview:self.baseView];
	// Do any additional setup after loading the view.
}

- (void)segmentAction:(UISegmentedControl *)seg
{
    self.segValue = [self.titleArray objectAtIndex:seg.selectedSegmentIndex];
//    DDLogVerbose(@"segValue %@",self.segValue);
}

- (void)doneAction
{
    NSString *otherString = [NSString stringWithFormat:@"%@,%@",self.emailField.text,self.telField.text];
    
    [self.feedBackTextView resignFirstResponder];
    
    NSString *guid = [self appDelegate].me.guid;
    if ([self.segValue length] == 0 ) {
        [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请选择反馈类型") andHideAfterDelay:1];
    }else{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = T(@"正在上传");
        
        [[AppNetworkAPIClient sharedClient] reportID:@"" myID:guid type:self.segValue description:self.feedBackTextView.text otherInfo:otherString withBlock:^(id responseObject, NSError *error) {
            [hud hide:YES];
            if (responseObject) {
                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.removeFromSuperViewOnHide = YES;
                hud.mode = MBProgressHUDModeText;
                hud.labelText = T(@"上传成功,谢谢");
                
                [hud showAnimated:YES whileExecutingBlock:^{
                    sleep(1);
                } completionBlock:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
//                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传成功,谢谢") andHideAfterDelay:2];
            }else{
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传失败,请再试") andHideAfterDelay:2];
            }
        }];
    }
}



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.handle != nil) {
        if ([self.handle isKindOfClass:[UITextField class]]) {
            [(UITextField *)self.handle resignFirstResponder];
        }else if([self.handle isKindOfClass:[UITextView class]]){
            [(UITextView *)self.handle resignFirstResponder];
        }
    }
}

/////////////////////////////////////////////////
#pragma mark - textview delegate
/////////////////////////////////////////////////

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.handle = textView;

    if ([textView isEqual:self.feedBackTextView]) {
        [self.baseView setContentOffset:CGPointMake(0, 200) animated:NO];
    }
//    [self.view addGestureRecognizer:self.tapGestureRecognizer];

}

- (void)textViewDidEndEditing:(UITextView *)textView
{
//    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
//    [self.baseView setFrame:self.view.bounds];

    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];
    [textView resignFirstResponder];    
}

/////////////////////////////////////////////////
#pragma mark - textfield delegate
/////////////////////////////////////////////////

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.handle = textField;
    if ([textField isEqual:self.telField]) {
        [self.baseView setContentOffset:CGPointMake(0, 50) animated:YES];
    }
    //    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //    [self.baseView setFrame:self.view.bounds];
    //    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    
    [self.baseView setContentOffset:CGPointMake(0, 0) animated:YES];
    [textField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}
@end
