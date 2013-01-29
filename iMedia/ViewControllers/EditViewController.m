//
//  EditViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-31.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "EditViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "NSDate+timesince.h"

@interface EditViewController ()

@property(strong, nonatomic) UILabel * nameLabel;
@property(strong, nonatomic) UILabel * horoscopeLabel;
@property(strong, nonatomic) UILabel *noticeLabel;
@property(strong, nonatomic) UITextView * valueTextView;
@property(strong, nonatomic) UITextField * valueTextField;
@property(strong, nonatomic) UIPickerView *sexPicker;
@property(strong, nonatomic) NSDictionary *sexTitleDict;
@property(strong, nonatomic) NSArray *sexTitleValue;
@property(strong, nonatomic) NSArray *sexTitleKey;
@property(strong, nonatomic) UIDatePicker *datePicker;
@property(strong, nonatomic) NSDateFormatter *dateFormatter;
@property(strong, nonatomic) UIButton* doneButton;
@property(strong, nonatomic) UILabel *restCountLabel;

// for birth area
@property(strong, nonatomic) UILabel * ageTitleLabel;
@property(strong, nonatomic) UILabel * horoscopeTitleLabel;
@property(strong, nonatomic) UILabel * birthValueLabel;
@property(strong, nonatomic) UILabel * ageValueLabel;
@property(strong, nonatomic) UILabel * horoscopeValueLabel;

@end

@implementation EditViewController
@synthesize nameLabel;
@synthesize horoscopeLabel;
@synthesize noticeLabel;
@synthesize valueTextView;
@synthesize valueTextField;
@synthesize nameText;
@synthesize valueText;
@synthesize delegate;
@synthesize valueIndex;
@synthesize sexPicker;
@synthesize sexTitleDict;
@synthesize sexTitleValue;
@synthesize sexTitleKey;
@synthesize datePicker;
@synthesize dateFormatter;
@synthesize doneButton;
@synthesize restCountLabel;

//
@synthesize ageTitleLabel;
@synthesize horoscopeTitleLabel;
@synthesize birthValueLabel;
@synthesize ageValueLabel;
@synthesize horoscopeValueLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIBarButtonItem *ttButton = [[UIBarButtonItem alloc] initWithTitle:T(@"完成")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(doneAction)];
        [ttButton setTintColor:RGBCOLOR(77, 139, 192)];
        self.navigationItem.rightBarButtonItem = ttButton;
        self.navigationItem.leftBarButtonItem  = ttButton; // hide left bar button
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BGCOLOR;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"yyyy-MM-dd"];
    
    self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 20, 300 , 30)];
    [self.nameLabel setBackgroundColor:[UIColor clearColor]];
    [self.nameLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.nameLabel setTextColor:[UIColor grayColor]];
    self.nameLabel.text = self.nameText;
    self.nameLabel.shadowColor = [UIColor whiteColor];
    self.nameLabel.shadowOffset = CGSizeMake(0, 1);
    [self.view addSubview:self.nameLabel];

    self.valueTextView = [[UITextView alloc] initWithFrame:CGRectMake(20 , 60, 280 , 100)];
    [self.valueTextView.layer setMasksToBounds:YES];
    [self.valueTextView.layer setCornerRadius:5.0];    
    [self.valueTextView.inputView setFrame:CGRectMake(20, 10, 240, 60)];
    self.valueTextView.font = [UIFont systemFontOfSize:14.0];
    self.valueTextView.textColor = [UIColor blackColor];
    self.valueTextView.backgroundColor = [UIColor whiteColor];
    self.valueTextView.delegate = self;
    
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 110, 320, 20)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    [self.view addSubview:self.noticeLabel];
    
    self.restCountLabel = [[UILabel alloc]initWithFrame:CGRectMake(270, 25, 30, 20)];
    [self.restCountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.restCountLabel setBackgroundColor:RGBCOLOR(213, 213, 213)];
    [self.restCountLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.restCountLabel.textColor = RGBCOLOR(106, 106, 106);
    self.restCountLabel.layer.cornerRadius = 3;

    self.valueTextField = [[UITextField alloc] initWithFrame:CGRectMake(20 , 60, 280 , 40)];
    self.valueTextField.font = [UIFont systemFontOfSize:18.0];
    self.valueTextField.textColor = [UIColor grayColor];
    self.valueTextField.delegate = self;
    self.valueTextField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.valueTextField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.valueTextField.layer.borderWidth  = 1.0f;
    self.valueTextField.layer.cornerRadius = 5.0f;
    self.valueTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.valueTextField.textAlignment = UITextAlignmentCenter;
    
    self.sexPicker = [[UIPickerView alloc]init ];
    self.sexPicker.delegate = self;
    [self.sexPicker setFrame:CGRectMake(0, 60, 320, 240)];
    self.sexPicker.showsSelectionIndicator = YES;
    self.sexTitleDict = [ServerDataTransformer sexDict];
    self.sexTitleValue = [self.sexTitleDict allValues];
    self.sexTitleKey = [self.sexTitleDict allKeys];
    
    self.datePicker = [[UIDatePicker alloc]init];
    [self.datePicker setFrame:CGRectMake(0, 200, 320, 300)];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    
//    self.doneButton  = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 300, 275, 40)];
//    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
//    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.doneButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
//    [self.doneButton setTitle:T(@"完成") forState:UIControlStateNormal];
//    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
//    [self.doneButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.doneButton];

}

