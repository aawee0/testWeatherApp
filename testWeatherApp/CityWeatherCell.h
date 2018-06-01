//
//  CityWeatherCell.h
//  testWeatherApp
//
//  Created by Evgeny Patrikeev on 31.05.2018.
//  Copyright © 2018 Evgeny Patrikeev. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ForecastModel.h"

@interface CityWeatherCell : UITableViewCell

- (void)initWithForecast:(ForecastModel *)forecast;

@end
