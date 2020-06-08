//
//  O2SPushContext.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushContext.h"
#import "O2SPushContext+HookService.h"
#import "O2SPushContext+Other.h"
#import "O2SPushNotificationContent.h"
#import "O2SPushNotificationContent+Private.h"
#import "O2SPushNotificationRequest.h"
#import "O2SPushNotificationMessage.h"
#import "O2SPushNotificationMessage+Private.h"
#import "O2SPushDevice.h"
#import "O2SPushNotificationConfiguration+Private.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>


// iOS10以下添加本地通知时userInfo中加入标识如：userInfo[O2SPushIdentifierKey]=identifier,根据此标识进行删除或查找。
NSString *const O2SPushIdentifierKey = @"O2SPushIdentifier";

NSString *const O2SPushDidReceiveMessageNotification = @"O2SPushDidReceiveMessageNotification";

NSString *const O2SPushDidRegisterRemoteNotification = @"O2SPushDidRegisterRemoteNotification";
NSString *const O2SPushFailedRegisterRemoteNotification = @"O2SPushFailedRegisterRemoteNotification";

NSString *const O2SPushCommandClearBadge = @"O2SPush_Command_ClearBadge";

@interface O2SPushContext ()

@property (nonatomic, strong) O2SPushNotificationConfiguration *configuration;
@property (nonatomic, assign) O2SPushAuthorizationOptions foregroundType;

@end

@implementation O2SPushContext

+ (instancetype)currentContext
{
    static O2SPushContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[O2SPushContext alloc] init];
        [context addObserver];
    });
    return context;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _foregroundType = O2SPushAuthorizationOptionAlert | O2SPushAuthorizationOptionBadge | O2SPushAuthorizationOptionSound;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addObserver
{
    //监听应用启动
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    //监听用户退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    //监听用户回到前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    //监听程序被杀死
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminateNotification)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

#pragma mark - Observer
//监听应用启动
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    //    id localNoti = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    //    id remoteNoti = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    /// 应用杀死，通知栏本地通知普通点击，由于iOS10之前版本，点击本地通知无法通过application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification获取
    if (notification.userInfo && [O2SPushDevice versionCompare:@"10.0"] < 0)
    {
        id localNoti = notification.userInfo[UIApplicationLaunchOptionsLocalNotificationKey];
        
        if (localNoti && [localNoti isKindOfClass:UILocalNotification.class])
        {
            [self didReceiveLocalNotification:localNoti];
        }
    }

}
//监听用户退到后台
- (void)applicationDidEnterBackground
{
    
}
//监听用户回到前台
- (void)applicationWillEnterForeground
{
    
}
//监听程序被杀死
- (void)applicationWillTerminateNotification
{
    
}

#pragma mark - Setter

- (void)setApplicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
{
    if (!_appDelegates)
    {
        _appDelegates = [NSMutableArray array];
    }
    
    Class delegateClass = [applicationDelegate class];
    
    BOOL hasHooked = NO;
    
    for (Class obj in _appDelegates)
    {
        if ([applicationDelegate isKindOfClass:obj])
        {
            hasHooked = YES;
            break;
        }
    }
    
    if (delegateClass && !hasHooked)
    {
        _applicationDelegate = applicationDelegate;
        [_appDelegates addObject:delegateClass];
        [self hookApplicationDelegate];
    }
    
//    if (applicationDelegate != nil)
//    {
//        if (_applicationDelegate != applicationDelegate)
//        {
//            _applicationDelegate = applicationDelegate;
//
//            [self hookApplicationDelegate];
//        }
//    }
}

- (void)setUnDelegate:(id)unDelegate
{
    if (unDelegate != nil && unDelegate != [O2SPushContext currentContext])
    {
        _unDelegate = unDelegate;
    }
}

#pragma mark - Protect

- (void)registerForRemoteNotification:(O2SPushNotificationConfiguration *)configuration
{
    self.configuration = configuration;
    [self _registerForRemoteNotification];
}

- (void)unregisterForRemoteNotification
{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}

- (void)setupForegroundNotificationOptions:(O2SPushAuthorizationOptions)type
{
    self.foregroundType = type;
}

- (void)requestNotificationAuthorizationStatus:(void (^)(O2SPushAuthorizationStatus status))handler
{
    //权限的获取
    if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
    {
        // iOS10 以上
        Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
        SEL currentNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
        id (*userNotificationCenterAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
        id center = userNotificationCenterAction(userNotificationCenterCls, currentNotificationCenterSEL);

        SEL getNotificationSettingsSEL = NSSelectorFromString(@"getNotificationSettingsWithCompletionHandler:");
        void (*getNotificationSettingsAction) (id, SEL, id) = (void (*) (id, SEL, id)) objc_msgSend;
        getNotificationSettingsAction(center, getNotificationSettingsSEL, ^(id _Nonnull settings){

            SEL authorizationStatusSEL = NSSelectorFromString(@"authorizationStatus");
            NSInteger (*authorizationStatusAction) (id, SEL) = (NSInteger (*) (id, SEL)) objc_msgSend;
            NSInteger status = authorizationStatusAction(settings, authorizationStatusSEL);
            if (handler)
            {
                handler(status);
            }
        });
    }
    else
    {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        NSInteger status = 0;
        if (UIUserNotificationTypeNone == settings.types)
        {
            status = 0;
        }
        else
        {
            status = 2;
        }
        
        if (handler)
        {
            handler(status);
        }
    }
}

- (void)addLocalNotification:(O2SPushNotificationRequest *)request
                     handler:(void (^) (id result, NSError *error))handler
{
    [self _addLocalNotification:request handler:handler];
}

- (void)removeNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatuses:(O2SPushNotificationRequestStatusOptions)requestStatuses;
{
    [self _removeNotificationWithIdentifiers:identifiers requestStatuses:requestStatuses];
}

- (void)findNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatus:(O2SPushNotificationRequestStatusOptions)requestStatus
                                handler:(void (^) (NSArray *result, NSError *error))handler
{
    [self _findNotificationWithIdentifiers:identifiers requestStatus:requestStatus handler:handler];
}

#pragma mark - Hook UIAppDelegate 相关处理

/// 注册远程通知后，厂商(APNS)DeviceToken回调成功
/// @param deviceToken .
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenStr = [O2SPushDevice hexStringByData:deviceToken];
    DebugLogWithLevel(2,@"deviceToken:%@",deviceTokenStr);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidRegisterRemoteNotification
                                                            object:deviceToken
                                                          userInfo:@{@"deviceToken":deviceTokenStr}];
    });
}

/// 注册远程通知后，厂商(APNS)DeviceToken回调失败
/// @param error .
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DebugLog(@"%@",error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushFailedRegisterRemoteNotification object:error];
    });
}

/// 1. 静默通知：前台后台都能唤醒，进入回调。「系统杀死可唤醒，开发者手动杀死进程，不能唤醒」[目前 iOS 所有静默通知回调都在这里]
/// 2. iOS10以下，应用程序前台态：收到远程通知
///             应用程序后台态：远程通知点击通知栏回调
/// @param userInfo .
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DebugLog(@"%@",userInfo);

    
    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    message.notificationMessageType = O2SPushNotificationMessageTypeAPNs;
    if ([userInfo isKindOfClass:[NSDictionary class]])
    {
        O2SPushNotificationContent *O2SPushContent = [O2SPushNotificationContent apnsNotificationWithDict:[userInfo copy]];
        message.content = O2SPushContent;
//        if (message.content.contentAvailable && message.content.badge == nil && message.content.category == nil && message.content.sound == nil)//在apnsNotificationWithDict判断
//        {
//            message.content.silentPush = YES;
//        }
        
    }
    
    //当程序在后台或者杀死时，点击通知栏
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {// 点击通知
        if (message.content && !message.content.silentPush)
        {
            //获取应用当前角标-1
            NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
            [self setBadge:badge];
            message.notificationMessageType = O2SPushNotificationMessageTypeAPNsClicked;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });
}

