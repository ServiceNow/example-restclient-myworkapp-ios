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

#import "Properties.h"
#import "SSKeychain.h"

@implementation Properties

+(void) setInstanceName:(NSString *)instanceName {
    [SSKeychain setPassword:instanceName
                 forService: [Properties getAPPID]
                    account:INSTANCE_NAME];
}

+ (NSString *) getInstanceName;{
    return [SSKeychain passwordForService:[Properties getAPPID] account:INSTANCE_NAME];
}

+ (NSString *) getHostName;{
    NSString * instanceName = [self getInstanceName];
    
    if([instanceName length] ==0) {
        return @"";
    }

    NSString *hostName = [instanceName hasSuffix:DOMAIN_NAME] ? instanceName : [instanceName stringByAppendingString:DOMAIN_NAME];
    
    NSString *fullHostName = [hostName hasPrefix:PROTOCOL] ?hostName:[PROTOCOL stringByAppendingString:hostName];

    return fullHostName;
}

+ (NSString *) getBaseURL;{
    return [self getHostName];
}

+ (NSString *) getAPPID;{
    return KEYCHAIN_APP_ID;
}

+(NSString *)getClientId;{
    return OAUTH_CLIENT_ID_VALUE;
}

+(NSString *)getClientSecret;{
    return OAUTH_CLIENT_SECRET_VALUE;
}

@end
