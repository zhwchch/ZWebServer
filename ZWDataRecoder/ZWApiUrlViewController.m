
#import "ZWApiUrlViewController.h"
#import "ZWApiDataViewController.h"
#import "ZWApiDataStorer.h"
#import "ZWApiDataRecorder.h"


#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define NAVIGATION_BAR_HEIGHT 64.0
#define TABLEVIEWCELL_HEIGHT 45.0

@interface ZWApiUrlViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *urls;
@end

@implementation ZWApiUrlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _urls = [[ZWApiDataStorer sharedStorer] allDataUrls];
    
    [self addSubView];
}

- (void)addSubView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 8, SCREEN_WIDTH, SCREEN_HEIGHT-NAVIGATION_BAR_HEIGHT) style:UITableViewStyleGrouped];
    [self.view addSubview:_tableView];
    _tableView.bounces = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.sectionFooterHeight = 4;
    _tableView.sectionHeaderHeight = 4;
    _tableView.rowHeight = TABLEVIEWCELL_HEIGHT;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.01)];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DataUrls"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _urls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"DataUrls" forIndexPath:indexPath];
    cell.textLabel.text = _urls[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:14.f];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    ZWApiDataViewController *vc = [[ZWApiDataViewController alloc] initWithUrl:_urls[indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];

}

@end
