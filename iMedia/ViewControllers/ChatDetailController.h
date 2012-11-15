//
//  ChatDetailController.h
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSBubbleTableView.h"

@class Conversation;
@class ACPlaceholderTextView;

@interface ChatDetailController : UIViewController
{
    NSString *titleString;
}

@property (nonatomic, strong) ACPlaceholderTextView *textView;
@property (nonatomic, strong) UIButton  *sendButton;
@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


@property (nonatomic, strong) WSBubbleTableView *bubbleTable;
@property (nonatomic, strong) NSMutableArray *bubbleData;



@end