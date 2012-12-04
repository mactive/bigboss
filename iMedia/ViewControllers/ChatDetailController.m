//
//  ChatDetailController.m
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ChatDetailController.h"
#import "WSBubbleTableView.h"
#import "WSBubbleData.h"
#import "User.h"
#import "Me.h"
#import "Message.h"
#import "Channel.h"
#import "Conversation.h"
#import "AppDefs.h"
#import "AppDelegate.h"
#import "ACPlaceholderTextView.h"
#import <CocoaPlant/CocoaPlant.h>
#import "UIImageView+AFNetworking.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import "ConversationsController.h"
#import "NSDate-Utilities.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define SentDateFontSize                     13
#define MESSAGE_SENT_DATE_LABEL_HEIGHT       (SentDateFontSize+7)
#define MessageFontSize                      16
#define MESSAGE_TEXT_WIDTH_MAX               180
#define MESSAGE_MARGIN_TOP                   7
#define MESSAGE_MARGIN_BOTTOM                10
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define ContentHeightMax                     80
#define MESSAGE_COUNT_LIMIT                  50
#define MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL 13*60 // 13 minutes
#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG    101
#define MESSAGE_TEXT_LABEL_TAG               102

#define MESSAGE_TEXT_SIZE_WITH_FONT(message, font) \
[message.text sizeWithFont:font constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap]


@interface ChatDetailController () <UITextViewDelegate>
{
    NSMutableArray *_heightForRow;
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
    NSDate *_previousShownSentDate;
}

@property(strong, nonatomic)UITapGestureRecognizer *tapGestureRecognizer;

- (void)addMessage:(Message *)msg toBubbleData:(NSMutableArray *)data;

// receive new message notification
- (void)newMessageReceived:(NSNotification *)notification;
@end

@implementation ChatDetailController

@synthesize textView=_textView;
@synthesize sendButton = _sendButton;
@synthesize bubbleData;
@synthesize bubbleTable;
@synthesize conversation;
@synthesize managedObjectContext;
@synthesize tapGestureRecognizer;

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newMessageReceived:)
                                                     name:NEW_MESSAGE_NOTIFICATION object:nil];
    }    
    return self;
}

- (void)dealloc {
    NotificationsUnobserve();
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bubbleTable = [[WSBubbleTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-40)];
    self.bubbleTable.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.bubbleTable.backgroundColor = RGBCOLOR(222, 224, 227);
    self.bubbleTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
//    bubbleTable.dataSource = self;
    self.bubbleTable.snapInterval = 120;
    self.bubbleTable.showAvatars = YES;

    
    // Create messageInputBar to contain _textView, messageInputBarBackgroundImageView, & _sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    messageInputBar.opaque = YES;
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)]; // 8 x 40
    
    // Create _textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    _textView = [[ACPlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, TEXT_VIEW_WIDTH, TEXT_VIEW_HEIGHT_MIN)];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    _textView.scrollsToTop = NO;
    _textView.font = [UIFont systemFontOfSize:MessageFontSize];
    _textView.placeholder = NSLocalizedString(@" Message", nil);
    [messageInputBar addSubview:_textView];
    _previousTextViewContentHeight = MessageFontSize+20;
    
    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]]; // 32 x 40
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, TEXT_VIEW_WIDTH+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = self.bubbleTable.autoresizingMask;
    [messageInputBar addSubview:messageInputBarBackgroundImageView];
    
    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(messageInputBar.frame.size.width-65, 8, 59, 26);
    _sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin /* multiline input */ | UIViewAutoresizingFlexibleLeftMargin /* landscape */);
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [_sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [messageInputBar addSubview:_sendButton];
    
    [self.view addSubview:self.bubbleTable];
    [self.view addSubview:messageInputBar];
    
    //  单点触控
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTaps:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
}

- (void)handleTaps:(UIGestureRecognizer *)paramSender
{
    NSLog(@"handleTaps");
    [self.textView resignFirstResponder];
}

/////////////////////////////////////////////////////
#pragma mark - sort Bubble data make a section data
/////////////////////////////////////////////////////

