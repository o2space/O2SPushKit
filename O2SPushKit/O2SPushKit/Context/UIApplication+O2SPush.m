//
//  UIApplication+O2SPush.m
//  O2SPushKit
//
//  Created by wkx on 2020/5/30.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "UIApplication+O2SPush.h"
#import "O2SPushContext.h"

@implementation UIApplication (O2SPush)

- (void)o2spushSetDelegate:(id<UIApplicationDelegate>)delegate
{
    [O2SPushContext currentContext].applicationDelegate = delegate;
    [self o2spushSetDelegate:delegate];
}

@end