- (void)initBirthView
{
    // birth area
    self.ageTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 60, 100 , 30)];
    [self.ageTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.ageTitleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.ageTitleLabel setTextColor:[UIColor grayColor]];
    self.ageTitleLabel.text = self.nameText;
    self.ageTitleLabel.shadowColor = [UIColor whiteColor];
    self.ageTitleLabel.shadowOffset = CGSizeMake(0, 1);
    self.ageTitleLabel.text = T(@"年龄");
    
    self.horoscopeTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 100, 100 , 30)];
    [self.horoscopeTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.horoscopeTitleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.horoscopeTitleLabel setTextColor:[UIColor grayColor]];
    self.horoscopeTitleLabel.text = self.nameText;
    self.horoscopeTitleLabel.shadowColor = [UIColor whiteColor];
    self.horoscopeTitleLabel.shadowOffset = CGSizeMake(0, 1);
    self.horoscopeTitleLabel.text = T(@"星座");
    
    self.ageValueLabel = [[UILabel alloc]initWithFrame:CGRectMake(120, 60, 100 , 30)];
    [self.ageValueLabel setTextAlignment:NSTextAlignmentCenter];
    [self.ageValueLabel setBackgroundColor:[UIColor clearColor]];
    [self.ageValueLabel setFont:[UIFont systemFontOfSize:20.0]];
    self.ageValueLabel.textColor = RGBCOLOR(195, 70, 21);
    self.ageValueLabel.shadowColor = [UIColor whiteColor];
    self.ageValueLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.birthValueLabel = [[UILabel alloc]initWithFrame:CGRectMake(120, 20, 120 , 30)];
    [self.birthValueLabel setTextAlignment:NSTextAlignmentCenter];
    [self.birthValueLabel setBackgroundColor:[UIColor clearColor]];
    [self.birthValueLabel setFont:[UIFont systemFontOfSize:20.0]];
    self.birthValueLabel.textColor = RGBCOLOR(195, 70, 21);
    self.birthValueLabel.shadowColor = [UIColor whiteColor];
    self.birthValueLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.horoscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(120, 100, 100 , 30)];
    [self.horoscopeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.horoscopeLabel setBackgroundColor:[UIColor clearColor]];
    [self.horoscopeLabel setFont:[UIFont systemFontOfSize:20.0]];
    self.horoscopeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.horoscopeLabel.shadowColor = [UIColor whiteColor];
    self.horoscopeLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.birthValueLabel.text = self.valueText;
    NSDate *_date = [self.dateFormatter dateFromString:self.valueText];
    if (_date == nil) {
        self.ageValueLabel.text = nil;
    } else {
        NSUInteger age = floor([_date daysBeforeDate:[NSDate dateWithDaysFromNow:0]] / 365);
        self.ageValueLabel.text = [ NSString stringWithFormat:T(@"%i 岁"), age ];
    }
    
    [self.view addSubview:self.horoscopeLabel];    
    [self.view addSubview:self.ageTitleLabel];
    [self.view addSubview:self.ageValueLabel];
    [self.view addSubview:self.birthValueLabel];
    [self.view addSubview:self.horoscopeTitleLabel];
}

