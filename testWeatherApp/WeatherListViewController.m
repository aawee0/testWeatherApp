
#import "WeatherListViewController.h"
#import "CityWeatherCell.h"

#import "ApiManager.h"

#import "ForecastModel.h"


@interface WeatherListViewController ()

@property (nonatomic, weak) IBOutlet UITextField *addCityTextField;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, weak) IBOutlet UIView *progressView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *forecastArray;

@end

@implementation WeatherListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _forecastArray = [[NSMutableArray alloc] init];
    
    [self initTableView];
    
    UINib *nib = [UINib nibWithNibName:@"CityWeatherCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cityWeatherCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)initTableView {
    _tableView.allowsSelection = NO;
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_tableView addSubview:_refreshControl];
    [_refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
}

- (void)refreshTable {
    NSMutableArray *idsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < _forecastArray.count; i++) {
        ForecastModel *forecast = [_forecastArray objectAtIndex:i];
        [idsArray addObject: forecast.cityId];
    }
    [_forecastArray removeAllObjects];
    
    [self fetchForecastForCityList:idsArray];
    
    [_refreshControl endRefreshing];
    [_tableView reloadData];
}

- (void)fetchForecastForCity:(NSString *)cityName {
    [self showProgressView:YES];
    [ApiManager fetchForecastForCityApi:cityName withCompletion:^(NSData *data,
                                                                  NSURLResponse *response,
                                                                  NSError *error) {
        [self showProgressView:NO];
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments error:nil];
            ForecastModel *forecast = [ForecastModel initWithDictionary:dict];
            
            NSLog(@"(!) Response: %@ ", response);
            NSLog(@"(!) Serialized data: %@ ", dict);
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if (error) {
                    [self showAlertWithTitle:@"Error" andText:error.description andButtonNamed:@"Ok"];
                    NSLog(@"(!) Error %ld: %@ ", error.code, error.description);
                }
                else {
                    NSNumber *responseCode = dict[@"cod"];
                    if (!responseCode) {
                        [self showAlertWithTitle:@"Oops!" andText:@"Something went wrong... please check your connection and try again." andButtonNamed:@"Ok"];
                    }
                    else if ([responseCode integerValue] == 404) {
                        [self showAlertWithTitle:@"City not found" andText:nil andButtonNamed:@"Ok"];
                    }
                    else if ([responseCode integerValue] != 200) {
                        NSString *message = dict[@"message"];
                        if (message) [self showAlertWithTitle:@"Error" andText:message andButtonNamed:@"Ok"];
                    }
                    else {
                        [self addNewCity:forecast];
                    }
                }
            });
        }
        // BLOCK END
    }];
}

- (void)fetchForecastForCityList:(NSArray *)cities {
    [self showProgressView:YES];
    [ApiManager fetchForecastForSeveralCitiesApi:cities withCompletion:^(NSData *data,
                                                                  NSURLResponse *response,
                                                                  NSError *error) {
        [self showProgressView:NO];
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments error:nil];
            //ForecastModel *forecast = [ForecastModel initWithDictionary:dict];
            NSArray *forecastArray = [ForecastModel initForecastArrayWithDictionary:dict];
            
            NSLog(@"(!) Response: %@ ", response);
            NSLog(@"(!) Serialized data: %@ ", dict);
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if (error) {
                    [self showAlertWithTitle:@"Error" andText:error.description andButtonNamed:@"Ok"];
                    NSLog(@"(!) Error %ld: %@ ", error.code, error.description);
                }
                else {
                    NSNumber *responseCode = dict[@"cod"];
                    if (responseCode && [responseCode integerValue] != 200) {
                        [self showAlertWithTitle:@"Oops!" andText:@"Something went wrong... please check your connection and try again." andButtonNamed:@"Ok"];
                    }
                    else {
                        [self addCitiesFromArray:forecastArray];
                    }
                }
            });
        }
        // BLOCK END
    }];
}

- (IBAction)addNewCityButtonPressed:(id)sender {
    [self fetchForecastForCity:_addCityTextField.text];
}

- (void)addNewCity:(ForecastModel *)forecast {
    [_forecastArray addObject:forecast];
    NSLog(@"New city added: %@ ", forecast.city);
    
    _addCityTextField.text = @"";
    [_tableView reloadData];
}

- (void)addCitiesFromArray:(NSArray *)cities {
    [_forecastArray addObjectsFromArray:cities];
    
    [_tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _forecastArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CityWeatherCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"cityWeatherCell"];

    [cell initWithForecast:[_forecastArray objectAtIndex:indexPath.row]];
    
    return cell;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        [self.forecastArray removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    return @[deleteAction];
}

#pragma mark - Misc methods

- (void)showAlertWithTitle:(NSString *)title andText:(NSString *)text andButtonNamed:(NSString *)buttonName {
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:text
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:buttonName
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                         }];

    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showProgressView:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^(){
        self.progressView.hidden = !show;
    });
}

@end
