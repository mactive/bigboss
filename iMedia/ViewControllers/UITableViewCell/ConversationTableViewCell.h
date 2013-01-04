//
//  ConversationTableViewCell.h
//  jiemo
//
//  Created by meng qian on 12-12-5.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Conversation.h"

@interface ConversationTableViewCell : UITableViewCell
@property(nonatomic, strong)Conversation *data;

- (void)setNewTimeShow:(BOOL)timeShowBool;
@end
