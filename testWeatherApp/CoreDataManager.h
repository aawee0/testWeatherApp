
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;

+ (CoreDataManager *)sharedManager;

- (void)saveContext;
- (void)updateCityForecastDB:(ForecastModel *)forecast;
- (NSArray *)getAllCityForecastsFromDB;
- (void)updateCityForecastsInDB:(NSArray *)forecastArray;
- (void)deleteCityForecastFromDB:(NSString *)cityID;

@end
