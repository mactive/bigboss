//
//  ChatDetailController.m
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ChatDetailController.h"
#import <CocoaPlant/CocoaPlant.h>
#import <AssetsLibrary/AssetsLibrary.h>
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
#import "UIImageView+AFNetworking.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import "ConversationsController.h"
#import "NSDate-Utilities.h"
#import "ConvenienceMethods.h"
#import "math.h"
#import "DDLog.h"
#import "UIImage+ProportionalFill.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "AFImageRequestOperation.h"



// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif


// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define SentDateFontSize                     13
#define MESSAGE_SENT_DATE_LABEL_HEIGHT       (SentDateFontSize+7)
#define MessageFontSize                      16
#define MESSAGE_TEXT_WIDTH_MAX               180
#define MESSAGE_MARGIN_TOP                   7
#define MESSAGE_MARGIN_BOTTOM                10
#define BUTTON_VIEW_X                        10
#define BUTTON_VIEW_Y                        5.5
#define BUTTON_VIEW_WIDTH                    35
#define BUTTON_VIEW_HEIGHT                   29
#define TEXT_VIEW_X                          53   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      260 // 249 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define ContentHeightMax                     80
#define MESSAGE_COUNT_LIMIT                  50
#define MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL 13*60 // 13 minutes
#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG    101
#define MESSAGE_TEXT_LABEL_TAG               102
#define TEXT_VIEW_DEFAULT_HEIGHT             36.0f
#define TEXT_VIEW_DEFAULT_MAX_HEIGHT         96.0f
#define MESSAGE_TEXT_SIZE_WITH_FONT(message, font) \
[message.text sizeWithFont:font constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap]


#define kCameraSource       UIImagePickerControllerSourceTypeCamera


@interface ChatDetailController () <UITextViewDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    NSMutableArray *_heightForRow;
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
    NSDate *_previousShownSentDate;
}

@property(strong, nonatomic)UISwipeGestureRecognizer *swipeGestureRecognizer;
@property(strong, nonatomic)UITapGestureRecognizer *tapGestureRecognizer;
@property(strong, nonatomic)UIView *swipeView;
@property(nonatomic, readwrite)CGFloat keyboardBoundHeight;
@property(nonatomic, readwrite)CGFloat textViewContentHeight;
@property(nonatomic, strong)UIActionSheet *photoActionSheet;

- (WSBubbleData *)addMessage:(Message *)msg toBubbleData:(NSMutableArray *)data;

// receive new message notification
- (void)newMessageReceived:(NSNotification *)notification;
@end

@implementation ChatDetailController

@synthesize textView=_textView;
@synthesize photoButton = _photoButton;
@synthesize photoActionSheet;
@synthesize bubbleData;
@synthesize bubbleTable;
@synthesize conversation;
@synthesize managedObjectContext;
@synthesize swipeGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize keyboardBoundHeight;
@synthesize textViewContentHeight;

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
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)];
    
    // Create _textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    _textView = [[ACPlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, TEXT_VIEW_WIDTH, TEXT_VIEW_HEIGHT_MIN)];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    _textView.scrollsToTop = NO;
    _textView.font = [UIFont systemFontOfSize:MessageFontSize];
    _textView.placeholder = T(@"说点什么吧");
    _textView.returnKeyType = UIReturnKeySend;
    _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [messageInputBar addSubview:_textView];
    _previousTextViewContentHeight = MessageFontSize+20;
    
    self.photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.photoButton setFrame:CGRectMake(BUTTON_VIEW_X, BUTTON_VIEW_Y, BUTTON_VIEW_WIDTH, BUTTON_VIEW_HEIGHT)];
    [self.photoButton setBackgroundImage:[UIImage imageNamed:@"barbutton_photo.png"] forState:UIControlStateNormal];
    [self.photoButton addTarget:self action:@selector(photoButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [messageInputBar addSubview:self.photoButton];

    
    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]]; // 32 x 40
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, TEXT_VIEW_WIDTH+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = self.bubbleTable.autoresizingMask;
    [messageInputBar addSubview:messageInputBarBackgroundImageView];
    
    [self.view addSubview:self.bubbleTable];
    [self.view addSubview:messageInputBar];
    
    //  单点触控
    self.swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
    self.swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    self.swipeGestureRecognizer.numberOfTouchesRequired = 1;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    
    self.swipeView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 150)];
    self.swipeView.backgroundColor = [UIColor clearColor];
    
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification{
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    self.keyboardBoundHeight = keyboardBounds.size.height;
    self.swipeView.frame =  CGRectMake(0, 0, 320, 370 - self.keyboardBoundHeight);

//    DDLogVerbose(@"keyboardBounds.size.height %f",keyboardBounds.size.height);
    
}

