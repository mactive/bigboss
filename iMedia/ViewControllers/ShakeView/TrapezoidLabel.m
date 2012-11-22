//
//  TrapezoidLabel.m
//  iMedia
//
//  Created by meng qian on 12-11-22.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "TrapezoidLabel.h"
#import <QuartzCore/QuartzCore.h>

@implementation TrapezoidLabel
@synthesize bgColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // draw background
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, rect.size.width - 6, rect.size.height);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, 0, 0);
    
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillPath(context);
    
    // draw text
    NSString *string = self.text;
    CGContextSetFillColorWithColor(context, self.textColor.CGColor);
    [string drawAtPoint:CGPointMake(5.0f, (rect.size.height - 10)/2 ) withFont:[UIFont boldSystemFontOfSize:10.0f]];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
