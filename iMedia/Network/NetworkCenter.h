//
//  NetworkCenter.h
//  iMedia
//
//  Created by Li Xiaosi on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkCenterDelegate <NSObject>

-(void)didReceiveMessage:(NSString*)jsonText;

@end

@interface NetworkCenter : NSObject

-(BOOL)connectWithUsername:(NSString *)username andPassword:(NSString *)password;
-(BOOL)setupWithHostname:(NSString *)hostname andPort:(int)port;

@end
