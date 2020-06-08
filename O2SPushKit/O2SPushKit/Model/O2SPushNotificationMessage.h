//
//  O2SPushNotificationMessage.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@class O2SPushNotificationContent;

typedef NS_ENUM(NSUInteger, O2SPushNotificationMessageType)
{
    O2SPushNotificationMessageTypeAPNs = 0,         //接收APNs推送(包括"前台"和"前台或后台静默"APNS消息)
    O2SPushNotificationMessageTypeLocal = 1,        //接收前台本地推送通知
    O2SPushNotificationMessageTypeAPNsClicked = 2,  //接收点击APNs推送通知
    O2SPushNotificationMessageTypeLocalClicked = 3, //接收点击本地推送通知
};

@interface O2SPushNotificationMessage : NSObject

 //推送通知消息类型
@property (nonatomic, assign, readonly) O2SPushNotificationMessageType notificationMessageType;

// 推送消息唯一标识
@property(nonatomic, copy, readonly) NSString *identifier;

// 推送通知消息
@property(nonatomic, strong, readonly) O2SPushNotificationContent *content;

- (NSDictionary *)convertDictionary;

@end



