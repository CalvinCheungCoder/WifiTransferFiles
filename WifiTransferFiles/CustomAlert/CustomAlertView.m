//
//  CustomAlertView.m
//  CustomAlertView
//
//  Created by CalvinCheung on 2017/1/3.
//  Copyright © 2017年 CalvinCheung. All rights reserved.
//

#import "CustomAlertView.h"

#import <Accelerate/Accelerate.h>

NSString *const CustomAlertViewWillShowNotification = @"CustomAlertViewWillShowNotification";
NSString *const CustomAlertViewDidShowNotification = @"CustomAlertViewDidShowNotification";
NSString *const CustomAlertViewWillDismissNotification = @"CustomAlertViewWillDismissNotification";
NSString *const CustomAlertViewDidDismissNotification = @"CustomAlertViewDidDismissNotification";


#define CustomColor(r, g, b) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:1.0]
//#define ScreenWidth [UIScreen mainScreen].bounds.size.width
//#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define CustomAlertViewWidth ScreenWidth - 60
#define CustomAlertViewHeight 174
#define CustomAlertViewMaxHeight 440
#define CustomMargin 8
#define CustomButtonHeight 44

#define CustomAlertViewTitleLabelHeight 45
#define CustomAlertViewTitleColor CustomColor(75, 75, 75)
#define CustomAlertViewTitleFont [UIFont boldSystemFontOfSize:18]

#define CustomAlertViewContentColor CustomColor(102, 102, 102)
#define CustomAlertViewContentFont [UIFont systemFontOfSize:16]

#define CustomAlertViewContentHeight (CustomAlertViewHeight - CustomAlertViewTitleLabelHeight - CustomButtonHeight - CustomMargin * 2)
#define CustomiOS7OrLater ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@class CustomViewController;

@protocol CustomViewControllerDelegate <NSObject>

@optional

- (void)coverViewTouched;

@end

@interface CustomAlertView () <CustomViewControllerDelegate>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) NSArray *clicks;
@property (nonatomic, copy) clickHandleWithIndex clickWithIndex;
@property (nonatomic, weak) CustomViewController *vc;
@property (nonatomic, strong) UIImageView *screenShotView;
@property (nonatomic, getter = isCustomAlert) BOOL customAlert;
@property (nonatomic, getter = isDismissWhenTouchBackground) BOOL dismissWhenTouchBackground;
@property (nonatomic, getter = isAlertReady) BOOL alertReady;

- (void)setup;

@end

@interface CustomSingleTon : NSObject

@property (nonatomic, strong) UIWindow *backgroundWindow;
@property (nonatomic, weak) UIWindow *oldKeyWindow;
@property (nonatomic, strong) NSMutableArray *alertStack;
@property (nonatomic, strong) CustomAlertView *previousAlert;

@end

@implementation CustomSingleTon

+ (instancetype)shareSingleTon{
    static CustomSingleTon *shareSingleTonInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        shareSingleTonInstance = [CustomSingleTon new];
    });
    return shareSingleTonInstance;
}

- (UIWindow *)backgroundWindow{
    if (!_backgroundWindow) {
        _backgroundWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _backgroundWindow.windowLevel = UIWindowLevelStatusBar - 1;
    }
    return _backgroundWindow;
}

- (NSMutableArray *)alertStack{
    if (!_alertStack) {
        _alertStack = [NSMutableArray array];
    }
    return _alertStack;
}

@end


@interface CustomViewController : UIViewController

@property (nonatomic, strong) UIImageView *screenShotView;
@property (nonatomic, strong) UIButton *coverView;
@property (nonatomic, weak) CustomAlertView *alertView;
@property (nonatomic, weak) id <CustomViewControllerDelegate> delegate;

@end

@implementation CustomViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.alertView.layer.cornerRadius = 6;
    self.alertView.clipsToBounds = YES;
    
    [self addScreenShot];
    [self addCoverView];
    [self addAlertView];
    
}

