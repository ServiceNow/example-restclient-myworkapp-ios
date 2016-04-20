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

#import "LoginProgressViewController.h"
#import "Authenticator.h"
#import "Properties.h"
#import "AppDelegate.h"

@interface LoginProgressViewController ()

@end

@implementation LoginProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self authenticationCheck];
}

-(void)authenticationCheck;{
    // If not authenticated. Most of the time when launching, it is not, show indicator view(or some non login required view) while we try to authenticate from Keychain data
    
   Authenticator *authenticator=[Authenticator sharedAuthenticator];

    if(![authenticator isAuthenticated]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginEventListener:) name:KEYCHAIN_LOGIN_EVENT object:nil];
        
        [authenticator authenticateFromKeyChain];
        // Loading Login progress view: redirected here from App delegate waiting for authentication using keychain data.
        // Listen for Login Event

    } else {
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TaskListViewNavController"];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

-(void) loginEventListener:(NSNotification *) ntfcn {
    AuthSession *session = [AuthSession sharedSession];

    if([session isAuthenticated]) {
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        [appDelegate sendDeviceToken];

        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TaskListViewNavController"];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewNavController"];
        [vc setModalPresentationStyle:UIModalPresentationFullScreen];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