// textview 如果输入换行 当作发送
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	if ([text isEqualToString:@"\n"]){
        if (StringHasValue(self.textView.text)) {
            [self sendMessage:nil];
            return NO;
        }else{
            [textView resignFirstResponder];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"信息不能为空") andHideAfterDelay:1];
            return YES;
        }

    }else{
        return YES; 
    }
}


- (void)handleTap:(UITapGestureRecognizer *)paramSender
{
    [self.textView resignFirstResponder];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)paramSender
{
    if (paramSender.direction & UISwipeGestureRecognizerDirectionDown) {
        [self.textView resignFirstResponder];
    }
    
}

/////////////////////////////////////////////////////
#pragma mark - sort Bubble data make a section data
/////////////////////////////////////////////////////

- (NSMutableArray *)addLatestData:(WSBubbleData *)data toSortedBubbleSection:(NSMutableArray *)section
{
    if (section == nil) {
        WSBubbleData *headerData = [WSBubbleData dataWithSectionHeader:data.date type:BubbleTypeSectionHeader];
        NSMutableArray *result = [[NSMutableArray alloc] initWithObjects:[[NSMutableArray alloc] initWithObjects:headerData, data, nil], nil];
        return result;
    }
    
    NSMutableArray *lastSection = [section lastObject];
    WSBubbleData* lastData = [lastSection lastObject];
    if ([data.date timeIntervalSinceDate:lastData.date] > self.bubbleTable.snapInterval) {
        NSMutableArray* oneNewSection = [[NSMutableArray alloc] init];
        WSBubbleData *headerData = [WSBubbleData dataWithSectionHeader:data.date type:BubbleTypeSectionHeader];
        [oneNewSection addObject:headerData];
        [section addObject:oneNewSection];
        [oneNewSection addObject:data];
    } else {
        [lastSection addObject:data];
    }
    
    return section;
}
- (NSMutableArray *)sortBubbleSection:(NSMutableArray *)unorderData
{
    if (unorderData != nil && [unorderData count] > 0)
    {
        
        NSArray *resultData = [unorderData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            WSBubbleData *bubbleData1 = (WSBubbleData *)obj1;
            WSBubbleData *bubbleData2 = (WSBubbleData *)obj2;
            
            return [bubbleData1.date compare:bubbleData2.date];
        }];
        
        NSDate *last = [NSDate dateWithTimeIntervalSince1970:0];
        NSMutableArray *currentSection = nil;
        NSMutableArray *bubbleSection = [[NSMutableArray alloc] init];
        for (int i = 0; i < [unorderData count]; i++)
        {
            WSBubbleData *data = (WSBubbleData *)[resultData objectAtIndex:i];
                    
            if ([data.date timeIntervalSinceDate:last] > self.bubbleTable.snapInterval)
            {

                currentSection = [[NSMutableArray alloc] init];
                WSBubbleData *headerData = [WSBubbleData dataWithSectionHeader:data.date type:BubbleTypeSectionHeader];
                [currentSection addObject:headerData];
                
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
    [self scrollToBottomBubble:YES];
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
    
    [self scrollToBottomBubble:YES];
    [self.textView resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIKeyboardNotificationsObserve();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessageReceived:)
                                                 name:NEW_MESSAGE_NOTIFICATION object:conversation];
    [self.bubbleTable flashScrollIndicators];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    NotificationsUnobserve();
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    
    // 让键盘和中文选择消失
    [self.textView resignFirstResponder];
    UIView *messageInputBar = _textView.superview;
    UIViewSetFrameY(messageInputBar, self.view.frame.size.height - messageInputBar.frame.size.height);
    
    self.keyboardBoundHeight = 0;

    [self scrollToBottomBubble:YES];
    
    [self.swipeView removeGestureRecognizer:self.swipeGestureRecognizer];
    [self.swipeView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.swipeView removeFromSuperview];
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
    [self.view addSubview:self.swipeView];
    [self.swipeView addGestureRecognizer:self.swipeGestureRecognizer];
    [self.swipeView addGestureRecognizer:self.tapGestureRecognizer];

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    
    //    DDLogVerbose(@"animationDuration: %f", animationDuration); // TODO: Why 0.35 on viewDidLoad?
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        CGFloat viewHeight = [self.view convertRect:frameEnd fromView:nil].origin.y;
        UIView *messageInputBar = _textView.superview;
        UIViewSetFrameY(messageInputBar, viewHeight-messageInputBar.frame.size.height);
        
        [self scrollToBottomBubble:YES];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self.swipeView removeGestureRecognizer:self.swipeGestureRecognizer];
    [self.swipeView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.swipeView removeFromSuperview];

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    
    //    DDLogVerbose(@"animationDuration: %f", animationDuration); // TODO: Why 0.35 on viewDidLoad?
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        UIView *messageInputBar = _textView.superview;
        UIViewSetFrameY(messageInputBar, self.view.frame.size.height - messageInputBar.frame.size.height);
        
        self.keyboardBoundHeight = 0;
        [self scrollToBottomBubble:YES];
        
    } completion:nil];
}

