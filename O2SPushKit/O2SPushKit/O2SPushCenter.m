//
//  O2SPushCenter.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushCenter.h"
#import "O2SPushContext.h"
#import "O2SPushContext+Other.h"
#import "O2SPushDevice.h"
#import "O2SPushNotificationConfiguration+Private.h"
#import "O2SPushNotificationCategory.h"
#import "O2SPushNotificationCategory+Private.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>

@implementation O2SPushCenter

+ (void)registerForRemoteNotification:(O2SPushNotificationConfiguration *)configuration
{
    [[O2SPushContext currentContext] registerForRemoteNotification:configuration];
}

+ (void)unregisterForRemoteNotification
{
    [[O2SPushContext currentContext] unregisterForRemoteNotification];
}

+ (void)setupForegroundNotificationOptions:(O2SPushAuthorizationOptions)type
{
    [[O2SPushContext currentContext] setupForegroundNotificationOptions:type];
}

+ (void)requestNotificationAuthorizationStatus:(void (^)(O2SPushAuthorizationStatus status))handler
{
    [[O2SPushContext currentContext] requestNotificationAuthorizationStatus:handler];
}

+ (void)addLocalNotification:(O2SPushNotificationRequest *)request
                     handler:(void (^) (id result, NSError *error))handler
{
    [[O2SPushContext currentContext] addLocalNotification:request handler:handler];
}

+ (void)removeNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatuses:(O2SPushNotificationRequestStatusOptions)requestStatuses;
{
    [[O2SPushContext currentContext] removeNotificationWithIdentifiers:identifiers requestStatuses:requestStatuses];
}

+ (void)findNotificationWithIdentifiers:(NSArray<NSString *> *)identifiers
                          requestStatus:(O2SPushNotificationRequestStatusOptions)requestStatus
                                handler:(void (^) (NSArray *result, NSError *error))handler
{
    [[O2SPushContext currentContext] findNotificationWithIdentifiers:identifiers requestStatus:requestStatus handler:handler];
}

#pragma mark - other

+ (void)openSettingsForNotification:(void(^)(BOOL success))handler
{
    [[O2SPushContext currentContext] openSettingsForNotification:handler];
}

+ (void)setBadge:(NSInteger)badge
{
    [[O2SPushContext currentContext] setBadge:badge];
}

+ (void)clearBadge
{
    [[O2SPushContext currentContext] setBadge:0];
}

+ (void)clearNoticeBar
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

@end

@interface O2SPushNotificationConfiguration () //<NSCoding>

@end

@implementation O2SPushNotificationConfiguration

//- (void)encodeWithCoder:(NSCoder *)coder
//{
//    [coder encodeInteger:self.types forKey:@"O2SPushNotificationConfigurationType"];
//    if (self.categories)
//    {
//        [coder encodeObject:self.categories forKey:@"O2SPushNotificationConfigurationCategories"];
//    }
//}
//
//- (id)initWithCoder:(NSCoder *)coder
//{
//    if (self = [super init])
//    {
//        self.types = [coder decodeIntegerForKey:@"O2SPushNotificationConfigurationType"];
//
//        id value = [coder decodeObjectForKey:@"O2SPushNotificationConfigurationCategories"];
//        if ([value isKindOfClass:[NSSet class]])
//        {
//            self.categories = value;
//        }
//    }
//    return self;
//}

