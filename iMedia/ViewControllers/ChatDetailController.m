//
//  ChatDetailController.m
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ChatDetailController.h"
#import "UIBubbleTableView.h"
#import "NSBubbleData.h"
#import "User.h"
#import "Me.h"
#import "Message.h"
#import "Conversation.h"
#import "AppDefs.h"
#import "AppDelegate.h"
#import "UIBubbleTableViewDataSource.h"
#import "ACPlaceholderTextView.h"
#import <CocoaPlant/CocoaPlant.h>

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


@interface ChatDetailController () <UITextViewDelegate, UIBubbleTableViewDataSource>
{
    NSMutableArray *_heightForRow;
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
    NSDate *_previousShownSentDate;
}

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
    bubbleTable = [[UIBubbleTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-40)];
    bubbleTable.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    bubbleTable.backgroundColor = RGBCOLOR(222, 224, 227);
    bubbleTable.separatorStyle = UITableViewCellSeparatorStyleNone;
   
    NSSet *messages = conversation.messages;
    bubbleData = [[NSMutableArray alloc] initWithCapacity:[messages count]];
    NSEnumerator *enumerator = [conversation.messages objectEnumerator];
    Message* aMessage;
    while (aMessage = [enumerator nextObject]) {
        [self addMessage:aMessage toBubbleData:bubbleData];
    }
    
    bubbleTable.bubbleDataSource = self;
    bubbleTable.snapInterval = 100;
    bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
    bubbleTable.showAvatars = YES;
    
    
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
    
    [self.view addSubview:bubbleTable];
    [self.view addSubview:messageInputBar];
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
    bubbleData = [[NSMutableArray alloc] initWithCapacity:[messages count]];
    NSEnumerator *enumerator = [conversation.messages objectEnumerator];
    Message* aMessage;
    while (aMessage = [enumerator nextObject]) {
        [self addMessage:aMessage toBubbleData:bubbleData];
    }
    [bubbleTable reloadData];
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshBubbleData];
    
    // setup self.title
    NSEnumerator *enumerator = [conversation.users objectEnumerator];
    User *anUser = [enumerator nextObject];
    self.title = anUser.displayName;
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
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Keyboard Notification

- (void)keyboardWillShow:(NSNotification *)notification {
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
        CGFloat tmp1 = viewHeight - messageInputBar.frame.size.height;
        CGFloat tmp2 = messageInputBar.frame.size.height;
        CGFloat tmp3 = self.view.frame.size.height;
        UIViewSetFrameY(messageInputBar, viewHeight-messageInputBar.frame.size.height);
        self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-viewHeight, 0);
        
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification {
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
        CGFloat tmp1 = viewHeight - messageInputBar.frame.size.height;
        CGFloat tmp2 = messageInputBar.frame.size.height;
        CGFloat tmp3 = self.view.frame.size.height;
        UIViewSetFrameY(messageInputBar, self.view.frame.size.height-messageInputBar.frame.size.height);
 //       self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-messageInputBar.frame.size.height, 0);
        self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsZero; 
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
#pragma mark - UIBubbleTableViewDataSource implementation
////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
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
    [self.textView becomeFirstResponder];
    
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
    
    message.from = [self appDelegate].me;
    message.sentDate = [NSDate date];
    message.text = self.textView.text;
    message.conversation = self.conversation;
    message.type = [NSNumber numberWithInt:MessageTypeChat];
    
    [self.conversation addMessagesObject:message];
    self.conversation.lastMessageSentDate = message.sentDate;
    self.conversation.lastMessageText = message.text;
     
    [self addMessage:message toBubbleData:bubbleData];
    [bubbleTable reloadData];

    self.textView.text = nil;
    [self textViewDidChange:_textView];
    [self.textView resignFirstResponder];
    
    [[XMPPNetworkCenter sharedClient] sendMessage:message];
}

- (void)addMessage:(Message *)msg toBubbleData:(NSMutableArray *)data
{
    NSBubbleType type = BubbleTypeMine;
    if (msg.from.ePostalID != [self appDelegate].me.ePostalID) {
        type = BubbleTypeSomeoneElse;
    }
    if (msg.type == [NSNumber numberWithInt:MessageTypeChat])
    {
        NSBubbleData *itemBubble = [NSBubbleData dataWithText:msg.text date:msg.sentDate type:type];
        itemBubble.avatar = [UIImage imageNamed:@"avatar.png"];
        [bubbleData addObject:itemBubble];
        
    } else if (msg.type == [NSNumber numberWithInt:MessageTypePublish]) {
        [bubbleData addObject:[NSBubbleData dataWithText:msg.text date:msg.sentDate type:BUbbleTypeWebview]];
    }
}

- (void)newMessageReceived:(NSNotification *)notification
{
    [self refreshBubbleData];
}
@end
