//
//  O2SPushHookTool.m
//  O2SPushKit
//
//  Created by wkx on 2020/6/2.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushHookTool.h"
#import <objc/message.h>

@implementation O2SPushHookTool

/**
 是否含有方法

 @param cls 原类
 @param m 方法
 @return 标识
 */
+ (BOOL)hasMethodWithClass:(Class)cls method:(SEL)m
{
    
    
    BOOL hasMethod = NO;
    unsigned int outCountMethod = 0;
    Method * methods = class_copyMethodList(cls, &outCountMethod);
    
    for (int j = 0; j < outCountMethod; j++) {
        
        Method method = methods[j];
        SEL methodSEL = method_getName(method);
        NSString *name = NSStringFromSelector(methodSEL);
        
        if ([name isEqualToString:NSStringFromSelector(m)]) {
            hasMethod = YES;
            break;
        }
    }
    
    free(methods);
    
    return hasMethod;
}

+ (void)hookRawClass:(Class)cls
              rawSEL:(SEL)dulRawSEL
         targetClass:(Class)targetCls
              newSEL:(SEL)newSEL
      placeHolderSEL:(SEL)holderSEL
{
    BOOL hasNewMethod = [self hasMethodWithClass:cls method:newSEL];
    
    //是否已经添加实现
    if (cls && !hasNewMethod) {
        
        //找到本地、原始方法实现体
        IMP dulIMP = class_getMethodImplementation(targetCls, newSEL);
        IMP dulRawIMP = class_getMethodImplementation(cls, dulRawSEL);
        IMP holderIMP = class_getMethodImplementation(targetCls, holderSEL);
        
        Method dulRawMethod = class_getInstanceMethod(cls, dulRawSEL);
        
        BOOL hasRawMethod = [self hasMethodWithClass:cls method:dulRawSEL];
        
        Method newM = class_getInstanceMethod(targetCls, newSEL);
        const char * types = method_getTypeEncoding(newM);
        
        if (dulRawMethod == NULL) {
            //增加本地holder
            class_addMethod(cls, dulRawSEL, holderIMP, types);
            
            dulRawMethod = class_getInstanceMethod(cls, dulRawSEL);
            dulRawIMP = method_getImplementation(dulRawMethod);
        }else if (!hasRawMethod){
            class_addMethod(cls, dulRawSEL, dulRawIMP, types);
            dulRawMethod = class_getInstanceMethod(cls, dulRawSEL);
            dulRawIMP = method_getImplementation(dulRawMethod);
        }
        
        if (dulRawIMP != dulIMP) {
            //添加本地方法
            class_addMethod(cls, newSEL, dulIMP, types);
            newM = class_getInstanceMethod(cls, newSEL);
            method_setImplementation(dulRawMethod, dulIMP);
            method_setImplementation(newM, dulRawIMP);
        }
        
    }
}

+ (void)hookRawClass:(Class)cls
      classMethodSEL:(SEL)dulRawMethodSel
         targetClass:(Class)targetCls
   newClassMethodSEL:(SEL)newSel
{
    if (cls) {
        
        Method originalMethod = class_getClassMethod(cls, dulRawMethodSel);
        Method swizzledMethod = class_getClassMethod(targetCls, newSel);
        
        if (!originalMethod || !swizzledMethod) {
            return;
        }
        
        IMP originalIMP = method_getImplementation(originalMethod);
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        const char *originalType = method_getTypeEncoding(originalMethod);
        const char *swizzledType = method_getTypeEncoding(swizzledMethod);
        
        // 类方法添加,需要将方法添加到MetaClass中
        Class metaClass = objc_getMetaClass(class_getName(cls));
        class_replaceMethod(metaClass,dulRawMethodSel,swizzledIMP,swizzledType);
        class_replaceMethod(metaClass,newSel,originalIMP,originalType);
    }
}


@end
