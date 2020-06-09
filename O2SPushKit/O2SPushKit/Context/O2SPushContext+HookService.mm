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

static SEL o2spushHookDidRegisterForRemoteNotificationsWithDeviceTokenSEL = NSSelectorFromString(@"O2SPushApplication:didRegisterForRemoteNotificationsWithDeviceToken:");
static SEL o2spushHookDidFailToRegisterForRemoteNotificationsWithErrorSEL = NSSelectorFromString(@"O2SPushApplication:didFailToRegisterForRemoteNotificationsWithError:");

static SEL o2spushHookDidReceiveRemoteNotificationSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveRemoteNotification:");
static SEL o2spushHookDidReceiveLocalNotificationSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveLocalNotification:");
static SEL o2spushHookFetchCompletionHandlerSEL = NSSelectorFromString(@"O2SPushApplication:didReceiveRemoteNotification:fetchCompletionHandler:");

const SEL o2spushHookHandleActionLocalNotificationSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forLocalNotification:completionHandler:");
const SEL o2spushHookHandleActionLocalNotificationResponseInfoSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:");
const SEL o2spushHookHandleActionRemoteNotificationSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forRemoteNotification:completionHandler:");
const SEL o2spushHookHandleActionRemoteNotificationResponseInfoSEL = NSSelectorFromString(@"O2SPushApplication:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:");

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

#pragma mark 接收通知