/// iOS10以下
/// 应用程序前台态：收到本地通知
/// 应用程序后台态：本地通知点击通知栏回调
/// @param notification .
- (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    message.notificationMessageType = O2SPushNotificationMessageTypeLocal;
    
    O2SPushNotificationContent *O2SPushContent = [[O2SPushNotificationContent alloc] init];
    NSString *identifier = nil;
    //获取本地通知额外字段
    if ([notification.userInfo isKindOfClass:[NSDictionary class]])
    {
        O2SPushContent.userInfo = [notification.userInfo copy];
        identifier = notification.userInfo[O2SPushIdentifierKey];
    }
    
    if ([O2SPushDevice versionCompare:@"8.2"] >= 0)
    {
        O2SPushContent.title = notification.alertTitle;
    }
    O2SPushContent.sound = notification.soundName;
    O2SPushContent.category = notification.category;
    O2SPushContent.body = notification.alertBody;
    O2SPushContent.badge = @(notification.applicationIconBadgeNumber);
    if (identifier != nil)
    {
        message.identifier = identifier;
    }
    message.content = O2SPushContent;
    
    //当程序在后台或者杀死时，点击通知栏
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        //获取应用当前角标-1
        NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
        [self setBadge:badge];
        
        message.notificationMessageType = O2SPushNotificationMessageTypeLocalClicked;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });
}


/// iOS8-iOS10 通知栏远程通知
/// @param userInfo .
/// @param responseInfo .
- (void)handActionWithIdentifier:(NSString *)actionIdentifier forRemoteNotification:(NSDictionary *)userInfo ResponseInfo:(NSDictionary *)responseInfo
{
    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    message.notificationMessageType = O2SPushNotificationMessageTypeAPNsClicked;
    if ([userInfo isKindOfClass:[NSDictionary class]])
    {
        O2SPushNotificationContent *O2SPushContent = [O2SPushNotificationContent apnsNotificationWithDict:[userInfo copy]];
        message.content = O2SPushContent;
        
        O2SPushContent.actionIdentifier = actionIdentifier;
        if (actionIdentifier && responseInfo)
        {
            NSString *input = responseInfo[UIUserNotificationActionResponseTypedTextKey];
            O2SPushContent.actionUserText = input;
        }
    }
        
    //获取应用当前角标-1
    NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
    [self setBadge:badge];
            
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });
}

- (void)handActionWithIdentifier:(NSString *)actionIdentifier forLocalNotification:(UILocalNotification *)notification ResponseInfo:(NSDictionary *)responseInfo
{
    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    message.notificationMessageType = O2SPushNotificationMessageTypeLocalClicked;
    
    O2SPushNotificationContent *O2SPushContent = [[O2SPushNotificationContent alloc] init];
    NSString *identifier = nil;
    //获取本地通知额外字段
    if ([notification.userInfo isKindOfClass:[NSDictionary class]])
    {
        O2SPushContent.userInfo = [notification.userInfo copy];
        identifier = notification.userInfo[O2SPushIdentifierKey];
    }
    
    if ([O2SPushDevice versionCompare:@"8.2"] >= 0)
    {
        O2SPushContent.title = notification.alertTitle;
    }
    O2SPushContent.sound = notification.soundName;
    O2SPushContent.category = notification.category;
    O2SPushContent.body = notification.alertBody;
    O2SPushContent.badge = @(notification.applicationIconBadgeNumber);
    if (identifier != nil)
    {
        message.identifier = identifier;
    }
    
    O2SPushContent.actionIdentifier = actionIdentifier;
    if (actionIdentifier && responseInfo)
    {
        NSString *input = responseInfo[UIUserNotificationActionResponseTypedTextKey];
        O2SPushContent.actionUserText = input;
    }
    
    message.content = O2SPushContent;
    
    
    //获取应用当前角标-1
    NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
    [self setBadge:badge];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });
}

#pragma mark - iOS10及以上 推送通知代理 UNUserNotificationCenterDelegate


