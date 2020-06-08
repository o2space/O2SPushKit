//
//  O2SPushHookTool.h
//  O2SPushKit
//
//  Created by wkx on 2020/6/2.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface O2SPushHookTool : NSObject

/**
 Hook钩子（实例方法）

 @param cls 原始类
 @param dulRawSEL 要钩取的类的方法
 @param targetCls 目标类：实现本地方法的类
 @param newSEL 新方法
 @param holderSEL 占位方法
 */
+ (void)hookRawClass:(Class)cls
              rawSEL:(SEL)dulRawSEL
         targetClass:(Class)targetCls
              newSEL:(SEL)newSEL
      placeHolderSEL:(SEL)holderSEL;

/**
 Hook钩子（类方法）

 @param cls 原始类
 @param dulRawMethodSel 要钩取的类的原始方法
 @param targetCls 目标类：实现本地方法的类
 @param newSel 新方法
 */
+ (void)hookRawClass:(Class)cls
      classMethodSEL:(SEL)dulRawMethodSel
         targetClass:(Class)targetCls
   newClassMethodSEL:(SEL)newSel;

@end

