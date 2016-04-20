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

#import "OAuthHandle.h"
#import "Properties.h"
#import "AFHTTPSessionManagerFactory.h"
#import "SSKeychain.h"

#define ACCESS_TOKEN @"access_token"
#define REFRESH_TOKEN @"refresh_token"
#define CLIENT_ID @"client_id"
#define CLIENT_SECRET @"client_secret"
#define EXPIRY_TIME @"expires_in"
#define GRANT_TYPE @"grant_type"

@implementation OAuthHandle


-(id)init;{
    self =[super init];
    
    _clientId = [Properties getClientId];
    _clientSecret = [Properties getClientSecret];
    [SSKeychain setPassword:_clientId
                 forService:[Properties getAPPID]
                    account:CLIENT_ID];
    [SSKeychain setPassword:_clientSecret
                 forService:[Properties getAPPID]
                    account:CLIENT_SECRET];
    
    return self;
}

-(void) authenticate:(NSString *)userName password:(NSString *)password;{
    AFHTTPSessionManager *manager = [AFHTTPSessionManagerFactory sharedManager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"password",GRANT_TYPE,_clientId,CLIENT_ID, _clientSecret,CLIENT_SECRET, userName, USER_NAME, password, PASSWORD, nil];
    
    [manager POST:@"/oauth_token.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // On success, save UserName, refresh token, client Id, client secret, expiry time in keychain
        NSString *refresh_token = responseObject[REFRESH_TOKEN];
        NSString *expiryTime = responseObject[EXPIRY_TIME];
        NSString *access_token = responseObject[ACCESS_TOKEN];
        
        [SSKeychain setPassword:userName
                     forService: [Properties getAPPID]
                        account:USER_NAME];
        
        [SSKeychain setPassword:refresh_token
                     forService:[Properties getAPPID]
                        account:REFRESH_TOKEN];

        [self saveExpiryTime:expiryTime];
        
        [self login:userName accessToken:access_token fromKeyChain:NO];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_EVENT object: nil];
    }];

}

- (void)authenticateUsingKeyChain; {
    NSString *userName = [SSKeychain passwordForService:[Properties getAPPID] account:USER_NAME];
    NSString *access_token = [SSKeychain passwordForService:[Properties getAPPID] account:ACCESS_TOKEN];

    NSString *expiryTimeString = [SSKeychain passwordForService:[Properties getAPPID] account:EXPIRY_TIME];

    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterFullStyle];
    NSDate *expiryDate = [formatter dateFromString:expiryTimeString];
    
    if(NSOrderedDescending ==[expiryDate compare:[NSDate date]]) {
            // If not expired, make sys_user call with access token
        [self login:userName accessToken:access_token fromKeyChain:YES];
    } else {
        AFHTTPSessionManager *manager = [AFHTTPSessionManagerFactory sharedManager];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        
        NSString *refresh_token = [SSKeychain passwordForService:[Properties getAPPID] account:REFRESH_TOKEN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"refresh_token",GRANT_TYPE,_clientId,CLIENT_ID, _clientSecret,CLIENT_SECRET, refresh_token, REFRESH_TOKEN, nil];

        [manager POST:@"/oauth_token.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            // On success, save UserName, refresh token, client Id, client secret, expiry time in keychain
            NSString *refresh_token = responseObject[REFRESH_TOKEN];
            NSString *expiryTime = responseObject[EXPIRY_TIME];
            NSString *access_token = responseObject[ACCESS_TOKEN];
            
            [SSKeychain setPassword:userName
                         forService: [Properties getAPPID]
                            account:USER_NAME];
            [SSKeychain setPassword:refresh_token
                         forService:[Properties getAPPID]
                            account:REFRESH_TOKEN];
            [self saveExpiryTime:expiryTime];

            [self login:userName accessToken:access_token fromKeyChain:YES];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:KEYCHAIN_LOGIN_EVENT object: nil];
        }];
    }
}

-(void) login:(NSString *)userName accessToken:(NSString *)accessToken fromKeyChain:(BOOL)fromKC;{
    
    
    NSString *fields = @"name,email";
    NSString *userInfoAPI = [NSString stringWithFormat:@"/api/now/table/sys_user?sysparm_fields=%@&user_name=%@",  fields, userName];
    
    // Setting up HTTPSession manager for entire app with proper username and password.
    AFHTTPSessionManager *manager = [AFHTTPSessionManagerFactory sharedManager];
    NSString *authHeader = [NSString stringWithFormat: @"Bearer %@", accessToken];
    [manager.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    [manager GET:userInfoAPI parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [SSKeychain setPassword:accessToken
                     forService: [Properties getAPPID]
                        account:ACCESS_TOKEN];
        
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
    [SSKeychain deletePasswordForService:[Properties getAPPID] account:ACCESS_TOKEN];
    [SSKeychain deletePasswordForService:[Properties getAPPID] account:REFRESH_TOKEN];
    [SSKeychain deletePasswordForService:[Properties getAPPID] account:EXPIRY_TIME];
}

-(void)saveExpiryTime: (NSString *)expiryTime{
    NSDate *mydate = [NSDate date];
    NSDate *expiryDate = [mydate dateByAddingTimeInterval:[expiryTime intValue]];
    NSString *expiryDateString = [NSDateFormatter localizedStringFromDate:expiryDate
                                                                dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterFullStyle];
    
    [SSKeychain setPassword:expiryDateString
                 forService:[Properties getAPPID]
                    account:EXPIRY_TIME];

}
@end
