
#import <UIKit/UIKit.h>

@interface ApiManager : NSObject

+ (void)fetchForecastForCityByName:(NSString *)cityName
                        orCoordinates:(CGPoint)point
                       withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)fetchForecastForSeveralCitiesApi:(NSArray *)cityIdsArray
                          withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
