
#import <Foundation/Foundation.h>

@interface ApiManager : NSObject

+ (void)fetchForecastForCityApi:(NSString *)cityName
                withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)fetchForecastForSeveralCitiesApi:(NSArray *)cityIdsArray
                          withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)sendGETRequestWithParams:(NSString *)paramsString
                  withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
