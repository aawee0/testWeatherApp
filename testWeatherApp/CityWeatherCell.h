
#import <UIKit/UIKit.h>

#import "ForecastModel.h"

@interface CityWeatherCell : UITableViewCell

- (void)updateWithForecast:(ForecastModel *)forecast;

@end
