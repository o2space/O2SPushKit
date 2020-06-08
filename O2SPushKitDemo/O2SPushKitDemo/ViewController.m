//
//  ViewController.m
//  O2SPushKitDemo
//
//  Created by wkx on 2020/6/1.
//  Copyright © 2020 O2Space. All rights reserved.
//

#import "ViewController.h"
#import <O2SPushKit/O2SPushKit.h>

#import "MBProgressHUD+Extension.h"

@interface ViewController ()

@property(nonatomic, weak) IBOutlet UITextField *identifierTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)openSystemSetting:(id)sender
{
    [O2SPushCenter openSettingsForNotification:^(BOOL success) {
        [MBProgressHUD showTitle:@"打开成功"];
    }];
}

- (IBAction)selectLocalNotification:(id)sender
{
    NSMutableArray *arr = [NSMutableArray array];
    if (self.identifierTextField.text.length > 0)
    {
        [arr addObject:self.identifierTextField.text];
    }
    
    __weak typeof(self) weakSelf = self;
    [O2SPushCenter findNotificationWithIdentifiers:[arr copy] requestStatus:O2SPushNotificationRequestStatusDelivered handler:^(NSArray *result, NSError *error) {
        NSString *title = [NSString stringWithFormat:@"查找所有通知 %ld 条",result.count];
        NSString *message = [NSString stringWithFormat:@"%@",result];
        [weakSelf showAlertControllerWithTitle:title message:message];
    }];
    
}

- (IBAction)addLocalNotification:(id)sender
{

    O2SPushNotificationContent *content = [O2SPushNotificationContent new];
    content.title = @"标题";
    content.subTitle = @"子标题";
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    content.badge = @-1; //[UIApplication sharedApplication].applicationIconBadgeNumber < 0 ? @0 : @([UIApplication sharedApplication].applicationIconBadgeNumber + 1);
    content.body = @"消息body";
    content.alertAction = @"滑动解锁查看";// iOS10以下生效
    content.userInfo = @{@"attachment":@"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=1999522452,4111312461&fm=26&gp=0.jpg", @"key01":@"value01"};//扩展信息(attachment为多媒体信息，亦可通过content.attachments添加UNNotificationAttachment对象)
    content.sound = @"default"; //本地资源警告音
    content.category = @"doSomethingCategory";
    //category、threadIdentifier、targetContentIdentifier、...
    
    // 推送通知触发条件
    O2SPushNotificationTrigger *trigger = [O2SPushNotificationTrigger new];
    // 根据需求设置条件 trigger.fireDate(iOS10以下)、trigger.dateComponents、trigger.timeInterval、trigger.region
//    NSDate *date = [NSDate date];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:
//                                                                            NSCalendarUnitYear |
//                                                                            NSCalendarUnitMonth |
//                                                                            NSCalendarUnitWeekday |
//                                                                            NSCalendarUnitDay |
//                                                                            NSCalendarUnitHour |
//                                                                            NSCalendarUnitMinute |
//                                                                            NSCalendarUnitSecond
//                                                                            fromDate:date];
//    trigger.dateComponents = components;
//    trigger.repeat = YES;
    
    trigger.timeInterval = 1.0;
    
    // 推送通知唯一标识
    //”推送通知“标识，相同值的“推送通知”将覆盖旧“推送通知”(iOS10及以上)
    O2SPushNotificationRequest *request = [O2SPushNotificationRequest requestWithIdentifier:self.identifierTextField.text content:content trigger:trigger];
    
    // 添加本地推送
    [O2SPushCenter addLocalNotification:request handler:^(id result, NSError *error) {
        if (!error)
        {
            //iOS10以上result为UNNotificationRequest对象、iOS10以下成功result为UILocalNotification对象
            if (result)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD showTitle:@"发送成功"];
                    NSLog(@"本地通知添加成功：%@", result);
                });
            }
        }
    }];
}

- (IBAction)deleteLocalNotification:(id)sender
{
    [O2SPushCenter removeNotificationWithIdentifiers:@[] requestStatuses:(O2SPushNotificationRequestStatusPending | O2SPushNotificationRequestStatusDelivered)];
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
      [self presentViewController:alert animated:YES completion:nil];
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