/// iOS10及以上
/// 应用程序在前台：收到本地或者远程通知
/// @param center UNUserNotificationCenter
/// @param notification UNNotification
/// @param completionHandler void(^)(UNNotificationPresentationOptions options)
- (void)userNotificationCenter:(id)center willPresentNotification:(id)notification withCompletionHandler:(void (^)(NSUInteger))completionHandler
{
    Class NotificationTriggerClass = NSClassFromString(@"UNPushNotificationTrigger");
    SEL triggerSEL = NSSelectorFromString(@"trigger");
    SEL requestSEL = NSSelectorFromString(@"request");
    SEL contentSEL = NSSelectorFromString(@"content");
    SEL userInfoSEL = NSSelectorFromString(@"userInfo");

    static id (*sendMessage) (id, SEL) = (id (*) (id, SEL))objc_msgSend;


    id request = sendMessage(notification, requestSEL);
    id content = sendMessage(request, contentSEL);

    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    O2SPushNotificationContent *O2SPushContent = [[O2SPushNotificationContent alloc] init];

    SEL titleSEL = NSSelectorFromString(@"title");
    O2SPushContent.title = sendMessage(content, titleSEL);

    SEL subtitleSEL = NSSelectorFromString(@"subtitle");
    O2SPushContent.subTitle = sendMessage(content, subtitleSEL);

    SEL bodySEL = NSSelectorFromString(@"body");
    O2SPushContent.body = sendMessage(content, bodySEL);

//    //不处理 未提供获取声音名称
//    SEL soundSEL = NSSelectorFromString(@"sound");
//    if ([content respondsToSelector:soundSEL])
//    {
//        id sound  = sendMessage(content, soundSEL);
//        Class notificationSoundCls = NSClassFromString(@"UNNotificationSound");
//        if ([sound isKindOfClass:notificationSoundCls])
//        {
//
//        }
//    }

    SEL badgeSEL = NSSelectorFromString(@"badge");
    O2SPushContent.badge = sendMessage(content, badgeSEL);

    SEL categorySEL = NSSelectorFromString(@"categoryIdentifier");
    O2SPushContent.category = sendMessage(content, categorySEL);

    SEL attachmentsSEL = NSSelectorFromString(@"attachments");
    O2SPushContent.attachments = sendMessage(content, attachmentsSEL);

    SEL threadIdentifierSEL = NSSelectorFromString(@"threadIdentifier");
    O2SPushContent.threadIdentifier = sendMessage(content, threadIdentifierSEL);

    SEL launchImageNameSEL = NSSelectorFromString(@"launchImageName");
    O2SPushContent.launchImageName = sendMessage(content, launchImageNameSEL);

    if ([O2SPushDevice versionCompare:@"12.0"] >= 0)
    {
        SEL summaryArgumentSEL = NSSelectorFromString(@"summaryArgument");
        SEL summaryArgumentCountSEL = NSSelectorFromString(@"summaryArgumentCount");
        if ([content respondsToSelector:summaryArgumentSEL])
        {
            O2SPushContent.summaryArgument = sendMessage(content, summaryArgumentSEL);
        }
        if ([content respondsToSelector:summaryArgumentCountSEL])
        {
            NSUInteger (*getPropertyNSUIntegerAction) (id, SEL) = (NSUInteger (*) (id, SEL))objc_msgSend;
            O2SPushContent.summaryArgumentCount = getPropertyNSUIntegerAction(content, summaryArgumentCountSEL);
        }
    }

    if ([O2SPushDevice versionCompare:@"13.0"] >= 0)
    {
        SEL targetContentIdentifierSEL =  NSSelectorFromString(@"targetContentIdentifier");
        if ([content respondsToSelector:targetContentIdentifierSEL])
        {
            O2SPushContent.targetContentIdentifier = sendMessage(content, targetContentIdentifierSEL);
        }
    }

    if ([content respondsToSelector:userInfoSEL])
    {
        id userInfo = sendMessage(content, userInfoSEL);
        if ([userInfo isKindOfClass:[NSDictionary class]])
        {
            O2SPushContent.userInfo = userInfo;
        }
    }

    SEL identifierSEL = NSSelectorFromString(@"identifier");
    if ([request respondsToSelector:identifierSEL])
    {
        message.identifier = sendMessage(request, identifierSEL);
    }

    message.content = O2SPushContent;

    id trigger = sendMessage(sendMessage(notification, requestSEL), triggerSEL);

    if ([trigger isKindOfClass:NotificationTriggerClass])
    { // 远程
        message.notificationMessageType = O2SPushNotificationMessageTypeAPNs;
    }
    else
    { // 本地
       message.notificationMessageType = O2SPushNotificationMessageTypeLocal;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });

    // 派发
    if (O2SPushContext.currentContext.unDelegate && [O2SPushContext.currentContext.unDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)])
    {
        [O2SPushContext.currentContext.unDelegate userNotificationCenter:center
                                                 willPresentNotification:notification
                                                   withCompletionHandler:completionHandler];
    }
    else
    {
        if (message.notificationMessageType == O2SPushNotificationMessageTypeAPNs && self.applicationDelegate)
        {
            [self PublicSendRawO2SPush:self.applicationDelegate application:[UIApplication sharedApplication] didReceiveRemoteNotification:message.content.userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            }];
        }
        else if (message.notificationMessageType == O2SPushNotificationMessageTypeLocal && self.applicationDelegate)
        {
//            Class concreteLNCls = NSClassFromString(@"UIConcreteLocalNotification");
//            if (![concreteLNCls isKindOfClass:object_getClass(UILocalNotification.class)])
//            {
//                return;
//            }
//            SEL newSEL = NSSelectorFromString(@"new");
//            if (![concreteLNCls respondsToSelector:newSEL])
//            {
//                return;
//            }
//            id concreteNotification = [concreteLNCls performSelector:newSEL];
//            if (!concreteNotification)
//            {
//                return;
//            }
            
            UILocalNotification *notification = [UILocalNotification new];//concreteNotification;
            BOOL repeats = NO;
            if (trigger)
            {
                static BOOL (*propertyForBool) (id, SEL) = (BOOL (*) (id, SEL))objc_msgSend;
                SEL repeatsSEL = NSSelectorFromString(@"repeats");
                if ([trigger respondsToSelector:repeatsSEL])
                {
                    repeats = propertyForBool(trigger, repeatsSEL);
                }
            }
            
            if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNTimeIntervalNotificationTrigger")])
            {
                notification.fireDate = [NSDate date];
//                SEL nextFireDateSEL = NSSelectorFromString(@"nextFireDateForLastFireDate:");
//                if ([concreteNotification respondsToSelector:nextFireDateSEL])
//                {
//                    static void (*sendMessageArg) (id, SEL, id) = (void (*) (id, SEL, id))objc_msgSend;
//                    sendMessageArg(concreteNotification, nextFireDateSEL, [NSDate date]);
//                }
                notification.repeatInterval = 0;
            }
            else if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNCalendarNotificationTrigger")])
            {
                NSDateComponents *dateComponents;
                SEL dateComponentsSEL = NSSelectorFromString(@"dateComponents");
                if ([trigger respondsToSelector:dateComponentsSEL])
                {
                    dateComponents = sendMessage(trigger, dateComponentsSEL);
                    notification.fireDate = dateComponents.date;
                    notification.timeZone = dateComponents.timeZone;
//                    SEL nextFireDateSEL = NSSelectorFromString(@"nextFireDateAfterDate:localTimeZone:");
//                    if ([concreteNotification respondsToSelector:nextFireDateSEL])
//                    {
//                        static void (*sendMessageArg) (id, SEL, id, id) = (void (*) (id, SEL, id, id))objc_msgSend;
//                        sendMessageArg(concreteNotification, nextFireDateSEL, dateComponents.date, dateComponents.timeZone);
//                    }
                    
                    notification.repeatInterval = 0;
                }
            }
            else if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNLocationNotificationTrigger")])
            {
                id region;
                SEL regionSEL = NSSelectorFromString(@"region");
                if ([trigger respondsToSelector:regionSEL])
                {
                    region = sendMessage(trigger, regionSEL);
                    notification.region = region;
                    notification.regionTriggersOnce = !repeats;
                }
            }

            notification.alertBody = message.content.body;
            notification.alertLaunchImage = message.content.launchImageName;
            if ([O2SPushDevice versionCompare:@"8.2"] >= 0)
            {
                notification.alertTitle = message.content.title;
            }
            
            notification.category = message.content.category;
            notification.applicationIconBadgeNumber = message.content.badge?[message.content.badge intValue]:0;

            notification.hasAction = YES;
            notification.soundName = message.content.sound;
            notification.userInfo = message.content.userInfo;
            
            [self PublicSendRawO2SPush:self.applicationDelegate application:[UIApplication sharedApplication] didReceiveLocalNotification:notification];
        }
    }

    // 需要执行这个方法，选择是否提醒用户，有 Badge、Sound、Alert 三种类型可以设置
    if (completionHandler)
    {
        completionHandler(self.foregroundType);
    }

}


