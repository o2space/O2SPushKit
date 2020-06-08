//
//  O2SPushNotificationContent+Private.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationContent.h"

// 注意：在O2SPushNotificationContent.m文件中 #import "O2SPushNotificationContent+Private.h" 此头文件否则无法生成Setter方法
@interface O2SPushNotificationContent ()

@property (nonatomic, copy) NSString *actionIdentifier;

@property (nonatomic, copy) NSString *actionUserText;

@property (nonatomic, assign) BOOL silentPush;

+ (instancetype)apnsNotificationWithDict:(NSDictionary *)dict;

@end
