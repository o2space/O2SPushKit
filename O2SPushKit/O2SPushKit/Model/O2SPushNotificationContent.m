//
//  O2SPushNotificationContent.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationContent.h"
#import "O2SPushNotificationContent+Private.h"
#import "O2SPushDevice.h"

@interface O2SPushNotificationContent()

@property (nonatomic, assign) BOOL contentAvailable;
@property (nonatomic, assign) BOOL mutableContent;

@end

@implementation O2SPushNotificationContent

+ (instancetype)apnsNotificationWithDict:(NSDictionary *)dict
{
    return [[self alloc] initApnsNotificationWithDict:dict];
}

- (instancetype)initApnsNotificationWithDict:(NSDictionary *)dict
{
    if (self == [super init])
    {
        self.userInfo = dict;
        NSDictionary *apsDic = dict[@"aps"];
        if ([apsDic isKindOfClass:[NSDictionary class]])
        {
            id value = [apsDic objectForKey:@"badge"];
            if (value)
            {
                self.badge = @([value integerValue]);
            }
            
            value = [apsDic objectForKey:@"sound"];
            if ([value isKindOfClass:[NSString class]])
            {
                self.sound = value;
            }
            
            value = [apsDic objectForKey:@"content-available"];
            if (value)
            {
                self.contentAvailable = [value boolValue];
            }
            
            value = [apsDic objectForKey:@"category"];
            if ([value isKindOfClass:[NSString class]])
            {
                self.category = value;
            }
            
            id alertDic = [apsDic objectForKey:@"alert"];
            if ([alertDic isKindOfClass:[NSDictionary class]])
            {
                value = [alertDic objectForKey:@"body"];
                if ([value isKindOfClass:[NSString class]])
                {
                    self.body = value;
                }
                
                value = [alertDic objectForKey:@"title"];
                if ([value isKindOfClass:[NSString class]])
                {
                    self.title = value;
                }
                
                value = [alertDic objectForKey:@"subtitle"];
                if ([value isKindOfClass:[NSString class]])
                {
                    self.subTitle = value;
                }
                
                value = [alertDic objectForKey:@"action"];
                if ([value isKindOfClass:[NSString class]])
                {
                    self.alertAction = value;
                }
                
            }
            else if ([alertDic isKindOfClass:[NSString class]])
            {
                self.body = alertDic;
            }
            
            if (self.category == nil && self.sound == nil && self.badge == nil && self.contentAvailable)
            {
                self.silentPush = YES;
            }
        }
        
        
    }
    return self;
}

- (NSDictionary *)convertDictionary
{
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    if (self.title)
    {
        mutDic[@"title"] = self.title;
    }
    if (self.subTitle)
    {
        mutDic[@"subTitle"] = self.subTitle;
    }
    if (self.body)
    {
        mutDic[@"body"] = self.body;
    }
    if (self.sound)
    {
        mutDic[@"sound"] = self.sound;
    }
    if (self.badge)
    {
        mutDic[@"badge"] = self.badge;
    }
    if (self.category)
    {
        mutDic[@"category"] = self.category;
    }
    if (self.actionIdentifier)
    {
        mutDic[@"actionIdentifier"] = self.actionIdentifier;
    }
    if (self.actionUserText)
    {
        mutDic[@"actionUserText"] = self.actionUserText;
    }
    if (self.alertAction)
    {
        mutDic[@"alertAction"] = self.alertAction;
    }
    if (self.threadIdentifier)
    {
        mutDic[@"threadIdentifier"] = self.threadIdentifier;
    }
    if (self.launchImageName)
    {
        mutDic[@"launchImageName"] = self.launchImageName;
    }
    if ([O2SPushDevice versionCompare:@"12.0"] >= 0)
    {
        if (self.summaryArgument)
        {
            mutDic[@"summaryArgument"] = self.summaryArgument;
            mutDic[@"summaryArgumentCount"] = @(self.summaryArgumentCount);
        }
    }
    if ([O2SPushDevice versionCompare:@"13.0"] >= 0)
    {
        if (self.targetContentIdentifier)
        {
            mutDic[@"targetContentIdentifier"] = self.targetContentIdentifier;
        }
    }
    if (self.silentPush)
    {
        mutDic[@"silentPush"] = @(YES);
    }
    if (self.contentAvailable)
    {
        mutDic[@"contentAvailable"] = @(YES);
    }
    if (self.mutableContent)
    {
        mutDic[@"mutableContent"] = @(YES);
    }
    if (self.userInfo)
    {
        mutDic[@"userInfo"] = self.userInfo;
    }
    return [mutDic copy];
}

@end
