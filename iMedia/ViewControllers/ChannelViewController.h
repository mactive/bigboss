//
//  ChannelViewController.h
//  iMedia
//
//  Created by Xiaosi Li on 10/14/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Channel;
@interface ChannelViewController : UIViewController
{
}

@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UILabel  *nameLabel;

@property (strong, nonatomic) Channel *channel;
@property (strong, nonatomic) id   jsonData;

@end
