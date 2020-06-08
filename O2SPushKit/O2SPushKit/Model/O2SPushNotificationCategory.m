//
//  O2SPushNotificationCategory.m
//  O2SPushKit
//
//  Created by wkx on 2020/6/4.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationCategory.h"
#import "O2SPushNotificationCategory+Private.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
static const O2SPushNotificationActionOptions O2SPushNotificationActionOptionNone = 0;
#pragma clang diagnostic pop

@implementation O2SPushNotificationCategory

+ (instancetype)categoryWithIdentifier:(NSString *)identifier
                               actions:(NSArray<O2SPushNotificationAction *> *)actions
                     intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
         hiddenPreviewsBodyPlaceholder:(nullable NSString *)hiddenPreviewsBodyPlaceholder
                 categorySummaryFormat:(nullable NSString *)categorySummaryFormat
                               options:(O2SPushNotificationCategoryOptions)options
{
    O2SPushNotificationCategory *category = [[O2SPushNotificationCategory alloc] initDefault];
    category.identifier = identifier;
    category.actions = actions;
    category.intentIdentifiers = intentIdentifiers;
    category.hiddenPreviewsBodyPlaceholder = hiddenPreviewsBodyPlaceholder;
    category.categorySummaryFormat = categorySummaryFormat;
    category.options = options;
    return category;
}

- (instancetype)initDefault
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

@end

@implementation O2SPushNotificationAction

+ (instancetype)defaultActionWithIdentifier:(NSString *)identifier
                                      title:(NSString *)title
                                    options:(O2SPushNotificationActionOptions)options
{
    O2SPushNotificationAction *action = [[O2SPushNotificationAction alloc] initDefault];
    action.identifier = identifier;
    action.title = title;
    action.options = options;
    
    action.actionType = O2SPushNotificationActionTypeDefault;
    
    return action;
}

+ (instancetype)textInputActionWithIdentifier:(NSString *)identifier
                                        title:(NSString *)title
                                      options:(O2SPushNotificationActionOptions)options
                         textInputButtonTitle:(nullable NSString *)textInputButtonTitle
                         textInputPlaceholder:(nullable NSString *)textInputPlaceholder
{
    O2SPushNotificationAction *action = [[O2SPushNotificationAction alloc] initDefault];
    action.identifier = identifier;
    action.title = title;
    action.options = options;
    action.textInputButtonTitle = textInputButtonTitle;
    action.textInputPlaceholder = textInputPlaceholder;
    
    action.actionType = O2SPushNotificationActionTypeTextInput;
    
    return action;
}

- (instancetype)initDefault
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

@end
