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

#import "LoginViewController.h"
#import "Properties.h"
#import "Authenticator.h"
#import "AFHTTPSessionManagerFactory.h"
#import "AppDelegate.h"


@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *instanceName;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UILabel *errorMsg;
@property (weak, nonatomic) IBOutlet UIButton *login;
@property (weak, nonatomic) IBOutlet UILabel *protocol;
@property (weak, nonatomic) IBOutlet UILabel *domainName;
@property (weak, nonatomic) IBOutlet UILabel *fullHostName;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Loading login view:  reset error message, logout to clean redundant session data
    [self.errorMsg setText:@""];
    UIImage* logoImage = [UIImage imageNamed:@"icon_small.png"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:logoImage];
    
    self.navigationItem.hidesBackButton = YES;
    self.instanceName.text= [Properties getInstanceName];
    [self setFullHostNameText];

    _authenticator=[Authenticator sharedAuthenticator];
    [_authenticator logout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)login:(id)sender {
    if([self.instanceName.text length]==0 || [self.userName.text length]==0 || [self.password.text length]==0){
        [self.errorMsg setText: @"Enter login credentials "];
    }
    
    // Login button clicked. Start authentication process and wait for login_event ntfcn
    [_authenticator authenticate:self.userName.text password:self.password.text];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginEventListener:) name:LOGIN_EVENT object:nil];
}
- (IBAction)instanceNameChanged:(id)sender {
    [self setFullHostNameText];
    [Properties setInstanceName:self.instanceName.text];
}

- (IBAction)instanceNameValueEdited:(id)sender {
        [self setFullHostNameText];
}

-(void) setFullHostNameText;{
    if([self.instanceName.text length] ==0)
        self.fullHostName.text=[[PROTOCOL stringByAppendingString:@"<Instance name>"]stringByAppendingString:DOMAIN_NAME];
    else
        self.fullHostName.text=[[PROTOCOL stringByAppendingString:self.instanceName.text]stringByAppendingString:DOMAIN_NAME];
}

-(void) loginEventListener:(NSNotification *) ntfcn {
    // Handle Login Event. Verify if authentication succeeded and redirect to approapriate view or set appropriate error message
    AuthSession *session = [AuthSession sharedSession];
    if([session isAuthenticated]) {
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        [appDelegate sendDeviceToken];
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TaskListViewNavController"];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        [self.errorMsg setText:@"Login failed. Check credentials"];
    }
}

@end
