//
//  WSBubbleHeaderTableViewCell.m
//  WSBubbleTableViewExample
//
//  Created by Александр Баринов on 10/7/12.
//  Copyright (c) 2012 Stex Group. All rights reserved.
//

#import "WSBubbleSectionHeader.h"

@interface WSBubbleSectionHeader ()

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIImageView *bgView;

@end

@implementation WSBubbleSectionHeader

@synthesize label = _label;
@synthesize date = _date;
@synthesize bgView = _bgView;


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

    }
    return self;
}

- (void)setDate:(NSDate *)value
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *text = [dateFormatter stringFromDate:value];
    
    if (self.label)
    {
        self.label.text = text;
        return;
    }
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.label.text = text;
    self.label.font = [UIFont boldSystemFontOfSize:12];
    self.label.textAlignment = UITextAlignmentCenter;
    self.label.shadowOffset = CGSizeMake(0, 1);
    self.label.shadowColor = [UIColor whiteColor];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.backgroundColor = [UIColor clearColor];
    
    self.bgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"MessageBubbleSectionHeader.png"]];
    [self.bgView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height )];
    
    [self addSubview:self.bgView];
    [self addSubview:self.label];
}



@end
