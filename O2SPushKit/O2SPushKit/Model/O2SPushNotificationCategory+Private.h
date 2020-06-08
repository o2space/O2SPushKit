//
//  O2SPushNotificationCategory+Private.h
//  O2SPushKit
//
//  Created by wkx on 2020/6/4.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationCategory.h"

// 注意：在O2SPushNotificationCategory.m文件中 #import "O2SPushNotificationCategory+Private.h" 此头文件否则无法生成Setter方法

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, O2SPushNotificationActionType)
{
    O2SPushNotificationActionTypeDefault = 0,
    O2SPushNotificationActionTypeTextInput = 1,
};

@interface O2SPushNotificationCategory ()

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) NSArray<O2SPushNotificationAction *> *actions;

@property (nonatomic, copy) NSArray<NSString *> *intentIdentifiers;

@property (nonatomic, assign) O2SPushNotificationCategoryOptions options;

@property (nonatomic, copy, nullable) NSString *hiddenPreviewsBodyPlaceholder;

@property (nonatomic, copy, nullable) NSString *categorySummaryFormat;

@end


@interface O2SPushNotificationAction ()

@property (nonatomic, assign) O2SPushNotificationActionType actionType;

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, assign) O2SPushNotificationActionOptions options;

@property (nonatomic, copy, nullable) NSString *textInputButtonTitle;

@property (nonatomic, copy, nullable) NSString *textInputPlaceholder;

@end

NS_ASSUME_NONNULL_END
