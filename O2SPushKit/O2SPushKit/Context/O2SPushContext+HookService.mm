//
//  O2SPushContext+HookService.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/30.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushContext+HookService.h"
#import "UIApplication+O2SPush.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "O2SPushHookTool.h"

struct O2SPushHookServiceMain
{
    O2SPushHookServiceMain()
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            // 勾取UIApplication的设置委托对象方法
            Method raw = class_getInstanceMethod([UIApplication class], @selector(setDelegate:));
            Method hook = class_getInstanceMethod([UIApplication class], @selector(o2spushSetDelegate:));
            IMP imp1 = method_getImplementation(raw);
            IMP imp2 = method_getImplementation(hook);
            method_setImplementation(raw, imp2);
            method_setImplementation(hook, imp1);
            
            // 勾取UNUserNotificationCenter的设置委托对象方法
            Class O2SPushNotificationCenter = NSClassFromString(@"UNUserNotificationCenter");
            if (O2SPushNotificationCenter)
            {
                SEL rawSEL = NSSelectorFromString(@"setDelegate:");
                SEL hookSEL = NSSelectorFromString(@"o2spushSetUNDelegate:");
                SEL placeHolderSEL = NSSelectorFromString(@"p_o2spushSetUNDelegate:");
                [O2SPushHookTool hookRawClass:O2SPushNotificationCenter
                                       rawSEL:rawSEL
                                  targetClass:[O2SPushContext class]
                                       newSEL:hookSEL
                               placeHolderSEL:placeHolderSEL];
            }
        });
    }
};

static O2SPushHookServiceMain o2spushHookServiceMain;

const SEL o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL = NSSelectorFromString(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
const SEL o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL = NSSelectorFromString(@"application:didFailToRegisterForRemoteNotificationsWithError:");

const SEL o2spushDidReceiveRemoteNotificationSEL = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
const SEL o2spushDidReceiveLocalNotificationSEL = NSSelectorFromString(@"application:didReceiveLocalNotification:");
const SEL o2spushFetchCompletionHandlerSEL = NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");

const SEL o2spushHandleActionLocalNotificationSEL = NSSelectorFromString(@"application:handleActionWithIdentifier:forLocalNotification:completionHandler:");
const SEL o2spushHandleActionLocalNotificationResponseInfoSEL = NSSelectorFromString(@"application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:");
const SEL o2spushHandleActionRemoteNotificationSEL = NSSelectorFromString(@"application:handleActionWithIdentifier:forRemoteNotification:completionHandler:");
const SEL o2spushHandleActionRemoteNotificationResponseInfoSEL = NSSelectorFromString(@"application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:");

const SEL super_o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL = NSSelectorFromString(@"O2SPushApplication:didRegisterForRemoteNotificationsWithDeviceToken:");
const SEL super_o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL = NSSelectorFromString(@"O2SPushApplication:didFailToRegisterForRemoteNotificationsWithError:");

const SEL super_o2spushDidReceiveRemoteNotificationSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveRemoteNotification:");
const SEL super_o2spushDidReceiveLocalNotificationSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveLocalNotification:");
const SEL super_o2spushFetchCompletionHandlerSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveRemoteNotification:fetchCompletionHandler:");

const SEL super_o2spushHandleActionLocalNotificationSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forLocalNotification:completionHandler:");
const SEL super_o2spushHandleActionLocalNotificationResponseInfoSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:");
const SEL super_o2spushHandleActionRemoteNotificationSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forRemoteNotification:completionHandler:");
const SEL super_o2spushHandleActionRemoteNotificationResponseInfoSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:");

@implementation O2SPushContext (HookService)

- (void)o2spushSetUNDelegate:(id)delegate
{
    if ([O2SPushContext currentContext].unDelegate == nil)
    {
        [self o2spushSetUNDelegate:[O2SPushContext currentContext]];
    }
    
    // 保存外来的 delegate，后面做交换
    [O2SPushContext currentContext].unDelegate = delegate;
}

- (void)p_o2spushSetUNDelegate:(id)delegate
{
    
}

#pragma mark - IMP 推送通知iOS10以下 Hook IMP

#pragma mark DeviceToken

// 获取 DeviceToken
// ios3及以上 注册远程推送成功回调返回deviceToken
// - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
// hook或添加 最终方法实现
static void O2SPushDidRegisterForRemoteNotificationsWithDeviceTokenIMP(id self, SEL cmd, UIApplication *application, NSData *deviceToken)
{
    [[O2SPushContext currentContext] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSData *) = (void(*)(struct objc_super *, SEL, UIApplication *, NSData *))objc_msgSendSuper;
//        action (&supperInfo, o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL, application, deviceToken);
//    }
    if ([delegater respondsToSelector:super_o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSData *) = (void(*)(id, SEL, UIApplication *, NSData *))objc_msgSend;
        action (delegater, super_o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL, application, deviceToken);
    }

}


// 获取 DeviceToken 失败
// ios3及以上 注册远程推送失败回调
// - (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
// hook或添加 最终方法实现
static void O2SPushDidFailToRegisterForRemoteNotificationsWithErrorIMP(id self, SEL cmd, UIApplication *application, NSError *error)
{
    [[O2SPushContext currentContext] didFailToRegisterForRemoteNotificationsWithError:error];
        
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSError *) = (void(*)(struct objc_super *, SEL, UIApplication *, NSError *))objc_msgSendSuper;
//        action (&supperInfo, o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL, application, error);
//    }
    if ([delegater respondsToSelector:super_o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSError *) = (void(*)(id, SEL, UIApplication *, NSError *))objc_msgSend;
        action (delegater, super_o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL, application, error);
    }

}

