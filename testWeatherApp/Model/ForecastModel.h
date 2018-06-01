
#import <UIKit/UIKit.h>

@interface ForecastModel : NSObject

@property (strong, nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSInteger tempMax;
@property (nonatomic, readonly) NSInteger tempMin;
@property (strong, nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) NSInteger weatherId;
@property (strong, nonatomic, readonly) NSString *weatherIcon;

+ (ForecastModel *)initWithDictionary:(NSDictionary *)dict;

@end
