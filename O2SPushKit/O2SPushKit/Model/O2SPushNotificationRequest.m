//
//  O2SPushNotificationRequest.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/29.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "O2SPushNotificationRequest.h"

@interface O2SPushNotificationRequest ()

@property(nonatomic, copy) NSString *requestIdentifier;

@property(nonatomic, strong) O2SPushNotificationContent *content;

@property(nonatomic, strong) O2SPushNotificationTrigger *trigger;

@end

@implementation O2SPushNotificationRequest

- (instancetype)initDefault
{
    if (self = [super init])
    {
        
    }
    return self;
}

+ (instancetype)requestWithIdentifier:(NSString *)identifier content:(O2SPushNotificationContent *)content trigger:(nullable O2SPushNotificationTrigger *)trigger;
{
    O2SPushNotificationRequest *request = [[O2SPushNotificationRequest alloc] initDefault];
    request.content = content;
    request.requestIdentifier = identifier;
    request.trigger = trigger;
    
    return request;
}


@end

@implementation O2SPushNotificationTrigger

@end