// ios3-ios10 远程推送
// - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
// hook或添加 最终方法实现
static void O2SPushDidReceiveRemoteNotificationIMP(id self, SEL cmd, UIApplication *application, NSDictionary *userInfo)
{
    //不处理 已经基本无iOS6及以下版本用户
    [[O2SPushContext currentContext] didReceiveRemoteNotification:userInfo];
    // 派发回原方法
    SendRawO2SPushDidReceiveRemoteNotificationIMP(self, application, userInfo);
}
static void SendRawO2SPushDidReceiveRemoteNotificationIMP(id self, UIApplication *application, NSDictionary *userInfo)
{
    // 派发回原方法
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
    SEL hookDidReceiveRemoteNotificationSEL = o2spushHookDidReceiveRemoteNotificationSEL;
    if ([delegater respondsToSelector:hookDidReceiveRemoteNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSDictionary *) = (void(*)(id, SEL, UIApplication *, NSDictionary *))objc_msgSend;
        action (delegater, hookDidReceiveRemoteNotificationSEL, application, userInfo);
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
    SEL hookDidReceiveLocalNotificationSEL = o2spushHookDidReceiveLocalNotificationSEL;
    if ([delegater respondsToSelector:hookDidReceiveLocalNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, UILocalNotification *) = (void(*)(id, SEL, UIApplication *, UILocalNotification *))objc_msgSend;
        action (delegater, hookDidReceiveLocalNotificationSEL, application, notification);
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
    SEL hookFetchCompletionHandlerSEL = o2spushHookFetchCompletionHandlerSEL;
    if ([delegater respondsToSelector:hookFetchCompletionHandlerSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)) = (void(*)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult) ))objc_msgSend;
        action (delegater, hookFetchCompletionHandlerSEL, application, userInfo, completionHandler);
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
    SEL hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL = o2spushHookDidRegisterForRemoteNotificationsWithDeviceTokenSEL;
    if ([delegater respondsToSelector:hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSData *) = (void(*)(id, SEL, UIApplication *, NSData *))objc_msgSend;
        action (delegater, hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL, application, deviceToken);
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
    SEL hookDidFailToRegisterForRemoteNotificationsWithErrorSEL = o2spushHookDidFailToRegisterForRemoteNotificationsWithErrorSEL;
    if ([delegater respondsToSelector:hookDidFailToRegisterForRemoteNotificationsWithErrorSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSError *) = (void(*)(id, SEL, UIApplication *, NSError *))objc_msgSend;
        action (delegater, hookDidFailToRegisterForRemoteNotificationsWithErrorSEL, application, error);
    }
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
    SEL hookHandleActionLocalNotificationSEL = o2spushHookHandleActionLocalNotificationSEL;
    if ([delegater respondsToSelector:hookHandleActionLocalNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, UILocalNotification *, void (^)()))objc_msgSend;
        action (delegater, hookHandleActionLocalNotificationSEL, application, identifier, notification, completionHandler);
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
    SEL hookHandleActionLocalNotificationResponseInfoSEL = o2spushHookHandleActionLocalNotificationResponseInfoSEL;
    if ([delegater respondsToSelector:hookHandleActionLocalNotificationResponseInfoSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, hookHandleActionLocalNotificationResponseInfoSEL, application, identifier, notification, responseInfo, completionHandler);
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
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
    SEL hookHandleActionRemoteNotificationSEL = o2spushHookHandleActionRemoteNotificationSEL;
    if ([delegater respondsToSelector:hookHandleActionRemoteNotificationSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, hookHandleActionRemoteNotificationSEL, application, identifier, userInfo, completionHandler);
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
    id<UIApplicationDelegate> delegater = (id<UIApplicationDelegate>)self;
    SEL hookHandleActionRemoteNotificationResponseInfoSEL = o2spushHookHandleActionRemoteNotificationResponseInfoSEL;
    if ([delegater respondsToSelector:hookHandleActionRemoteNotificationResponseInfoSEL])
    {
        void(*action)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()) = (void(*)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()))objc_msgSend;
        action (delegater, hookHandleActionRemoteNotificationResponseInfoSEL, application, identifier, userInfo, responseInfo, completionHandler);
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

#pragma mark Hook

- (void)hookApplicationDelegate
{
    if (self.applicationDelegate)
    {
        // 获取 deviceToken application:didRegisterForRemoteNotificationsWithDeviceToken:
        SEL rawDidRegisterForRemoteNotificationsWithDeviceTokenSEL = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        if ([self.applicationDelegate respondsToSelector:rawDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
        {
            SEL hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL = o2spushHookDidRegisterForRemoteNotificationsWithDeviceTokenSEL;
            if (![self.applicationDelegate respondsToSelector:hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
            {
                // 添加方法
                class_addMethod([self.applicationDelegate class], hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL, (IMP)O2SPushDidRegisterForRemoteNotificationsWithDeviceTokenIMP, "v@:@@");
            }
            
            if ([self.applicationDelegate respondsToSelector:hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL])
            {
                //勾取方法
                Method raw = class_getInstanceMethod([self.applicationDelegate class], rawDidRegisterForRemoteNotificationsWithDeviceTokenSEL);
                Method hook = class_getInstanceMethod([self.applicationDelegate class], hookDidRegisterForRemoteNotificationsWithDeviceTokenSEL);
                IMP imp1 = method_getImplementation(raw);
                IMP imp2 = method_getImplementation(hook);
                if (imp1 != imp2)
                {
                    method_setImplementation(raw, imp2);
                    method_setImplementation(hook, imp1);
                }
                
            }
        }
        else
        {
            class_addMethod([self.applicationDelegate class], rawDidRegisterForRemoteNotificationsWithDeviceTokenSEL, (IMP)O2SPushDidRegisterForRemoteNotificationsWithDeviceTokenIMP, "v@:@@");
        }

        
        // 获取 deviceToken 失败 application:didFailToRegisterForRemoteNotificationsWithError:
        
        SEL rawDidFailToRegisterForRemoteNotificationsWithErrorSEL = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        if ([self.applicationDelegate respondsToSelector:rawDidFailToRegisterForRemoteNotificationsWithErrorSEL])
        {
            SEL hookDidFailToRegisterForRemoteNotificationsWithErrorSEL = o2spushHookDidFailToRegisterForRemoteNotificationsWithErrorSEL;
            if (![self.applicationDelegate respondsToSelector:hookDidFailToRegisterForRemoteNotificationsWithErrorSEL])
            {
                // 添加方法
                class_addMethod([self.applicationDelegate class], hookDidFailToRegisterForRemoteNotificationsWithErrorSEL, (IMP)O2SPushDidFailToRegisterForRemoteNotificationsWithErrorIMP, "v@:@@");
            }
            
            if ([self.applicationDelegate respondsToSelector:hookDidFailToRegisterForRemoteNotificationsWithErrorSEL])
            {
                //勾取方法
                Method raw = class_getInstanceMethod([self.applicationDelegate class], rawDidFailToRegisterForRemoteNotificationsWithErrorSEL);
                Method hook = class_getInstanceMethod([self.applicationDelegate class], hookDidFailToRegisterForRemoteNotificationsWithErrorSEL);
                IMP imp1 = method_getImplementation(raw);
                IMP imp2 = method_getImplementation(hook);
                if (imp1 != imp2)
                {
                    method_setImplementation(raw, imp2);
                    method_setImplementation(hook, imp1);
                }
            }
        }
        else
        {
            class_addMethod([self.applicationDelegate class], rawDidFailToRegisterForRemoteNotificationsWithErrorSEL, (IMP)O2SPushDidFailToRegisterForRemoteNotificationsWithErrorIMP, "v@:@@");
        }
        
        //收到本地消息 application:didReceiveLocalNotification:  [iOS 10以前本地通知]
        SEL rawDidReceiveLocalNotificationSEL = @selector(application:didReceiveLocalNotification:);
        if ([self.applicationDelegate respondsToSelector:rawDidReceiveLocalNotificationSEL])
        {
            SEL hookDidReceiveLocalNotificationSEL = o2spushHookDidReceiveLocalNotificationSEL;
            if (![self.applicationDelegate respondsToSelector:hookDidReceiveLocalNotificationSEL])
            {
                // 添加方法
                class_addMethod([self.applicationDelegate class], hookDidReceiveLocalNotificationSEL, (IMP)O2SPushDidReceiveLocalNotificationIMP, "v@:@@");
            }
            
            if ([self.applicationDelegate respondsToSelector:hookDidReceiveLocalNotificationSEL])
            {
                //勾取方法
                Method raw = class_getInstanceMethod([self.applicationDelegate class], rawDidReceiveLocalNotificationSEL);
                Method hook = class_getInstanceMethod([self.applicationDelegate class], hookDidReceiveLocalNotificationSEL);
                IMP imp1 = method_getImplementation(raw);
                IMP imp2 = method_getImplementation(hook);
                if (imp1 != imp2)
                {
                    method_setImplementation(raw, imp2);
                    method_setImplementation(hook, imp1);
                }
            }
        }
        else
        {
            // 直接添加handleOpenURL方法
            class_addMethod([self.applicationDelegate class], rawDidReceiveLocalNotificationSEL, (IMP)O2SPushDidReceiveLocalNotificationIMP, "v@:@@");
        }
        
        //收到远程消息 application:didReceiveRemoteNotification: [iOS 6 以前远程通知]
        SEL rawDidReceiveRemoteNotificationSEL = @selector(application:didReceiveRemoteNotification:);
        if ([self.applicationDelegate respondsToSelector:rawDidReceiveRemoteNotificationSEL])
        {
            SEL hookDidReceiveRemoteNotificationSEL = o2spushHookDidReceiveRemoteNotificationSEL;
            if (![self.applicationDelegate respondsToSelector:hookDidReceiveRemoteNotificationSEL])
            {
                // 添加方法
                class_addMethod([self.applicationDelegate class], hookDidReceiveRemoteNotificationSEL, (IMP)O2SPushDidReceiveRemoteNotificationIMP, "v@:@@");
            }
            
            if ([self.applicationDelegate respondsToSelector:hookDidReceiveRemoteNotificationSEL])
            {
                //勾取方法
                Method raw = class_getInstanceMethod([self.applicationDelegate class], rawDidReceiveRemoteNotificationSEL);
                Method hook = class_getInstanceMethod([self.applicationDelegate class], hookDidReceiveRemoteNotificationSEL);
                IMP imp1 = method_getImplementation(raw);
                IMP imp2 = method_getImplementation(hook);
                if (imp1 != imp2)
                {
                    method_setImplementation(raw, imp2);
                    method_setImplementation(hook, imp1);
                }
            }
        }
        else
        {
            // 直接添加handleOpenURL方法
            class_addMethod([self.applicationDelegate class], rawDidReceiveRemoteNotificationSEL, (IMP)O2SPushDidReceiveRemoteNotificationIMP, "v@:@@");
        }
        
        //hook - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler [iOS 10 以前，6以后远程通知]
        SEL rawFetchCompletionHandlerSEL = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        if ([self.applicationDelegate respondsToSelector:rawFetchCompletionHandlerSEL])
        {
            SEL hookFetchCompletionHandlerSEL = o2spushHookFetchCompletionHandlerSEL;
            if (![self.applicationDelegate respondsToSelector:hookFetchCompletionHandlerSEL])
            {
                // 添加方法
                class_addMethod([self.applicationDelegate class], hookFetchCompletionHandlerSEL, (IMP)O2SPushFetchCompletionHandlerIMP, "v@:@@@");
            }
            
            if ([self.applicationDelegate respondsToSelector:hookFetchCompletionHandlerSEL])
            {
                //勾取方法
                Method raw = class_getInstanceMethod([self.applicationDelegate class], rawFetchCompletionHandlerSEL);
                Method hook = class_getInstanceMethod([self.applicationDelegate class], hookFetchCompletionHandlerSEL);
                IMP imp1 = method_getImplementation(raw);
                IMP imp2 = method_getImplementation(hook);
                if (imp1 != imp2)
                {
                    method_setImplementation(raw, imp2);
                    method_setImplementation(hook, imp1);
                }
            }
        }
        else
        {
            // 直接添加方法
            class_addMethod([self.applicationDelegate class], rawFetchCompletionHandlerSEL, (IMP)O2SPushFetchCompletionHandlerIMP, "v@:@@@");
        }
        
        [self hookApplicationDelegateWithHandAction];
    }
}

- (void)hookApplicationDelegateWithHandAction
{
    
    SEL rawHandleActionLocalNotificationSEL = @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:);
    if ([self.applicationDelegate respondsToSelector:rawHandleActionLocalNotificationSEL])
    {
        SEL hookHandleActionLocalNotificationSEL = o2spushHookHandleActionLocalNotificationSEL;
        if (![self.applicationDelegate respondsToSelector:hookHandleActionLocalNotificationSEL])
        {
            // 添加方法
            class_addMethod([self.applicationDelegate class], hookHandleActionLocalNotificationSEL, (IMP)O2SPushHandActionLocalCompletionHandlerIMP, "v@:@@@@");
        }
        
        if ([self.applicationDelegate respondsToSelector:hookHandleActionLocalNotificationSEL])
        {
            //勾取方法
            Method raw = class_getInstanceMethod([self.applicationDelegate class], rawHandleActionLocalNotificationSEL);
            Method hook = class_getInstanceMethod([self.applicationDelegate class], hookHandleActionLocalNotificationSEL);
            IMP imp1 = method_getImplementation(raw);
            IMP imp2 = method_getImplementation(hook);
            if (imp1 != imp2)
            {
                method_setImplementation(raw, imp2);
                method_setImplementation(hook, imp1);
            }
            
        }
    }
    else
    {
        class_addMethod([self.applicationDelegate class], rawHandleActionLocalNotificationSEL, (IMP)O2SPushHandActionLocalCompletionHandlerIMP, "v@:@@@@");
    }
    
    SEL rawHandleActionLocalNotificationResponseInfoSEL = @selector(application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:);
    if ([self.applicationDelegate respondsToSelector:rawHandleActionLocalNotificationResponseInfoSEL])
    {
        SEL hookHookHandleActionLocalNotificationResponseInfoSEL = o2spushHookHandleActionLocalNotificationResponseInfoSEL;
        if (![self.applicationDelegate respondsToSelector:hookHookHandleActionLocalNotificationResponseInfoSEL])
        {
            // 添加方法
            class_addMethod([self.applicationDelegate class], hookHookHandleActionLocalNotificationResponseInfoSEL, (IMP)O2SPushHandActionLocalResponseInfoCompletionHandlerIMP, "v@:@@@@@");
        }
        
        if ([self.applicationDelegate respondsToSelector:hookHookHandleActionLocalNotificationResponseInfoSEL])
        {
            //勾取方法
            Method raw = class_getInstanceMethod([self.applicationDelegate class], rawHandleActionLocalNotificationResponseInfoSEL);
            Method hook = class_getInstanceMethod([self.applicationDelegate class], hookHookHandleActionLocalNotificationResponseInfoSEL);
            IMP imp1 = method_getImplementation(raw);
            IMP imp2 = method_getImplementation(hook);
            if (imp1 != imp2)
            {
                method_setImplementation(raw, imp2);
                method_setImplementation(hook, imp1);
            }
            
        }
    }
    else
    {
        class_addMethod([self.applicationDelegate class], rawHandleActionLocalNotificationResponseInfoSEL, (IMP)O2SPushHandActionLocalResponseInfoCompletionHandlerIMP, "v@:@@@@@");
    }
    
    
    
    SEL rawHandleActionRemoteNotificationSEL = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    if ([self.applicationDelegate respondsToSelector:rawHandleActionRemoteNotificationSEL])
    {
        SEL hookHandleActionRemoteNotificationSEL = o2spushHookHandleActionRemoteNotificationSEL;
        if (![self.applicationDelegate respondsToSelector:hookHandleActionRemoteNotificationSEL])
        {
            // 添加方法
            class_addMethod([self.applicationDelegate class], hookHandleActionRemoteNotificationSEL, (IMP)O2SPushHandActionRemoteCompletionHandlerIMP, "v@:@@@@");
        }
        
        if ([self.applicationDelegate respondsToSelector:hookHandleActionRemoteNotificationSEL])
        {
            //勾取方法
            Method raw = class_getInstanceMethod([self.applicationDelegate class], rawHandleActionRemoteNotificationSEL);
            Method hook = class_getInstanceMethod([self.applicationDelegate class], hookHandleActionRemoteNotificationSEL);
            IMP imp1 = method_getImplementation(raw);
            IMP imp2 = method_getImplementation(hook);
            if (imp1 != imp2)
            {
                method_setImplementation(raw, imp2);
                method_setImplementation(hook, imp1);
            }
            
        }
    }
    else
    {
        class_addMethod([self.applicationDelegate class], rawHandleActionRemoteNotificationSEL, (IMP)O2SPushHandActionRemoteCompletionHandlerIMP, "v@:@@@@");
    }
    
    SEL rawHandleActionRemoteNotificationResponseInfoSEL = @selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:);
    if ([self.applicationDelegate respondsToSelector:rawHandleActionRemoteNotificationResponseInfoSEL])
    {
        SEL hookHookHandleActionRemoteNotificationResponseInfoSEL = o2spushHookHandleActionRemoteNotificationResponseInfoSEL;
        if (![self.applicationDelegate respondsToSelector:hookHookHandleActionRemoteNotificationResponseInfoSEL])
        {
            // 添加方法
            class_addMethod([self.applicationDelegate class], hookHookHandleActionRemoteNotificationResponseInfoSEL, (IMP)O2SPushHandActionRemoteResponseInfoCompletionHandlerIMP, "v@:@@@@@");
        }
        
        if ([self.applicationDelegate respondsToSelector:hookHookHandleActionRemoteNotificationResponseInfoSEL])
        {
            //勾取方法
            Method raw = class_getInstanceMethod([self.applicationDelegate class], rawHandleActionRemoteNotificationResponseInfoSEL);
            Method hook = class_getInstanceMethod([self.applicationDelegate class], hookHookHandleActionRemoteNotificationResponseInfoSEL);
            IMP imp1 = method_getImplementation(raw);
            IMP imp2 = method_getImplementation(hook);
            if (imp1 != imp2)
            {
                method_setImplementation(raw, imp2);
                method_setImplementation(hook, imp1);
            }
            
        }
    }
    else
    {
        class_addMethod([self.applicationDelegate class], rawHandleActionRemoteNotificationResponseInfoSEL, (IMP)O2SPushHandActionRemoteResponseInfoCompletionHandlerIMP, "v@:@@@@@");
    }
}

@end
