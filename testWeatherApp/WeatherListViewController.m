
#import "WeatherListViewController.h"
#import "CityWeatherCell.h"
#import "MapViewController.h"

#import "ApiManager.h"

@interface WeatherListViewController ()

@property (nonatomic, weak) IBOutlet UIView *topBackgroundView, *addButtonBackgroundView;
@property (nonatomic, weak) IBOutlet UITextField *addCityTextField;
@property (nonatomic, weak) IBOutlet UIButton *addButton, *mapsButton;
@property (nonatomic) UIView *placeholderView;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic, weak) IBOutlet UIView *progressView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic) NSMutableArray *forecastArray;

@end

@implementation WeatherListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initStyles];
    [self initTableView];
    
    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // PREFETCH: use forecasts from Core Data
    _forecastArray = [[NSMutableArray alloc] initWithArray:
                      [[CoreDataManager sharedManager] getAllCityForecastsFromDB]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // FETCH: use forecasts from API
    [self refreshTableWithProgressView:NO];
}

- (void)initStyles {
    _topBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    _topBackgroundView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _topBackgroundView.layer.shadowRadius = 5.0f;
    _topBackgroundView.layer.shadowOpacity = 0.5f;
    
    _mapsButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _mapsButton.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    _mapsButton.layer.shadowRadius = 2.0f;
    _mapsButton.layer.shadowOpacity = 0.5f;
    
    _addButtonBackgroundView.layer.cornerRadius = _addButtonBackgroundView.frame.size.width/2.0f;
    _addButtonBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    _addButtonBackgroundView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    _addButtonBackgroundView.layer.shadowRadius = 1.0f;
    _addButtonBackgroundView.layer.shadowOpacity = 0.5f;
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
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
    else [self reloadTableView];
}

- (void)reloadTableView {
    if (_forecastArray.count == 0) {
        [self.view insertSubview:self.placeholderView belowSubview:_tableView];
    }
    else {
        if (_placeholderView) [_placeholderView removeFromSuperview];
    }
    
    [_tableView reloadData];
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
    _addButton.enabled = NO;
    
    [self reloadTableView];
    
    [[CoreDataManager sharedManager] updateCityForecastDB:forecast];
    NSLog(@"New city added: %@ ", forecast.city);
}

- (void)addCitiesFromArray:(NSArray *)cities {
    [_forecastArray removeAllObjects];
    [_forecastArray addObjectsFromArray:cities];
    
    [self reloadTableView];
    
    [[CoreDataManager sharedManager] updateCityForecastsInDB:cities];
}

- (void)deleteCityAtIndex:(NSInteger)index {
    NSString *idToDelete = [[_forecastArray objectAtIndex:index] cityId];
    [_forecastArray removeObjectAtIndex:index];
    
    [self reloadTableView];
    
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

#pragma mark - UITextFieldDelegate & Events

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)textFieldDidChange:(UITextField *)sender {
    _addButton.enabled = (sender.text.length > 0);
}

#pragma mark - Misc

- (UIView *)placeholderView {
    if (!_placeholderView) {
        _placeholderView = [[UIView alloc] initWithFrame:_tableView.bounds];
        CGRect placeholderFrame = _placeholderView.frame;
        
        CGFloat imageViewSize = placeholderFrame.size.width/4.0f;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, imageViewSize, imageViewSize)];
        imageView.image = [UIImage imageNamed:@"placeholder"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.center = CGPointMake(placeholderFrame.size.width/2.0f, imageView.center.y);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(imageView.frame) + 10.0f, placeholderFrame.size.width, 40.0f)];
        label.text = @"No cities yet";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor grayColor];
        label.center = CGPointMake(placeholderFrame.size.width/2.0f, label.center.y);
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, placeholderFrame.size.width, CGRectGetMaxY(label.frame))];
        containerView.center = CGPointMake(containerView.center.x, placeholderFrame.size.height/2.0f);
        [containerView addSubview:imageView];
        [containerView addSubview:label];
        [_placeholderView addSubview:containerView];
    }
    return _placeholderView;
}

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
        self.placeholderView.hidden = !self.progressView.hidden;
    });
}

@end
