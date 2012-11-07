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

@interface EditViewController ()

@property(strong, nonatomic) UILabel * nameLabel;
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

@end

@implementation EditViewController
@synthesize nameLabel;
@synthesize noticeLabel;
@synthesize valueTextView;
@synthesize valueTextField;
@synthesize nameText;
@synthesize valueText;
@synthesize delegate;
@synthesize valueIndex;
@synthesize valueType;
@synthesize sexPicker;
@synthesize sexTitleDict;
@synthesize sexTitleValue;
@synthesize sexTitleKey;
@synthesize datePicker;
@synthesize dateFormatter;
@synthesize doneButton;

#define NICKNAME_MAX_LENGTH 20
#define SIGNATURE_MAX_LENGTH 200
#define CELL_MAX_LENGTH 11

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
    [self.datePicker setFrame:CGRectMake(0, 60, 320, 300)];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"所填项目不能为空") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.valueIndex == SEX_ITEM_INDEX) {
//        [self.sexPicker selectRow:1 inComponent:1 animated:YES];
        NSInteger index =  [self.sexTitleKey indexOfObject:self.valueText];
        [self.sexPicker selectRow:index inComponent:0 animated:YES];
        [self.view addSubview:self.sexPicker];
        
    }else if(self.valueIndex == BIRTH_ITEM_INDEX)
    {
        NSDate *_date = [self.dateFormatter dateFromString:self.valueText];
        NSLog(@"date:%@", _date);
        [self.datePicker setDate:_date animated:YES];
        [self.datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:self.datePicker];
    }else if(self.valueIndex == SIGNATURE_ITEM_INDEX || self.valueIndex == SELF_INTRO_ITEM_INDEX)
    {
        [self.valueTextView  setFrame:CGRectMake(20 , 60, 280 , 100)];
        self.valueTextView.text = self.valueText;
        [self.view addSubview:self.valueTextView];
        [self.valueTextView becomeFirstResponder];
    }
    else {
        if (self.valueIndex == NICKNAME_ITEM_INDEX) {
            self.noticeLabel.text = [NSString stringWithFormat:T(@"昵称不能超过%i个字符."),NICKNAME_MAX_LENGTH];
        }else if (self.valueIndex == CELL_ITEM_INDEX){
            self.noticeLabel.text = T(@"请填写11位手机号码");
            self.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
        }
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
        if (self.valueIndex == NICKNAME_ITEM_INDEX || self.valueIndex  == CAREER_ITEM_INDEX) {
            if ([toBeString length] > NICKNAME_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:NICKNAME_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"超过最大字数不能输入了") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }
        }else if (self.valueIndex == CELL_ITEM_INDEX){
            if ([toBeString length] > CELL_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:CELL_MAX_LENGTH];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:T(@"手机号码有点长") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return NO;
            }

        }

    }
    return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [self.delegate passStringValue:self.valueTextField.text andIndex:self.valueIndex];
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
    [self.delegate passNSDateValue:self.datePicker.date  andIndex:self.valueIndex];
}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - textview delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.delegate passStringValue:self.valueTextView.text andIndex:self.valueIndex];
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
