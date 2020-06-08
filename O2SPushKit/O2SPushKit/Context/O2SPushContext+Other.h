//
//  O2SPushContext+Other.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/30.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushContext.h"

@interface O2SPushContext (Other)

/// 跳转至系统设置应用权限页面，iOS8及以上有效
/// @param handler 返回跳转结果
- (void)openSettingsForNotification:(void(^)(BOOL success))handler;

/// 设置应用角标
/// 此处特殊处理赋0值不清空通知栏
/// @param badge 角标数值
- (void)setBadge:(NSInteger)badge;

@end