- (void)doneAction
{
    if(self.valueIndex == CELL_ITEM_INDEX)
    {
        if ([self.valueTextField.text length] < CELL_MAX_LENGTH && [self.valueTextField.text length] != 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"手机号码有点短") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else if(self.valueIndex == NICKNAME_ITEM_INDEX){
        if ([self.valueTextField.text length] == 0 ) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"昵称不能为空") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if(self.valueIndex == BIRTH_ITEM_INDEX)
    {
        [self initBirthView];
        
        if (self.valueText == nil) {
            self.horoscopeLabel.text = T(@"星座");
        } else {
            NSDate *_date = [self.dateFormatter dateFromString:self.valueText];
            if (_date != nil) {
                [self.datePicker setDate:_date animated:YES];
                self.horoscopeLabel.text = [_date horoscope];
            }
            [self.datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
            [self.view addSubview:self.datePicker];
        }
        
    }else if(self.valueIndex == SIGNATURE_ITEM_INDEX || self.valueIndex == SELF_INTRO_ITEM_INDEX)
    {
        [self.valueTextView  setFrame:CGRectMake(20 , 60, 280 , 100)];
        self.valueTextView.text = self.valueText;
        [self.view addSubview:self.valueTextView];
        [self.valueTextView becomeFirstResponder];
        
        if (self.valueIndex == SIGNATURE_ITEM_INDEX){
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",SIGNATURE_MAX_LENGTH - [self.valueText length] ];
        }else{
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",SELF_INTRO_MAX_LENGTH - [self.valueText length]];
        }
        
        [self.view addSubview:self.restCountLabel];
    }
    else {
        if (self.valueIndex == NICKNAME_ITEM_INDEX) {
            self.noticeLabel.text = [NSString stringWithFormat:T(@"不能超过%i个字符."),NICKNAME_MAX_LENGTH];
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",NICKNAME_MAX_LENGTH - [self.valueText length]];
        }else if (self.valueIndex == CELL_ITEM_INDEX){
            self.noticeLabel.text = T(@"请填写11位手机号码");
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",CELL_MAX_LENGTH - [self.valueText length]];
            self.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
        }else if (self.valueIndex == HOMETOWN_ITEM_INDEX){
            self.noticeLabel.text = [NSString stringWithFormat:T(@"不能超过%i个字符."),HOMETOWN_MAX_LENGTH];
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",HOMETOWN_MAX_LENGTH - [self.valueText length]];
        }else{
            // school interest company always
            self.noticeLabel.text = [NSString stringWithFormat:T(@"不能超过%i个字符."),DEFAULT_MAX_LENGTH];
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",DEFAULT_MAX_LENGTH - [self.valueText length]];
        }
        
        [self.view addSubview:self.restCountLabel];
        
        self.valueTextField.text = self.valueText;
        [self.view addSubview:self.self.valueTextField];
        [self.valueTextView becomeFirstResponder];
    }
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - uitextfield delegate
/////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    if ([string isEqualToString:@"\n"])
    {
        return YES;
    }
    NSString * toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (self.valueTextField == textField)
    {
        if (self.valueIndex == NICKNAME_ITEM_INDEX) {
            
            NSInteger countInt = (NICKNAME_MAX_LENGTH > [toBeString length]) ? NICKNAME_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];
            
            if ([toBeString length] > NICKNAME_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:NICKNAME_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"超过最大字数不能输入了") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
            
            if ([toBeString length] == 0) {
                textField.text = @"";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"此项不能为空") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
            
            
        }
        
        else if (self.valueIndex == CELL_ITEM_INDEX){
            
            NSInteger countInt = (CELL_MAX_LENGTH > [toBeString length]) ? CELL_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];

            if ([toBeString length] > CELL_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:CELL_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"手机号码有点长") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
        }else if (self.valueIndex == HOMETOWN_ITEM_INDEX){
            
            
            NSInteger countInt = (HOMETOWN_MAX_LENGTH > [toBeString length]) ? HOMETOWN_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];
                        
            if ([toBeString length] > HOMETOWN_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:HOMETOWN_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"家乡有点长") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
            
        }else{
            // school interest company always
            NSInteger countInt = (DEFAULT_MAX_LENGTH > [toBeString length]) ? DEFAULT_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];
            
            if ([toBeString length] > DEFAULT_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:DEFAULT_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"超过最大字数不能输入") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }

        }
    
    }
    return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
