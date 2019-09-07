
#import "WeatherListViewController.h"
#import "CityWeatherCell.h"
#import "MapViewController.h"

#import "ApiManager.h"

@interface WeatherListViewController ()

@property (nonatomic, weak) IBOutlet UIView *topBackgroundView;
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

    [self initTopView];
    [self initTableView];
    
    [_addCityTextField setReturnKeyType:UIReturnKeyDone];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)initTopView {
    _topBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    _topBackgroundView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _topBackgroundView.layer.shadowRadius = 5.0f;
    _topBackgroundView.layer.shadowOpacity = 0.5f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // PREFETCH: use forecasts from Core Data
    _forecastArray = [[NSMutableArray alloc] initWithArray:
                      [[CoreDataManager sharedManager] getAllCityForecastsFromDB]];
    [_tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // FETCH: use forecasts from API
    [self refreshTableWithProgressView:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Init methods

- (void)initTableView {
    _tableView.allowsSelection = NO;
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_tableView addSubview:_refreshControl];
    [_refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    UINib *nib = [UINib nibWithNibName:@"CityWeatherCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cityWeatherCell"];
}

- (void)refreshTable {
    [self refreshTableWithProgressView:YES];
}

- (void)refreshTableWithProgressView:(BOOL)progressView {
    // getting forecast ids to put into request
    NSMutableArray *idsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < _forecastArray.count; i++) {
        ForecastModel *forecast = [_forecastArray objectAtIndex:i];
        [idsArray addObject: forecast.cityId];
    }
    
    [_refreshControl endRefreshing];
    if (idsArray.count > 0) [self fetchForecastForCityList:idsArray withProgressView:progressView];
}

#pragma mark - API-related

- (void)fetchForecastForCityByName:(NSString *)cityName { // single city
    if (cityName && ![cityName isEqualToString:@""]) {
        // check if already in list
        BOOL alreadyInList = NO;
        for (ForecastModel *forecast in _forecastArray) {
            if ([forecast.city isEqualToString:cityName]) alreadyInList = YES;
        }
        if (alreadyInList) {
            [self showAlertWithTitle:@"City is already in list" andText:nil andButtonNamed:@"Ok"];
        }
        else { // if not, then add
            [self showProgressView:YES];
            [ApiManager fetchForecastForCityByNameApi:cityName withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
                 [self showProgressView:NO];
                 if (data) {
                     [self proceedAddingCityWithData:data andResponse:response andError:error];
                 }
                 else [self showUnknownError];
                 // BLOCK END
             }];
        }
    }
}

- (void)fetchForecastForCityByCoordinates:(CGPoint)point { // single city
    [self showProgressView:YES];
    [ApiManager fetchForecastForCityByCoordinatesApi:point withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
         [self showProgressView:NO];
         if (data) {
             [self proceedAddingCityWithData:data andResponse:response andError:error];
         }
         else [self showUnknownError];
         // BLOCK END
     }];
}

- (void)proceedAddingCityWithData:(NSData *)data andResponse:(NSURLResponse *)response
                         andError:(NSError *)error {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                    options:NSJSONReadingAllowFragments error:nil];
    ForecastModel *forecast = [ForecastModel forecastWithDictionary:dict];
    
    NSLog(@"(!) Response: %@ ", response);
    NSLog(@"(!) Serialized data: %@ ", dict);
    
    // UI changes
    
    if (error) {
        [self showAlertWithTitle:@"Error" andText:error.description andButtonNamed:@"Ok"];
        NSLog(@"(!) Error %ld: %@ ", error.code, error.description);
    }
    else {
        NSNumber *responseCode = dict[@"cod"];
        if (!responseCode) {
            [self showUnknownError];
        }
        else if ([responseCode integerValue] == 404) {
            [self showAlertWithTitle:@"City not found" andText:nil andButtonNamed:@"Ok"];
        }
        else if ([responseCode integerValue] != 200) {
            NSString *message = dict[@"message"];
            if (message) [self showAlertWithTitle:@"Error" andText:message andButtonNamed:@"Ok"];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [self addNewCity:forecast];
            });
        }
    }
}

- (void)fetchForecastForCityList:(NSArray *)cities withProgressView:(BOOL)progressView {
    if (progressView) [self showProgressView:YES];
    [ApiManager fetchForecastForSeveralCitiesApi:cities withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (progressView) [self showProgressView:NO];
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments error:nil];
            NSArray *forecastArray = [ForecastModel forecastArrayWithDictionary:dict];
            
            NSLog(@"(!) Response: %@ ", response);
            NSLog(@"(!) Serialized data: %@ ", dict);
            
            // UI changes
            if (error) {
                [self showAlertWithTitle:@"Error" andText:error.description andButtonNamed:@"Ok"];
                NSLog(@"(!) Error %ld: %@ ", error.code, error.description);
            }
            else {
                NSNumber *responseCode = dict[@"cod"];
                if (responseCode && [responseCode integerValue] != 200) {
                    [self showUnknownError];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        [self addCitiesFromArray:forecastArray];
                    });
                }
            }
        }
        else [self showUnknownError];
        // BLOCK END
    }];
}

#pragma mark - Data array methods

- (void)addNewCity:(ForecastModel *)forecast {
    [_forecastArray addObject:forecast];
    _addCityTextField.text = @"";
    [_addCityTextField resignFirstResponder];
    
    [_tableView reloadData];
    
    [[CoreDataManager sharedManager] updateCityForecastDB:forecast];
    NSLog(@"New city added: %@ ", forecast.city);
}

- (void)addCitiesFromArray:(NSArray *)cities {
    [_forecastArray removeAllObjects];
    [_forecastArray addObjectsFromArray:cities];
    
    [_tableView reloadData];
    
    [[CoreDataManager sharedManager] updateCityForecastsInDB:cities];
}

- (void)deleteCityAtIndex:(NSInteger)index {
    NSString *idToDelete = [[_forecastArray objectAtIndex:index] cityId];
    [_forecastArray removeObjectAtIndex:index];
    
    [_tableView reloadData];
    
    [[CoreDataManager sharedManager] deleteCityForecastFromDB:idToDelete];
}

#pragma mark - IBActions

- (IBAction)mapButtonPressed:(id)sender {
    MapViewController *mapVC = [[MapViewController alloc] init];
    mapVC.completionBlock = ^(CGPoint point) {
        [self fetchForecastForCityByCoordinates:point];
    };
    
    [[self navigationItem] setBackBarButtonItem:
     [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain
                                     target:nil action:nil]]; // rename back button
    
    [self.navigationController pushViewController:mapVC animated:YES];
}

- (IBAction)addNewCityButtonPressed:(id)sender {
    [self fetchForecastForCityByName: _addCityTextField.text];
}

- (IBAction)doneButtonFromKeyboardPressed:(id)sender {
    [self.view endEditing:YES];
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
    [cell updateWithForecast:[_forecastArray objectAtIndex:indexPath.row]];
    return cell;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        [self deleteCityAtIndex:indexPath.row];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    return @[deleteAction];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Misc methods

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)showAlertWithTitle:(NSString *)title andText:(NSString *)text andButtonNamed:(NSString *)buttonName {
    dispatch_async(dispatch_get_main_queue(), ^(){
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
    });
}

- (void)showUnknownError {
    [self showAlertWithTitle:@"Oops!" andText:@"Something went wrong... please check your connection and try again." andButtonNamed:@"Ok"];
}

- (void)showProgressView:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^(){
        self.progressView.hidden = !show;
    });
}

@end