/// iOS10及以上
/// 应用程序在前台或者后台：点击通知栏回调
/// @param center UNUserNotificationCenter
/// @param response UNNotificationResponse
/// @param completionHandler void (^)(void)
- (void)userNotificationCenter:(id)center didReceiveNotificationResponse:(id)response withCompletionHandler:(void (^)(void))completionHandler
{
    Class NotificationTriggerClass = NSClassFromString(@"UNPushNotificationTrigger");
    
    SEL triggerSEL = NSSelectorFromString(@"trigger");
    
    // 收到用户的基本信息
    SEL notificationSEL = NSSelectorFromString(@"notification");
    SEL requestSEL = NSSelectorFromString(@"request");
    SEL contentSEL = NSSelectorFromString(@"content");
    SEL userInfoSEL = NSSelectorFromString(@"userInfo");
    
    static id (*sendMessage) (id, SEL) = (id (*) (id, SEL))objc_msgSend;

    
    //获取应用当前角标-1
    NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
    [self setBadge:badge];
    
    id notification = sendMessage(response, notificationSEL);
    id request = sendMessage(notification, requestSEL);
    id content = sendMessage(request,contentSEL);
        
    O2SPushNotificationMessage *message = [[O2SPushNotificationMessage alloc] init];
    O2SPushNotificationContent *O2SPushContent = [[O2SPushNotificationContent alloc] init];
                
    SEL titleSEL = NSSelectorFromString(@"title");
    O2SPushContent.title = sendMessage(content, titleSEL);
                
    SEL subtitleSEL = NSSelectorFromString(@"subtitle");
    O2SPushContent.subTitle = sendMessage(content, subtitleSEL);
                
    SEL bodySEL = NSSelectorFromString(@"body");
    O2SPushContent.body = sendMessage(content, bodySEL);
                
    //    //不处理 未提供获取声音名称
    //    SEL soundSEL = NSSelectorFromString(@"sound");
    //    if ([content respondsToSelector:soundSEL])
    //    {
    //        id sound  = sendMessage(content, soundSEL);
    //        Class notificationSoundCls = NSClassFromString(@"UNNotificationSound");
    //        if ([sound isKindOfClass:notificationSoundCls])
    //        {
    //
    //        }
    //    }
                
    SEL badgeSEL = NSSelectorFromString(@"badge");
    O2SPushContent.badge = sendMessage(content, badgeSEL);
                
    SEL categorySEL = NSSelectorFromString(@"categoryIdentifier");
    O2SPushContent.category = sendMessage(content, categorySEL);
                
    SEL attachmentsSEL = NSSelectorFromString(@"attachments");
    O2SPushContent.attachments = sendMessage(content, attachmentsSEL);
                
    SEL threadIdentifierSEL = NSSelectorFromString(@"threadIdentifier");
    O2SPushContent.threadIdentifier = sendMessage(content, threadIdentifierSEL);
                
    SEL launchImageNameSEL = NSSelectorFromString(@"launchImageName");
    O2SPushContent.launchImageName = sendMessage(content, launchImageNameSEL);
                
    if ([O2SPushDevice versionCompare:@"12.0"] >= 0)
    {
        SEL summaryArgumentSEL = NSSelectorFromString(@"summaryArgument");
        SEL summaryArgumentCountSEL = NSSelectorFromString(@"summaryArgumentCount");
        if ([content respondsToSelector:summaryArgumentSEL])
        {
            O2SPushContent.summaryArgument = sendMessage(content, summaryArgumentSEL);
        }
        if ([content respondsToSelector:summaryArgumentCountSEL])
        {
            NSUInteger (*getPropertyNSUIntegerAction) (id, SEL) = (NSUInteger (*) (id, SEL))objc_msgSend;
            O2SPushContent.summaryArgumentCount = getPropertyNSUIntegerAction(content, summaryArgumentCountSEL);
        }
    }
                
    if ([O2SPushDevice versionCompare:@"13.0"] >= 0)
    {
        SEL targetContentIdentifierSEL =  NSSelectorFromString(@"targetContentIdentifier");
        if ([content respondsToSelector:targetContentIdentifierSEL])
        {
            O2SPushContent.targetContentIdentifier = sendMessage(content, targetContentIdentifierSEL);
        }
    }
                
    if ([content respondsToSelector:userInfoSEL])
    {
        id userInfo = sendMessage(content, userInfoSEL);
        if ([userInfo isKindOfClass:[NSDictionary class]])
        {
            O2SPushContent.userInfo = userInfo;
        }
    }
        
    SEL identifierSEL = NSSelectorFromString(@"identifier");
    if ([request respondsToSelector:identifierSEL])
    {
        message.identifier = sendMessage(request, identifierSEL);
    }
    
    SEL actionIdentifierSEL = NSSelectorFromString(@"actionIdentifier");
    if ([response respondsToSelector:actionIdentifierSEL])
    {
        NSString *actionIdentifier = sendMessage(response, actionIdentifierSEL);
        if (actionIdentifier)
        {
            O2SPushContent.actionIdentifier = actionIdentifier;
            Class UNTextInputNotificationResponseCls = NSClassFromString(@"UNTextInputNotificationResponse");
            if (UNTextInputNotificationResponseCls && [response isKindOfClass:UNTextInputNotificationResponseCls])
            {
                SEL userTextSEL = NSSelectorFromString(@"userText");
                if ([response respondsToSelector:userTextSEL])
                {
                    O2SPushContent.actionUserText = sendMessage(response, userTextSEL);
                }
            }
        }
    }
    
    message.content = O2SPushContent;
        
    id trigger = sendMessage(sendMessage(notification, requestSEL), triggerSEL);
        
    if ([trigger isKindOfClass:NotificationTriggerClass])
    { // 远程
        message.notificationMessageType = O2SPushNotificationMessageTypeAPNsClicked;
    }
    else
    { // 本地
        message.notificationMessageType = O2SPushNotificationMessageTypeLocalClicked;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:O2SPushDidReceiveMessageNotification object:message];
    });
    
    if (completionHandler)
    {
        completionHandler();
    }
    
    // 派发原方法
    if (O2SPushContext.currentContext.unDelegate && [O2SPushContext.currentContext.unDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
    {
        [O2SPushContext.currentContext.unDelegate userNotificationCenter:center
                                          didReceiveNotificationResponse:response
                                                   withCompletionHandler:completionHandler];
    }
    else
    {
        if (message.notificationMessageType == O2SPushNotificationMessageTypeAPNsClicked && self.applicationDelegate)
        {
            if (message.content.actionIdentifier == nil || [message.content.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])
            {
                [self PublicSendRawO2SPushHand:self.applicationDelegate application:[UIApplication sharedApplication] actionIdentifier:nil forRemoteNotification:message.content.userInfo withResponseInfo:nil completionHandler:^{
                }];
            }
            else
            {
                NSMutableDictionary *responseInfo = nil;
                if (message.content.actionUserText)
                {
                    responseInfo = [NSMutableDictionary dictionary];
                    responseInfo[UIUserNotificationActionResponseTypedTextKey] = message.content.actionUserText;
                }
                [self PublicSendRawO2SPushHand:self.applicationDelegate application:[UIApplication sharedApplication] actionIdentifier:message.content.actionIdentifier forRemoteNotification:message.content.userInfo withResponseInfo:(responseInfo?[responseInfo copy]:nil) completionHandler:^{
                }];
            }
            
        }
        else if (message.notificationMessageType == O2SPushNotificationMessageTypeLocalClicked && self.applicationDelegate)
        {
//            Class concreteLNCls = NSClassFromString(@"UIConcreteLocalNotification");
//            if (![concreteLNCls isKindOfClass:object_getClass(UILocalNotification.class)])
//            {
//                return;
//            }
//            SEL newSEL = NSSelectorFromString(@"new");
//            if (![concreteLNCls respondsToSelector:newSEL])
//            {
//                return;
//            }
//            id concreteNotification = [concreteLNCls performSelector:newSEL];
//            if (!concreteNotification)
//            {
//                return;
//            }
        
            UILocalNotification *notification = [UILocalNotification new];//concreteNotification;
            BOOL repeats = NO;
            if (trigger)
            {
                static BOOL (*propertyForBool) (id, SEL) = (BOOL (*) (id, SEL))objc_msgSend;
                SEL repeatsSEL = NSSelectorFromString(@"repeats");
                if ([trigger respondsToSelector:repeatsSEL])
                {
                    repeats = propertyForBool(trigger, repeatsSEL);
                }
            }
            static void (*setProperty) (id, SEL, id) = (void (*) (id, SEL, id))objc_msgSend;
            if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNTimeIntervalNotificationTrigger")])
            {
                notification.fireDate = [NSDate date];
//                SEL nextFireDateSEL = NSSelectorFromString(@"nextFireDateForLastFireDate:");
//                if ([concreteNotification respondsToSelector:nextFireDateSEL])
//                {
//                    static void (*sendMessageArg) (id, SEL, id) = (void (*) (id, SEL, id))objc_msgSend;
//                    sendMessageArg(concreteNotification, nextFireDateSEL, [NSDate date]);
//                }
                
                notification.repeatInterval = 0;
            }
            else if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNCalendarNotificationTrigger")])
            {
                NSDateComponents *dateComponents;
                SEL dateComponentsSEL = NSSelectorFromString(@"dateComponents");
                if ([trigger respondsToSelector:dateComponentsSEL])
                {
                    dateComponents = sendMessage(trigger, dateComponentsSEL);
                    notification.fireDate = dateComponents.date;
                    notification.timeZone = dateComponents.timeZone;
//                    SEL nextFireDateSEL = NSSelectorFromString(@"nextFireDateAfterDate:localTimeZone:");
//                    if ([concreteNotification respondsToSelector:nextFireDateSEL])
//                    {
//                        static void (*sendMessageArg) (id, SEL, id, id) = (void (*) (id, SEL, id, id))objc_msgSend;
//                        sendMessageArg(concreteNotification, nextFireDateSEL, dateComponents.date, dateComponents.timeZone);
//                    }
                    
                    notification.repeatInterval = 0;
                }
            }
            else if (trigger && [trigger isKindOfClass:NSClassFromString(@"UNLocationNotificationTrigger")])
            {
                id region;
                SEL regionSEL = NSSelectorFromString(@"region");
                if ([trigger respondsToSelector:regionSEL])
                {
                    region = sendMessage(trigger, regionSEL);
                    notification.region = region;
                    notification.regionTriggersOnce = !repeats;
                }
            }

            notification.alertBody = message.content.body;
            notification.alertLaunchImage = message.content.launchImageName;
            if ([O2SPushDevice versionCompare:@"8.2"] >= 0)
            {
                notification.alertTitle = message.content.title;
            }
            notification.category = message.content.category;
            notification.applicationIconBadgeNumber = message.content.badge?[message.content.badge intValue]:0;

            notification.hasAction = YES;
            notification.soundName = message.content.sound;
            notification.userInfo = message.content.userInfo;

            if (message.content.actionIdentifier == nil || [message.content.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])
            {
                [self PublicSendRawO2SPushHand:self.applicationDelegate application:[UIApplication sharedApplication] actionIdentifier:nil forLocalNotification:notification withResponseInfo:nil completionHandler:^{
                }];
            }
            else
            {
                NSMutableDictionary *responseInfo = nil;
                if (message.content.actionUserText)
                {
                    responseInfo = [NSMutableDictionary dictionary];
                    responseInfo[UIUserNotificationActionResponseTypedTextKey] = message.content.actionUserText;
                }
                [self PublicSendRawO2SPushHand:self.applicationDelegate application:[UIApplication sharedApplication] actionIdentifier:message.content.actionIdentifier forLocalNotification:notification withResponseInfo:(responseInfo?[responseInfo copy]:nil) completionHandler:^{
                }];
            }
            
            
            
        }
    }
    
}

/// iOS12以后
/// @param center UNUserNotificationCenter
/// @param notification UNNotification
- (void)userNotificationCenter:(id)center openSettingsForNotification:(id)notification
{
    DebugLog(@"====== iOS12以后新增[UNUserNotificationCenter userNotificationCenter:openSettingsForNotification:] ====== ");
    // 派发原方法
    if (O2SPushContext.currentContext.unDelegate && [O2SPushContext.currentContext.unDelegate respondsToSelector:@selector(userNotificationCenter:openSettingsForNotification:)])
    {
        [O2SPushContext.currentContext.unDelegate userNotificationCenter:center
                                             openSettingsForNotification:notification];
    }
}

#pragma mark - Private

#pragma mark 远程通知

// 注册远程通知
- (void)_registerForRemoteNotification
{
    //权限的获取
    if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
    {
        // iOS10 以上
        // UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
        SEL currentNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
        id (*userNotificationCenterAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
        id center = userNotificationCenterAction(userNotificationCenterCls, currentNotificationCenterSEL);
        
        if (self.configuration.convertCategories)
        {
            //  [center setNotificationCategories:[NSSet setWithObject:configuration.categories]];
            SEL setNotificationCategoriesSEL = NSSelectorFromString(@"setNotificationCategories:");
            void (*setNotificationCategoriesAction) (id, SEL, id) = (void (*) (id, SEL, id)) objc_msgSend;
            setNotificationCategoriesAction(center, setNotificationCategoriesSEL, self.configuration.convertCategories);
        }
        
        //设置代理，必须要代理，不然无法监听通知的接收与点击事件
        //  center.delegate = self;
        [center performSelector:@selector(setDelegate:) withObject:self];
        
        //判断是否已申请通知权限
        //[center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings)
        //{
        //  if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined ||
        //      settings.authorizationStatus == UNAuthorizationStatusDenied)
        //  {
        //      //申请通知权限
        //      [center requestAuthorizationWithOptions:(UNAuthorizationOptions)configuration.types
        //                            completionHandler:^(BOOL granted, NSError * _Nullable error)
        //      {
        //          if (!error && granted)
        //          {
        //              //用户点击允许
        //          }
        //          else
        //          {
        //              //用户点击不允许
        //          };
        //      }];
        //  }
        //}];
        
//        __weak typeof(self) weakSelf = self;
        SEL getNotificationSettingsSEL = NSSelectorFromString(@"getNotificationSettingsWithCompletionHandler:");
        void (*getNotificationSettingsAction) (id, SEL, id) = (void (*) (id, SEL, id)) objc_msgSend;
        getNotificationSettingsAction(center, getNotificationSettingsSEL, ^(id _Nonnull settings){
            
            SEL authorizationStatusSEL = NSSelectorFromString(@"authorizationStatus");
            NSInteger (*authorizationStatusAction) (id, SEL) = (NSInteger (*) (id, SEL)) objc_msgSend;
            NSInteger status = authorizationStatusAction(settings, authorizationStatusSEL);
            
            if (status == 0 || status == 1)
            {
                //申请通知权限
                SEL requestAuthorizationSEL = NSSelectorFromString(@"requestAuthorizationWithOptions:completionHandler:");
                void (*requestAuthorizationAction) (id, SEL, NSInteger, id) = (void (*) (id, SEL, NSInteger, id)) objc_msgSend;
                requestAuthorizationAction(center, requestAuthorizationSEL, self.configuration.types, ^(BOOL granted, NSError * _Nullable error){
                    if (!error && granted == YES)
                    {
                        //用户点击允许
                    }
                    else
                    {
                        //用户点击不允许
                    }
                });
            }
        });
    }
    else
    {
        // iOS10 以下
        UIUserNotificationType notificationType = (UIUserNotificationType)self.configuration.types;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationType categories:(NSSet<UIUserNotificationCategory *> *)self.configuration.convertCategories];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    }
    
    // 注册远程推送
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark 添加本地推送通知

- (void)_addLocalNotification:(O2SPushNotificationRequest *)O2SPushRequest handler:(void (^) (id result, NSError *error))handler
{
    O2SPushNotificationContent *notification = O2SPushRequest.content;
    if (notification == nil)
    {
        return;
    }

    if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
    {
        // iOS10及以上
        Class contentCls = NSClassFromString(@"UNMutableNotificationContent");
        SEL contentSEL = NSSelectorFromString(@"new");
        id (*contentAction) (id, SEL) = (id (*) (id, SEL))objc_msgSend;
        id content = contentAction(contentCls, contentSEL);
        
        void (*setPropertyAction) (id, SEL, id) = (void (*) (id, SEL, id))objc_msgSend;
        
        SEL setTitle = NSSelectorFromString(@"setTitle:");
        setPropertyAction(content, setTitle, notification.title);
        
        SEL setSubtitle = NSSelectorFromString(@"setSubtitle:");
        setPropertyAction(content, setSubtitle, notification.subTitle);
        
        SEL setBody = NSSelectorFromString(@"setBody:");
        setPropertyAction(content, setBody, notification.body);
        
        SEL setUserInfo = NSSelectorFromString(@"setUserInfo:");
        setPropertyAction(content, setUserInfo, notification.userInfo);
        
        // 静默推送
        if(!notification.silentPush)
        {
            SEL setBadge = NSSelectorFromString(@"setBadge:");
            setPropertyAction(content, setBadge, notification.badge);
            
            if (notification.sound)
            {
                //  content.sound = [UNNotificationSound soundNamed:notification.sound];
                Class notificationSoundCls = NSClassFromString(@"UNNotificationSound");
                SEL soundNamedSEL = NSSelectorFromString(@"soundNamed:");
                id (*setSoundNameAction) (id, SEL, id) = (id (*) (id, SEL, id))objc_msgSend;
                id sound = setSoundNameAction(notificationSoundCls, soundNamedSEL, notification.sound);
                
                SEL setSound = NSSelectorFromString(@"setSound:");
                setPropertyAction(content, setSound, sound);
            }
            else
            {
                //  content.sound = [UNNotificationSound defaultSound];
                Class notificationSoundCls = NSClassFromString(@"UNNotificationSound");
                SEL defaultSoundSEL = NSSelectorFromString(@"defaultSound");
                id (*defaultSoundAction) (id, SEL) = (id (*) (id, SEL))objc_msgSend;
                id sound = defaultSoundAction(notificationSoundCls, defaultSoundSEL);
                
                SEL setSound = NSSelectorFromString(@"setSound:");
                setPropertyAction(content, setSound, sound);
            }
            
            
            // 用于添加 category 的标识
            if (notification.category)
            {
                //  content.categoryIdentifier = notification.category;
                SEL setCategoryIdentifier = NSSelectorFromString(@"setCategoryIdentifier:");
                setPropertyAction(content, setCategoryIdentifier, notification.category);
            }
        }
        
        if (notification.threadIdentifier)
        {
            //content.threadIdentifier = notification.threadIdentifier;
            SEL setThreadIdentifier = NSSelectorFromString(@"setThreadIdentifier:");
            setPropertyAction(content, setThreadIdentifier, notification.threadIdentifier);
        }
        
        if (notification.launchImageName.length > 0)
        {
            //content.launchImageName = notification.launchImageName;
            SEL setLaunchImageName = NSSelectorFromString(@"setLaunchImageName:");
            setPropertyAction(content, setLaunchImageName, notification.launchImageName);
        }
        
        if ([O2SPushDevice versionCompare:@"12.0"] >= 0)
        {
            if (notification.summaryArgument)
            {
                //content.summaryArgument = notification.summaryArgument;
                SEL setSummaryArgument = NSSelectorFromString(@"setSummaryArgument:");
                setPropertyAction(content, setSummaryArgument, notification.summaryArgument);
                
                //content.summaryArgumentCount = notification.summaryArgumentCount;
                SEL setSummaryArgumentCount = NSSelectorFromString(@"setSummaryArgumentCount:");
                void (*setPropertyNSUIntegerAction) (id, SEL, NSUInteger) = (void (*) (id, SEL, NSUInteger))objc_msgSend;
                setPropertyNSUIntegerAction(content, setSummaryArgumentCount, notification.summaryArgumentCount);
            }
        }
        
        if ([O2SPushDevice versionCompare:@"13.0"] >= 0)
        {
            if (notification.targetContentIdentifier)
            {
                //content.targetContentIdentifier = notification.targetContentIdentifier;
                SEL setTargetContentIdentifier = NSSelectorFromString(@"setTargetContentIdentifier:");
                setPropertyAction(content, setTargetContentIdentifier, notification.targetContentIdentifier);
            }
            
        }
        
        
        id trigger = nil;
        if(O2SPushRequest.trigger && O2SPushRequest.trigger.region) //UNLocationNotificationTrigger
        {
            
            BOOL repeats = O2SPushRequest.trigger.repeat;
            //设置触发条件
            //UNLocationNotificationTrigger *locationTrigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:NO];
            Class locationNotificationTriggerCls = NSClassFromString(@"UNLocationNotificationTrigger");
            SEL locationNotificationTriggerSEL = NSSelectorFromString(@"triggerWithRegion:repeats:");
            id (*locationNotificationTriggerAction) (id, SEL, id, BOOL) = (id (*) (id, SEL, id, BOOL))objc_msgSend;
            id locationTrigger = locationNotificationTriggerAction(locationNotificationTriggerCls, locationNotificationTriggerSEL, O2SPushRequest.trigger.region, repeats);
            
            trigger = locationTrigger;
            
        }
        else if(O2SPushRequest.trigger && O2SPushRequest.trigger.dateComponents) //UNCalendarNotificationTrigger
        {
            BOOL repeats = O2SPushRequest.trigger.repeat;
            // 设置触发条件
            // UNCalendarNotificationTrigger *calendarTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:date repeats:NO];
            
            Class calendarNotificationTriggerCls = NSClassFromString(@"UNCalendarNotificationTrigger");
            SEL calendarNotificationTriggerSEL = NSSelectorFromString(@"triggerWithDateMatchingComponents:repeats:");
            id (*calendarNotificationTriggerAction) (id, SEL, id, BOOL) = (id (*) (id, SEL, id, BOOL))objc_msgSend;
            id calendarTrigger = calendarNotificationTriggerAction(calendarNotificationTriggerCls, calendarNotificationTriggerSEL, O2SPushRequest.trigger.dateComponents, repeats);
            
            trigger = calendarTrigger;
        }
        else //UNTimeIntervalNotificationTrigger
        {
            BOOL repeats = NO;
            NSTimeInterval interval = 0.1f;
            if (O2SPushRequest.trigger && O2SPushRequest.trigger.timeInterval != 0 )
            {
                interval = O2SPushRequest.trigger.timeInterval;
                repeats = O2SPushRequest.trigger.repeat;
            }

            // UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1f repeats:NO];
            Class timeIntervalNotificationTriggerCls = NSClassFromString(@"UNTimeIntervalNotificationTrigger");
            SEL triggerWithTimeIntervalSEL = NSSelectorFromString(@"triggerWithTimeInterval:repeats:");
            id (*triggerWithTimeIntervalAction) (id, SEL, NSTimeInterval, BOOL) = (id (*) (id, SEL, NSTimeInterval, BOOL)) objc_msgSend;
            id timeTrigger = triggerWithTimeIntervalAction(timeIntervalNotificationTriggerCls, triggerWithTimeIntervalSEL, interval, repeats);
            
            trigger = timeTrigger;
                
        }

        NSString *identifier = (O2SPushRequest.requestIdentifier.length > 0 ? O2SPushRequest.requestIdentifier : [self _randomRequestIdentifier]);
        
        //推送多媒体附件
        NSString *attachmentUrlStr = notification.userInfo ? notification.userInfo[@"attachment"] : nil;
        if ([attachmentUrlStr isKindOfClass:[NSString class]] && [attachmentUrlStr length] > 0)
        {
            __weak typeof(self) weakSelf = self;
            [self _handleNotificationServiceRequestUrl:attachmentUrlStr withAttachmentsComplete:^(NSArray *attachments, NSError *error) {
                NSMutableArray *attachmentsTemp = [NSMutableArray array];
                
                if (notification.attachments)
                {
                    [attachmentsTemp addObjectsFromArray:notification.attachments];
                }
                
                if (error == nil && attachments != nil)
                {
                    [attachmentsTemp addObjectsFromArray:attachments];
                }
                
                if (attachmentsTemp.count > 0)
                {
                    //content.attachments = @[attachment];
                    SEL setAttachments = NSSelectorFromString(@"setAttachments:");
                    setPropertyAction(content, setAttachments, [attachmentsTemp copy]);
                }
                [weakSelf _requestWithIdentifier:identifier content:content trigger:trigger result:handler];
            }];
        }
        else
        {
            if (notification.attachments.count > 0)
            {
                //content.attachments = @[attachment];
                SEL setAttachments = NSSelectorFromString(@"setAttachments:");
                setPropertyAction(content, setAttachments, notification.attachments);
            }
            [self _requestWithIdentifier:identifier content:content trigger:trigger result:handler];
        }
    }
    else
    {
        // iOS10及以下
        BOOL repeats = NO;
        if (O2SPushRequest.trigger)
        {
            repeats = O2SPushRequest.trigger.repeat;
        }
        
        UILocalNotification *local = [[UILocalNotification alloc] init];
        if ([O2SPushDevice versionCompare:@"8.2"] >= 0)
        {
            local.alertTitle = notification.title;
        }
        local.alertBody = notification.body;
        local.applicationIconBadgeNumber = [notification.badge intValue];
        local.timeZone = [NSTimeZone defaultTimeZone];
        
        // 静默推送
        if(!notification.silentPush)
        {
            if (notification.sound)
            {
                local.soundName = notification.sound;
            }
            else
            {
                local.soundName = UILocalNotificationDefaultSoundName;
            }
            
            if ([O2SPushDevice versionCompare:@"8.0"] >= 0 && notification.category)
            {
                local.category = notification.category;
            }
        }
        
        if (notification.launchImageName)
        {
            local.alertLaunchImage = notification.launchImageName;
        }
        
        if (notification.alertAction)
        {
            local.alertAction = notification.alertAction;
        }
        
        NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
        if (local.userInfo)
        {
            tmp = local.userInfo.mutableCopy;
        }
        if (O2SPushRequest.requestIdentifier)
        {
            tmp[O2SPushIdentifierKey] = O2SPushRequest.requestIdentifier;
        }
        if (notification.userInfo)
        {
            [tmp addEntriesFromDictionary:notification.userInfo];
        }
        local.userInfo = [tmp copy];
        
        if (O2SPushRequest.trigger && O2SPushRequest.trigger.region)
        {
            local.region = O2SPushRequest.trigger.region;
            local.regionTriggersOnce = !repeats;
        }
        else if (O2SPushRequest.trigger && O2SPushRequest.trigger.fireDate)
        {
            local.fireDate = O2SPushRequest.trigger.fireDate;
        }
        else
        {
            // 如果是即时消息
            [[UIApplication sharedApplication] presentLocalNotificationNow:local];
            if (handler)
            {
                handler(local, nil);
            }
            return;
        }
        
        [[UIApplication sharedApplication] scheduleLocalNotification:local];
        if (handler)
        {
            handler(local, nil);
        }
    }
    
}

- (void)_requestWithIdentifier:(NSString *)identifier content:(id)content trigger:(id)trigger result:(void (^) (id result, NSError *error))handler
{
    Class requestCls = NSClassFromString(@"UNNotificationRequest");
    SEL requestSEL = NSSelectorFromString(@"requestWithIdentifier:content:trigger:");
    id (*requestAction) (id, SEL, id, id, id) = (id (*) (id, SEL, id, id, id))objc_msgSend;
    id request = requestAction(requestCls, requestSEL, identifier, content, trigger);
    
    // UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
    SEL userNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
    id (*currentNotificationCenterAction) (id, SEL) = (id (*) (id, SEL))objc_msgSend;
    id center = currentNotificationCenterAction(userNotificationCenterCls, userNotificationCenterSEL);
    
    // 将通知请求添加到用户通知中心
    // [center addNotificationRequest:request
    //         withCompletionHandler:^(NSError * _Nullable error)
    // {
    // }];
    SEL addNotificationRequestSEL = NSSelectorFromString(@"addNotificationRequest:withCompletionHandler:");
    id (*addNotificationRequestAction) (id, SEL, id, id) = (id (*) (id, SEL, id, id))objc_msgSend;
    addNotificationRequestAction(center, addNotificationRequestSEL, request, ^(NSError * _Nullable error){
        if (error)
        {
            if (handler)
            {
                handler(nil, error);
            }
        }
        else
        {
            if (handler)
            {
                handler(request, nil);
            }
        }
    });
}

// 多媒体下载
- (void)_handleNotificationServiceRequestUrl:(NSString *)requestUrl
                     withAttachmentsComplete:(void (^)(NSArray *attachments, NSError *error))completeBlock
{
    if(requestUrl.length > 0)
    {
        //获取文件后缀名
        NSString *fileType = [requestUrl pathExtension];
        [self _loadAttachmentForUrlString:requestUrl withType:fileType completionHandle:^(id attach) {
            if (attach)
            {
                if (completeBlock)
                {
                    completeBlock(@[attach], nil);
                }
            }
            else
            {
                if (completeBlock)
                {
                    completeBlock(nil, nil);
                }
            }
            
        }];
    }
    else
    {
        if (completeBlock)
        {
            completeBlock(nil, [NSError errorWithDomain:@"Attachment" code:999 userInfo:@{@"Description" : @"该推送不包含多媒体附件"}]);
        }
    }
}

- (void)_loadAttachmentForUrlString:(NSString *)urlString
                           withType:(NSString *)type
                   completionHandle:(void(^)(id attach))completionHandler
{
    __block id attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlString];
    NSString *fileExt = [@"." stringByAppendingString:type];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
        if (!error)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
            // 将系统下载后的文件移到指定的路径下
            [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
            
            // 生成UNNotificationAttachment推送文件
            // attachment = [UNNotificationAttachment attachmentWithIdentifier:@"attachment" URL:localURL options:nil error:nil];
            Class attachmentCls = NSClassFromString(@"UNNotificationAttachment");
            SEL attachmentSEL = NSSelectorFromString(@"attachmentWithIdentifier:URL:options:error:");
            id (*attachmentAction) (id, SEL, id, id, id, id) = (id (*) (id, SEL, id, id, id, id))objc_msgSend;
            attachment = attachmentAction(attachmentCls, attachmentSEL, @"attachment", localURL, nil, nil);
        }
        
        if (completionHandler)
        {
            completionHandler(attachment);
        }
    }] resume];
}

