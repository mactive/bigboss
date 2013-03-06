//
//  WSBubbleTextTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleImageTableViewCell.h"
#import "WSBubbleData.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "Me.h"
#import "AppDelegate.h"
#import "ImageViewController.h"

@interface WSBubbleImageTableViewCell ()

@property (nonatomic, strong) UIImage *bubbleImage;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) UILabel *bubbleLabel;
@property (nonatomic, strong) WSBubbleData *rowData;
@property (nonatomic, strong) UIImageView *messageImage;
@property (nonatomic, strong) UIButton *button1;


- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleImageTableViewCell

@synthesize data = _data;
@synthesize bubbleImage;
@synthesize avatarImage;
@synthesize bubbleLabel;
@synthesize rowData;
@synthesize button1;
@synthesize messageImage = _messageImage;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.avatarImage = nil;
        self.bubbleImage = nil;
        self.rowData = [[WSBubbleData alloc]init];
        self.messageImage = [[UIImageView alloc]initWithFrame:CGRectMake(5, 5, TEMPLATE_IMAGE_WIDTH, TEMPLATE_IMAGE_HEIGHT)];
        [self.contentView addSubview:self.messageImage];
        
        //button1
        self.button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button1.frame = self.messageImage.bounds;
        [self.button1 setTitle:@"" forState:UIControlStateNormal];
        self.button1.alpha = 1;
        self.button1.tag = 0;
        
        [self.contentView addSubview:self.button1];

    }
    return self;
}

- (void)setData:(WSBubbleData *)data
{
    [super setData:data];
}

- (void)setupInternalData:(WSBubbleData *)cellData
{
    [super setupInternalData:cellData];

    // set rowdata and redraw
    self.rowData = cellData;
    [self setNeedsDisplay];
    
    // message images
    WSBubbleType type = self.rowData.type;
    CGFloat width = self.rowData.view.frame.size.width;
    CGFloat height = self.rowData.view.frame.size.height;
    CGFloat sizeWidth = self.frame.size.width;
    CGFloat x = (type == BubbleTypeSomeoneElse) ? 56 : sizeWidth - width - 56 - self.rowData.insets.left - self.rowData.insets.right;

    CGRect bubbleRect =  CGRectMake(x + self.rowData.insets.left, floorf(self.rowData.insets.top/3*2), width, height);

    self.messageImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.messageImage setFrame:bubbleRect];
    // 缓存 thumbnail
    NSString *thumbnailString = [cellData.msg.text stringByReplacingOccurrencesOfString:@"jpg?" withString:@"jpg!tm?"];
    [self.messageImage setImageWithURL:[NSURL URLWithString:thumbnailString] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    [self.button1 setFrame:bubbleRect];
    [self.button1 addTarget:self action:@selector(linkAction:) forControlEvents:UIControlEventTouchUpInside];

}

#warning addtarget chatDetailController
- (void)linkAction:(UIButton *)sender
{
    NSString* imageString = self.rowData.msg.text;
    
    if (StringHasValue(imageString)) {
        ImageViewController *controller = [[ImageViewController alloc]initWithNibName:nil bundle:nil];
        controller.urlString = imageString;
        
        [[self appDelegate].conversationController.chatDetailController.navigationController setHidesBottomBarWhenPushed:YES];
        [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
    }
    
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)drawRect:(CGRect)rect
{
    // count size and x y
    WSBubbleType type = self.rowData.type;
    
    CGFloat width = self.rowData.view.frame.size.width;
    CGFloat height = self.rowData.view.frame.size.height;
    CGFloat x = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - width - self.rowData.insets.left - self.rowData.insets.right-3;
    CGFloat y = self.rowData.insets.top / 4 ;
    
    if (type == BubbleTypeSomeoneElse) x += 54;
    if (type == BubbleTypeMine) x -= 54;
    
    // bubbleimage bg
    if (type == BubbleTypeSomeoneElse)
    {
        self.bubbleImage = [[UIImage imageNamed:@"bubbleSomeone.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(14, 8, 4, 4) ];
    }else if(type == BubbleTypeMine) {
        self.bubbleImage = [[UIImage imageNamed:@"bubbleMine.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(14, 4, 4, 8) ];
    }
    
    [self.bubbleImage drawInRect:CGRectMake(x, y, width + self.rowData.insets.left + self.rowData.insets.right, height + self.rowData.insets.top/2 + self.rowData.insets.bottom/2)];
    
    // avatar XY
    CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 4 : self.frame.size.width - 54;
    CGFloat avatarY = 0 ;
    CGRect avatarRect = CGRectMake(avatarX, avatarY, 50, 50);

    // avatar border //
    
    // get the contect
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);    
    //now draw the rounded rectangle
    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    

    //since I need room in my rect for the shadow, make the rounded rectangle a little smaller than frame
    CGFloat radius = 5.0;
    // the rest is pretty much copied from Apples example
    CGFloat minx = CGRectGetMinX(avatarRect), midx = CGRectGetMidX(avatarRect), maxx = CGRectGetMaxX(avatarRect);
    CGFloat miny = CGRectGetMinY(avatarRect), midy = CGRectGetMidY(avatarRect), maxy = CGRectGetMaxY(avatarRect);
    
    // Start at 1
    CGContextMoveToPoint(context, minx, midy);
    // Add an arc through 2 to 3
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    // Add an arc through 4 to 5
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    // Add an arc through 6 to 7
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    // Add an arc through 8 to 9
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    // Close the path
    CGContextClosePath(context);
    // Fill & stroke the path
    CGContextDrawPath(context, kCGPathFillStroke);
//    CGContextRestoreGState(context);
    
    // avatar
    self.avatarImage = self.rowData.avatar ? self.rowData.avatar : [UIImage imageNamed:@"placeholder_user.png"];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);

    
    // bubblestring
    NSString *bubbleString = self.rowData.content;
    UIColor *bubbleMagentaColor = RGBCOLOR(20, 20, 20);
    [bubbleMagentaColor set];
    UIFont *bubbleFont = [UIFont systemFontOfSize:14.0f];
    CGRect bubbleRect =  CGRectMake(x + self.rowData.insets.left, floorf(self.rowData.insets.top/3*2), width, height);
//    [bubbleString drawInRect:bubbleRect withFont:bubbleFont];
}

@end
