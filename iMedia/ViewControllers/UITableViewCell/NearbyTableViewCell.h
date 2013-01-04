//
//  NearbyTableViewCell.h
//  iMedia
//
//  Created by meng qian on 12-11-19.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassValueDelegate.h"
@interface NearbyTableViewCell : UITableViewCell

@property(nonatomic,weak) id<PassValueDelegate> delegate;
- (void)setNewData:(NSDictionary *)data;

@end