#pragma mark 接收通知

// ios3-ios10 远程推送
// - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
// hook或添加 最终方法实现
static void O2SPushDidReceiveRemoteNotificationIMP(id self, SEL cmd, UIApplication *application, NSDictionary *userInfo)
{
    [[O2SPushContext currentContext] didReceiveRemoteNotification:userInfo];
    // 派发回原方法
    SendRawO2SPushDidReceiveRemoteNotificationIMP(self, application, userInfo);
}

static void SendRawO2SPushDidReceiveRemoteNotificationIMP(id self, UIApplication *application, NSDictionary *userInfo)
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushDidReceiveRemoteNotificationSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSDictionary *) = (void(*)(struct objc_super *, SEL, UIApplication *, NSDictionary *))objc_msgSendSuper;
//        action (&supperInfo, o2spushDidReceiveRemoteNotificationSEL, application, userInfo);
//    }
    
    if ([delegater respondsToSelector:super_o2spushDidReceiveRemoteNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSDictionary *) = (void(*)(id, SEL, UIApplication *, NSDictionary *))objc_msgSend;
        action (delegater, super_o2spushDidReceiveRemoteNotificationSEL, application, userInfo);
    }

}


/* iOS10以下
应用程序前台：收到本地通知
应用程序后台：本地通知点击通知栏回调
*/
// ios4-ios10 本地推送
// - (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
// hook或添加 最终方法实现
static void O2SPushDidReceiveLocalNotificationIMP(id self, SEL cmd, UIApplication *application, UILocalNotification *notification)
{
    
    if (notification.userInfo && notification.userInfo[O2SPushCommandClearBadge])
    {
        BOOL clearbadge = [notification.userInfo[O2SPushCommandClearBadge] boolValue];
        if (clearbadge)
        {
            return;
        }
    }
    
    [[O2SPushContext currentContext] didReceiveLocalNotification:notification];
    
    // 派发回原方法
    SendRawO2SPushDidReceiveLocalNotificationIMP(self, application, notification);
}
static void SendRawO2SPushDidReceiveLocalNotificationIMP(id self, UIApplication *application, UILocalNotification *notification)
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushDidReceiveLocalNotificationSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, UILocalNotification *) = (void(*)(struct objc_super *, SEL, UIApplication *, UILocalNotification *))objc_msgSendSuper;
//        action (&supperInfo, o2spushDidReceiveLocalNotificationSEL, application, notification);
//    }
    
    if ([delegater respondsToSelector:super_o2spushDidReceiveLocalNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, UILocalNotification *) = (void(*)(id, SEL, UIApplication *, UILocalNotification *))objc_msgSend;
        action (delegater, super_o2spushDidReceiveLocalNotificationSEL, application, notification);
    }
}

