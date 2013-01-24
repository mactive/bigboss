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

@interface MetroButton()
@property(readwrite, nonatomic)CGRect mainframe;

@end

@implementation MetroButton

@synthesize iconView;
@synthesize titleLabel;
@synthesize colorArray;
@synthesize mainframe;
#define LABEL_HEIGHT 20.0f
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
        
        self.iconView  = [[UIImageView alloc]initWithFrame:CGRectZero];
        
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setBackgroundColor:[UIColor clearColor]];
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
        [self addSubview:self.iconView];
        [self addSubview:self.titleLabel];
        self.mainframe = frame;
    }
    return self;
}

- (void)initMetroButton:(UIImage *)image andText:(NSString *)titleString andIndex:(NSUInteger)index
{
    if (self.mainframe.size.height < 100) {
        [self.iconView setFrame:CGRectMake(10, (self.mainframe.size.height-image.size.height)/2, image.size.width, image.size.height)];
        [self.titleLabel setFrame:CGRectMake(image.size.width+30, (self.mainframe.size.height-LABEL_HEIGHT)/2 , self.mainframe.size.width, LABEL_HEIGHT)];
        [self.titleLabel setTextAlignment:NSTextAlignmentLeft];

    }else{
        [self.iconView setFrame:CGRectMake((self.mainframe.size.width-image.size.width)/2, (self.mainframe.size.height-image.size.height)/3*1, image.size.width, image.size.height)];
        [self.titleLabel setFrame:CGRectMake(0, (self.mainframe.size.height-LABEL_HEIGHT*2) , self.mainframe.size.width, LABEL_HEIGHT)];
    }
    
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
