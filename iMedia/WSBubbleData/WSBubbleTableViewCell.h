//
//  WSBubbleTableViewCell.h
//  iMedia
//
//  Created by meng qian on 12-11-13.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSBubbleData.h"

@interface WSBubbleTableViewCell : UITableViewCell

@property (nonatomic, strong) WSBubbleData *data;
@property (nonatomic) BOOL showAvatar;

@end
