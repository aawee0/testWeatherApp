
#import "ForecastModel.h"

#import "AppDelegate.h"

@interface ForecastModel ()

@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *cityId;
@property (nonatomic) NSInteger tempMax;
@property (nonatomic) NSInteger tempMin;
@property (strong, nonatomic) NSString *desc;
@property (nonatomic) NSInteger weatherId;
@property (strong, nonatomic) NSString *weatherIcon;

@end

@implementation ForecastModel

+ (ForecastModel *)initWithDictionary:(NSDictionary *)dict {
    ForecastModel *forecast = [[ForecastModel alloc] init];
    
    NSString *cityName = dict[@"name"];
    if (cityName) forecast.city = cityName;
    
    NSDictionary *cityIdDict = dict[@"id"];
    if (cityIdDict && [cityIdDict isKindOfClass:[NSNumber class]]) {
        NSNumber *cityId = (NSNumber *)cityIdDict;
        forecast.cityId = [cityId stringValue];
    }
    
    NSDictionary *main = dict[@"main"];
    if (main) {
        NSDictionary *tempMaxDict = main[@"temp_max"];
        if (tempMaxDict && [tempMaxDict isKindOfClass:[NSNumber class]]) {
            NSNumber *tempMax = (NSNumber *)tempMaxDict;
            forecast.tempMax = [ForecastModel convertToCelsius:[tempMax floatValue]];
        }

        NSDictionary *tempMinDict = main[@"temp_min"];
        if (tempMinDict && [tempMinDict isKindOfClass:[NSNumber class]]) {
            NSNumber *tempMin = (NSNumber *)tempMinDict;
            forecast.tempMin = [ForecastModel convertToCelsius:[tempMin floatValue]];
        }
    }
    
    NSDictionary *weatherDict = dict[@"weather"];
    if (weatherDict && [weatherDict isKindOfClass:[NSArray class]]) {
        NSArray *weather = (NSArray *)weatherDict;
        if (weather.count) {
            NSDictionary *dominantWeatherType = [weather objectAtIndex:0];
            
            NSString *desc = dominantWeatherType[@"main"];
            if (desc) forecast.desc = desc;
            
            NSNumber *weatherId = dominantWeatherType[@"id"];
            if (weatherId) forecast.weatherId = [weatherId integerValue];
            
            NSString *icon = dominantWeatherType[@"icon"];
            if (icon) forecast.weatherIcon = icon;
        }
    }

    return forecast;
}

+ (NSArray *)initForecastArrayWithDictionary:(NSDictionary *)dict {
    NSMutableArray *forecastArray = [[NSMutableArray alloc] init];
    
    NSDictionary *listDict = dict[@"list"];
    if (listDict && [listDict isKindOfClass:[NSArray class]]) {
        for (NSDictionary *forecastDict in listDict) {
            [forecastArray addObject: [ForecastModel initWithDictionary: forecastDict]];
        }
    }
    
    return forecastArray;
}

+ (NSInteger)convertToCelsius:(CGFloat)kelvinTemp {
    return (NSInteger) (kelvinTemp - 273.15);
}

#pragma mark - Core Data

+ (void)updateCityForecastDB:(ForecastModel *)forecast {
    NSManagedObjectContext *context = sharedAppDelegate.persistentContainer.viewContext;
    NSError *error = nil;
    
    // check if exists
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ForecastEntity"
                                   inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cityId == %@", forecast.cityId];
    [request setPredicate:predicate];
    NSArray *forecastEntitiesArray = [context executeFetchRequest:request error:&error];
    
    NSManagedObject *forecastEntity;
    if (forecastEntitiesArray.count > 0) { // exists -- update
        forecastEntity = [forecastEntitiesArray objectAtIndex:0];
    }
    else { // not exists -- insert new
        forecastEntity = [NSEntityDescription insertNewObjectForEntityForName:@"ForecastEntity"
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

+ (NSArray *)getAllCityForecastsFromDB {
    NSManagedObjectContext *context = sharedAppDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *forecastEntity = [NSEntityDescription entityForName:@"ForecastEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:forecastEntity];
    
    NSError *error;
    NSArray *forecastEntities = [context executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *forecastArray = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *forecastEntity in forecastEntities) {
        ForecastModel *forecast = [[ForecastModel alloc] init];
        
        forecast.city = [forecastEntity valueForKey:@"city"];
        forecast.cityId = [forecastEntity valueForKey:@"cityId"];
        forecast.tempMax = [[forecastEntity valueForKey:@"tempMax"] integerValue];
        forecast.tempMin = [[forecastEntity valueForKey:@"tempMin"] integerValue];
        forecast.desc = [forecastEntity valueForKey:@"desc"];
        forecast.weatherId = [[forecastEntity valueForKey:@"weatherId"] integerValue];
        forecast.weatherIcon = [forecastEntity valueForKey:@"weatherIcon"];
        
        [forecastArray addObject:forecast];
    }
    
    return forecastArray;
}

+ (void)updateCityForecastsInDB:(NSArray *)forecastArray {
    for (ForecastModel *forecast in forecastArray) {
        [ForecastModel updateCityForecastDB:forecast];
    }
}

+ (void)deleteCityForecastFromDB:(NSString *)cityId {
    NSManagedObjectContext *context = sharedAppDelegate.persistentContainer.viewContext;
    NSError *error = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ForecastEntity"
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
