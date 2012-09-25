//
//  ChatDetailController.h
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>


@class UIBubbleTableView;
@class Conversation;
@class ACPlaceholderTextView;

@interface ChatDetailController : UIViewController

@property (nonatomic, strong) ACPlaceholderTextView *textView;
@property (nonatomic, strong) UIButton  *sendButton;

@property (nonatomic, strong) UIBubbleTableView *bubbleTable;
@property (nonatomic, strong) NSMutableArray *bubbleData;
@property (nonatomic, strong) Conversation *conversation;

@end