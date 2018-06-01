
#import "ApiManager.h"

@implementation ApiManager

+ (void)fetchForecastForCityApi:(NSString *)cityName
             withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *safeCityName = [cityName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *requestURL = [[NSString alloc] initWithFormat:@"%@weather?q=%@&appid=%@",
                            OWMAP_APIURL, safeCityName, APPID];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:requestURL]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:completionHandler] resume];
}

@end