- (void)addScreenShot{
    UIWindow *screenWindow = [UIApplication sharedApplication].windows.firstObject;
    UIGraphicsBeginImageContext(screenWindow.frame.size);
    [screenWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *originalImage = nil;
    if (CustomiOS7OrLater) {
        originalImage = viewImage;
    } else {
        originalImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(viewImage.CGImage, CGRectMake(0, 20, 320, 460))];
    }
    
    CGFloat blurRadius = 4;
    UIColor *tintColor = [UIColor clearColor];
    CGFloat saturationDeltaFactor = 1;
    UIImage *maskImage = nil;
    
    CGRect imageRect = { CGPointZero, originalImage.size };
    UIImage *effectImage = originalImage;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -originalImage.size.height);
        CGContextDrawImage(effectInContext, imageRect, originalImage.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data	 = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width	= CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data	 = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width	= CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,					0,					0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -originalImage.size.height);
    
    CGContextDrawImage(outputContext, imageRect, originalImage.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.screenShotView = [[UIImageView alloc] initWithImage:outputImage];
    
    [self.view addSubview:self.screenShotView];
}

- (void)addCoverView{
    self.coverView = [[UIButton alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.coverView.backgroundColor = CustomColor(5, 0, 10);
    [self.coverView addTarget:self action:@selector(coverViewClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.coverView];
}

- (void)coverViewClick{
    if ([self.delegate respondsToSelector:@selector(coverViewTouched)]) {
        [self.delegate coverViewTouched];
    }
}

- (void)addAlertView{
    [self.alertView setup];
    [self.view addSubview:self.alertView];
}

- (void)showAlert{
    [[NSNotificationCenter defaultCenter] postNotificationName:CustomAlertViewWillShowNotification object:self];
    self.alertView.alertReady = NO;
    
    CGFloat duration = 0.3;
    
    for (UIButton *btn in self.alertView.subviews) {
        btn.userInteractionEnabled = NO;
    }
    
    self.screenShotView.alpha = 0;
    self.coverView.alpha = 0;
    self.alertView.alpha = 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.screenShotView.alpha = 1;
        self.coverView.alpha = 0.65;
        self.alertView.alpha = 1.0;
    } completion:^(BOOL finished) {
        for (UIButton *btn in self.alertView.subviews) {
            btn.userInteractionEnabled = YES;
        }
        self.alertView.alertReady = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:CustomAlertViewDidShowNotification object:self.alertView];
    }];
    
    if (CustomiOS7OrLater) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        animation.values = @[@(0.8), @(1.05), @(1.1), @(1)];
        animation.keyTimes = @[@(0), @(0.3), @(0.5), @(1.0)];
        animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        animation.duration = duration;
        [self.alertView.layer addAnimation:animation forKey:@"bouce"];
    } else {
        self.alertView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView animateWithDuration:duration * 0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alertView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration * 0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.alertView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:duration * 0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.alertView.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }];
    }
}

