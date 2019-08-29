
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ForecastModel : NSObject

@property (strong, nonatomic, readonly) NSString *city;
@property (strong, nonatomic, readonly) NSString *cityId;
@property (nonatomic, readonly) NSInteger tempMax;
@property (nonatomic, readonly) NSInteger tempMin;
@property (strong, nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) NSInteger weatherId;
@property (strong, nonatomic, readonly) NSString *weatherIcon;

+ (ForecastModel *)forecastWithDictionary:(NSDictionary *)dict;
+ (ForecastModel *)forecastWithEntity:(NSManagedObject *)forecastEntity;
+ (NSArray *)forecastArrayWithDictionary:(NSDictionary *)dict;

@end
