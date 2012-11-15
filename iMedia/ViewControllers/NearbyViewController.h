//
//  NearbyViewController.h
//  iMedia
//
//  Created by meng qian on 12-11-15.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface NearbyViewController : UIViewController
{
    NSFetchedResultsController *fetchedResultsController;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end
