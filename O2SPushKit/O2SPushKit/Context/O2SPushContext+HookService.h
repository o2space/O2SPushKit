//
//  O2SPushContext+HookService.h
//  O2SPushKit
//
//  Created by wkx on 2020/5/30.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushContext.h"

extern const SEL o2spushHookHandleActionLocalNotificationSEL;
extern const SEL o2spushHookHandleActionLocalNotificationResponseInfoSEL;
extern const SEL o2spushHookHandleActionRemoteNotificationSEL;
extern const SEL o2spushHookHandleActionRemoteNotificationResponseInfoSEL;

@interface O2SPushContext (HookService)

- (void)PublicSendRawO2SPush:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

- (void)PublicSendRawO2SPush:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

- (void)PublicSendRawO2SPushHand:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application actionIdentifier:(NSString *)actionIdentifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler;

- (void)PublicSendRawO2SPushHand:(id<UIApplicationDelegate>)applicationDelegate application:(UIApplication *)application actionIdentifier:(NSString *)actionIdentifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler;

/**
 勾取ApplicationDeleagte
 */
- (void)hookApplicationDelegate;

/**
 保存用户设置的 UNDelegate
 */
- (void)o2spushSetUNDelegate:(id)delegate;

@end

