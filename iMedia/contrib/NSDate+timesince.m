//
//  NSDate+timesince.m
//  youpinapp
//
//  Created by Zhicheng Wei on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// code is borrow from 
// http://objectivesnippets.com/snippet/timesince-category-for-nsdate/


//#define keys [NSArray arrayWithObjects:@"year", @"month", @"week", @"day", @"hour", @"min", @"sec", nil]
//#define values [NSArray arrayWithObjects:[NSNumber numberWithInt:31556926],[NSNumber numberWithInt:2629744],[NSNumber numberWithInt:604800],[NSNumber numberWithInt:86400],[NSNumber numberWithInt:3600],[NSNumber numberWithInt:60],[NSNumber numberWithInt:1],nil]
#define kDepth 1

#import "NSDate+timesince.h"


@implementation NSDate (timesince)

-(NSString *)timesince 
{
    return [self timesinceWithHuman];
//	return [self timesinceWithDepth:kDepth];
}
#define A_DAY 86400
#define A_WEEK 604800
#define SIX_DAYS 518400

-(NSString *)timesinceWithHuman
{
    NSString *result = [[NSString alloc]init];
    int delta = -(int)[self timeIntervalSinceNow];
    BOOL isToday;
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    if([today day] == [otherDay day] &&
       [today month] == [otherDay month] &&
       [today year] == [otherDay year] &&
       [today era] == [otherDay era]) {
        //do stuff
        isToday = YES;
    }else{
        isToday = NO;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    
    if (delta <= A_DAY) {
        //22:10
        if (isToday) {
            [dateFormatter setDateFormat:@"HH:mm"];
            result = [dateFormatter stringFromDate:self];
        }else{
            result = T(@"昨天");
        }
		
    }else if( delta > A_DAY &&  delta <= A_DAY *2 ){
        //昨天
        result = T(@"昨天");
    }else if( delta > A_DAY *2 && delta <= SIX_DAYS){
        //星期X
        NSArray *weekdayAry = [NSArray arrayWithObjects:T(@"星期天"),T(@"星期一"),T(@"星期二"),T(@"星期三"),T(@"星期四"),T(@"星期五"),T(@"星期六"),nil];
        [dateFormatter setDateFormat:NSLocalizedString(@"eee", nil)];
        // 此处更改显示的大写字母的星期几
        [dateFormatter setShortWeekdaySymbols:weekdayAry];
        result = [dateFormatter stringFromDate:self];
    }else if( delta > SIX_DAYS ){
        // mm:dd
		[dateFormatter setDateFormat:@"MM-dd"];
        result = [dateFormatter stringFromDate:self];
    }
    
    return result;
}

/*
-(NSString *)timesinceWithDepth:(int)depth 
{
	NSArray *timeUnits = [NSArray arrayWithObjects:
						  [NSArray arrayWithObjects:T(@"year"), 
						   [NSNumber numberWithInt:31556926], nil],
						  [NSArray arrayWithObjects:T(@"month"), 
						   [NSNumber numberWithInt:2629744], nil],
						  [NSArray arrayWithObjects:T(@"week"), 
						   [NSNumber numberWithInt:604800], nil],
						  [NSArray arrayWithObjects:T(@"day"), 
						   [NSNumber numberWithInt:86400], nil],
						  [NSArray arrayWithObjects:T(@"hour"), 
						   [NSNumber numberWithInt:3600], nil],
						  [NSArray arrayWithObjects:T(@"min"), 
						   [NSNumber numberWithInt:60], nil],
						  [NSArray arrayWithObjects:T(@"sec"), 
						   [NSNumber numberWithInt:1], nil],
						  nil];
	NSString *delimiter = T(@", ");
	NSString *combination = T(@"%@%i %@");
	NSString *plural_combination = T(@"%@%i %@s");
	NSString *justNow = T(@"just now");

	int delta = -(int)[self timeIntervalSinceNow];
	
	NSString *s = [NSString string];
	
	for(NSArray *timeUnit in timeUnits) {
		NSString *key = [timeUnit objectAtIndex:0];
		int unit = [[timeUnit objectAtIndex:1] intValue];
		int v = (int)(delta/unit);
		
		delta = delta % unit;
		
		if ( (v == 0) || (depth == 0) ) {
			// do nothing
		} else if (v==1) {
			s = [s length] ? [NSString stringWithFormat:@"%@%@", s, delimiter] : s;
			s = [NSString stringWithFormat:combination, s, v, key];
			depth--;
		} else {
			s = [s length] ? [NSString stringWithFormat:@"%@%@", s, delimiter] : s;
			s = [NSString stringWithFormat:plural_combination, s, v, key]; 
			depth--;
		}
        

	}
	
	if ([s length] == 0) {
		s = justNow;
	}else {
        s = [NSString stringWithFormat:@"%@ %@", s, T(@"ago")];
    }
	
	return s;
}
*/
@end