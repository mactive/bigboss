//
//  WSBubbleRateTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleRateTableViewCell.h"
#import "WSBubbleData.h"
#import "AppDefs.h"

@interface WSBubbleRateTableViewCell ()

@property (nonatomic, strong) UILabel *rateLabel;
@property (nonatomic, strong) UIImageView *rateView;

@end


@implementation WSBubbleRateTableViewCell

@synthesize rateLabel = _rateLabel;
@synthesize rateView = _rateView;
@synthesize data = _data;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.rateView = [[UIImageView alloc]initWithFrame:CGRectMake(80, 10, 160, 41)];
        self.rateLabel = [[UILabel alloc]initWithFrame:self.rateView.bounds];
        [self.rateLabel setTextAlignment:NSTextAlignmentCenter];
        [self.rateLabel setTextColor:[UIColor whiteColor]];
        [self.rateLabel setBackgroundColor:[UIColor clearColor]];
        [self.rateView addSubview:self.rateLabel];
        [self.contentView addSubview:self.rateView];
    }
    return self;
}

- (void)setData:(WSBubbleData *)data
{
    [super setData:data];
}


- (void) setupInternalData:(WSBubbleData *)cellData;
{
    [super setupInternalData:cellData];

    [self.rateView setImage:[UIImage imageNamed:@"welcome_btn.png"]];
    [self.rateLabel setText:T(@"评价客服")];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
