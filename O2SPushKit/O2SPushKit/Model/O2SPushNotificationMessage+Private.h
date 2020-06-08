//
//  O2SPushNotificationMessage+Private.h
//  O2SPushKit
//
//  Created by wkx on 2020/6/2.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationMessage.h"


// 注意：在O2SPushNotificationMessage.m文件中 #import "O2SPushNotificationMessage+Private.h" 此头文件否则无法生成Setter方法
@interface O2SPushNotificationMessage ()

 //推送通知消息类型
@property (nonatomic, assign) O2SPushNotificationMessageType notificationMessageType;

// 推送消息唯一标识
@property(nonatomic, copy) NSString *identifier;

// 推送通知消息
@property(nonatomic, strong) O2SPushNotificationContent *content;

@end
