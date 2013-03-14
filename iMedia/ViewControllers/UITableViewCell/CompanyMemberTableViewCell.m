//
//  CompanyMemberTableViewCell.m
//  iMedia
//
//  Created by meng qian on 13-3-14.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyMemberTableViewCell.h"
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h"
#import "Me.h"

@interface CompanyMemberTableViewCell()

@property(nonatomic, strong)NSDictionary *data;
@property(nonatomic, strong)UIImage *avatarImage;

@end

@implementation CompanyMemberTableViewCell

@synthesize data;
@synthesize avatarImage;

#define CELL_HEIGHT 50.0f
#define AVATAR_HEIGHT 36
#define AVATAR_X    (CELL_HEIGHT - AVATAR_HEIGHT)/2
#define NAME_X      75
#define NAME_HEIGHT 16
#define NAME_Y      (CELL_HEIGHT - NAME_HEIGHT)/2
#define NAME_WIDTH  200

#define COUNT_X     145
#define COUNT_WIDTH 130
#define COUNT_HEIGHT 14
#define COUNT_Y     (CELL_HEIGHT - COUNT_HEIGHT)/2
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


- (void)setNewMember:(NSDictionary *)member
{
    self.data  = member;
    self.avatarImage = [UIImage imageNamed:@"placeholder_user.png"];

    if (StringHasValue([member objectForKey:@"thumbnail"])){
        [[AppNetworkAPIClient sharedClient] loadImage:[member objectForKey:@"thumbnail"] withBlock:^(UIImage *image, NSError *error) {
            if (image) {
                self.avatarImage = image;
#warning everytime get image redraw memory
                [self setNeedsDisplay];
            }
        }];
    }
    
    // show the right arrow
    if ([[self appDelegate].me.guid isEqualToString:[member objectForKey:@"guid"]]) {
        self.accessoryType = UITableViewCellAccessoryNone;
    }else{
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
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
    
    //drabottomline
    UIImage *cellBg = [UIImage imageNamed:@"cell_H1_bg.png"];
    [cellBg drawInRect:CGRectMake(0, CELL_HEIGHT-1.0f , 320.0f, 1.0f)];
    
    //// avatar
    CGRect avatarRect = CGRectMake(AVATAR_X*2, AVATAR_X, AVATAR_HEIGHT, AVATAR_HEIGHT);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);
    
    // name
    UIColor *nameMagentaColor = RGBCOLOR(107, 107, 107);
    [nameMagentaColor set];
    NSString *nameString = [self.data objectForKey:@"nickname"];
    CGRect nameRect = CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_HEIGHT);
    
    [nameString drawInRect:nameRect
                  withFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
    
    // signture
    UIColor *signatureMagentaColor = LIVID_COLOR;
    [signatureMagentaColor set];
    NSString *signatureString = [self.data objectForKey:@"signature"];
    CGRect signatureRect  = CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT);
    [signatureString drawInRect:signatureRect withFont:[UIFont systemFontOfSize:14.0f]];
    
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}




@end
