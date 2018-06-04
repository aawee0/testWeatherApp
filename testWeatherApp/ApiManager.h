
#import <UIKit/UIKit.h>

@interface ApiManager : NSObject

+ (void)fetchForecastForCityByNameApi:(NSString *)cityName
                       withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)fetchForecastForCityByCoordinatesApi:(CGPoint)point
                              withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)fetchForecastForSeveralCitiesApi:(NSArray *)cityIdsArray
                          withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
