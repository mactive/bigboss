//
//  Identity.m
//  iMedia
//
//  Created by Xiaosi Li on 10/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Identity.h"
#import "ImageRemote.h"


@implementation Identity

@dynamic displayName;
@dynamic ePostalID;
@dynamic guid;
@dynamic avatarURL;
@dynamic thumbnailURL;
@dynamic state;
@dynamic type;
@dynamic lastGPSLocation;
@dynamic lastGPSUpdated;
@dynamic images;


-(NSArray *)getOrderedImages
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    NSArray *result = [self.images sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}

-(NSArray *)getOrderedNonNilImages
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sequence > 0"];
    NSSet *filteredSet =[self.images filteredSetUsingPredicate:predicate];
    NSArray *result = [filteredSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}

@end
