//
//  CompanyTableViewCell.m
//  iMedia
//
//  Created by meng qian on 13-3-13.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyTableViewCell.h"
#import "AppNetworkAPIClient.h"

@interface CompanyTableViewCell()
@property(nonatomic, strong)Company *data;
@property(nonatomic, strong)UIImage *avatarImage;
@end

@implementation CompanyTableViewCell

@synthesize data;
@synthesize avatarImage;


#define CELL_HEIGHT 50.0f

#define AVATAR_HEIGHT 36
#define AVATAR_X    (CELL_HEIGHT - AVATAR_HEIGHT)/2
#define NAME_X      75
#define NAME_HEIGHT 16
#define NAME_Y      (CELL_HEIGHT - NAME_HEIGHT)/2
#define NAME_WIDTH  200

#define COUNT_X     230
#define COUNT_WIDTH 15
#define COUNT_HEIGHT 15
#define COUNT_Y     (CELL_HEIGHT - COUNT_HEIGHT)/2

#define AVATAR_TAG  1
#define NAME_TAG    2
#define COUNT_TAG   3

#define MIDDLE_COLUMN_WIDTH 100.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_WIDTH_OFFEST 30.0
#define SUMMARY_WIDTH 80.0
#define MAIN_FONT_SIZE 16.0



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self setNeedsDisplay];
}

- (void)setNewCompany:(Company *)company{
    self.data  = company;
    
    if (StringHasValue(company.logo)){
        [[AppNetworkAPIClient sharedClient] loadImage:company.logo withBlock:^(UIImage *image, NSError *error) {
            if (image) {
                self.avatarImage = image;
            }
        }];
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (self.selected || self.highlighted) {
        CGRect rectangle = self.bounds;
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 0.86, 0.86, 0.86, 1.0);
        //        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, rectangle);
    }
    
    //// avatar
    CGRect avatarRect = CGRectMake(AVATAR_X*2, AVATAR_X, AVATAR_HEIGHT, AVATAR_HEIGHT);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    CGFloat _labelHeight;
    
    NSString *nameString;
    
    nameString = self.data.name;
    
    // nickname
    UIColor *nameMagentaColor = RGBCOLOR(107, 107, 107);
    [nameMagentaColor set];
    UIFont* nameFont = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    CGSize labelSize = [nameString sizeWithFont:nameFont constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (labelSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    
    CGRect nameRect = CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_HEIGHT);
    
    [nameString drawInRect:nameRect
                  withFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
    
    
    // location icon
    UIImage *privateIcon = [UIImage imageNamed:@"private_icon.png"];
    
    if (self.data.isPrivate.boolValue) {
        [privateIcon drawInRect:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    }
    
}

@end
