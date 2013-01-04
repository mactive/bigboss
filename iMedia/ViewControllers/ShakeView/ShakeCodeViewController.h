//
//  ShakeCodeViewController.h
//  iMedia
//
//  Created by mac on 12-11-27.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShakeCodeViewController : UIViewController

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property(nonatomic, strong)NSString *codeString;
@end