- (void)scrollToBottomBubble:(BOOL)isScroll {
    
    if([self.bubbleTable contentOffset].y > 0) {
        UIEdgeInsets insets = self.bubbleTable.contentInset;
        insets.bottom = self.keyboardBoundHeight;
        [self.bubbleTable setContentInset:insets];
        [self.bubbleTable setScrollIndicatorInsets:insets];
    }
    
    CGFloat t1 = [self.bubbleTable contentOffset].y;
    CGFloat t2 = [self.bubbleTable contentSize].height;
    CGFloat t3 = self.bubbleTable.contentInset.bottom;
    CGFloat t4 = self.keyboardBoundHeight;
    CGFloat t5 = self.textViewContentHeight;
    CGFloat t6 = self.bubbleTable.frame.size.height;
    BOOL T5BOOL = t5 > TEXT_VIEW_DEFAULT_HEIGHT && t5 <= TEXT_VIEW_DEFAULT_MAX_HEIGHT ? YES : NO ;
    BOOL HALFSCREEN = (t2+t4 > t6) && (t2 < t6) ? YES : NO ;
    CGFloat contentOffsetY = t2- t6 ;
    if (isScroll &&  (contentOffsetY > 0 || HALFSCREEN) ) { // 超过一屏 不够一屏幕超过半屏幕
        // key show
        // t1 只能用来判断 不能用来赋值计算
        if(t1 >= 0) {
            if (self.textViewContentHeight <= TEXT_VIEW_DEFAULT_MAX_HEIGHT) {
                if (self.keyboardBoundHeight == 0) {
                    [self.bubbleTable setContentOffset:CGPointMake(0, contentOffsetY-t3)];
                }else{
                    if (HALFSCREEN) {
                        [self.bubbleTable setContentOffset:CGPointMake(0, contentOffsetY+t4)];
                    }else{
                        [self.bubbleTable setContentOffset:CGPointMake(0, contentOffsetY+t3)];
                    }
                }
            }else{
                CGFloat tmp = TEXT_VIEW_DEFAULT_MAX_HEIGHT - TEXT_VIEW_DEFAULT_HEIGHT;
                if (self.keyboardBoundHeight == 0) {
                    [self.bubbleTable setContentOffset:CGPointMake(0, contentOffsetY-t3+tmp)];
                }else{
                    [self.bubbleTable setContentOffset:CGPointMake(0, contentOffsetY+t3+tmp)];
                }
            }

        }

        // 输入过程中 input 高度变化
        if (T5BOOL) {
            [self.bubbleTable setContentOffset:CGPointMake(0, t2-t6 +t4+(t5 - TEXT_VIEW_DEFAULT_HEIGHT))];
        }
    
    }else{
        if (!HALFSCREEN ) {
            [self.bubbleTable setContentOffset:CGPointMake(0, 0)];
        }
    }
    
    
//    t1 = [self.bubbleTable contentOffset].y;
//    t2 = [self.bubbleTable contentSize].height;
//    t3 = self.bubbleTable.contentInset.bottom;
//    t4 = self.keyboardBoundHeight;
//    t5 = self.textViewContentHeight;
//    t6 = self.bubbleTable.frame.size.height;
//    DDLogVerbose(@"=================================");
//    DDLogVerbose(@"offsetY %li %li %li %li %li %li", lrintf(t1),lrintf(t2),lrintf(t3),lrintf(t4),lrintf(t5),lrintf(t6) );
    
}

/* replace with scrollToBottomBubble
- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = 0;
    NSInteger numberOfSections = [self.bubbleTable numberOfSectionsInTableView:self.bubbleTable];
    if (numberOfSections > 0) {
        numberOfRows = [self.bubbleTable tableView:self.bubbleTable numberOfRowsInSection:numberOfSections-1];
    }
    if (numberOfRows) {
        NSIndexPath *scrollIndex = [NSIndexPath indexPathForRow:numberOfRows-1 inSection:numberOfSections -1];
        [self.bubbleTable scrollToRowAtIndexPath:scrollIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}
*/

