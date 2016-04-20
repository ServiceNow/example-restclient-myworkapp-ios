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

#import "BasicAuthHandle.h"
#import "SSKeychain.h"
#import "Properties.h"
#import "AFHTTPSessionManagerFactory.h"
#import "AFNetworking.h"
#import "AuthSession.h"
#import "AFNetworking/AFURLResponseSerialization.h"

@implementation BasicAuthHandle

-(void) authenticate:(NSString *)userName password:(NSString *)password;{

    [self login:userName password:password fromKeyChain:NO];

}

- (void)authenticateUsingKeyChain; {

    NSString * userName = [SSKeychain passwordForService:[Properties getAPPID] account:USER_NAME];
    NSString * password = [SSKeychain passwordForService:[Properties getAPPID] account:PASSWORD];
    [self login:userName password:password fromKeyChain:YES];
}

-(void) login:(NSString *)userName password:(NSString *)password fromKeyChain:(BOOL)fromKC;{

    NSString *fields = @"name,email";
    NSString *userInfoAPI = [NSString stringWithFormat:@"/api/now/v2/table/sys_user?sysparm_fields=%@&user_name=%@",  fields, userName];

    // Setting up HTTPSession manager for entire app with proper username and password.
    AFHTTPSessionManager *manager = [AFHTTPSessionManagerFactory sharedManager];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:userName password:password];

    [manager GET:userInfoAPI parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        // On success store username and password in keychain. Helps in authenticating from keychain later on
        
        [SSKeychain setPassword:userName
                     forService: [Properties getAPPID]
                        account:USER_NAME];
        [SSKeychain setPassword:password
                     forService:[Properties getAPPID]
                        account:PASSWORD];

        // Populate auth session with User Info
        [self populateUserSession:responseObject[@"result"][0][@"name"]];


        // Notify Users
        
        if (fromKC) {
            [[NSNotificationCenter defaultCenter] postNotificationName:KEYCHAIN_LOGIN_EVENT object: nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_EVENT object: nil];
        }
        
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            [self logout];
            
            if (fromKC) {
                [[NSNotificationCenter defaultCenter] postNotificationName:KEYCHAIN_LOGIN_EVENT object: nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_EVENT object: nil];
            }

        }];
}

-(void) logout;{
    // Clear out credentials from keychain
    [SSKeychain deletePasswordForService:[Properties getAPPID] account:USER_NAME];
    [SSKeychain deletePasswordForService:[Properties getAPPID] account:PASSWORD];
}

@end
