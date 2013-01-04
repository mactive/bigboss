//
//  WSBubbleNoticationTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleNoticationTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "XMPPFramework.h"
#import "UIImageView+AFNetworking.h"
#import "WSBubbleData.h"


@interface WSBubbleNoticationTableViewCell ()

@property (nonatomic, strong) UIView *templateView;
@property (nonatomic, strong) UILabel *templateTitle;


- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleNoticationTableViewCell
@synthesize templateView = _templateView;
@synthesize templateTitle = _templateTitle;
@synthesize data = _data;

#define OFFSET_CONTENT 20

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.templateView = [[UIView alloc]initWithFrame:CGRectMake((320-TEMPLATEB_RESIZE_WIDTH)/2, 10, TEMPLATEB_RESIZE_WIDTH, 30)];
        self.templateView.backgroundColor = RGBACOLOR(0, 0, 0, 0.05);
        self.templateView.layer.cornerRadius = 5.0f;

        self.templateTitle = [[UILabel alloc] initWithFrame:CGRectMake( 5, 5, TEMPLATEB_RESIZE_WIDTH, 30)];
        self.templateTitle.numberOfLines = 0;
        self.templateTitle.backgroundColor = [UIColor clearColor];
        self.templateTitle.font = [UIFont systemFontOfSize:14];
        self.templateTitle.textColor = RGBCOLOR(145, 145, 145);
        self.templateTitle.textAlignment = NSTextAlignmentCenter;
        
        [self.templateView addSubview:self.templateTitle];
        [self.contentView addSubview:self.templateView];
        
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
                
    NSString* titleString = cellData.content;
    
    CGSize titleSize = [(titleString ? titleString : @"") sizeWithFont:self.templateTitle.font constrainedToSize:CGSizeMake(TEMPLATEB_RESIZE_WIDTH-OFFSET_CONTENT, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    [self.templateTitle setFrame:CGRectMake(OFFSET_CONTENT/2, OFFSET_CONTENT/2,
                                            TEMPLATEB_RESIZE_WIDTH-OFFSET_CONTENT, titleSize.height)];
    
    [self.templateView setFrame:CGRectMake(self.templateView.frame.origin.x, cellData.insets.top,
                                            TEMPLATEB_RESIZE_WIDTH, titleSize.height+OFFSET_CONTENT)];
    
    self.templateTitle.text = titleString;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
