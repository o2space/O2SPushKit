//
//  AppDelegate.m
//  O2SPushKitDemo
//
//  Created by wkx on 2020/6/1.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "AppDelegate.h"
#import <O2SPushKit/O2SPushKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // 注册远程通知并配置权限及categories
    O2SPushNotificationConfiguration *config = [[O2SPushNotificationConfiguration alloc] init];
    config.types = O2SPushAuthorizationOptionBadge | O2SPushAuthorizationOptionSound | O2SPushAuthorizationOptionAlert;
    config.categories = [self registerNotificationCategory];
    [O2SPushCenter registerForRemoteNotification:config];
    
    // 设置应用在前台时收到推送通知是否展示通知横幅、角标、声音(iOS10以后有效，iOS10之前不展示)
    [O2SPushCenter setupForegroundNotificationOptions:(O2SPushAuthorizationOptionBadge | O2SPushAuthorizationOptionSound | O2SPushAuthorizationOptionAlert)];
    
    // 推送消息接收
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(o2spush_didReceiveMessageNotification:) name:O2SPushDidReceiveMessageNotification object:nil];
    // 注册远程通知结果
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(o2spush_didRegisterRemoteNotification:) name:O2SPushDidRegisterRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(o2spush_failedRegisterRemoteNotification:) name:O2SPushFailedRegisterRemoteNotification object:nil];
    
    return YES;
}

- (id) registerNotificationCategory
{
    // Action
    O2SPushNotificationAction *inputAction = [O2SPushNotificationAction textInputActionWithIdentifier:@"action.input"
                                                                                                title:@"Input"
                                                                                              options:O2SPushNotificationActionOptionNone
                                                                                 textInputButtonTitle:@"Send Say"
                                                                                 textInputPlaceholder:@"What do you want to say..."];
    
    O2SPushNotificationAction *goodbyeAction = [O2SPushNotificationAction defaultActionWithIdentifier:@"action.goodbye"
                                                                                                title:@"Goodbye"
                                                                                              options:O2SPushNotificationActionOptionForeground];
    
    O2SPushNotificationAction *cancelAction = [O2SPushNotificationAction defaultActionWithIdentifier:@"action.cancel"
                                                                                                title:@"Cancel"
                                                                                              options:O2SPushNotificationActionOptionDestructive];
    
    // Category
    O2SPushNotificationCategory *doSomethingCategory = [O2SPushNotificationCategory categoryWithIdentifier:@"doSomethingCategory"
                                                                                                   actions:@[inputAction, goodbyeAction, cancelAction]
                                                                                         intentIdentifiers:@[]
                                                                             hiddenPreviewsBodyPlaceholder:nil //@"新的消息"
                                                                                     categorySummaryFormat:nil //@"还有%u条来自%@的消息"
                                                                                                   options:O2SPushNotificationCategoryOptionCustomDismissAction];
    return [NSSet setWithObjects:doSomethingCategory, nil];
    
//    if (@available(iOS 10.0, *))
//    {
//        UNTextInputNotificationAction *inputAction = [UNTextInputNotificationAction actionWithIdentifier:@"action.input" title:@"Input" options:UNNotificationActionOptionForeground textInputButtonTitle:@"Send Say" textInputPlaceholder:@"What do you want to say..."];
//
//        UNNotificationAction *goodbyeAction = [UNNotificationAction actionWithIdentifier:@"action.goodbye" title:@"Goodbye" options:UNNotificationActionOptionForeground];
//
//        UNNotificationAction *cancelAction = [UNNotificationAction actionWithIdentifier:@"action.cancel" title:@"Cancel" options:UNNotificationActionOptionDestructive];
//
//        UNNotificationCategory *doSomethingCategory = [UNNotificationCategory categoryWithIdentifier:@"doSomethingCategory"
//                                                                                             actions:@[inputAction, goodbyeAction, cancelAction]
//                                                                                   intentIdentifiers:@[]
////                                                                       hiddenPreviewsBodyPlaceholder:@"新的消息"
////                                                                               categorySummaryFormat:@"还有%u条来自%@的消息"
//                                                                                             options:UNNotificationCategoryOptionCustomDismissAction];
//
//        return [NSSet setWithObjects:doSomethingCategory, nil];
//    }
//    else if (@available(iOS 8.0, *))
//    {
//        // ios8-ios10 最多显示2个Action
//        UIMutableUserNotificationAction *inputAction = [UIMutableUserNotificationAction new];
//        if (@available(iOS 9.0, *))
//        {
//            inputAction.identifier = @"action.input"; // action的唯一标识
//            inputAction.title = @"Input"; // 展示在通知上的title
//            inputAction.behavior = UIUserNotificationActionBehaviorTextInput;
//            inputAction.activationMode = UIUserNotificationActivationModeBackground;
//            inputAction.destructive = NO; // 当前操作按钮为红色
//            inputAction.authenticationRequired = NO; //需要解锁与否
//            inputAction.parameters = @{UIUserNotificationTextInputActionButtonTitleKey:@"Send Say"};//设置发送键的title
//        }
//        UIMutableUserNotificationAction *goodbyeAction = [UIMutableUserNotificationAction new];
//        goodbyeAction.identifier = @"action.goodbye";
//        goodbyeAction.title = @"Goodbye";
//        goodbyeAction.activationMode = UIUserNotificationActivationModeBackground; //不会调起app到前台,在后台处理
//        goodbyeAction.destructive = NO;
//        goodbyeAction.authenticationRequired = NO;
//
//        UIMutableUserNotificationAction *cancelAction = [UIMutableUserNotificationAction new];
//        cancelAction.identifier = @"action.cancel";
//        cancelAction.title = @"Cancel";
//        cancelAction.activationMode = UIUserNotificationActivationModeBackground;
//        cancelAction.destructive = YES;
//        cancelAction.authenticationRequired = NO;
//
//        UIMutableUserNotificationCategory *doSomethingCategory = [UIMutableUserNotificationCategory new];
//        doSomethingCategory.identifier = @"doSomethingCategory";
//        if (@available(iOS 9.0, *))
//        {
//            [doSomethingCategory setActions:@[inputAction, goodbyeAction, cancelAction] forContext:UIUserNotificationActionContextDefault];
//        }
//        else
//        {
//            [doSomethingCategory setActions:@[goodbyeAction, cancelAction] forContext:UIUserNotificationActionContextDefault];
//        }
//
//        return [NSSet setWithObjects:doSomethingCategory, nil];
//    }
}

