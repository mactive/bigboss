//
//  WSBubbleHeaderTableViewCell.m
//  WSBubbleTableViewExample
//
//  Created by Александр Баринов on 10/7/12.
//  Copyright (c) 2012 Stex Group. All rights reserved.
//

#import "WSBubbleSectionHeaderTableViewCell.h"
#import "WSBubbleData.h"

@interface WSBubbleSectionHeaderTableViewCell ()

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIImageView *bgView;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleSectionHeaderTableViewCell

@synthesize label = _label;
@synthesize bgView = _bgView;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.label.font = [UIFont boldSystemFontOfSize:12];
        self.label.textAlignment = UITextAlignmentCenter;
        self.label.shadowOffset = CGSizeMake(0, 1);
        self.label.shadowColor = [UIColor whiteColor];
        self.label.textColor = [UIColor darkGrayColor];
        self.label.backgroundColor = [UIColor clearColor];
        
        self.bgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"MessageBubbleSectionHeader.png"]];
        [self.bgView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height )];
        
        [self.bgView addSubview:self.label];
        [self addSubview:self.bgView];
    }
    return self;
}

- (void)setData:(WSBubbleData *)data
{
    [super setData:data];
}


- (void) setupInternalData:(WSBubbleData *)cellData
{
    [super setupInternalData:cellData];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *text = [dateFormatter stringFromDate:cellData.date];
    self.label.text = text;
    self.label.frame = CGRectMake(0, 0, 320, cellData.cellHeight);
    self.bgView.frame = CGRectMake(0, cellData.insets.top, self.frame.size.width, cellData.cellHeight);

}



@end