- (void)hideAlertWithCompletion:(void(^)(void))completion{
    [[NSNotificationCenter defaultCenter] postNotificationName:CustomAlertViewWillDismissNotification object:self];
    self.alertView.alertReady = NO;
    
    CGFloat duration = 0.2;
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 0;
        self.screenShotView.alpha = 0;
        self.alertView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.screenShotView removeFromSuperview];
        if (completion) {
            completion();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CustomAlertViewDidDismissNotification object:self];
    }];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alertView.transform = CGAffineTransformMakeScale(0.4, 0.4);
    } completion:^(BOOL finished) {
        self.alertView.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

@end

@implementation CustomAlertView

- (NSArray *)buttons{
    if (!_buttons) {
        _buttons = [NSArray array];
    }
    return _buttons;
}

- (NSArray *)clicks{
    if (!_clicks) {
        _clicks = [NSArray array];
    }
    return _clicks;
}

- (instancetype)initWithCustomView:(UIView *)customView dismissWhenTouchedBackground:(BOOL)dismissWhenTouchBackground{
    if (self = [super initWithFrame:customView.bounds]) {
        [self addSubview:customView];
        self.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
        self.customAlert = YES;
        self.dismissWhenTouchBackground = dismissWhenTouchBackground;
    }
    return self;
}

- (void)show{
    [[CustomSingleTon shareSingleTon].alertStack addObject:self];
    [self showAlert];
}

- (void)dismissWithCompletion:(void(^)(void))completion{
    [self dismissAlertWithCompletion:^{
        if (completion) {
            completion();
        }
    }];
}

+ (void)showOneButtonWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(CustomAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click{
    id newClick = click;
    if (!newClick) {
        newClick = [NSNull null];
    }
    CustomAlertView *alertView = [CustomAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:@[@{[NSString stringWithFormat:@"%zi", buttonType] : buttonTitle}] Clicks:@[newClick] ClickWithIndex:nil];
}

+ (void)showTwoButtonsWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(CustomAlertViewButtonType)
buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click ButtonType:(CustomAlertViewButtonType)buttonType1 ButtonTitle:(NSString *)buttonTitle1 Click:(clickHandle)click1{
    id newClick = click;
    if (!newClick) {
        newClick = [NSNull null];
    }
    id newClick1 = click1;
    if (!newClick1) {
        newClick1 = [NSNull null];
    }
    CustomAlertView *alertView = [CustomAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:@[@{[NSString stringWithFormat:@"%zi", buttonType] : buttonTitle}, @{[NSString stringWithFormat:@"%zi", buttonType1] : buttonTitle1}] Clicks:@[newClick, newClick1] ClickWithIndex:nil];
}

+ (void)showMultipleButtonsWithTitle:(NSString *)title Message:(NSString *)message Click:(clickHandleWithIndex)click Buttons:(NSDictionary *)buttons, ...{
    NSMutableArray *btnArray = [NSMutableArray array];
    NSString* curStr;
    va_list list;
    if(buttons)
    {
        [btnArray addObject:buttons];
        
        va_start(list, buttons);
        while ((curStr = va_arg(list, NSString*))) {
            [btnArray addObject:curStr];
        }
        va_end(list);
    }
    NSMutableArray *btns = [NSMutableArray array];
    for (int i = 0; i<btnArray.count; i++) {
        NSDictionary *dic = btnArray[i];
        [btns addObject:@{dic.allKeys.firstObject : dic.allValues.firstObject}];
    }
    
    CustomAlertView *alertView = [CustomAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:btns Clicks:nil ClickWithIndex:click];
}

- (void)configAlertViewPropertyWithTitle:(NSString *)title Message:(NSString *)message Buttons:(NSArray *)buttons Clicks:(NSArray *)clicks ClickWithIndex:(clickHandleWithIndex)clickWithIndex{
    self.title = title;
    self.message = message;
    self.buttons = buttons;
    self.clicks = clicks;
    self.clickWithIndex = clickWithIndex;
    
    [[CustomSingleTon shareSingleTon].alertStack addObject:self];
    
    [self showAlert];
}

- (void)showAlert{
    NSInteger count = [CustomSingleTon shareSingleTon].alertStack.count;
    CustomAlertView *previousAlert = nil;
    if (count > 1) {
        NSInteger index = [[CustomSingleTon shareSingleTon].alertStack indexOfObject:self];
        previousAlert = [CustomSingleTon shareSingleTon].alertStack[index - 1];
    }
    
    if (previousAlert && previousAlert.vc) {
        if (previousAlert.isAlertReady) {
            [previousAlert.vc hideAlertWithCompletion:^{
                [self showAlertHandle];
            }];
        } else {
            [self showAlertHandle];
        }
    } else {
        [self showAlertHandle];
    }
}

- (void)showAlertHandle{
    UIWindow *keywindow = [UIApplication sharedApplication].keyWindow;
    if (keywindow != [CustomSingleTon shareSingleTon].backgroundWindow) {
        [CustomSingleTon shareSingleTon].oldKeyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    CustomViewController *vc = [[CustomViewController alloc] init];
    vc.delegate = self;
    vc.alertView = self;
    self.vc = vc;
    
    [CustomSingleTon shareSingleTon].backgroundWindow.frame = [UIScreen mainScreen].bounds;
    [[CustomSingleTon shareSingleTon].backgroundWindow makeKeyAndVisible];
    [CustomSingleTon shareSingleTon].backgroundWindow.rootViewController = self.vc;
    
    [self.vc showAlert];
}

- (void)coverViewTouched{
    if (self.isDismissWhenTouchBackground) {
        [self dismissAlertWithCompletion:nil];
    }
}

- (void)alertBtnClick:(UIButton *)btn{
    [self dismissAlertWithCompletion:^{
        if (self.clicks.count > 0) {
            clickHandle handle = self.clicks[btn.tag];
            if (![handle isEqual:[NSNull null]]) {
                handle();
            }
        } else {
            if (self.clickWithIndex) {
                self.clickWithIndex(btn.tag);
            }
        }
    }];
}

- (void)dismissAlertWithCompletion:(void(^)(void))completion{
    [self.vc hideAlertWithCompletion:^{
        [self stackHandle];
        
        if (completion) {
            completion();
        }
        
        NSInteger count = [CustomSingleTon shareSingleTon].alertStack.count;
        if (count > 0) {
            CustomAlertView *lastAlert = [CustomSingleTon shareSingleTon].alertStack.lastObject;
            [lastAlert showAlert];
        }
    }];
}

- (void)stackHandle{
    [[CustomSingleTon shareSingleTon].alertStack removeObject:self];
    
    NSInteger count = [CustomSingleTon shareSingleTon].alertStack.count;
    if (count == 0) {
        [self toggleKeyWindow];
    }
}

- (void)toggleKeyWindow{
    [[CustomSingleTon shareSingleTon].oldKeyWindow makeKeyAndVisible];
    [CustomSingleTon shareSingleTon].backgroundWindow.rootViewController = nil;
    [CustomSingleTon shareSingleTon].backgroundWindow.frame = CGRectZero;
}

- (void)setup{
    if (self.subviews.count > 0) {
        return;
    }
    
    if (self.isCustomAlert) {
        return;
    }
    
    if (self.title.length > 0) {
        self.frame = CGRectMake(0, 0, CustomAlertViewWidth, CustomAlertViewHeight);
    }else{
        self.frame = CGRectMake(0, 0, CustomAlertViewWidth, CustomAlertViewHeight-40);
    }
    
    NSInteger count = self.buttons.count;
    
    if (count > 2) {
        self.frame = CGRectMake(0, 0, CustomAlertViewWidth, CustomAlertViewTitleLabelHeight + CustomAlertViewContentHeight + CustomMargin + (CustomMargin + CustomButtonHeight) * count);
    }
    self.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
    self.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    if (self.title.length > 0) {
        titleLabel.frame = CGRectMake(CustomMargin, 10, CustomAlertViewWidth - CustomMargin * 2, CustomAlertViewTitleLabelHeight-10);
    }else{
        titleLabel.frame = CGRectMake(CustomMargin, 10, CustomAlertViewWidth - CustomMargin * 2, 5);
    }
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = self.title;
    titleLabel.textColor = CustomAlertViewTitleColor;
    titleLabel.font = CustomAlertViewTitleFont;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:titleLabel];
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(CustomMargin, titleLabel.frame.origin.y + titleLabel.frame.size.height, CustomAlertViewWidth - CustomMargin * 2, CustomAlertViewContentHeight)];
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.text = self.message;
    contentLabel.textColor = CustomAlertViewContentColor;
    contentLabel.font = CustomAlertViewContentFont;
    contentLabel.numberOfLines = 0;
    contentLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:contentLabel];
    
    CGFloat contentHeight = [contentLabel sizeThatFits:CGSizeMake(CustomAlertViewWidth, CGFLOAT_MAX)].height;
    
    if (contentHeight > CustomAlertViewContentHeight) {
        [contentLabel removeFromSuperview];
        
        UITextView *contentView = [[UITextView alloc] initWithFrame:CGRectMake(CustomMargin, CustomAlertViewTitleLabelHeight, CustomAlertViewWidth - CustomMargin * 2, CustomAlertViewContentHeight)];
        contentView.backgroundColor = [UIColor clearColor];
        contentView.text = self.message;
        contentView.textColor = CustomAlertViewContentColor;
        contentView.font = CustomAlertViewContentFont;
        contentView.editable = NO;
        if (CustomiOS7OrLater) {
            contentView.selectable = NO;
        }
        [self addSubview:contentView];
        
        CGFloat realContentHeight = 0;
        if (CustomiOS7OrLater) {
            [contentView.layoutManager ensureLayoutForTextContainer:contentView.textContainer];
            CGRect textBounds = [contentView.layoutManager usedRectForTextContainer:contentView.textContainer];
            CGFloat height = (CGFloat)ceil(textBounds.size.height + contentView.textContainerInset.top + contentView.textContainerInset.bottom);
            realContentHeight = height;
        }else {
            realContentHeight = contentView.contentSize.height;
        }
        
        if (realContentHeight > CustomAlertViewContentHeight) {
            CGFloat remainderHeight = CustomAlertViewMaxHeight - CustomAlertViewTitleLabelHeight - CustomMargin - (CustomMargin + CustomButtonHeight) * count;
            contentHeight = realContentHeight;
            if (realContentHeight > remainderHeight) {
                contentHeight = remainderHeight;
            }
            
            CGRect frame = contentView.frame;
            frame.size.height = contentHeight;
            contentView.frame = frame;
            
            CGRect selfFrame = self.frame;
            selfFrame.size.height = selfFrame.size.height + contentHeight - CustomAlertViewContentHeight;
            self.frame = selfFrame;
            self.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
        }
    }
    
    if (!CustomiOS7OrLater) {
        CGRect frame = self.frame;
        frame.origin.y -= 10;
        self.frame = frame;
    }
    
    if (count == 1) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(CustomMargin, self.frame.size.height - CustomButtonHeight - CustomMargin, CustomAlertViewWidth - CustomMargin * 2, CustomButtonHeight)];
        NSDictionary *btnDict = [self.buttons firstObject];
        [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
        [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
        [self addSubview:btn];
        btn.tag = 0;
        [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    } else if (count == 2) {
        for (int i = 0; i < 2; i++) {
            //            CGFloat btnWidth = CustomAlertViewWidth / 2 - CustomMargin * 1.5;
            //            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(CustomMargin + (CustomMargin + btnWidth) * i, self.frame.size.height - CustomButtonHeight - CustomMargin, btnWidth, CustomButtonHeight)];
            CGFloat btnWidth = (ScreenWidth - 90) / 2;
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(btnWidth * i+ i * 10 + 10, self.frame.size.height - CustomButtonHeight- CustomMargin, btnWidth, CustomButtonHeight)];
            NSDictionary *btnDict = self.buttons[i];
            if (i == 0) {
                //                [btn roundSide:kSMBSideLeft];
            }else{
                
            }
            [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
            [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
            [self addSubview:btn];
            btn.tag = i;
            [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    } else if (count > 2) {
        if (contentHeight < CustomAlertViewContentHeight) {
            contentHeight = CustomAlertViewContentHeight;
        }
        for (int i = 0; i < count; i++) {
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(CustomMargin, CustomAlertViewTitleLabelHeight + contentHeight + CustomMargin + (CustomMargin + CustomButtonHeight) * i, CustomAlertViewWidth - CustomMargin * 2, CustomButtonHeight)];
            NSDictionary *btnDict = self.buttons[i];
            [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
            [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
            [self addSubview:btn];
            btn.tag = i;
            [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)setButton:(UIButton *)btn BackgroundWithButonType:(CustomAlertViewButtonType)buttonType{
    UIColor *textColor = nil;
    UIColor *layColor = nil;
    switch (buttonType) {
        case CustomAlertViewButtonTypeDefault:
            
            layColor = CustomColor(68, 190, 255);
            textColor = CustomColor(255, 255, 255);
            [btn setBackgroundColor:CustomColor(50, 160, 255)];
            break;
        case CustomAlertViewButtonTypeCancel:
            
            layColor = CustomColor(151, 151, 151);
            textColor = CustomColor(255, 255, 255);
            [btn setBackgroundColor:CustomColor(50, 160, 255)];
            break;
        case CustomAlertViewButtonTypeWarn:
            
            layColor = CustomColor(255, 87, 107);
            textColor = CustomColor(255, 255, 255);
            [btn setBackgroundColor:[UIColor grayColor]];
            break;
    }
    btn.backgroundColor = layColor;
    btn.layer.cornerRadius = 3;
    [btn setTitleColor:textColor forState:UIControlStateNormal];
}

- (UIImage *)resizeImage:(UIImage *)image{
    return [image stretchableImageWithLeftCapWidth:image.size.width / 2 topCapHeight:image.size.height / 2];
}


- (void)roundSide:(SMBSide)side
{
    UIBezierPath *maskPath;
    
    if (side == kSMBSideLeft)
        maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                         byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerBottomLeft)
                                               cornerRadii:CGSizeMake(8.f, 8.f)];
    else if (side == kSMBSideRight)
        maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                         byRoundingCorners:(UIRectCornerTopRight|UIRectCornerBottomRight)
                                               cornerRadii:CGSizeMake(8.f, 8.f)];
    else if (side == kSMBSideUp)
        maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                         byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight)
                                               cornerRadii:CGSizeMake(8.f, 8.f)];
    else
        maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                         byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                               cornerRadii:CGSizeMake(8.f, 8.f)];
    
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the image view's layer
    self.layer.mask = maskLayer;
    
    [self.layer setMasksToBounds:YES];
}

@end