- (void)PublicSendRawO2SPush:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // 派发回原方法
    SendRawO2SPushDidReceiveLocalNotificationIMP(applicationDelegate, application, notification);
}


/*
1. 静默通知：前台后台都能唤醒，进入回调。「系统杀死可唤醒，开发者手动杀死进程，不能唤醒」[目前 iOS 所有静默通知回调都在这里]
2. iOS10以下，应用程序前台：收到远程通知
  应用程序后台：远程通知点击通知栏回调
*/
// ios7-ios10远程推送 及 ios7及以上远程静默推送
// - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
// hook或添加 最终方法实现
static void O2SPushFetchCompletionHandlerIMP(id self, SEL cmd, UIApplication *application, NSDictionary *userInfo, void (^completionHandler)(UIBackgroundFetchResult))
{
    [[O2SPushContext currentContext] didReceiveRemoteNotification:userInfo];
    
    // 派发回原方法
    SendRawO2SPushFetchCompletionHandlerIMP(self, application, userInfo, completionHandler);
}
static void SendRawO2SPushFetchCompletionHandlerIMP(id self, UIApplication *application, NSDictionary *userInfo, void (^completionHandler)(UIBackgroundFetchResult))
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushFetchCompletionHandlerSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)) = (void(*)(struct objc_super *, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult) ))objc_msgSendSuper;
//        action (&supperInfo, o2spushFetchCompletionHandlerSEL, application, userInfo, completionHandler);
//    }
    if ([delegater respondsToSelector:super_o2spushFetchCompletionHandlerSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)) = (void(*)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult) ))objc_msgSend;
        action (delegater, super_o2spushFetchCompletionHandlerSEL, application, userInfo, completionHandler);

    }
    else
    {
        SendRawO2SPushDidReceiveRemoteNotificationIMP(self, application, userInfo);
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)PublicSendRawO2SPush:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    // 派发回原方法
    SendRawO2SPushFetchCompletionHandlerIMP(applicationDelegate, application, userInfo, completionHandler);
}





#pragma mark iOS8-iOS10 Action,iOS10及以上在UNUserNotificationCenterDelegate实例方法内

// iOS8-iOS10(不含) 本地通知Category-Action
// - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)(void))completionHandler
// hook或添加 最终方法实现
static void O2SPushHandActionLocalCompletionHandlerIMP(id self, SEL cmd, UIApplication *application, NSString *identifier, UILocalNotification *notification, void (^completionHandler)())
{
    
    [[O2SPushContext currentContext] handActionWithIdentifier:identifier forLocalNotification:notification ResponseInfo:nil];
    
    // 派发回原方法
    SendRawO2SPushHandActionLocalCompletionHandlerIMP(self, application, identifier, notification, completionHandler);
}
static void SendRawO2SPushHandActionLocalCompletionHandlerIMP(id self, UIApplication *application, NSString *identifier, UILocalNotification *notification, void (^completionHandler)())
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushHandleActionLocalNotificationSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()) = (void(*)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()))objc_msgSendSuper;
//        action (&supperInfo, o2spushHandleActionLocalNotificationSEL, application, identifier, notification, completionHandler);
//    }
    
    if ([delegater respondsToSelector:super_o2spushHandleActionLocalNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()))objc_msgSend;
        action (delegater, super_o2spushHandleActionLocalNotificationSEL, application, identifier, notification, completionHandler);

    }
    
    if (completionHandler)
    {
        completionHandler();
    }
}


