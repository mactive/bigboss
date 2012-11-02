//
//  DataTransformer.h
//  iMedia
//
//  Created by Xiaosi Li on 11/2/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageToDataTransformer : NSValueTransformer {
}

+ (BOOL)allowsReverseTransformation;

+ (Class)transformedValueClass;


- (id)transformedValue:(id)value;


- (id)reverseTransformedValue:(id)value;
@end
