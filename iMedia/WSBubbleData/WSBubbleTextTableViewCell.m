//
//  WSBubbleTextTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTextTableViewCell.h"
#import "WSBubbleData.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@interface WSBubbleTextTableViewCell ()

@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, strong) UIImageView *avatarImage;
@property (nonatomic, strong) UILabel *bubbleLabel;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleTextTableViewCell

@synthesize data = _data;
@synthesize bubbleImage;
@synthesize avatarImage;
@synthesize bubbleLabel;

- (void)setData:(WSBubbleData *)data
{
    [self setupInternalData:data];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        

        self.bubbleImage = [[UIImageView alloc] init];
        
        self.avatarImage = [[UIImageView alloc] init];
        self.avatarImage.layer.cornerRadius = 9.0;
        self.avatarImage.layer.masksToBounds = YES;
        self.avatarImage.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.avatarImage.layer.borderWidth = 1.0;
        
        self.bubbleLabel = [[UILabel alloc]init];
        self.bubbleLabel.numberOfLines = 0;
        self.bubbleLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.bubbleLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.bubbleLabel.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.avatarImage];
        [self.contentView addSubview:self.bubbleImage];
        [self.contentView addSubview:self.bubbleLabel];


    }
    return self;
}
- (void) setupInternalData:(WSBubbleData *)cellData
{
    [super setupInternalData:cellData];
    // count size and x y
    WSBubbleType type = cellData.type;
    
    CGFloat width = cellData.view.frame.size.width;
    CGFloat height = cellData.view.frame.size.height;
    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - cellData.insets.left - cellData.insets.right;
    CGFloat y = 5;
    
    // avatar
    [self.avatarImage setImage:(cellData.avatar ? cellData.avatar : [UIImage imageNamed:@"user_avatar_placeholder.png"])];
    CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - 52;
    CGFloat avatarY = 0 ;// self.frame.size.height - 50;
    self.avatarImage.frame = CGRectMake(avatarX, avatarY, 50, 50);
    
    if (type == BubbleTypeSomeoneElse) x += 54;
    if (type == BubbleTypeMine) x -= 54;
    
    // text label
    NSLog(@"CELL - %@",cellData.content);
    self.bubbleLabel.text = cellData.content;
    self.bubbleLabel.frame = CGRectMake(x + cellData.insets.left, y + cellData.insets.top, width, height);
    
    // bubbleimage bg
    if (type == BubbleTypeSomeoneElse)
    {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
    }else if(type == BubbleTypeMine) {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    }
    
    self.bubbleImage.frame = CGRectMake(x, y, width + cellData.insets.left + cellData.insets.right, height + cellData.insets.top + cellData.insets.bottom);
    
}



@end
