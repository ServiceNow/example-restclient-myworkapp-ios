/*
Copyright (c) 2016 ServiceNow, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
*/


#import "APIRequestMonitor.h"

@implementation APIRequestMonitor {
    BOOL _isMessageViewDisplayed;
}

+ (instancetype) _sharedRequestMonitor {
    static APIRequestMonitor *_sharedRequestMonitor = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedRequestMonitor = [[self alloc] init];
    });
    
    return _sharedRequestMonitor;
}


- (void)stopMontoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self stopMontoring];
}

- (void)startMontoring {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkRequestDidStart:)
                                                 name:AFNetworkingTaskDidResumeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkRequestDidFinish:)
                                                 name:AFNetworkingTaskDidCompleteNotification
                                               object:nil];
}

- (void) networkRequestDidStart:(NSNotification *)notification {

    UIView *view =  [[self topMostController] view];
    
    if(_isMessageViewDisplayed){
        return;
    }

    _isMessageViewDisplayed = YES;
    
    self.mask = [[UIView alloc] initWithFrame:[view bounds]];
    self.mask.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    UIAlertView *loadMessageView = [[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 170, 170)];
    [self.mask addSubview:loadMessageView];
    loadMessageView.center = view.center;
    
    loadMessageView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    loadMessageView.clipsToBounds = YES;
    loadMessageView.layer.cornerRadius = 10.0;
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.frame = CGRectMake(65, 40, activityIndicatorView.bounds.size.width, activityIndicatorView.bounds.size.height);
    [loadMessageView addSubview:activityIndicatorView];
    [activityIndicatorView startAnimating];
    
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(20, 115, 130, 22)];
    message.backgroundColor = [UIColor clearColor];
    message.textColor = [UIColor whiteColor];
    message.adjustsFontSizeToFitWidth = YES;
    message.textAlignment = NSTextAlignmentCenter;
    message.text = @"Loading...";
    [loadMessageView addSubview:message];

    [view addSubview:self.mask];
}

- (void) networkRequestDidFinish:(NSNotification *)notification {
     _isMessageViewDisplayed = NO;
    [self.mask removeFromSuperview];
}

- (UIViewController*) topMostController
{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end