- (NSString *)_randomRequestIdentifier
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];// 获取当前时间0秒后的时间
    NSTimeInterval time = [date timeIntervalSince1970] * 1000;// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}

#pragma mark 删除推送通知

- (void)_removeNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers requestStatuses:(O2SPushNotificationRequestStatusOptions)requestStatuses
{
    if (identifiers.count > 0)
    {
        if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
        {
            //  iOS 10 以上
            Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
            SEL currentNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
            id (*userNotificationCenterAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
            id center = userNotificationCenterAction(userNotificationCenterCls, currentNotificationCenterSEL);
            
            // [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:identifiers];
            SEL removePendingSEL = NSSelectorFromString(@"removePendingNotificationRequestsWithIdentifiers:");
            id (*removePendingAction) (id, SEL, NSArray *) = (id (*) (id, SEL, NSArray *)) objc_msgSend;
            
            // [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:identifiers];
            SEL removeDeliveredSEL = NSSelectorFromString(@"removeDeliveredNotificationsWithIdentifiers:");
            id (*removeDeliveredAction) (id, SEL, NSArray *) = (id (*) (id, SEL, NSArray *)) objc_msgSend;
            
            if (O2SPushNotificationRequestStatusPending & requestStatuses)
            {
                removePendingAction(center, removePendingSEL, identifiers);
            }
            
            if (O2SPushNotificationRequestStatusDelivered & requestStatuses)
            {
                removeDeliveredAction(center, removeDeliveredSEL, identifiers);
            }
            
        }
        else
        {
            if (O2SPushNotificationRequestStatusPending & requestStatuses) //iOS10之前只能获取未发送通知
            {
                return;
            }
            // 取消一个未发送的通知
            NSArray *notificaitons = [[UIApplication sharedApplication] scheduledLocalNotifications];
            // 获取当前所有的本地通知
            if (!notificaitons || notificaitons.count <= 0)
            {
                return;
            }
            
            for (NSString *identifier in identifiers)
            {
                for (UILocalNotification *notify in notificaitons)
                {
                    if ([[notify.userInfo objectForKey:O2SPushIdentifierKey] isEqualToString:identifier])
                    {
                        [[UIApplication sharedApplication] cancelLocalNotification:notify];
                        break;
                    }
                }
            }
        }
    }
    else
    {
        if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
        {
            // iOS 10 以上
            Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
            SEL currentNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
            id (*userNotificationCenterAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
            id center = userNotificationCenterAction(userNotificationCenterCls, currentNotificationCenterSEL);
            
            // [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
            SEL removeAllPendingSEL = NSSelectorFromString(@"removeAllPendingNotificationRequests");
            id (*removeAllPendingAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
            
            
            // [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
            SEL removeAllDeliveredSEL = NSSelectorFromString(@"removeAllDeliveredNotifications");
            id (*removeAllDeliveredAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
            
            if (O2SPushNotificationRequestStatusPending & requestStatuses)
            {
                removeAllPendingAction(center, removeAllPendingSEL);
            }
            
            if (O2SPushNotificationRequestStatusDelivered & requestStatuses)
            {
                removeAllDeliveredAction(center, removeAllDeliveredSEL);
            }
            
        }
        else
        {
            // 删除所有通知
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
        }
    }
}

#pragma mark 查找推送通知

- (void)_findNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers requestStatus:(O2SPushNotificationRequestStatusOptions)requestStatus handler:(void (^) (NSArray *result, NSError *error))handler
{
    if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
    {
        //  iOS 10 以上
        Class userNotificationCenterCls = NSClassFromString(@"UNUserNotificationCenter");
        SEL currentNotificationCenterSEL = NSSelectorFromString(@"currentNotificationCenter");
        id (*userNotificationCenterAction) (id, SEL) = (id (*) (id, SEL)) objc_msgSend;
        id center = userNotificationCenterAction(userNotificationCenterCls, currentNotificationCenterSEL);
                    
        if (requestStatus & O2SPushNotificationRequestStatusDelivered)
        {
            // [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {}];
            SEL getDeliveredNotificationsSEL = NSSelectorFromString(@"getDeliveredNotificationsWithCompletionHandler:");
            id (*getDeliveredNotificationsAction) (id, SEL, id) = (id (*) (id, SEL, id)) objc_msgSend;
            getDeliveredNotificationsAction(center, getDeliveredNotificationsSEL, ^(NSArray * _Nonnull notifications) {
                if (identifiers.count == 0)
                {
                    handler(notifications, nil);
                }
                else
                {
                    NSMutableArray *notificationsTmp = [NSMutableArray array];
                    NSString *identifiersStr = [identifiers componentsJoinedByString:@"||||||"];
                    identifiersStr = [NSString stringWithFormat:@"||||||%@||||||", identifiersStr];
                                
                    Class UNNotificationCls = NSClassFromString(@"UNNotification");
                                
                    SEL requestSEL = NSSelectorFromString(@"request");
                    SEL identifierSEL = NSSelectorFromString(@"identifier");
                    id (*getPropertyAction) (id, SEL) = (id (*) (id, SEL))objc_msgSend;
                                
                    for (id item in notifications)
                    {
                        if ([item isKindOfClass:UNNotificationCls])
                        {
                            id request = getPropertyAction(item, requestSEL);
                            if (request)
                            {
                                NSString *identifierStr = getPropertyAction(request, identifierSEL);
                                if ([identifierStr isKindOfClass:NSString.class])
                                {
                                    identifierStr = [NSString stringWithFormat:@"||||||%@||||||", identifierStr];
                                    NSRange range = [identifiersStr rangeOfString:identifierStr];
                                    if (range.location != NSNotFound)
                                    {
                                        [notificationsTmp addObject:item];
                                    }
                                }
                            }
                        }
                    }
                                
                    handler([notificationsTmp copy], nil);
            
                }
            });
        }
        else
        {
            //  [[UNUserNotificationCenter currentNotificationCenter] getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {}];
            SEL getPendingNotificationSEL = NSSelectorFromString(@"getPendingNotificationRequestsWithCompletionHandler:");
            id (*getPendingNotificationAction) (id, SEL, id) = (id (*) (id, SEL, id)) objc_msgSend;
            getPendingNotificationAction(center, getPendingNotificationSEL, ^(NSArray * _Nonnull requests) {
                if (identifiers.count == 0)
                {
                    handler(requests, nil);
                }
                else
                {
                    NSMutableArray *requestsTmp = [NSMutableArray array];
                    NSString *identifiersStr = [identifiers componentsJoinedByString:@"||||||"];
                    identifiersStr = [NSString stringWithFormat:@"||||||%@||||||", identifiersStr];
                                
                    Class UNNotificationRequestCls = NSClassFromString(@"UNNotificationRequest");
                                
                    SEL identifierSEL = NSSelectorFromString(@"identifier");
                    id (*getPropertyAction) (id, SEL) = (id (*) (id, SEL))objc_msgSend;
                                
                    for (id req in requests)
                    {
                        if ([req isKindOfClass:UNNotificationRequestCls])
                        {
                            NSString *identifierStr = getPropertyAction(req, identifierSEL);
                            if ([identifierStr isKindOfClass:NSString.class])
                            {
                                identifierStr = [NSString stringWithFormat:@"||||||%@||||||", identifierStr];
                                NSRange range = [identifiersStr rangeOfString:identifierStr];
                                if (range.location != NSNotFound)
                                {
                                    [requestsTmp addObject:req];
                                }
                            }
                        }
                    }
                                
                    handler([requestsTmp copy], nil);
                }
            });
        }
    }
    else
    {
        if (requestStatus & O2SPushNotificationRequestStatusDelivered)
        {
            handler(nil, nil);
        }
        else
        {
            NSArray<UILocalNotification *> *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
            {
                NSString *identifiersStr = [identifiers componentsJoinedByString:@"||||||"];
                identifiersStr = [NSString stringWithFormat:@"||||||%@||||||", identifiersStr];
                
                NSMutableArray *notificationsTmp = [NSMutableArray array];
                for (UILocalNotification *notify in notifications)
                {
                    if(notify.userInfo && [notify.userInfo[O2SPushIdentifierKey] isKindOfClass:NSString.class])
                    {
                        NSString *identifierStr = notify.userInfo[O2SPushIdentifierKey];
                        identifierStr = [NSString stringWithFormat:@"||||||%@||||||", identifierStr];
                        NSRange range = [identifiersStr rangeOfString:identifiersStr];
                        if (range.location != NSNotFound)
                        {
                            [notificationsTmp addObject:notify];
                        }
                    }
                }
                
                handler([notificationsTmp copy], nil);
            }
        }
                
    }
}



@end
