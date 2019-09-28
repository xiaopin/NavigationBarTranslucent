//
//  ViewController.m
//  Example
//
//  Created by xiaopin on 2018/3/22.
//

#import "ViewController.h"
#import "XPNavigationBarTranslucent.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // translucent必须为YES,导航栏才能实现透明效果
    self.navigationController.navigationBar.translucent = YES;
    // 自定义导航栏颜色
    self.navigationController.navigationBar.barTintColor = [UIColor purpleColor];
    // 导航栏透明度
    [self setNavigationBarAlpha:0.0];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * const reuseIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row];
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat maxOffset = 100.0;
    CGFloat verticalOffset = MIN(MAX(scrollView.contentOffset.y, 0.0), maxOffset);
    CGFloat alpha = verticalOffset / maxOffset;
    [self setNavigationBarAlpha:alpha];
}

@end