////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITextViewDelegate
////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidChange:(UITextView *)textView {
    // Change height of _tableView & messageInputBar to match textView's content height.
    self.textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
//    DDLogVerbose(@"textViewContentHeight: %f", self.textViewContentHeight);
    
    if (self.textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }
    
    if (changeInHeight) {
        [UIView animateWithDuration:0.2 animations:^{
            
            self.bubbleTable.contentInset = self.bubbleTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.bubbleTable.contentInset.bottom+changeInHeight, 0);

            [self scrollToBottomBubble:YES];

            UIView *messageInputBar = _textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
        } completion:^(BOOL finished) {
            [_textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(self.textViewContentHeight, kChatBarHeight4+2);
    }
    
}

- (void)sendMessage:(NSString *)bodyText
{
    // Autocomplete text before sending. @hack
//    [self.textView resignFirstResponder];
    
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
    message.from = [self appDelegate].me;
    message.sentDate = [NSDate date];
    message.text = self.textView.text;
    message.conversation = self.conversation;
    message.type = [NSNumber numberWithInt:MessageTypeChat];
    
    if (StringHasValue(bodyText)) {
        message.text = bodyText;
        message.bodyType = [NSNumber numberWithInt:MessageBodyTypeImage];
    }else{
        message.text = self.textView.text;
        message.bodyType = [NSNumber numberWithInt:MessageBodyTypeText];
    }
    
    [self.conversation addMessagesObject:message];
    self.conversation.lastMessageSentDate = message.sentDate;
    self.conversation.lastMessageText = message.text;
    
    WSBubbleData* wsData = [self addMessage:message toBubbleData:self.bubbleData];
    self.bubbleTable.bubbleSection = [self addLatestData:wsData toSortedBubbleSection:self.bubbleTable.bubbleSection];
    
    self.textView.text = nil;
    [self textViewDidChange:_textView];

    // check whether the user is a friend. If not then hint to add a friend first
    if ((self.conversation.type == ConversationTypeSingleUserChat) && (![[XMPPNetworkCenter sharedClient] isBuddyWithJIDString:self.conversation.ownerEntity.ePostalID] && (self.conversation.ownerEntity.state != IdentityStatePendingAddFriend && self.conversation.ownerEntity.state != IdentityStateActive))) {
        // this user is not a buddy on our roster, and is not on pending add friend or active
        // we will display a warning message to ask user to add a friend first
        
        Message *msg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
        msg.from = self.conversation.ownerEntity;
        msg.sentDate = [NSDate date];
        msg.text = [NSString stringWithFormat:@"%@开启了好友认证，你还不是TA好友，请点击发送好友验证请求，对方验证通过后，才能对话", self.conversation.ownerEntity.displayName];
        msg.conversation = self.conversation;
        msg.type = [NSNumber numberWithInt:MessageTypeNotification];
        
        [self.conversation addMessagesObject:msg];
        self.conversation.lastMessageSentDate = msg.sentDate;
        self.conversation.lastMessageText = msg.text;
        
        WSBubbleData* wsData2 = [self addMessage:msg toBubbleData:self.bubbleData];
        self.bubbleTable.bubbleSection = [self addLatestData:wsData2 toSortedBubbleSection:self.bubbleTable.bubbleSection];
    } else {
        [[XMPPNetworkCenter sharedClient] sendMessage:message];
    }
    [self.bubbleTable reloadData];
    [self scrollToBottomBubble:YES];
    
}

- (WSBubbleData *)addMessage:(Message *)msg toBubbleData:(NSMutableArray *)data
{
    WSBubbleType type = BubbleTypeMine; // 默认是自己的
    
    if (msg.from.ePostalID != [self appDelegate].me.ePostalID) {
        type = BubbleTypeSomeoneElse;   // 如果发送过来的 jid 不同就是别人的
    }
    WSBubbleData *wsData = nil;
    if (msg.type == [NSNumber numberWithInt:MessageTypeChat])
    {
        wsData = [WSBubbleData dataWithText:msg.text date:msg.sentDate type:type];
        wsData.msg = msg;
        wsData.avatar = msg.from.thumbnailImage;
        if (msg.from.thumbnailImage == nil) {
            [[AppNetworkAPIClient sharedClient] loadImage:msg.from.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                msg.from.thumbnailImage = image;
                wsData.avatar = msg.from.thumbnailImage;
            }];
        }
    }
    else if (msg.type == [NSNumber numberWithInt:MessageTypeTemplateA]) {
        wsData = [WSBubbleData dataWithTemplateA:msg.text date:msg.sentDate type:BubbleTypeTemplateAview];
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeTemplateB]) {
        wsData = [WSBubbleData dataWithTemplateB:msg.text date:msg.sentDate type:BubbleTypeTemplateBview];
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeNotification]) {
        wsData = [WSBubbleData dataWithNotication:msg.text date:msg.sentDate type:BubbleTypeNoticationview];
        wsData.msg = msg;
    }else if (msg.type == [NSNumber numberWithInt:MessageTypeRate]) {
        wsData = [WSBubbleData dataWithTemplateA:msg.text date:msg.sentDate type:BubbleTypeRateview];
        wsData.msg = msg;
    }
    
    if (msg.type == [NSNumber numberWithInt:MessageTypeChat]) {
        self.bubbleTable.showAvatars = YES;
    } else {
        self.bubbleTable.showAvatars = NO;
    }
    [data addObject:wsData];
    return wsData;
}

