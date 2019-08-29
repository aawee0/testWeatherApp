
#import "CoreDataManager.h"

NSString * const kEntityName = @"ForecastEntity";

@implementation CoreDataManager

@synthesize persistentContainer = _persistentContainer;

+ (CoreDataManager *)sharedManager {
    static CoreDataManager *sharedManager = nil;
    @synchronized (self){
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            sharedManager = [CoreDataManager new];
        });
    }
    return sharedManager;
}

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"testWeatherApp"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (void)updateCityForecastDB:(ForecastModel *)forecast {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    
    // check if exists
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kEntityName
                                   inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cityId == %@", forecast.cityId];
    [request setPredicate:predicate];
    NSArray *forecastEntitiesArray = [context executeFetchRequest:request error:&error];
    
    NSManagedObject *forecastEntity;
    if (forecastEntitiesArray.count > 0) { // exists -- update
        forecastEntity = [forecastEntitiesArray objectAtIndex:0];
    }
    else { // not exists -- insert new
        forecastEntity = [NSEntityDescription insertNewObjectForEntityForName:kEntityName
                                                       inManagedObjectContext:context];
    }
    [forecastEntity setValue:forecast.city forKey:@"city"];
    [forecastEntity setValue:forecast.cityId forKey:@"cityId"];
    [forecastEntity setValue:[NSNumber numberWithInteger:forecast.tempMax] forKey:@"tempMax"];
    [forecastEntity setValue:[NSNumber numberWithInteger:forecast.tempMin] forKey:@"tempMin"];
    [forecastEntity setValue:forecast.desc forKey:@"desc"];
    [forecastEntity setValue:[NSNumber numberWithInteger:forecast.weatherId] forKey:@"weatherId"];
    [forecastEntity setValue:forecast.weatherIcon forKey:@"weatherIcon"];
    
    if (![context save:&error]) {
        NSLog(@"Save of ID #%@ failed", forecast.cityId);
    }
}

- (NSArray *)getAllCityForecastsFromDB {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *forecastEntity = [NSEntityDescription entityForName:kEntityName inManagedObjectContext:context];
    [fetchRequest setEntity:forecastEntity];
    
    NSError *error;
    NSArray *forecastEntities = [context executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *forecastArray = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *forecastEntity in forecastEntities) {
        ForecastModel *forecast = [ForecastModel forecastWithEntity:forecastEntity];
        [forecastArray addObject:forecast];
    }
    
    return forecastArray;
}

- (void)updateCityForecastsInDB:(NSArray *)forecastArray {
    for (ForecastModel *forecast in forecastArray) {
        [self updateCityForecastDB:forecast];
    }
}

- (void)deleteCityForecastFromDB:(NSString *)cityId {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kEntityName
                                   inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cityId == %@", cityId];
    [request setPredicate:predicate];
    NSArray *forecastEntitiesArray = [context executeFetchRequest:request error:&error];
    
    for (NSManagedObject *forecastEntity in forecastEntitiesArray) {
        [context deleteObject:forecastEntity];
    }
    
    if (![context save:&error]) {
        NSLog(@"Delete of ID #%@ failed", cityId);
    }
}

@end