// iOS9-iOS10(不含) 本地通知Category-Action 带TextInput
// - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler
// hook或添加 最终方法实现
static void O2SPushHandActionLocalResponseInfoCompletionHandlerIMP(id self, SEL cmd, UIApplication *application, NSString *identifier, UILocalNotification *notification, NSDictionary *responseInfo, void (^completionHandler)())
{
    
    [[O2SPushContext currentContext] handActionWithIdentifier:identifier forLocalNotification:notification ResponseInfo:responseInfo];
    
    // 派发回原方法
    SendRawO2SPushHandActionLocalResponseInfoCompletionHandlerIMP(self, application, identifier, notification, responseInfo, completionHandler);
}
static void SendRawO2SPushHandActionLocalResponseInfoCompletionHandlerIMP(id self, UIApplication *application, NSString *identifier, UILocalNotification *notification, NSDictionary *responseInfo, void (^completionHandler)())
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushHandleActionLocalNotificationResponseInfoSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()) = (void(*)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()))objc_msgSendSuper;
//        action (&supperInfo, o2spushHandleActionLocalNotificationResponseInfoSEL, application, identifier, notification, responseInfo, completionHandler);
//    }
    if ([delegater respondsToSelector:super_o2spushHandleActionLocalNotificationResponseInfoSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, super_o2spushHandleActionLocalNotificationResponseInfoSEL, application, identifier, notification, responseInfo, completionHandler);

    }
    else
    {
        SendRawO2SPushHandActionLocalCompletionHandlerIMP(self, application, identifier, notification, completionHandler);
    }
    
    if (completionHandler)
    {
        completionHandler();
    }
}

- (void)PublicSendRawO2SPushHand:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application actionIdentifier:(NSString *)actionIdentifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler
{
    // 派发回原方法
    SendRawO2SPushHandActionLocalResponseInfoCompletionHandlerIMP(applicationDelegate, application, actionIdentifier, notification, responseInfo, completionHandler);
}


// iOS8-iOS10(不含) 远程通知Category-Action
// - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
// hook或添加 最终方法实现
static void O2SPushHandActionRemoteCompletionHandlerIMP(id self, SEL cmd, UIApplication *application, NSString *identifier, NSDictionary *userInfo, void (^completionHandler)())
{
    
    [[O2SPushContext currentContext] handActionWithIdentifier:identifier forRemoteNotification:userInfo ResponseInfo:nil];
    
    // 派发回原方法
    SendRawO2SPushHandActionRemoteCompletionHandlerIMP(self, application, identifier, userInfo, completionHandler);
}
void SendRawO2SPushHandActionRemoteCompletionHandlerIMP(id self, UIApplication *application, NSString *identifier, NSDictionary *userInfo, void (^completionHandler)())
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushHandleActionRemoteNotificationSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()) = (void(*)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()))objc_msgSendSuper;
//        action (&supperInfo, o2spushHandleActionRemoteNotificationSEL, application, identifier, userInfo, completionHandler);
//    }
    if ([delegater respondsToSelector:super_o2spushHandleActionRemoteNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, super_o2spushHandleActionRemoteNotificationSEL, application, identifier, userInfo, completionHandler);

    }
    
    if (completionHandler)
    {
        completionHandler();
    }
}


