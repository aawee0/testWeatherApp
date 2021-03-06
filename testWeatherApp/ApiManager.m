
#import "ApiManager.h"

@implementation ApiManager

+ (void)fetchForecastForCityByNameApi:(NSString *)cityName
                       withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *safeCityName = [cityName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *paramsString = [[NSString alloc] initWithFormat:@"%@weather?q=%@&appid=%@",
                              OWMAP_APIURL, safeCityName, APPID];
    
    [ApiManager sendGETRequestWithParams:paramsString withCompletion:completionHandler];
}

+ (void)fetchForecastForCityByCoordinatesApi:(CGPoint)point
                              withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *paramsString = [[NSString alloc] initWithFormat:@"%@weather?lat=%f&lon=%f&appid=%@",
                    OWMAP_APIURL, point.x, point.y, APPID];
    
    [ApiManager sendGETRequestWithParams:paramsString withCompletion:completionHandler];
}

+ (void)fetchForecastForSeveralCitiesApi:(NSArray *)cityIdsArray
                 withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *cityIdsString = [cityIdsArray componentsJoinedByString:@","];
    NSString *paramsString = [[NSString alloc] initWithFormat:@"%@group?id=%@&appid=%@",
                              OWMAP_APIURL, cityIdsString, APPID];
    
    [ApiManager sendGETRequestWithParams:paramsString withCompletion:completionHandler];
}

+ (void)sendGETRequestWithParams:(NSString *)paramsString
                  withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:paramsString]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:completionHandler] resume];
}

@end
