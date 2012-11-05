//
//  MetroButton.m
//  iMedia
//
//  Created by meng qian on 12-11-5.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "MetroButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation MetroButton

@synthesize iconView;
@synthesize titleLabel;
@synthesize colorArray;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 0;
        self.colorArray = [[NSArray alloc] initWithObjects:
                           RGBCOLOR(151, 206, 45),
                           RGBCOLOR(117, 198, 231),
                           RGBCOLOR(248, 139, 202),
                           RGBCOLOR(236, 134, 94),nil];
        
        self.iconView  = [[UIImageView alloc]initWithFrame:CGRectMake((frame.size.width-75)/2, (frame.size.height-75)/3, 75, 75)];
        
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setBackgroundColor:[UIColor clearColor]];
        [self.titleLabel setFrame:CGRectMake(0, frame.size.height /4*3, frame.size.width, 20)];
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
        
        [self addSubview:self.iconView];
        [self addSubview:self.titleLabel];
        
    }
    return self;
}

- (void)initMetroButton:(UIImage *)image andText:(NSString *)titleString andIndex:(NSUInteger)index
{
    [self.iconView setImage:image];
    self.titleLabel.text = titleString;
    [self setBackgroundColor:[self.colorArray objectAtIndex:index]];
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
