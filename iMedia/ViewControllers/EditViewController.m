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
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"yyyy-MM-dd"];
    
    self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 20, 300 , 30)];
    [self.nameLabel setBackgroundColor:[UIColor clearColor]];
    [self.nameLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.nameLabel setTextColor:[UIColor grayColor]];
    self.nameLabel.text = self.nameText;
    self.nameLabel.shadowColor = [UIColor whiteColor];
    self.nameLabel.shadowOffset = CGSizeMake(0, 1);
    [self.view addSubview:self.nameLabel];

    self.valueTextView = [[UITextView alloc] initWithFrame:CGRectMake(20 , 50, 280 , 80)];
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
    [self.sexPicker setFrame:CGRectMake(0, 60, 320, 200)];
    self.sexPicker.showsSelectionIndicator = YES;
    self.sexTitleDict = [ServerDataTransformer sexDict];
    self.sexTitleValue = [self.sexTitleDict allValues];
    self.sexTitleKey = [self.sexTitleDict allKeys];
    
    self.datePicker = [[UIDatePicker alloc]init];
    [self.datePicker setFrame:CGRectMake(0, 60, 320, 300)];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
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
        [self.delegate passValue:[self.sexTitleKey objectAtIndex:row] andIndex:self.valueIndex];
    }
}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - datepicker delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)dateChanged
{
    NSString * _tmp = [[NSString alloc] initWithString:[self.dateFormatter stringFromDate:self.datePicker.date]];
    [self.delegate passValue:_tmp  andIndex:self.valueIndex];
}
/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - textview delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.delegate passValue:self.valueTextView.text andIndex:self.valueIndex];
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