- (void)newMessageReceived:(NSNotification *)notification
{
    [self refreshBubbleData];
}

//////////////////////////////////////////////////////////////////////
// photo action sheet
//////////////////////////////////////////////////////////////////////

- (void)photoButtonAction
{    
    self.photoActionSheet = [[UIActionSheet alloc]
                             initWithTitle:T(@"选择图片或者相机")
                             delegate:self
                             cancelButtonTitle:T(@"取消")
                             destructiveButtonTitle:nil
                             otherButtonTitles:T(@"本地相册"), T(@"照相"),nil];
    self.photoActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.photoActionSheet showFromRect:self.view.bounds inView:self.view animated:YES];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.photoActionSheet) {
        if (buttonIndex == 0) {
            [self takePhotoFromLibaray];
        }else if (buttonIndex == 1) {
            [self takePhotoFromCamera];
        }
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegateMethods
//////////////////////////////////////////////////////////////////////////////////////////


- (void)takePhotoFromLibaray
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.delegate = self;
	picker.allowsEditing = NO;
    [self presentModalViewController:picker animated:YES];
}

- (void)takePhotoFromCamera
{
    if (![UIImagePickerController isSourceTypeAvailable:kCameraSource]) {
        UIAlertView *cameraAlert = [[UIAlertView alloc] initWithTitle:T(@"cameraAlert") message:T(@"Camera is not available.") delegate:self cancelButtonTitle:T(@"Cancel") otherButtonTitles:nil, nil];
        [cameraAlert show];
		return;
	}
    
    //    self.tableView.allowsSelection = NO;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = NO;
#warning picker editing mode crop size
    
    [self presentModalViewController:picker animated:YES];
}

// UIImagePickerControllerSourceTypeCamera and UIImagePickerControllerSourceTypePhotoLibrary

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{

	UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *screenImage = [originalImage imageByScalingToSize:CGSizeMake(320, 480)];
    NSData *imageData = UIImageJPEGRepresentation(screenImage, JPEG_QUALITY);
    DDLogVerbose(@"Imagedata size %i", [imageData length]);
    UIImage *image = [UIImage imageWithData:imageData];
    UIImage *thumbnail = [image imageCroppedToFitSize:CGSizeMake(MESSAGE_THUMBNAIL_WIDTH, MESSAGE_THUMBNAIL_HEIGHT)];

    
    // HUD show
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"上传中");
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Save Video to Photo Album
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:imageData
                                         metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error){}];
    }


    
//    上传到upai
    
    [[AppNetworkAPIClient sharedClient] storeMessageImage:image thumbnail:thumbnail withBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        [picker dismissModalViewControllerAnimated:YES];

        if ((responseObject != nil) && error == nil) {
            
            DDLogVerbose(@"storeMessageImage %@", responseObject);
            NSDictionary *responseDict = [[NSDictionary alloc]initWithDictionary:responseObject];
            [[self appDelegate] saveContextInDefaultLoop];
            [self sendMessage:[responseDict objectForKey:@"url"]];

            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传成功") andHideAfterDelay:2];
        } else {
            DDLogVerbose (@"NSError received during store avatar: %@", error);
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传失败") andHideAfterDelay:2];
        }

    }];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    /* keep the order first dismiss picker and pop controller */
    [picker dismissModalViewControllerAnimated:YES];
    //    [self.controller.navigationController popViewControllerAnimated:NO];
}





@end
