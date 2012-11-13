//
//  WSBubbleData.m
//  iMedia
//
//  Created by meng qian on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleData.h"
#import <QuartzCore/QuartzCore.h>


@implementation WSBubbleData

@synthesize date = _date;
@synthesize type = _type;
@synthesize avatar = _avatar;
@synthesize content = _content;
@synthesize showAvatar = _showAvatar;
@synthesize isDone = _isDone;
@synthesize cellHeight = _cellHeight;
@synthesize msg = _msg;
@synthesize insets = _insets;
@synthesize view = _view;


const UIEdgeInsets textInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {5, 15, 11, 10};

#define MAX_WIDTH 220


+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithText:text date:date type:type];
}
- (id)initWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(MAX_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = (text ? text : @"");
    label.font = font;
    label.backgroundColor = [UIColor clearColor];

    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date content:text type:type insets:insets];
}



- (id)initWithView:(UIView *)view date:(NSDate *)date content:(NSString *)content type:(WSBubbleType)type insets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self)
    {

        _date = date;
        _type = type;
        _content = content;
        _insets = insets;
        
        self.showAvatar = type != BubbleTypeTemplateview ? YES : NO ;
        self.isDone = NO;
        self.cellHeight = view.frame.size.height;
        self.view = view;
    }
    return self;
}


@end