#warning    TEST for all UTF8 character handling
    [self.delegate passStringValue:self.valueTextField.text andIndex:self.valueIndex];
    return YES;
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - uipickerview delegate
/////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger result = 0;
    if ([pickerView isEqual:self.sexPicker]) {
        result = 1;
    }
    return result;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger result = 0;
    if ([pickerView isEqual:self.sexPicker]) {
        result = [self.sexTitleKey count];
    }
    return result;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString* result = @"";
    if ([pickerView isEqual:self.sexPicker]) {
        result = [self.sexTitleValue objectAtIndex:row];
    }
    return result;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([pickerView isEqual:self.sexPicker]) {
        [self.delegate passStringValue:[self.sexTitleKey objectAtIndex:row] andIndex:self.valueIndex];
    }
}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - datepicker delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)dateChanged
{
    NSString *_horoscope = [self.datePicker.date horoscope];
    self.horoscopeLabel.text = _horoscope;
    
    NSUInteger age = floor([self.datePicker.date daysBeforeDate:[NSDate dateWithDaysFromNow:0]] / 365);
    self.ageValueLabel.text = [ NSString stringWithFormat:T(@"%i 岁"), age ];
    
    self.birthValueLabel.text = [self.dateFormatter stringFromDate:self.datePicker.date];
    
    [self.delegate passNSDateValue:self.datePicker.date  andIndex:self.valueIndex];
}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - textview delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.delegate passStringValue:self.valueTextView.text andIndex:self.valueIndex];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString * toBeString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (self.valueTextView == textView)
    {
        if (self.valueIndex == SIGNATURE_ITEM_INDEX ) {
            
            NSInteger countInt = (SIGNATURE_MAX_LENGTH > [toBeString length]) ? SIGNATURE_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];
            
            if ([toBeString length] > SIGNATURE_MAX_LENGTH) {
                textView.text = [toBeString substringToIndex:SIGNATURE_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"字数有点多") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
        }else if ( self.valueIndex  == SELF_INTRO_ITEM_INDEX){
            NSInteger countInt = (SELF_INTRO_MAX_LENGTH > [toBeString length]) ? SELF_INTRO_MAX_LENGTH - [toBeString length]: 0;
            self.restCountLabel.text = [NSString stringWithFormat:@"%i",countInt];
            
            if ([toBeString length] > SELF_INTRO_MAX_LENGTH) {
                textView.text = [toBeString substringToIndex:SELF_INTRO_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"字数有点多") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
            
        }
        
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
