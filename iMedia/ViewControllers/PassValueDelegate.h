//
//  PassValueDelegate.h
//  iMedia
//
//  Created by qian meng on 12-10-31.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PassValueDelegate <NSObject>

-(void)passValue:(NSString *)value andIndex:(NSUInteger )index;

@end
