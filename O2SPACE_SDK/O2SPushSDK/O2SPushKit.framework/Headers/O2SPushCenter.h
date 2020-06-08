//
//  O2SPushCenter.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@class O2SPushNotificationConfiguration;
@class O2SPushNotificationRequest;
@class O2SPushNotificationConfiguration;
@class O2SPushNotificationCategory;

@class UIUserNotificationCategory;

NS_ASSUME_NONNULL_BEGIN

// 通过KVO 统一API接收推送消息通知(包括：前台接收本地推送消息、前台接收APNS远程推送消息、APNS静默远程消息后台亦能收到、通知栏点击本地推送消息、通知栏点击远程推送消息)
// 使用方式：[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(o2SPushDidReceiveMessageNotification:) name:O2SPushDidReceiveMessageNotification object:nil];
extern NSString *const O2SPushDidReceiveMessageNotification;

extern NSString *const O2SPushDidRegisterRemoteNotification;        // 注册远程通知成功 KVO 返回DeviceToken
extern NSString *const O2SPushFailedRegisterRemoteNotification;     // 注册远程通知失败 KVO 返回NSError

/// 系统通知授权状态
typedef NS_ENUM(NSInteger, O2SPushAuthorizationStatus) {
    // The user has not yet made a choice regarding whether the application may post user notifications.
    O2SPushAuthorizationStatusNotDetermined = 0,
    // The application is not authorized to post user notifications.
    O2SPushAuthorizationStatusDenied,
    // The application is authorized to post user notifications.
    O2SPushAuthorizationStatusAuthorized,
    // The application is authorized to post non-interruptive user notifications.
    O2SPushAuthorizationStatusProvisional NS_AVAILABLE_IOS(12.0),
};

/// 推送授予权限种类
typedef NS_ENUM(NSInteger, O2SPushAuthorizationOptions) {
    O2SPushAuthorizationOptionNone     = 0,             //不提醒
    O2SPushAuthorizationOptionBadge    = (1 << 0),      //角标提醒
    O2SPushAuthorizationOptionSound    = (1 << 1),      //声音提醒
    O2SPushAuthorizationOptionAlert    = (1 << 2),      //弹框提醒
    O2SPushAuthorizationOptionCarPlay  = (1 << 3),
    O2SPushAuthorizationOptionCriticalAlert NS_AVAILABLE_IOS(12.0) = (1 << 4),
    
    //临时授权 不会出现权限提示，临时授权，下方显示出“保持...”、“关闭”等提示用户进行权限设置的选项
    O2SPushAuthorizationOptionProvidesAppNotificationSettings NS_AVAILABLE_IOS(12.0) = (1 << 5),    //临时授权相关
    O2SPushAuthorizationOptionProvisional NS_AVAILABLE_IOS(12.0) = (1 << 6),                        //临时授权相关
    O2SPushAuthorizationOptionAnnouncement NS_AVAILABLE_IOS(13.0) = (1 << 6),
};

/// 推送请求在苹果通知系统中当前状态，目前用于查询、删除推送通知使用，O2SPushNotificationRequestStatusPending | O2SPushNotificationRequestStatusDelivered 为全部
typedef NS_OPTIONS(NSUInteger, O2SPushNotificationRequestStatusOptions) {
    O2SPushNotificationRequestStatusPending       = (1 << 0),   //待发送(如：定时推送未发送)
    O2SPushNotificationRequestStatusDelivered     = (1 << 1),   //在系统通知栏里的推送
};


/// 针对苹果推送进行模块封装，统一管理，兼容iOS8及以上
@interface O2SPushCenter : NSObject

/// 注册远程通知
/// @param configuration 内部(注册通知授予权限选项O2SPushAuthorizationOptions、类别组categories)
+ (void)registerForRemoteNotification:(O2SPushNotificationConfiguration *)configuration;

/// 关闭远程推送
+ (void)unregisterForRemoteNotification;

/// 设置应用在前台收到推送通知提醒默认 Badge | Sound | Alert，iOS10及以上有效
/// 如在前台取消提示可设置 None(:O2SPushAuthorizationOptionNone)
/// @param type 在前端提醒类型
+ (void)setupForegroundNotificationOptions:(O2SPushAuthorizationOptions)type;

/// 获取当前应用推送通知授权状态
/// @param handler 返回授权状态
+ (void)requestNotificationAuthorizationStatus:(void (^)(O2SPushAuthorizationStatus status))handler;

#pragma mark - 本地推送

/// 添加本地推送通知
/// 注意：iOS10及以上发送相同推送标识(identifier) 通知栏上旧通知将被覆盖(包括远程推送)
/// @param request 推送通知请求体(通知标识、通知具体信息、触发方式)
/// @param handler 回调添加结果，result值：
///         iOS10及以上成功：result为UNNotificationRequest对象
///         iOS10以下成功：result为UILocalNotification对象
///         失败：result为nil
+ (void)addLocalNotification:(O2SPushNotificationRequest *)request
                     handler:(void (^) (id result, NSError *error))handler;


/// 删除指定的推送通知
/// @param identifiers 推送请求标识数组，为nil时删除该类型所有通知
/// @param requestStatuses  三种值：
///         O2SPushNotificationRequestStatusPending：待发送 例如定时推送，未触发的推送
///         O2SPushNotificationRequestStatusDelivered：已经发送且在通知栏里的推送(包括本地推送和远程推送)
///         以上两种都包含：O2SPushNotificationRequestStatusPending | O2SPushNotificationRequestStatusDelivered
+ (void)removeNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
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
+ (void)findNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatus:(O2SPushNotificationRequestStatusOptions)requestStatus
                                handler:(void (^) (NSArray *result, NSError *error))handler;

#pragma mark - other

/// 跳转至系统设置应用权限页面，iOS8及以上有效
/// @param handler 返回跳转结果
+ (void)openSettingsForNotification:(void(^)(BOOL success))handler;

/// 设置应用角标
/// 此处特殊处理当赋0值时不清空通知栏
/// 注意： 清空角标的同时清空通知栏：
///             [UIApplication sharedApplication].applicationIconBadgeNumber =  0;
///      只清空角标不清空通知栏:
///             iOS11及以上，[UIApplication sharedApplication].applicationIconBadgeNumber =  -1;
///             iOS10及以上至iOS11，无法做到
///             iOS10以下：发起一个本地通知，前台收到“清空角标标识”的本地通知过滤即可:
///                 UILocalNotification *localNotification = [UILocalNotification new];
///                 localNotification.fireDate = NSDate.date;
///                 localNotification.applicationIconBadgeNumber = -1;
///                 localNotification.userInfo = @{@"清空角标标识": @(YES)};//用户本地收到时过滤
///                 [UIApplication.sharedApplication scheduleLocalNotification:localNotification];
/// @param badge 角标数值
+ (void)setBadge:(NSInteger)badge;

/// 清空角标，但不清空通知栏消息(除iOS10~iOS11(不含)外，其通知栏将会一起清除)
+ (void)clearBadge;

/// 清空角标，及清空通知栏消息
/// [UIApplication sharedApplication].applicationIconBadgeNumber =  0;
+ (void)clearNoticeBar;

@end


@interface O2SPushNotificationConfiguration : NSObject

/// O2SPushAuthorizationOptions 权限类型，如badge、sound、alert等
@property (nonatomic, assign) O2SPushAuthorizationOptions types;

/// 使用此类兼容iOS8及以上
@property (nonatomic, strong, nullable) NSSet<O2SPushNotificationCategory *> *categories;

@end

NS_ASSUME_NONNULL_END
