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

#import "DetailViewController.h"
#import "RestAPIRequestHandler.h"
#import "Properties.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UITextField *number;
@property (weak, nonatomic) IBOutlet UITextView *shortDescription;
@property (weak, nonatomic) IBOutlet UITextView *comment;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *save;
@property (weak, nonatomic) IBOutlet UITextField *opened;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title=self.item.tableName;
    [self retrieveDetail];
    [self getRecentActivity];
}

-(void) retrieveDetail;{
     RestAPIRequestHandler *apiHandler = [[RestAPIRequestHandler alloc]init];
    [apiHandler getTaskDetails:self.item.sysId success:^(NSDictionary *result)  {
        self.item.shortDescription=result[@"short_description"];
        self.item.number=result[@"number"];
        self.item.opened=result[@"sys_created_on"];
        self.number.text= self.item.number;
        self.shortDescription.text =self.item.shortDescription;
        self.opened.text=self.item.opened;
    } failure:^(NSError* error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error retrieving Task details. Retry ?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [self retrieveDetail];
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
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
        return 2;
    else if(section == 1){
        return 1;
    } else if(section == 2){
        return 3;
    }
    return 0;
}

- (IBAction)save:(id)sender {
    NSString *comment = self.comment.text;
    RestAPIRequestHandler *apiHandler = [[RestAPIRequestHandler alloc]init];
    [apiHandler postComment:comment onTask:self.item.sysId success:^(NSDictionary *result) {
        self.comment.text=@"";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Comment Saved" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        [self getRecentActivity];
    } failure:^(NSError* error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error saving comments. Retry ?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [self save];
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
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

-(void)getRecentActivity;{
    RestAPIRequestHandler *apiHandler = [[RestAPIRequestHandler alloc]init];
    [apiHandler getTaskComments:self.item.sysId success:^(NSArray *response) {
        for (int i=0; i<[response count]; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:2];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

            [cell initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            
            NSString *cellValue = response[i][@"value"];
            NSString *createdOn = response[i][@"sys_created_on"];
            NSString *createdBy = response[i][@"sys_created_by"];
            cell.textLabel.text = cellValue;
            
            NSMutableParagraphStyle *subtitleParagraphStyle = [NSMutableParagraphStyle new];
            subtitleParagraphStyle.minimumLineHeight = 5;
            subtitleParagraphStyle.lineSpacing = 0.3;
            subtitleParagraphStyle.minimumLineHeight = 0.4f;
            NSString *desc = [NSString stringWithFormat:@"%@, %@", createdBy, createdOn] ;
            NSMutableAttributedString *subText = [[[NSAttributedString alloc] initWithString:desc] mutableCopy];
            [subText addAttribute:NSParagraphStyleAttributeName value:subtitleParagraphStyle range:NSMakeRange(0, subText.length)];
            cell.detailTextLabel.attributedText = subText;
            cell.detailTextLabel.numberOfLines = 3;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }  failure:^(NSError* error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error retrieving recent activity" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
     ];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
