
#import "ZWApiDataViewController.h"
#import "ZWApiDataStorer.h"
#import "ZWApiDataRecorder.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define NAVIGATION_BAR_HEIGHT 64.0
#define TABLEVIEWCELL_HEIGHT 45.0

@interface ZWApiDataViewModel : NSObject
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, strong) NSDictionary *modelDict;
@property (nonatomic, strong) ZWApiDataModel *model;
@end

@implementation ZWApiDataViewModel

@end

@interface ZWApiDataViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSArray<ZWApiDataViewModel *> *apiData;
@end

@implementation ZWApiDataViewController
- (instancetype)initWithUrl:(NSString *)url {
    if (self = [super init]) {
        _url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self processData];
    
    [self addSubView];
}

- (void)processData {
    
   NSArray<ZWApiDataModel *> *models = [[ZWApiDataStorer sharedStorer] dataWithURLString:_url index:&_index];
    NSMutableArray<ZWApiDataViewModel *> *viewModels = [NSMutableArray array];
    for (ZWApiDataModel *obj in models) {
        [viewModels addObject:[ZWApiDataViewModel new]];
        viewModels.lastObject.model = obj;
        viewModels.lastObject.height = 44;
    }
    _apiData = viewModels;
}

- (void)addSubView
{
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
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ApiData"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _apiData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ZWApiDataViewModel *viewModel = _apiData[indexPath.row];
    if (!viewModel.modelDict) {
        viewModel.modelDict = [NSJSONSerialization JSONObjectWithData:viewModel.model.data options:kNilOptions error:nil];
    }

    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"ApiData" forIndexPath:indexPath];
    cell.textLabel.text = viewModel.modelDict.description;
    cell.textLabel.font = [UIFont systemFontOfSize:12.f];
    cell.textLabel.numberOfLines = 0;
    
    if (indexPath.row == _index) {
        cell.selected = YES;
        cell.backgroundColor = [UIColor blueColor];
    } else {
        cell.selected = NO;
        cell.backgroundColor = [UIColor whiteColor];
    }

    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZWApiDataViewModel *viewModel = _apiData[indexPath.row];
    if (viewModel.isExpanded) {
        if (viewModel.height > 44 || viewModel.model.data.length == 0) {
            return viewModel.height;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:viewModel.model.data options:kNilOptions error:nil];
        CGRect r = [dict.description boundingRectWithSize:CGSizeMake(334, NSIntegerMax) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f]} context:nil];
        viewModel.height = r.size.height;
        return r.size.height;
    }
    return 44;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    ZWApiDataViewModel *viewModel = _apiData[indexPath.row];
    viewModel.isExpanded = !viewModel.isExpanded;

    
    if (viewModel.model.data.length > 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.backgroundColor = [UIColor blueColor];
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_index inSection:0]];
        cell.backgroundColor = [UIColor whiteColor];
        
        _index = indexPath.row;
        [[ZWApiDataStorer sharedStorer] setDefaultDataWithURLString:_url index:_index];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