- (void)setCategories:(NSSet<O2SPushNotificationCategory *> *)categories
{
    _categories = categories;
    if (categories == nil || categories.count == 0)
    {
        self.convertCategories = [NSSet set];
        return;
    }
    
    if ([O2SPushDevice versionCompare:@"10.0"] >= 0)
    {
        @autoreleasepool
        {
            Class UNNotificationCategoryCls = NSClassFromString(@"UNNotificationCategory");
            SEL UNNotificationCategoryAfterIOS10NewSEL = NSSelectorFromString(@"categoryWithIdentifier:actions:intentIdentifiers:options:");
            static id (*sendMessageCategoryAfterIOS10NewSEL) (id, SEL, NSString *, NSArray *, NSArray *, NSUInteger) = (id (*) (id, SEL, NSString *, NSArray *, NSArray *, NSUInteger))objc_msgSend;
            SEL UNNotificationCategoryAfterIOS11NewSEL = NSSelectorFromString(@"categoryWithIdentifier:actions:intentIdentifiers:hiddenPreviewsBodyPlaceholder:options:");
            static id (*sendMessageCategoryAfterIOS11NewSEL) (id, SEL, NSString *, NSArray *, NSArray *, NSString *, NSUInteger) = (id (*) (id, SEL, NSString *, NSArray *, NSArray *, NSString *, NSUInteger))objc_msgSend;
            SEL UNNotificationCategoryAfterIOS12NewSEL = NSSelectorFromString(@"categoryWithIdentifier:actions:intentIdentifiers:hiddenPreviewsBodyPlaceholder:categorySummaryFormat:options:");
            static id (*sendMessageCategoryAfterIOS12NewSEL) (id, SEL, NSString *, NSArray *, NSArray *, NSString *, NSString *, NSUInteger) = (id (*) (id, SEL, NSString *, NSArray *, NSArray *, NSString *, NSString *, NSUInteger))objc_msgSend;
            
            Class UNNotificationActionCls = NSClassFromString(@"UNNotificationAction");
            SEL UNNotificationActionNewSEL = NSSelectorFromString(@"actionWithIdentifier:title:options:");
            static id (*sendMessageActionNewSEL) (id, SEL, NSString *, NSString *, NSUInteger) = (id (*) (id, SEL, NSString *, NSString *, NSUInteger))objc_msgSend;
            
             Class UNTextInputNotificationActionCls = NSClassFromString(@"UNTextInputNotificationAction");
            SEL UNTextInputNotificationActionNewSEL = NSSelectorFromString(@"actionWithIdentifier:title:options:textInputButtonTitle:textInputPlaceholder:");
            static id (*sendMessageTextInputActionNewSEL) (id, SEL, NSString *, NSString *, NSUInteger, NSString *, NSString *) = (id (*) (id, SEL, NSString *, NSString *, NSUInteger, NSString *, NSString *))objc_msgSend;
            
            NSMutableSet *categorySet = [NSMutableSet set];
            for (O2SPushNotificationCategory *category in categories)
            {
                NSString *identifier = category.identifier;
                NSArray<NSString *> *intentIdentifiers = category.intentIdentifiers;
                NSUInteger options = category.options;
                NSString *hiddenPreviewsBodyPlaceholder = category.hiddenPreviewsBodyPlaceholder;
                NSString *categorySummaryFormat = category.categorySummaryFormat;
                
                NSMutableArray *actionArray = [NSMutableArray array];
                for (O2SPushNotificationAction *action in category.actions)
                {
                    id un_action = nil;
                    if (action.actionType == O2SPushNotificationActionTypeTextInput)
                    {
                        un_action = sendMessageTextInputActionNewSEL(UNTextInputNotificationActionCls, UNTextInputNotificationActionNewSEL, action.identifier, action.title, action.options, action.textInputButtonTitle, action.textInputPlaceholder);
                    }
                    else if (action.actionType == O2SPushNotificationActionTypeDefault)
                    {
                        un_action = sendMessageActionNewSEL(UNNotificationActionCls, UNNotificationActionNewSEL, action.identifier, action.title, action.options);
                    }
                    
                    if (un_action)
                    {
                        [actionArray addObject:un_action];
                    }
                }
                
                id un_category = nil;
                if ([O2SPushDevice versionCompare:@"12.0"] >= 0)
                {
                    un_category = sendMessageCategoryAfterIOS12NewSEL(UNNotificationCategoryCls, UNNotificationCategoryAfterIOS12NewSEL, identifier, [actionArray copy], intentIdentifiers, hiddenPreviewsBodyPlaceholder, categorySummaryFormat, options);
                }
                else if ([O2SPushDevice versionCompare:@"12.0"] >= 0 && [O2SPushDevice versionCompare:@"12.0"] < 0)
                {
                    un_category = sendMessageCategoryAfterIOS11NewSEL(UNNotificationCategoryCls, UNNotificationCategoryAfterIOS11NewSEL, identifier, [actionArray copy], intentIdentifiers, hiddenPreviewsBodyPlaceholder, options);
                }
                else
                {
                    un_category = sendMessageCategoryAfterIOS10NewSEL(UNNotificationCategoryCls, UNNotificationCategoryAfterIOS10NewSEL, identifier, [actionArray copy], intentIdentifiers, options);
                }
                
                if (un_category)
                {
                    [categorySet addObject:un_category];
                }
                
            }
            
            self.convertCategories = [categorySet copy];
        }
    }
    else
    {
        @autoreleasepool
        {
            NSMutableSet *categorySet = [NSMutableSet set];
            for (O2SPushNotificationCategory *category in categories)
            {
                NSString *identifier = category.identifier;
//                NSArray<NSString *> *intentIdentifiers = category.intentIdentifiers;
//                NSUInteger options = category.options;
//                NSString *hiddenPreviewsBodyPlaceholder = category.hiddenPreviewsBodyPlaceholder;
//                NSString *categorySummaryFormat = category.categorySummaryFormat;
                
                NSMutableArray *actionArray = [NSMutableArray array];
                for (O2SPushNotificationAction *action in category.actions)
                {
                    UIMutableUserNotificationAction *ui_action = [UIMutableUserNotificationAction new];
                    ui_action.identifier = action.identifier;
                    ui_action.title = action.title;
                    if (action.actionType == O2SPushNotificationActionTypeTextInput && [O2SPushDevice versionCompare:@"9.0"] < 0)
                    {
                        continue;
                    }
                    if (action.actionType == O2SPushNotificationActionTypeTextInput)
                    {
                        ui_action.behavior = UIUserNotificationActionBehaviorTextInput;
                        if (action.textInputButtonTitle.length > 0)
                        {
                            ui_action.parameters = @{UIUserNotificationTextInputActionButtonTitleKey:action.textInputButtonTitle};
                        }
                    }
                    
                    ui_action.authenticationRequired = NO;
                    ui_action.destructive = NO;
                    ui_action.activationMode = UIUserNotificationActivationModeBackground;
                    if (action.options & O2SPushNotificationActionOptionAuthenticationRequired)
                    {
                        ui_action.authenticationRequired = YES;
                    }
                    if (action.options & O2SPushNotificationActionOptionDestructive)
                    {
                        ui_action.destructive = YES;
                    }
                    if (action.options & O2SPushNotificationActionOptionForeground)
                    {
                        ui_action.activationMode = O2SPushNotificationActionOptionForeground;
                    }
                    
                    [actionArray addObject:ui_action];
                    
                }
                
                UIMutableUserNotificationCategory *ui_category = [UIMutableUserNotificationCategory new];
                ui_category.identifier = identifier;
                [ui_category setActions:[actionArray copy] forContext:UIUserNotificationActionContextDefault];
                [ui_category setActions:[actionArray copy] forContext:UIUserNotificationActionContextMinimal];
                
                [categorySet addObject:ui_category];
            }
            
            self.convertCategories = [categorySet copy];
        }
    }
}

@end
