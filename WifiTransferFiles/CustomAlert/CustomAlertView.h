//
//  CustomAlertView.h
//  CustomAlertView
//
//  Created by CalvinCheung on 2017/1/3.
//  Copyright © 2017年 CalvinCheung. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const CustomAlertViewWillShowNotification;
UIKIT_EXTERN NSString *const CustomAlertViewDidShowNotification;
UIKIT_EXTERN NSString *const CustomAlertViewWillDismissNotification;
UIKIT_EXTERN NSString *const CustomAlertViewDidDismissNotification;

typedef void(^clickHandle)(void);

typedef void(^clickHandleWithIndex)(NSInteger index);

typedef NS_ENUM(NSInteger, CustomAlertViewButtonType) {
    CustomAlertViewButtonTypeDefault = 0,
    CustomAlertViewButtonTypeCancel,
    CustomAlertViewButtonTypeWarn
};

typedef NS_ENUM(NSInteger, SMBSide){
    
    kSMBSideLeft = 0,
    kSMBSideRight,
    kSMBSideUp,
};

@interface CustomAlertView : UIView

// show alertView with 1 button
+ (void)showOneButtonWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(CustomAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click;

// show alertView with 2 buttons
+ (void)showTwoButtonsWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(CustomAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click ButtonType:(CustomAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonType Click:(clickHandle)click;

// show alertView with greater than or equal to 3 buttons
// parameter of 'buttons' , pass by NSDictionary like @{CustomAlertViewButtonTypeDefault : @"ok"}
+ (void)showMultipleButtonsWithTitle:(NSString *)title Message:(NSString *)message Click:(clickHandleWithIndex)click Buttons:(NSDictionary *)buttons,... NS_REQUIRES_NIL_TERMINATION;

// ------------------------Show AlertView with customView-----------------------------

// create a alertView with customView.
// 'dismissWhenTouchBackground' : If you don't want to add a button on customView to call 'dismiss' method manually, set this property to 'YES'.
- (instancetype)initWithCustomView:(UIView *)customView dismissWhenTouchedBackground:(BOOL)dismissWhenTouchBackground;

- (void)configAlertViewPropertyWithTitle:(NSString *)title Message:(NSString *)message Buttons:(NSArray *)buttons Clicks:(NSArray *)clicks ClickWithIndex:(clickHandleWithIndex)clickWithIndex;

- (void)show;

// alert will resign keywindow in the completion.
- (void)dismissWithCompletion:(void(^)(void))completion;

@end