- (NSMutableArray *)sortBubbleSection:(NSMutableArray *)unorderData
{
    if (unorderData != nil && [unorderData count] > 0)
    {
        int count = [unorderData count];
        
        NSMutableArray *bubbleSection = [[NSMutableArray alloc] init];
        NSArray *resultData = [unorderData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            WSBubbleData *bubbleData1 = (WSBubbleData *)obj1;
            WSBubbleData *bubbleData2 = (WSBubbleData *)obj2;
            
            return [bubbleData1.date compare:bubbleData2.date];
        }];
        
        NSDate *last = [NSDate dateWithTimeIntervalSince1970:0];
        NSMutableArray *currentSection = nil;
        
        for (int i = 0; i < count; i++)
        {
            WSBubbleData *data = (WSBubbleData *)[resultData objectAtIndex:i];
                    
            if ([data.date timeIntervalSinceDate:last] > self.bubbleTable.snapInterval)
            {

                currentSection = [[NSMutableArray alloc] init];
                [bubbleSection addObject:currentSection];
            }
            
            [currentSection addObject:data];
            last = data.date;
        }
        return bubbleSection;
    }else{
        return nil;
    }
    
}


/*
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
*/

- (void)refreshBubbleData
{
    NSSet *messages = conversation.messages;
    
    self.bubbleData = [[NSMutableArray alloc] initWithCapacity:[messages count]];
    NSEnumerator *enumerator = [conversation.messages objectEnumerator];
    Message* aMessage;
    while (aMessage = [enumerator nextObject]) {
        [self addMessage:aMessage toBubbleData:self.bubbleData];
    }
    
    self.bubbleTable.bubbleSection = [self sortBubbleSection:self.bubbleData];
    [self.bubbleTable reloadData];
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#warning  -  this block may be in the viewdidiload
    
    NSSet *messages = conversation.messages;
    self.bubbleData = [[NSMutableArray alloc] initWithCapacity:[messages count]];
    NSEnumerator *enumerator = [conversation.messages objectEnumerator];
    Message* aMessage;
    while (aMessage = [enumerator nextObject]) {
        [self addMessage:aMessage toBubbleData:self.bubbleData];
    }
    
    self.bubbleTable.bubbleSection = [self sortBubbleSection:self.bubbleData];
    [self.bubbleTable reloadData];
    
#warning  -  this block end

    // setup self.title
    NSEnumerator *userEnumerator = [conversation.attendees objectEnumerator];
    
    User *anUser = [userEnumerator nextObject];
    if (anUser == nil) {
        self.title = conversation.ownerEntity.displayName;
    } else {
        self.title = anUser.displayName;
    }
    
    if (self.conversation.unreadMessagesCount > 0) {
        self.conversation.unreadMessagesCount = 0;
        [[self appDelegate].conversationController contentChanged];
    }
    
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIKeyboardNotificationsObserve();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessageReceived:)
                                                 name:NEW_MESSAGE_NOTIFICATION object:conversation];
    [self.bubbleTable flashScrollIndicators];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    NotificationsUnobserve();
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.conversation.unreadMessagesCount > 0) {
        self.conversation.unreadMessagesCount = 0;
        [[self appDelegate].conversationController contentChanged];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Keyboard Notification

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.bubbleTable addGestureRecognizer:self.tapGestureRecognizer];

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    
    //    NSLog(@"animationDuration: %f", animationDuration); // TODO: Why 0.35 on viewDidLoad?
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        CGFloat viewHeight = [self.view convertRect:frameEnd fromView:nil].origin.y;
        UIView *messageInputBar = _textView.superview;
        UIViewSetFrameY(messageInputBar, viewHeight-messageInputBar.frame.size.height);
        
        if([self.bubbleTable contentOffset].y > 0) {
            UIEdgeInsets insets = self.bubbleTable.contentInset;
            insets.bottom = viewHeight + 20;
            [self.bubbleTable setContentInset:insets];
            [self.bubbleTable setScrollIndicatorInsets:insets];
        }
        
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self.bubbleTable removeGestureRecognizer:self.tapGestureRecognizer];

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    
    //    NSLog(@"animationDuration: %f", animationDuration); // TODO: Why 0.35 on viewDidLoad?
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        CGFloat viewHeight = [self.view convertRect:frameEnd fromView:nil].origin.y;
        UIView *messageInputBar = _textView.superview;
        UIViewSetFrameY(messageInputBar, self.view.frame.size.height - messageInputBar.frame.size.height);
