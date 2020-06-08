//
//  O2SPushDevice.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushDevice.h"
#import <UIKit/UIKit.h>

@implementation O2SPushDevice

+ (NSInteger)versionCompare:(NSString *)other
{
    if (![other isKindOfClass:[NSString class]])
    {
        //非法版本号都视为比当前版本要低
        return NSOrderedDescending;
    }
    
    NSArray *oneComponents =
    [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"a"];
    NSArray *twoComponents = [other componentsSeparatedByString:@"a"];
    
    NSArray *oneVerComponents = nil;
    NSArray *twoVerComponents = nil;
    
    if (oneComponents.count > 0) {
        oneVerComponents = [oneComponents[0] componentsSeparatedByString:@"."];
    }
    
    if (twoComponents.count > 0) {
        twoVerComponents = [twoComponents[0] componentsSeparatedByString:@"."];
    }
    
    __block NSComparisonResult mainDiff = NSOrderedSame;
    [oneVerComponents
     enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx,
                                  BOOL *_Nonnull stop) {
         
         NSInteger oneVer = [obj integerValue];
         if (twoVerComponents.count > idx) {
             NSInteger twoVer = [twoVerComponents[idx] integerValue];
             if (oneVer > twoVer) {
                 mainDiff = NSOrderedDescending;
                 *stop = YES;
             } else if (oneVer < twoVer) {
                 mainDiff = NSOrderedAscending;
                 *stop = YES;
             }
             
         } else {
             mainDiff = NSOrderedDescending;
             *stop = YES;
         }
         
     }];
    
    if (mainDiff != NSOrderedSame) {
        return mainDiff;
    }
    
    if (oneVerComponents.count < twoVerComponents.count) {
        return NSOrderedAscending;
    }
    
    if ([oneComponents count] < [twoComponents count]) {
        return NSOrderedDescending;
        
    } else if ([oneComponents count] > [twoComponents count]) {
        return NSOrderedAscending;
        
    } else if ([oneComponents count] == 1) {
        return NSOrderedSame;
    }

    NSNumber *oneAlpha =
    [NSNumber numberWithInt:[[oneComponents objectAtIndex:1] intValue]];
    NSNumber *twoAlpha =
    [NSNumber numberWithInt:[[twoComponents objectAtIndex:1] intValue]];
    
    return [oneAlpha compare:twoAlpha];
}

+ (NSString *)hexStringByData:(NSData *)data
{
    if (![data isKindOfClass:[NSData class]])
    {
        return nil;
    }
    
    NSMutableString *hexStr = [NSMutableString string];
    const char *buf = [data bytes];
    for (int i = 0; i < [data length]; i++)
    {
        [hexStr appendFormat:@"%02X", buf[i] & 0xff];
    }
    return hexStr;
}

@end
