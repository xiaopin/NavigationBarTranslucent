//
//  XPNavigationBarTranslucent.m
//  https://github.com/xiaopin/NavigationBarTranslucent.git
//
//  Created by xiaopin on 2018/3/22.
//

#import "XPNavigationBarTranslucent.h"

#import <objc/message.h>


#pragma mark - UINavigationController

@interface UINavigationController (NavigationBarTranslucent) <UINavigationBarDelegate>

@end

@implementation UINavigationController (NavigationBarTranslucent)

static NSTimeInterval kAlphaDuration = 0.25;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString*> *swizzledSelectors = @[
                                                  @"_updateInteractiveTransition:",
                                                  NSStringFromSelector(@selector(popViewControllerAnimated:)),
                                                  NSStringFromSelector(@selector(popToViewController:animated:)),
                                                  NSStringFromSelector(@selector(popToRootViewControllerAnimated:)),
                                                  ];
        
        for (NSString *selectorStr in swizzledSelectors) {
            NSString *replaceSelector = [@"nbt_" stringByAppendingString:selectorStr];
            Method orignalMethod = class_getInstanceMethod(self, NSSelectorFromString(selectorStr));
            Method swizzledMethod = class_getInstanceMethod(self, NSSelectorFromString(replaceSelector));
            method_exchangeImplementations(orignalMethod, swizzledMethod);
        }
    });
}

- (void)nbt__updateInteractiveTransition:(CGFloat)percentComplete {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.topViewController.transitionCoordinator;
    if (transitionCoordinator) {
        if (@available(iOS 10.0, *)) {
            [transitionCoordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self dealInteractionChangesWithContext:context];
            }];
        } else {
            [transitionCoordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self dealInteractionChangesWithContext:context];
            }];
        }
        UIViewController *fromVC = [transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *toVC = [transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
        
        CGFloat alpha = fromVC.navigationBarAlpha + (toVC.navigationBarAlpha - fromVC.navigationBarAlpha) * percentComplete;
        [self setNavigationBarBackgroundAlpha:alpha];
    }
    [self nbt__updateInteractiveTransition:percentComplete];
}

- (UIViewController *)nbt_popViewControllerAnimated:(BOOL)animated {
    NSArray *viewControllers = [self viewControllers];
    NSUInteger count = [viewControllers count];
    NSUInteger index = MAX(count - 2, 0);
    UIViewController *preViewController = viewControllers[index];
    [UIView animateWithDuration:kAlphaDuration animations:^{
        [self setNavigationBarBackgroundAlpha:preViewController.navigationBarAlpha];
    }];
    return [self nbt_popViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)nbt_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [UIView animateWithDuration:kAlphaDuration animations:^{
        [self setNavigationBarBackgroundAlpha:viewController.navigationBarAlpha];
    }];
    return [self nbt_popToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)nbt_popToRootViewControllerAnimated:(BOOL)animated {
    CGFloat alpha = self.viewControllers.firstObject.navigationBarAlpha;
    [UIView animateWithDuration:kAlphaDuration animations:^{
        [self setNavigationBarBackgroundAlpha:alpha];
    }];
    return [self nbt_popToRootViewControllerAnimated:animated];
}

#pragma mark <UINavigationBarDelegate>

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    [self setNavigationBarBackgroundAlpha:self.topViewController.navigationBarAlpha];
    return YES;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.topViewController.transitionCoordinator;
    if (transitionCoordinator && transitionCoordinator.initiallyInteractive) {
        // 滑动手势
        if (@available(iOS 10.0, *)) {
            [transitionCoordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self dealInteractionChangesWithContext:context];
            }];
        } else {
            [transitionCoordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self dealInteractionChangesWithContext:context];
            }];
        }
    } else {
        NSInteger idx = self.viewControllers.count >= self.navigationBar.items.count ? 2 : 1;
        UIViewController *popToVC = self.viewControllers[self.viewControllers.count - idx];
        [self popToViewController:popToVC animated:YES];
    }
    return YES;
}

#pragma mark Private

- (void)setNavigationBarBackgroundAlpha:(CGFloat)alpha {
    UIView *barBackgroundView = self.navigationBar.subviews.firstObject;
    if (@available(iOS 13.0, *)) {
        barBackgroundView.alpha = alpha;
        return;
    }
    // 处理底部分割线
    UIView *shadowView = [barBackgroundView valueForKey:@"_shadowView"];
    shadowView.hidden = (alpha < 1.0);
    // 处理背景
    if (self.navigationBar.isTranslucent) {
        if (@available(iOS 10.0, *)) {
            UIView *backgroundEffectView = [barBackgroundView valueForKey:@"_backgroundEffectView"];
            backgroundEffectView.alpha = alpha;
        } else {
            UIView *adaptiveBackdrop = [barBackgroundView valueForKey:@"_adaptiveBackdrop"];
            adaptiveBackdrop.alpha = alpha;
        }
    } else {
        barBackgroundView.alpha = alpha;
    }
}

- (void)dealInteractionChangesWithContext:(id<UIViewControllerTransitionCoordinatorContext>)context {
    double percentComplete;
    UITransitionContextViewControllerKey transitionVCKey;
    if (context.isCancelled) {
        percentComplete = context.percentComplete;
        transitionVCKey = UITransitionContextFromViewControllerKey;
    } else {
        percentComplete = 1.0 - context.percentComplete;
        transitionVCKey = UITransitionContextToViewControllerKey;
    }
    NSTimeInterval duration = context.transitionDuration * percentComplete;
    CGFloat alpha = [[context viewControllerForKey:transitionVCKey] navigationBarAlpha];
    [UIView animateWithDuration:duration animations:^{
        [self setNavigationBarBackgroundAlpha:alpha];
    }];
}

- (UIColor *)averageColorWithFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor percent:(CGFloat)percent {
    CGFloat fromRed, fromGreen, fromBlue, fromAlpha;
    CGFloat toRed, toGreen, toBlue, toAlpha;
    [fromColor getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha];
    [toColor getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha];
    
    CGFloat red = fromRed + (toRed - fromRed) * percent;
    CGFloat green = fromGreen + (toGreen - fromGreen) * percent;
    CGFloat blue = fromBlue + (toBlue - fromBlue) * percent;
    CGFloat alpha = fromAlpha + (toAlpha - fromAlpha) * percent;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end


#pragma mark - UIViewController

@implementation UIViewController (NavigationBarTranslucent)

- (void)setNavigationBarAlpha:(CGFloat)navigationBarAlpha {
    CGFloat alpha = MIN(MAX(navigationBarAlpha, 0.0), 1.0);
    objc_setAssociatedObject(self, @selector(navigationBarAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.navigationController setNavigationBarBackgroundAlpha:alpha];
}

- (CGFloat)navigationBarAlpha {
    NSNumber *number = objc_getAssociatedObject(self, @selector(navigationBarAlpha));
    if (nil == number) {
        return 1.0;
    }
    return [number floatValue];
}

@end
