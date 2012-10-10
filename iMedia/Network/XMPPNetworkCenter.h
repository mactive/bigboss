//
//  XMPPNetworkCenter.h
//  iMedia
//
//  Created by Xiaosi Li on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

@protocol XMPPNetworkCenterDelegate <NSObject>

-(void)didReceiveMessage:(NSString*)jsonText;

@end

#define MESSAGE_TYPE_DICT_KEY       type
#define MESSAGE_TO_DICT_KEY         to
#define MESSAGE_BODY_DICT_KEY       body

@interface XMPPNetworkCenter : NSObject

-(BOOL)connectWithUsername:(NSString *)username andPassword:(NSString *)password;
-(BOOL)setupWithHostname:(NSString *)hostname andPort:(int)port;

-(BOOL)disconnet;

-(BOOL)sendMessage:(NSDictionary*)msgDict;

@end
