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
@property(strong, nonatomic) UITextView * valueTextView;
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
@synthesize valueTextView;
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
    self.valueTextView.text = self.valueText;
    
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
    
    self.doneButton  = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 300, 275, 40)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"完成") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_arrow_bg.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
}

- (void)doneAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.valueType isEqualToString:@"sex"]) {
//        [self.sexPicker selectRow:1 inComponent:1 animated:YES];
        NSInteger index =  [self.sexTitleKey indexOfObject:self.valueText];
        [self.sexPicker selectRow:index inComponent:0 animated:YES];
        [self.view addSubview:self.sexPicker];
        
    }else if([self.valueType isEqualToString:@"date"])
    {
        NSDate *_date = [self.dateFormatter dateFromString:self.valueText];
        NSLog(@"date:%@", _date);
        [self.datePicker setDate:_date animated:YES];
        [self.datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:self.datePicker];
    }
    else {
        if (self.valueIndex == 3 || self.valueIndex == 7) {
            [self.doneButton  setFrame:CGRectMake(22.5, 180, 275, 40)];
            [self.valueTextView  setFrame:CGRectMake(20 , 60, 280 , 100)];
        }else{
            [self.doneButton  setFrame:CGRectMake(22.5, 120, 275, 40)];
            [self.valueTextView  setFrame:CGRectMake(20 , 60, 280 , 40)];
        }
        
        [self.view addSubview:self.valueTextView];
    }
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
