//
//  CompanyDetailViewController.h
//  iMedia
//
//  Created by meng qian on 13-1-29.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBCustomBackButtonViewController.h"
@class Company;
@interface CompanyDetailViewController : BBCustomBackButtonViewController

@property(strong, nonatomic) id   jsonData;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
