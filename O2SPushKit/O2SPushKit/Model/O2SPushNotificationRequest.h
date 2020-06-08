//
//  O2SPushNotificationRequest.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLRegion;
@class O2SPushNotificationTrigger;
@class O2SPushNotificationContent;

NS_ASSUME_NONNULL_BEGIN

/// 用于发起本地推送请求
@interface O2SPushNotificationRequest : NSObject

// 推送消息唯一标识,iOS10以上 相同标识的消息将会被替换，如果为nil将随机生成
@property(nonatomic, copy, readonly) NSString *requestIdentifier;

// 推送通知消息
@property(nonatomic, strong, readonly) O2SPushNotificationContent *content;

// 推送消息触发方式,nil时为即时消息，立即推送
@property(nonatomic, strong, readonly, nullable) O2SPushNotificationTrigger *trigger;

+ (instancetype)requestWithIdentifier:(NSString *)identifier content:(O2SPushNotificationContent *)content trigger:(nullable O2SPushNotificationTrigger *)trigger;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end


/*
* 本地推送触发方式
* iOS10以上请使用region、dateComponents、timeInterval选择其中一种方式，如果同时多个赋值根据优先级(I：高、II：中、III：低)高的为主，如果全为空，为即时消息。
* iOS10以下定时推送使用fireDate
*/
@interface O2SPushNotificationTrigger : NSObject

// 设置是否重复，默认为NO
@property (nonatomic, assign) BOOL repeat;

// 用来设置触发推送的时间，iOS10以上无效
@property (nonatomic, copy, nullable) NSDate *fireDate NS_DEPRECATED_IOS(2_0, 10_0);

// 用来设置触发推送的位置，应用需要允许使用定位的授权，iOS8以上有效，iOS10以上优先级为I
@property (nonatomic, copy, nullable) CLRegion *region NS_AVAILABLE_IOS(8_0);

// 用来设置触发推送的日期时间，iOS10以上有效，优先级为II
@property (nonatomic, copy, nullable) NSDateComponents *dateComponents NS_AVAILABLE_IOS(10_0);

// 用来设置触发推送的时间，iOS10以上有效，优先级为III
@property (nonatomic, assign) NSTimeInterval timeInterval NS_AVAILABLE_IOS(10_0);

@end

NS_ASSUME_NONNULL_END
