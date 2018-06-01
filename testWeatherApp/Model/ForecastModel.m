
#import "ForecastModel.h"

@interface ForecastModel ()

@property (strong, nonatomic) NSString *city;
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
    
    NSDictionary *main = dict[@"main"];
    if (main) {
        NSNumber *tempMax = main[@"temp_max"];
        if (tempMax) forecast.tempMax = [ForecastModel convertToCelsius:[tempMax floatValue]];
        //if (tempMax) forecast.tempMax = tempMax;

        NSNumber *tempMin = main[@"temp_min"];
        if (tempMin) forecast.tempMin = [ForecastModel convertToCelsius:[tempMin floatValue]];
        //if (tempMin) forecast.tempMin = tempMin;
    }
    
    NSArray *weather = dict[@"weather"];
    if (weather && weather.count > 0) {
        NSDictionary *dominantWeatherType = [weather objectAtIndex:0];
        
        NSString *desc = dominantWeatherType[@"main"];
        if (desc) forecast.desc = desc;
        
        NSNumber *weatherId = dominantWeatherType[@"id"];
        if (weatherId) forecast.weatherId = [weatherId integerValue];
        
        NSString *icon = dominantWeatherType[@"icon"];
        if (icon) forecast.weatherIcon = icon;
    }

    return forecast;
}

+ (NSInteger)convertToCelsius:(CGFloat)kelvinTemp {
    return (NSInteger) (kelvinTemp - 273.15);
}

@end