// iOS9-iOS10(不含) 远程通知Category-Action 带TextInput
// - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler
// hook或添加 最终方法实现
static void O2SPushHandActionRemoteResponseInfoCompletionHandlerIMP(id self, SEL cmd, UIApplication *application, NSString *identifier, NSDictionary *userInfo, NSDictionary *responseInfo, void (^completionHandler)())
{
    
    [[O2SPushContext currentContext] handActionWithIdentifier:identifier forRemoteNotification:userInfo ResponseInfo:userInfo];
    
    // 派发回原方法
    SendRawO2SPushHandActionRemoteResponseInfoCompletionHandlerIMP(self, application, identifier, userInfo, responseInfo, completionHandler);
}
void SendRawO2SPushHandActionRemoteResponseInfoCompletionHandlerIMP(id self, UIApplication *application, NSString *identifier, NSDictionary *userInfo, NSDictionary *responseInfo, void (^completionHandler)())
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
//    Class superClass = class_getSuperclass(delegater.class);
//    struct objc_super supperInfo = {
//        .receiver = delegater,
//        .super_class = superClass
//    };
//
//    if ([superClass instancesRespondToSelector:o2spushHandleActionRemoteNotificationResponseInfoSEL])
//    {
//        void(*action)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()) = (void(*)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()))objc_msgSendSuper;
//        action (&supperInfo, o2spushHandleActionRemoteNotificationResponseInfoSEL, application, identifier, userInfo, responseInfo, completionHandler);
//    }
    if ([delegater respondsToSelector:super_o2spushHandleActionRemoteNotificationResponseInfoSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, super_o2spushHandleActionRemoteNotificationResponseInfoSEL, application, identifier, userInfo, responseInfo, completionHandler);

    }
    else
    {
        SendRawO2SPushHandActionRemoteCompletionHandlerIMP(self, application, identifier, userInfo, completionHandler);
    }
    if (completionHandler)
    {
        completionHandler();
    }
}
- (void)PublicSendRawO2SPushHand:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application actionIdentifier:(NSString *)actionIdentifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler
{
    // 派发回原方法
    SendRawO2SPushHandActionRemoteResponseInfoCompletionHandlerIMP(applicationDelegate, application, actionIdentifier, userInfo, responseInfo, completionHandler);
}

//static void O2SPush_HookedGetClass(Class cls, Class statedClass)
//{
//    Method method = class_getInstanceMethod(cls, @selector(class));
//    IMP newIMP = imp_implementationWithBlock(^(id self) {
//        return statedClass;
//    });
//    class_replaceMethod(cls, @selector(class), newIMP, method_getTypeEncoding(method));
//}

#pragma mark Hook

static NSString *const O2SPushSubclassPrefix = @"O2SPush_";

- (void)hookApplicationDelegate:(NSObject *)delegate
{
    Protocol *UIApplicationDelegateProtocol = NSProtocolFromString(@"UIApplicationDelegate");
    if (UIApplicationDelegateProtocol && [delegate conformsToProtocol:UIApplicationDelegateProtocol])
    {
//        Class statedClass = delegate.class;
        Class baseClass = object_getClass(delegate);
        NSString *className = NSStringFromClass(baseClass);
        if ([className hasPrefix:O2SPushSubclassPrefix])
        {
            return;
        }
        
        const char *subclassName = [O2SPushSubclassPrefix stringByAppendingString:className].UTF8String;
        Class subclass = objc_getClass(subclassName);
        if (subclass == nil)
        {
            // 创建类
            subclass = objc_allocateClassPair(baseClass, subclassName, 0);
            if (subclass == nil)
            {
                return;
            }
            
            // 不更换.class方法为父类，如果更换后，通过父类访问自身方法，无法访问子类方法。
//            O2SPush_HookedGetClass(subclass, statedClass);
//            O2SPush_HookedGetClass(object_getClass(subclass), statedClass);
            
            // 注册
            objc_registerClassPair(subclass);
            
            // 备份父类方法Imp
            [self backupsImpWithSuperclass:baseClass Subclass:subclass];
            // 添加方法
            [self hookAddMethodWithSubclass:subclass];
        }
        else if (class_isMetaClass(baseClass))
        {
            return;
        }
        else if ([baseClass isKindOfClass:subclass])//避免baseClass类是subclass的子类
        {
            return;
        }
        
        //替换对象的ISA指针
        object_setClass(delegate, subclass);
    }
}

