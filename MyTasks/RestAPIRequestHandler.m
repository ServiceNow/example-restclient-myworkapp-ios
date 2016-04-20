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

#import "RestAPIRequestHandler.h"
#import "Properties.h"
#import "AFHTTPSessionManagerFactory.h"

@implementation RestAPIRequestHandler

-(id) init;{
    if( self = [super init] ) {
        self.manager = [AFHTTPSessionManagerFactory sharedManager];
    }
    return self;
}

-(void) getTaskComments:(NSString*) taskId success: (void (^) (NSArray* result))success  failure:(void (^)(NSError* error))failure {
    NSString* query = [NSString stringWithFormat: @"element_id=%@^ORDERBYDESCsys_created_on",taskId];
    NSString* limit = @"3";
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:query,@"sysparm_query",limit,@"sysparm_limit",nil];
    NSString *endPoint = @"api/now/v2/table/sys_journal_field";
    
    [self.manager GET:endPoint parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* response = (NSDictionary *)responseObject;
        NSArray* comments =  response[@"result"];
        success(comments);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Request sent with error");
        failure(error);
    }];
}

-(void) getAssignedTasks:(void (^)(NSDictionary* result))success failure: (void (^) (NSURLSessionDataTask * _Nullable task, NSError* error))failure {
    NSString *endPoint = @"api/x_snc_my_work/v1/tracker/task";
    [self.manager GET:endPoint parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* response = (NSDictionary *)responseObject;
        NSDictionary* result =  response[@"result"];
        success(result);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Request sent with error");
        failure(task, error);
    }];
}

-(void) getTaskDetails:(NSString*) taskId success: (void (^) (NSDictionary* result))success failure: (void (^) (NSError* error))failure {
    NSString *endPoint = [NSString stringWithFormat: @"api/now/v2/table/task/%@",taskId];
    
    [self.manager GET:endPoint parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* response = (NSDictionary *)responseObject;
        NSDictionary* result =  response[@"result"];
        success(result);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Request sent with error");
                failure(error);
    }];
}

-(void) postComment:(NSString*) comment onTask: (NSString*) taskId success: (void (^) (NSDictionary* result))success failure: (void (^) (NSError* error))failure {
     NSString* endPoint = [NSString stringWithFormat: @"api/x_snc_my_work/v1/tracker/task/%@/comment",taskId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:comment,@"comment",nil];
    
    [self.manager POST:endPoint parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* response = (NSDictionary *)responseObject;
        success(response);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Request sent with error");
                failure(error);
    }];
}

-(void) postInstallation:(NSString*) token success: (void (^) (NSDictionary* result))success  failure:(void (^)(NSError* error))failure {
    NSString* applicationName = @"MyTasks";
    NSString* platform = @"Apple";
    NSString* endPoint = [NSString stringWithFormat: @"api/now/v1/push/%@/installation", applicationName];

    NSDictionary *params = @ {@"platform" :platform, @"token" :token };

    [self.manager POST:endPoint
            parameters:params
              progress:nil
               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   NSLog(@"Token installed on instance");
                   NSDictionary* response = [NSMutableDictionary dictionary];
                   if (success) {
                       success(response);
                   }
               } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   if (failure) {
                       failure(error);
                   }
               }];
}

@end
