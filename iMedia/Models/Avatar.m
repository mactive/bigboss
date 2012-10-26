//
//  Image.m
//  iMedia
//
//  Created by Xiaosi Li on 10/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Avatar.h"
#import "Me.h"


@implementation Avatar

@dynamic image;
@dynamic thumbnail;
@dynamic title;
@dynamic sequence;
@dynamic me;

@end

@implementation ImageToDataTransformer


+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSData class];
}


- (id)transformedValue:(id)value {
	NSData *data = UIImagePNGRepresentation(value);
	return data;
}


- (id)reverseTransformedValue:(id)value {
	UIImage *uiImage = [[UIImage alloc] initWithData:value];
	return uiImage;
}

@end