- (void)o2spush_didReceiveMessageNotification:(NSNotification *)notification
{
    O2SPushNotificationMessage *message = notification.object;
    if ([message isKindOfClass:O2SPushNotificationMessage.class])
    {
        NSLog(@"\n =============== message:\n%@\n =============== \n",message.convertDictionary);
        
        NSMutableString *title = [NSMutableString string];
        [title appendString:@"收到通知类型："];
        switch (message.notificationMessageType)
        {
            case O2SPushNotificationMessageTypeAPNs:
            {
                //远程推送消息
                if (message.content.silentPush)
                {
                    [title appendString:@"远程通知-静默推送"];
                }
                else
                {
                    [title appendString:@"远程通知"];
                }
            }
                break;
            case O2SPushNotificationMessageTypeLocal:
            {
                //本地推送消息
                [title appendString:@"本地通知"];
            }
                break;
            case O2SPushNotificationMessageTypeAPNsClicked:
            {
                //通知栏 远程推送点击
                if (message.content.actionIdentifier && ![message.content.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])//自定义按钮触发
                {
                    [title appendString:@"远程通知-通知栏点击-自定义按钮"];
                    [title appendFormat:@"\n Category:%@", message.content.category];
                    [title appendFormat:@"\n Action:%@", message.content.actionIdentifier];
                    if (message.content.actionUserText)
                    {
                        [title appendFormat:@"\n UserText:%@", message.content.actionUserText];
                    }
                }
                else
                {
                    [title appendString:@"远程通知-通知栏点击"];
                }
                
            }
                break;
            case O2SPushNotificationMessageTypeLocalClicked:
            {
                //通知栏 本地推送点击
                if (message.content.actionIdentifier && ![message.content.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])//自定义按钮触发
                {
                    // mess
                    [title appendString:@"本地通知-通知栏点击-自定义按钮"];
                    [title appendFormat:@"\n Category:%@", message.content.category];
                    [title appendFormat:@"\n Action:%@", message.content.actionIdentifier];
                    if (message.content.actionUserText)
                    {
                        [title appendFormat:@"\n UserText:%@", message.content.actionUserText];
                    }
                }
                else
                {
                    [title appendString:@"本地通知-通知栏点击"];
                }
            }
                break;
            default:
                break;
        }
        
        [self showAlertControllerWithTitle:title message:message.convertDictionary.description];
    }
}

- (void)o2spush_didRegisterRemoteNotification:(NSNotification *)notification
{
    NSString *deviceTokenStr = notification.userInfo[@"deviceToken"];//或 NSData *deviceTokenData = notification.object;
    NSLog(@"deviceToken:%@",deviceTokenStr);
}

- (void)o2spush_failedRegisterRemoteNotification:(NSNotification *)notification
{
    NSError *error = notification.object;
    if ([error isKindOfClass:NSError.class])
    {
        NSLog(@"%@",error);
    }
}

- (void)showAlertControllerWithTitle:(NSString *)title message:(NSString *)message
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
      [alert addAction: closeAction];
      [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
      UIAlertView *alert =
      [[UIAlertView alloc] initWithTitle:title
                                 message:message
                                delegate:self
                       cancelButtonTitle:@"确定"
                       otherButtonTitles:nil, nil];
      [alert show];
    }
  });
}

@end
