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
#import "EGORefreshTableHeaderView.h"


@interface NearbyViewController : UITableViewController<MBProgressHUDDelegate,EGORefreshTableHeaderDelegate>
{
	EGORefreshTableHeaderView *_refreshHeaderView;
    //  Reloading var should really be your tableviews datasource
    //  Putting it here for demo purposes
    BOOL _reloading;
    MBProgressHUD *HUD;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;
@end
