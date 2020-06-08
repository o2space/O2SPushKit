//
//  O2SPushNotificationMessage.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationMessage.h"
#import "O2SPushNotificationMessage+Private.h"
#import "O2SPushNotificationContent.h"

@implementation O2SPushNotificationMessage

- (NSDictionary *)convertDictionary
{
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    if (self.notificationMessageType > 0)
    {
        mutDic[@"notificationMessageType"] = @(self.notificationMessageType);
    }
    if (self.identifier)
    {
        mutDic[@"identifier"] = self.identifier;
    }
    if (self.content)
    {
        id noti = self.content.convertDictionary;
        if (noti)
        {
            mutDic[@"notification"] = noti;
        }
    }
    
    return [mutDic copy];
}

@end
