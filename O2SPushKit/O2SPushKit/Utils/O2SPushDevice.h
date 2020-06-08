//
//  O2SPushDevice.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface O2SPushDevice : NSObject

// 系统版本比较 扩充三段如:1.0.0
+ (NSInteger)versionCompare:(NSString *)other;

/// 将数据转换成16进制字符串
/// @param data 原始数据
/// @return 字符串
+ (NSString *)hexStringByData:(NSData *)data;

@end
