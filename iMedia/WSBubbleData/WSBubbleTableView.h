//
//  WSBubbleTableView.h
//  iMedia
//
//  Created by mac on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSBubbleTableView : UITableView<UITableViewDelegate, UITableViewDataSource>


@property (nonatomic) NSTimeInterval snapInterval;
@property (nonatomic) BOOL showAvatars;
@property (nonatomic, strong) NSMutableArray *bubbleSection;

@end
