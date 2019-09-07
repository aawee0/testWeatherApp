
#import "ForecastModel.h"

#import "AppDelegate.h"

@interface ForecastModel ()

@property (nonatomic) NSString *city;
@property (nonatomic) NSString *cityId;
@property (nonatomic) NSInteger tempMax;
@property (nonatomic) NSInteger tempMin;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSInteger weatherId;
@property (nonatomic) NSString *weatherIcon;

@end

@implementation ForecastModel

+ (ForecastModel *)forecastWithDictionary:(NSDictionary *)dict {
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

+ (ForecastModel *)forecastWithEntity:(NSManagedObject *)forecastEntity {
    ForecastModel *forecast = [[ForecastModel alloc] init];
    
    forecast.city = [forecastEntity valueForKey:@"city"];
    forecast.cityId = [forecastEntity valueForKey:@"cityId"];
    forecast.tempMax = [[forecastEntity valueForKey:@"tempMax"] integerValue];
    forecast.tempMin = [[forecastEntity valueForKey:@"tempMin"] integerValue];
    forecast.desc = [forecastEntity valueForKey:@"desc"];
    forecast.weatherId = [[forecastEntity valueForKey:@"weatherId"] integerValue];
    forecast.weatherIcon = [forecastEntity valueForKey:@"weatherIcon"];
    
    return forecast;
}

+ (NSArray *)forecastArrayWithDictionary:(NSDictionary *)dict {
    NSMutableArray *forecastArray = [[NSMutableArray alloc] init];
    
    NSDictionary *listDict = dict[@"list"];
    if (listDict && [listDict isKindOfClass:[NSArray class]]) {
        for (NSDictionary *forecastDict in listDict) {
            [forecastArray addObject: [ForecastModel forecastWithDictionary:forecastDict]];
        }
    }
    
    return forecastArray;
}

+ (NSInteger)convertToCelsius:(CGFloat)kelvinTemp {
    return (NSInteger) (kelvinTemp - 273.15);
}

@end
