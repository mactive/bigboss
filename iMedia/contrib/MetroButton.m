//
//  MetroButton.m
//  iMedia
//
//  Created by meng qian on 12-11-5.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "MetroButton.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDefs.h"
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
                           RGBCOLOR(231,117,117),
                           RGBCOLOR(151,206,45),
                           RGBCOLOR(117,198,231),
                           RGBCOLOR(238,175,212),
                           RGBCOLOR(251,176,147),
                           RGBCOLOR(136,143,154),nil];
        
        self.iconView  = [[UIImageView alloc]initWithFrame:CGRectMake((frame.size.height-75)/2, (frame.size.height-75)/2, 75, 75)];
        
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setBackgroundColor:[UIColor clearColor]];
        [self.titleLabel setFrame:CGRectMake(120, (frame.size.height-20)/2 , frame.size.width /2, 20)];
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
    UIImage *normalImage = [self createImageWithColor:[self.colorArray objectAtIndex:index]];
    UIImage *selectedImage = [self createImageWithColor:RGBCOLOR(195, 195, 195)];
    [self setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
}


- (UIImage *) createImageWithColor: (UIColor *) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
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
