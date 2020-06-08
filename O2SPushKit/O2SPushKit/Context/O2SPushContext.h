//
//  O2SPushContext.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "O2SPushCenter.h"

extern NSString *const O2SPushCommandClearBadge;

@interface O2SPushContext : NSObject

// Hook delegate
@property (nonatomic, weak) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, strong) NSMutableArray *appDelegates;

@property (nonatomic, weak) id unDelegate;


/// 单例
+ (instancetype)currentContext;

/// 注册远程通知
/// @param configuration 内部(注册通知授予权限选项O2SPushAuthorizationOptions、类别组categories)
- (void)registerForRemoteNotification:(O2SPushNotificationConfiguration *)configuration;

/// 关闭远程推送
- (void)unregisterForRemoteNotification;

/// 设置应用在前台收到推送通知提醒默认 Badge | Sound | Alert，iOS10及以上有效
/// 如在前台取消提示可设置 None(:O2SPushAuthorizationOptionNone)
/// @param type 在前端提醒类型
- (void)setupForegroundNotificationOptions:(O2SPushAuthorizationOptions)type;

/// 获取当前应用推送通知授权状态
/// @param handler 返回授权状态
- (void)requestNotificationAuthorizationStatus:(void (^)(O2SPushAuthorizationStatus status))handler;

#pragma mark - 本地推送

/// 添加本地推送通知
/// 注意：iOS10及以上发送相同推送标识(identifier) 通知栏上旧通知将被覆盖(包括远程推送)
/// @param request 推送通知请求体(通知标识、通知具体信息、触发方式)
/// @param handler 回调添加结果，result值：
///         iOS10及以上成功：result为UNNotificationRequest对象
///         iOS10以下成功：result为UILocalNotification对象
///         失败：result为nil
- (void)addLocalNotification:(O2SPushNotificationRequest *)request
                     handler:(void (^) (id result, NSError *error))handler;


/// 删除指定的推送通知
/// @param identifiers 推送请求标识数组，为nil时删除该类型所有通知
/// @param requestStatuses  三种值：
///         O2SPushNotificationRequestStatusPending：待发送 例如定时推送，未触发的推送
///         O2SPushNotificationRequestStatusDelivered：已经发送且在通知栏里的推送(包括本地推送和远程推送)
///         以上两种都包含：O2SPushNotificationRequestStatusPending | O2SPushNotificationRequestStatusDelivered
- (void)removeNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatuses:(O2SPushNotificationRequestStatusOptions)requestStatuses;


/// 查找推送通知
/// @param identifiers 推送请求标识数组，为nil或空数组时则返回相应类型下所有在通知中心显示推送通知或待推送通知
/// @param requestStatus 两种值：
///         O2SPushNotificationRequestStatusPending：待发送 例如定时推送，未触发的推送
///         O2SPushNotificationRequestStatusDelivered：已经发送且在通知栏里的推送(包括本地推送和远程推送)，iOS10以下查询结果为nil
///         注意：使用(O2SPushNotificationRequestStatusPending | O2SPushNotificationRequestStatusDelivered)以O2SPushNotificationRequestStatusDelivered处理
/// @param handler 回调查找结果，result值：
///         iOS10以下：返回UILocalNotification对象数组
///         iOS10及以上：
- (void)findNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatus:(O2SPushNotificationRequestStatusOptions)requestStatus
                                handler:(void (^) (NSArray *result, NSError *error))handler;


#pragma mark - Hook UIAppDelegate 相关处理

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)didReceiveLocalNotification:(UILocalNotification *)notification;
- (void)handActionWithIdentifier:(NSString *)actionIdentifier forRemoteNotification:(NSDictionary *)userInfo ResponseInfo:(NSDictionary *)responseInfo;
- (void)handActionWithIdentifier:(NSString *)actionIdentifier forLocalNotification:(UILocalNotification *)notification ResponseInfo:(NSDictionary *)responseInfo;

@end
