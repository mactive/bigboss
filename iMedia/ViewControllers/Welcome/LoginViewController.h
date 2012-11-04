//
//  LoginViewController.h
//  iMedia
//
//  Created by meng qian on 12-11-1.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface LoginViewController : UIViewController<MBProgressHUDDelegate,UITextFieldDelegate>
{
    MBProgressHUD *HUD;
}




@end
