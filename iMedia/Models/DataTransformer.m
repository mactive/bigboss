//
//  DataTransformer.m
//  iMedia
//
//  Created by Xiaosi Li on 11/2/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "DataTransformer.h"

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