//        self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
        
        if([self.bubbleTable contentOffset].y > 0) {
            UIEdgeInsets insets = self.bubbleTable.contentInset;
            insets.bottom = 0;
            [self.bubbleTable setContentInset:insets];
            [self.bubbleTable setScrollIndicatorInsets:insets];
        }
        
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = 0;
    NSInteger numberOfSections = [self.bubbleTable numberOfSections];
    if (numberOfSections > 0) {
        numberOfRows = [self.bubbleTable tableView:self.bubbleTable numberOfRowsInSection:numberOfSections-1];
    }
    if (numberOfRows) {
        [self.bubbleTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:numberOfSections-1] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITextViewDelegate
////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidChange:(UITextView *)textView {
    // Change height of _tableView & messageInputBar to match textView's content height.
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
    //    NSLog(@"textViewContentHeight: %f", textViewContentHeight);
    
    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }
    
    if (changeInHeight) {
        [UIView animateWithDuration:0.2 animations:^{
           self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.bubbleTable.contentInset.bottom+changeInHeight, 0);
            [self scrollToBottomAnimated:NO];
            UIView *messageInputBar = _textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
        } completion:^(BOOL finished) {
            [_textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
    }
    
    // Enable/disable sendButton if textView.text has/lacks length.
    if ([textView.text length]) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    }
}

- (void)sendMessage
{
    // Autocomplete text before sending. @hack
    [self.textView resignFirstResponder];
    
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
    message.from = [self appDelegate].me;
    message.sentDate = [NSDate date];
    message.text = self.textView.text;
    message.conversation = self.conversation;
    message.type = [NSNumber numberWithInt:MessageTypeChat];
    
    [self.conversation addMessagesObject:message];
    self.conversation.lastMessageSentDate = message.sentDate;
    self.conversation.lastMessageText = message.text;


    self.textView.text = nil;
    [self textViewDidChange:_textView];
    [self.textView resignFirstResponder];
    [[XMPPNetworkCenter sharedClient] sendMessage:message];
    
//    [self refreshBubbleData];
    
    [self addMessage:message toBubbleData:self.bubbleData];
    self.bubbleTable.bubbleSection = [self sortBubbleSection:self.bubbleData];
    [self.bubbleTable reloadData];
    
    [self scrollToBottomAnimated:NO];
    
}

- (void)addMessage:(Message *)msg toBubbleData:(NSMutableArray *)data
{
    WSBubbleType type = BubbleTypeMine; // 默认是自己的
    
    if (msg.from.ePostalID != [self appDelegate].me.ePostalID) {
        type = BubbleTypeSomeoneElse;   // 如果发送过来的 jid 不同就是别人的
    }
    if (msg.type == [NSNumber numberWithInt:MessageTypeChat])
    {
        WSBubbleData *itemBubble = [WSBubbleData dataWithText:msg.text date:msg.sentDate type:type];
        itemBubble.msg = msg;
        itemBubble.avatar = msg.from.thumbnailImage;
        if (msg.from.thumbnailImage == nil) {
            [[AppNetworkAPIClient sharedClient] loadImage:msg.from.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                msg.from.thumbnailImage = image;
                itemBubble.avatar = msg.from.thumbnailImage;
            }];
        }
        [data addObject:itemBubble];
        self.bubbleTable.showAvatars = YES;
    }
    else if (msg.type == [NSNumber numberWithInt:MessageTypeTemplateA]) {
        [data addObject:[WSBubbleData dataWithTemplateA:msg.text date:msg.sentDate type:BubbleTypeTemplateAview]];
        bubbleTable.showAvatars = NO;
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeTemplateB]) {
        [data addObject:[WSBubbleData dataWithTemplateB:msg.text date:msg.sentDate type:BubbleTypeTemplateBview]];
        bubbleTable.showAvatars = NO;
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeNotification]) {
        [data addObject:[WSBubbleData dataWithNotication:msg.text date:msg.sentDate type:BubbleTypeNoticationview]];
        bubbleTable.showAvatars = NO;
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeRate]) {
        WSBubbleData *rateData = [WSBubbleData dataWithTemplateA:msg.text date:msg.sentDate type:BubbleTypeRateview];
        rateData.msg = msg;
        [data addObject:rateData];
        bubbleTable.showAvatars = NO; 

    }

}

- (void)newMessageReceived:(NSNotification *)notification
{
    [self refreshBubbleData];
}

- (void)rateAction:(id)sender
{
    
}
@end
