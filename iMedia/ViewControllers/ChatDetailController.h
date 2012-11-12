//
//  ChatDetailController.h
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSBubbleTableView.h"

@class UIBubbleTableView;
@class Conversation;
@class ACPlaceholderTextView;

@interface ChatDetailController : UIViewController
{
    NSString *titleString;
}

@property (nonatomic, strong) ACPlaceholderTextView *textView;
@property (nonatomic, strong) UIButton  *sendButton;

@property (nonatomic, strong) UIBubbleTableView *bubbleTable;
@property (nonatomic, strong) NSMutableArray *bubbleData;
@property (nonatomic, strong) Conversation *conversation;

@property (nonatomic, strong) WSBubbleTableView *wsBubbleTable;
@property (nonatomic, strong) NSMutableArray *wsBubbleData;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end