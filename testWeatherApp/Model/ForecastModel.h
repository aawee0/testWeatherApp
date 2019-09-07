
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ForecastModel : NSObject

@property (nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSString *cityId;
@property (nonatomic, readonly) NSInteger tempMax;
@property (nonatomic, readonly) NSInteger tempMin;
@property (nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) NSInteger weatherId;
@property (nonatomic, readonly) NSString *weatherIcon;

+ (ForecastModel *)forecastWithDictionary:(NSDictionary *)dict;
+ (ForecastModel *)forecastWithEntity:(NSManagedObject *)forecastEntity;
+ (NSArray *)forecastArrayWithDictionary:(NSDictionary *)dict;

@end
