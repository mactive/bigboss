//
//  Image.h
//  iMedia
//
//  Created by Xiaosi Li on 10/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ImageToDataTransformer : NSValueTransformer {
}
@end

@class Me;

@interface Avatar : NSManagedObject

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) UIImage * thumbnail;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * sequence;
@property (nonatomic, retain) Me *me;

@end
