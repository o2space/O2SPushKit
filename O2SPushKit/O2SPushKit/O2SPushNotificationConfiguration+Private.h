//
//  O2SPushNotificationConfiguration+Private.h
//  O2SPushKit
//
//  Created by wkx on 2020/6/5.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushCenter.h"

@interface O2SPushNotificationConfiguration ()

/// 注入的类别
/// iOS8-iOS9 为UIUserNotificationCategory
/// iOS10及以上为UNNotificationCategory
@property (nonatomic, strong) NSSet *convertCategories;

@end
