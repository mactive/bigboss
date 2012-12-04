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

@property (nonatomic, strong) UILabel *templateTitle;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleNoticationTableViewCell
@synthesize templateTitle = _templateTitle;
@synthesize data = _data;

#define OFFSET_CONTENT 20

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        self.templateTitle = [[UILabel alloc] initWithFrame:CGRectMake((320-TEMPLATEB_RESIZE_WIDTH)/2, 10, TEMPLATEB_RESIZE_WIDTH, 30)];
        self.templateTitle.numberOfLines = 0;
        self.templateTitle.backgroundColor = RGBACOLOR(0, 0, 0, 0.2);
        self.templateTitle.font = [UIFont systemFontOfSize:16];
        self.templateTitle.textColor = RGBCOLOR(85, 85, 85);
        self.templateTitle.textAlignment = NSTextAlignmentCenter;
        self.templateTitle.layer.cornerRadius = 5.0f;
        
        [self.contentView addSubview:self.templateTitle];
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
    
    CGFloat height = cellData.view.frame.size.height;
    
    NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:cellData.content error:nil];
        
    NSString* titleString = [[element elementForName:@"title9"] stringValue];
    
    
    CGSize titleSize = [(titleString ? titleString : @"") sizeWithFont:self.templateTitle.font constrainedToSize:CGSizeMake(TEMPLATEB_RESIZE_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    [self.templateTitle setFrame:CGRectMake(self.templateTitle.frame.origin.x, self.templateTitle.frame.origin.y,
                                            TEMPLATEB_RESIZE_WIDTH, titleSize.height)];
    
    self.templateTitle.text = titleString;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
