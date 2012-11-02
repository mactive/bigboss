//
//  FriendRequest.m
//  iMedia
//
//  Created by Xiaosi Li on 11/2/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FriendRequest.h"
#import "NSObject+SBJson.h"


@implementation FriendRequest

@dynamic userJSONData;
@dynamic requestDate;
@dynamic state;
@dynamic requesterEPostalID;

@end

@implementation JSONToDataTransformer


+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSString class];
}


- (id)transformedValue:(id)value {
	NSString *data = [value JSONRepresentation];
	return data;
}


- (id)reverseTransformedValue:(id)value {
	id  obj = [value JSONValue];
	return obj;
}

@end

