//
//  O2SPushNotificationCategory.h
//  O2SPushKit
//
//  Created by wkx on 2020/6/4.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@class O2SPushNotificationAction;

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, O2SPushNotificationCategoryOptions) {
    
    O2SPushNotificationCategoryOptionCustomDismissAction = (1 << 0),
    
    O2SPushNotificationCategoryOptionAllowInCarPlay = (1 << 1),
    
    O2SPushNotificationCategoryOptionHiddenPreviewsShowTitle = (1 << 2),
    
    O2SPushNotificationCategoryOptionHiddenPreviewsShowSubtitle = (1 << 3),

    O2SPushNotificationCategoryOptionAllowAnnouncement = (1 << 4),

};

typedef NS_OPTIONS(NSUInteger, O2SPushNotificationActionOptions) {
    
    O2SPushNotificationActionOptionAuthenticationRequired = (1 << 0),
    
    O2SPushNotificationActionOptionDestructive = (1 << 1),

    O2SPushNotificationActionOptionForeground = (1 << 2),
};

static const O2SPushNotificationActionOptions O2SPushNotificationActionOptionNone;

@interface O2SPushNotificationCategory : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;

@property (nonatomic, readonly, copy) NSArray<O2SPushNotificationAction *> *actions;

@property (nonatomic, readonly, copy) NSArray<NSString *> *intentIdentifiers;

@property (nonatomic, readonly, assign) O2SPushNotificationCategoryOptions options;

@property (nonatomic, readonly, copy, nullable) NSString *hiddenPreviewsBodyPlaceholder;

@property (nonatomic, readonly, copy, nullable) NSString *categorySummaryFormat;


/// 自定义推送通知按钮的Group
/// @param identifier GroupID
/// @param actions 按钮列表
/// @param intentIdentifiers .
/// @param hiddenPreviewsBodyPlaceholder 通知栏内body内容过长，裁剪后面附加提示，iOS11及以上有效
/// @param categorySummaryFormat 通知栏分组折叠后 例如："还有%u条来自%@的消息" iOS12及以上有效
/// @param options .
+ (instancetype)categoryWithIdentifier:(NSString *)identifier
                               actions:(NSArray<O2SPushNotificationAction *> *)actions
                     intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
         hiddenPreviewsBodyPlaceholder:(nullable NSString *)hiddenPreviewsBodyPlaceholder
                 categorySummaryFormat:(nullable NSString *)categorySummaryFormat
                               options:(O2SPushNotificationCategoryOptions)options;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface O2SPushNotificationAction : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;

@property (nonatomic, readonly, copy) NSString *title;

@property (nonatomic, readonly, assign) O2SPushNotificationActionOptions options;

@property (nonatomic, readonly, copy, nullable) NSString *textInputButtonTitle;

@property (nonatomic, readonly, copy, nullable) NSString *textInputPlaceholder;

+ (instancetype)defaultActionWithIdentifier:(NSString *)identifier
                                      title:(NSString *)title
                                    options:(O2SPushNotificationActionOptions)options;

+ (instancetype)textInputActionWithIdentifier:(NSString *)identifier
                                        title:(NSString *)title
                                      options:(O2SPushNotificationActionOptions)options
                         textInputButtonTitle:(nullable NSString *)textInputButtonTitle
                         textInputPlaceholder:(nullable NSString *)textInputPlaceholder;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
