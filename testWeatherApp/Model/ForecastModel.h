
#import <UIKit/UIKit.h>

@interface ForecastModel : NSObject

@property (strong, nonatomic, readonly) NSString *city;
@property (strong, nonatomic, readonly) NSString *cityId;
@property (nonatomic, readonly) NSInteger tempMax;
@property (nonatomic, readonly) NSInteger tempMin;
@property (strong, nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) NSInteger weatherId;
@property (strong, nonatomic, readonly) NSString *weatherIcon;

// initialization
+ (ForecastModel *)initWithDictionary:(NSDictionary *)dict;
+ (NSArray *)initForecastArrayWithDictionary:(NSDictionary *)dict;

// Core Data related methods
+ (void)updateCityForecastDB:(ForecastModel *)forecast;
+ (NSArray *)getAllCityForecastsFromDB;
+ (void)updateCityForecastsInDB:(NSArray *)forecastArray;
+ (void)deleteCityForecastFromDB:(NSString *)cityID;

@end
