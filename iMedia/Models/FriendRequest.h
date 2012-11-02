//
//  FriendRequest.h
//  iMedia
//
//  Created by Xiaosi Li on 11/2/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum _FriendRequestState
{
    FriendRequestApproved = 1,
    FriendRequestDeclined     = 2,
    FriendRequestUnprocessed = 3
} FriendRequestStateType;

@interface JSONToDataTransformer : NSValueTransformer {
}
@end

@interface FriendRequest : NSManagedObject

@property (nonatomic, retain) NSString * userJSONData;
@property (nonatomic, retain) NSDate * requestDate;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * requesterEPostalID;

@end
