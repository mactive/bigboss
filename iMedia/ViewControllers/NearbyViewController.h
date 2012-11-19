//
//  NearbyViewController.h
//  iMedia
//
//  Created by meng qian on 12-11-15.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "NearbyTableViewCell.h"
#import "PullToRefreshView.h"


@interface NearbyViewController : UITableViewController<MBProgressHUDDelegate,PullToRefreshViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
	PullToRefreshView *pull;
    //  Reloading var should really be your tableviews datasource
    //  Putting it here for demo purposes
    MBProgressHUD *HUD;
}

@end
