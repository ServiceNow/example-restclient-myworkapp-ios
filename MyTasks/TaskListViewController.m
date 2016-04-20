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

#import "TaskListViewController.h"
#import "DetailViewController.h"
#import "AuthSession.h"
#import "Properties.h"
#import "RestAPIRequestHandler.h"


@interface TaskListViewController (){
    NSMutableSet* _collapsedSections;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutBtn;

@end

@implementation TaskListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"My Tasks";
     _collapsedSections = [NSMutableSet new];
    [self retrieveTasks];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionName = [self.sections objectAtIndex:section];
    NSArray *recordsForSection = [self.result objectForKey:sectionName];
    return [_collapsedSections containsObject:@(section)] ? 0 : [recordsForSection count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier  = @"Cell Identifier";
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:CellIdentifier];
    
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    
    NSArray *records = [self.result objectForKey:section];
    NSDictionary *record = [records objectAtIndex:indexPath.row];
    
    NSMutableParagraphStyle *subtitleParagraphStyle = [NSMutableParagraphStyle new];
    subtitleParagraphStyle.minimumLineHeight = 5;
    subtitleParagraphStyle.lineSpacing = 0.3;
    subtitleParagraphStyle.minimumLineHeight = 0.4f;
    
    NSString *desc = [record objectForKey:@"short_desc"];
    if(![desc isEqual:[NSNull null]]){
        NSMutableAttributedString *subText = [[[NSAttributedString alloc] initWithString:desc] mutableCopy];
        [subText addAttribute:NSParagraphStyleAttributeName value:subtitleParagraphStyle range:NSMakeRange(0, subText.length)];
        cell.detailTextLabel.attributedText = subText;
        cell.detailTextLabel.numberOfLines = 3;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }

    
    
    NSString *number = [record objectForKey:@"number"];
    cell.textLabel.text = number;
    
    self.tableView.rowHeight = 80.0;
    
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:
(NSIndexPath *)indexPath {
    
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DetailViewController *infoController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    NSArray *records = [self.result objectForKey:section];
    NSDictionary *record = [records objectAtIndex:indexPath.row];
    
    TaskItem *item = [[TaskItem alloc]init];
    item.tableName = section;
    item.sysId = [record objectForKey:@"sys_id"];
    infoController.item = item;
    [self.navigationController pushViewController: infoController animated: YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self.sections objectAtIndex:section];
    return sectionTitle;
}

-(NSArray*) indexPathsForSection:(int)section withNumberOfRows:(int)numberOfRows {
    NSMutableArray* indexPaths = [NSMutableArray new];
    for (int i = 0; i < numberOfRows; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

-(void)sectionAccordion:(UITapGestureRecognizer*)sender {
    [self.tableView beginUpdates];
    int section = sender.view.tag;
  
    bool shouldCollapse = ![_collapsedSections containsObject:@(section)];
    if (shouldCollapse) {
        int numOfRows = [self.tableView numberOfRowsInSection:section];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numOfRows];
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        [_collapsedSections addObject:@(section)];
        if([sender.view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *) sender.view;
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^
             {
                 CGAffineTransform transform = button.imageView.transform;
                 CGAffineTransform transform_new = CGAffineTransformRotate(transform, M_PI);
                 button.imageView.transform = transform_new;
             } completion:NULL];
        }
    } else {
        NSString *sectionName = [self.sections objectAtIndex:section];
        NSArray *recordsForSection = [self.result objectForKey:sectionName];
        int numRows = [recordsForSection count];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numRows];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        [_collapsedSections removeObject:@(section)];
        if([sender.view isKindOfClass:[UIButton class]]){
            UIButton *button = (UIButton *) sender.view;
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^
             {
                 CGAffineTransform transform = button.imageView.transform;
                 CGAffineTransform transform_new = CGAffineTransformRotate(transform, M_PI);
                 button.imageView.transform = transform_new;
             } completion:NULL];
        }
    }
    [self.tableView endUpdates];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *sectionView = [[UITableViewHeaderFooterView alloc]init];
    
    UIButton *button = [[UIButton alloc]init];
    [[button imageView] setContentMode:UIViewContentModeScaleAspectFill];

    UIImage *btnImage = [UIImage imageNamed:@"up.png"];
    [button setImage:btnImage forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [sectionView.contentView addSubview:button];
    [button.trailingAnchor constraintEqualToAnchor:sectionView.trailingAnchor].active = YES;
    [button.bottomAnchor constraintEqualToAnchor:sectionView.bottomAnchor].active = YES;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sectionAccordion:)];
    button.tag=section;
    [button addGestureRecognizer:tapGesture];
    return sectionView;
}

-(void)retrieveTasks; {
    RestAPIRequestHandler *apiHandler = [[RestAPIRequestHandler alloc]init];
    [apiHandler getAssignedTasks:^(NSDictionary *result) {
        self.sections = [[result allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        if([self.sections count] ==0){
            UIView *view =  self.view;
            
            UIView *msgView = [[UIView alloc] initWithFrame:[view bounds]];
            msgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
            
            UILabel *message = [[UILabel alloc] initWithFrame:[view bounds]];
            message.backgroundColor = [UIColor whiteColor];
            message.textColor = [UIColor blackColor];
            message.adjustsFontSizeToFitWidth = YES;
            message.textAlignment = NSTextAlignmentCenter;
            message.text = @"Nice Job!. It looks like you dont have any tasks in your queue";
            [msgView addSubview:message];
            [view addSubview:msgView];
        }
        self.result = result;
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError *error) {
        UIAlertController *alert = nil;
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        if(response.statusCode ==  400) {
            alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"The Task Tracker API is not found on this instance. Did you install the \"My Work\" Update Set?" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok];
        } else {
            alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error sending request. Retry ?" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [self retrieveTasks];
                             }];
            [alert addAction:ok];
            UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
            [alert addAction:cancel];
        }
        if(alert != nil) {
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

@end
