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

#import <Foundation/Foundation.h>
#define USER_NAME @"username"
#define PASSWORD @"password"
#define AUTH_TYPE @"authType"
#define BASIC @"Basic"
#define HOST_NAME @"host_name"
#define INSTANCE_NAME @"instance_name"
#define LOGIN_EVENT @"login_event"
#define KEYCHAIN_LOGIN_EVENT @"ks_login_event"
#define KEYCHAIN_APP_ID @"com.now.api.MyTasks"
#define DOMAIN_NAME @".service-now.com"
#define PROTOCOL @"https://"
#define OAUTH_CLIENT_ID_VALUE @"4351eb7c311d1240026d7202c346b092"
#define OAUTH_CLIENT_SECRET_VALUE @"C*AQK`J*:a"

@interface Properties : NSObject{

}

+(void) setInstanceName:(NSString *)instanceName;
+(NSString *) getHostName;
+(NSString *) getInstanceName;
+(NSString *) getBaseURL;
+(NSString *) getAPPID;
+(NSString *)getClientId;
+(NSString *)getClientSecret;

@end