- (void)backupsImpWithSuperclass:(Class)pclass Subclass:(Class)subclass
{
    // super DeviceToken
    if ([pclass instancesRespondToSelector:o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL];
        class_addMethod(subclass, super_o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL, imp, "v@:@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL];
        class_addMethod(subclass, super_o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL, imp, "v@:@@");
    }
    
    // super 消息接收
    if ([pclass instancesRespondToSelector:o2spushDidReceiveRemoteNotificationSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushDidReceiveRemoteNotificationSEL];
        class_addMethod(subclass, super_o2spushDidReceiveRemoteNotificationSEL, imp, "v@:@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushDidReceiveLocalNotificationSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushDidReceiveLocalNotificationSEL];
        class_addMethod(subclass, super_o2spushDidReceiveLocalNotificationSEL, imp, "v@:@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushFetchCompletionHandlerSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushFetchCompletionHandlerSEL];
        class_addMethod(subclass, super_o2spushFetchCompletionHandlerSEL, imp, "v@:@@@");
    }
    
    // super Action
    if ([pclass instancesRespondToSelector:o2spushHandleActionLocalNotificationSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushHandleActionLocalNotificationSEL];
        class_addMethod(subclass, super_o2spushHandleActionLocalNotificationSEL, imp, "v@:@@@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushHandleActionLocalNotificationResponseInfoSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushHandleActionLocalNotificationResponseInfoSEL];
        class_addMethod(subclass, super_o2spushHandleActionLocalNotificationResponseInfoSEL, imp, "v@:@@@@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushHandleActionRemoteNotificationSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushHandleActionRemoteNotificationSEL];
        class_addMethod(subclass, super_o2spushHandleActionRemoteNotificationSEL, imp, "v@:@@@@");
    }
    
    if ([pclass instancesRespondToSelector:o2spushHandleActionRemoteNotificationResponseInfoSEL])
    {
        IMP imp = [pclass instanceMethodForSelector:o2spushHandleActionRemoteNotificationResponseInfoSEL];
        class_addMethod(subclass, super_o2spushHandleActionRemoteNotificationResponseInfoSEL, imp, "v@:@@@@@");
    }
    
}

- (void)hookAddMethodWithSubclass:(Class)subclass
{
    // DeviceToken
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
    {
         class_addMethod(subclass, o2spushDidRegisterForRemoteNotificationsWithDeviceTokenSEL, (IMP)O2SPushDidRegisterForRemoteNotificationsWithDeviceTokenIMP, "v@:@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL])
    {
        class_addMethod(subclass, o2spushDidFailToRegisterForRemoteNotificationsWithErrorSEL, (IMP)O2SPushDidFailToRegisterForRemoteNotificationsWithErrorIMP, "v@:@@");
    }
    
    // iOS10以下 推送接收
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushDidReceiveRemoteNotificationSEL])
    {
        class_addMethod(subclass, o2spushDidReceiveRemoteNotificationSEL, (IMP)O2SPushDidReceiveRemoteNotificationIMP, "v@:@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushDidReceiveLocalNotificationSEL])
    {
        class_addMethod(subclass, o2spushDidReceiveLocalNotificationSEL, (IMP)O2SPushDidReceiveLocalNotificationIMP, "v@:@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushFetchCompletionHandlerSEL])
    {
        class_addMethod(subclass, o2spushFetchCompletionHandlerSEL, (IMP)O2SPushFetchCompletionHandlerIMP, "v@:@@@");
    }
    
    
    // iOS10以下 Action
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushHandleActionLocalNotificationSEL])
    {
        class_addMethod(subclass, o2spushHandleActionLocalNotificationSEL, (IMP)O2SPushHandActionLocalCompletionHandlerIMP, "v@:@@@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushHandleActionLocalNotificationResponseInfoSEL])
    {
        class_addMethod(subclass, o2spushHandleActionLocalNotificationResponseInfoSEL, (IMP)O2SPushHandActionLocalResponseInfoCompletionHandlerIMP, "v@:@@@@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushHandleActionRemoteNotificationSEL])
    {
        class_addMethod(subclass, o2spushHandleActionRemoteNotificationSEL, (IMP)O2SPushHandActionRemoteCompletionHandlerIMP, "v@:@@@@");
    }
    
    if (![O2SPushHookTool hasMethodWithClass:subclass method:o2spushHandleActionRemoteNotificationResponseInfoSEL])
    {
        class_addMethod(subclass, o2spushHandleActionRemoteNotificationResponseInfoSEL, (IMP)O2SPushHandActionRemoteResponseInfoCompletionHandlerIMP, "v@:@@@@@");
    }
    
    //  父类是否实现了
    
    
}

@end
