//
//  EditViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-31.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassValueDelegate.h"

@interface EditViewController : UIViewController<UITextViewDelegate,UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    
}

@property(nonatomic,assign) id<PassValueDelegate> delegate;

@property(strong, nonatomic) NSString * nameText;
@property(strong, nonatomic) NSString * valueText;
@property(assign, nonatomic) NSUInteger valueIndex;

@end
