//
//  O2SPushContext+Other.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/30.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushContext+Other.h"
#import "O2SPushDevice.h"

@implementation O2SPushContext (Other)

- (void)openSettingsForNotification:(void(^)(BOOL success))handler
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
        {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success)
            {
                if (handler)
                {
                    handler(success);
                }
            }];
        }
        else
        {
            [[UIApplication sharedApplication] openURL:url];
            if (handler)
            {
                handler(YES);
            }
        }
        
    }
    else
    {
        if (handler)
        {
            handler(false);
        }
    }
}

- (void)setBadge:(NSInteger)badge
{
    if (badge > 0)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
    }
    else
    {
        if ([UIApplication sharedApplication].applicationIconBadgeNumber <= 0)
        {
            return;
        }
        
        if ([O2SPushDevice versionCompare:@"11.0"] >= 0)
        {
            [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
        }
        else if([O2SPushDevice versionCompare:@"10.0"] >= 0 && [O2SPushDevice versionCompare:@"11.0"] < 0)
        {
            // iOS10~iOS11(不包含),无法做到清角标并保留通知栏需求
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        }
        else
        {
            UILocalNotification *localNotification = [UILocalNotification new];
            localNotification.applicationIconBadgeNumber = -1;
            localNotification.userInfo = @{O2SPushCommandClearBadge: @(YES)};
            [UIApplication.sharedApplication presentLocalNotificationNow:localNotification];
        }
    }
}

@end
