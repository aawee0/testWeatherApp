//
//  CityWeatherCell.m
//  testWeatherApp
//
//  Created by Evgeny Patrikeev on 31.05.2018.
//  Copyright © 2018 Evgeny Patrikeev. All rights reserved.
//

#import "CityWeatherCell.h"

@interface CityWeatherCell ()

@property (weak, nonatomic) IBOutlet UILabel *cellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellTempMaxLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellTempMinLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellWeatherDescLabel;

@property (weak, nonatomic) IBOutlet UIImageView *cellWeatherImageView;

@end

@implementation CityWeatherCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)initWithForecast:(ForecastModel *)forecast {
    [_cellTitleLabel setText:forecast.city];
    
    [_cellTempMaxLabel setText:[NSString stringWithFormat:@"%ld°", forecast.tempMax]];
    [_cellTempMinLabel setText:[NSString stringWithFormat:@"%ld°", forecast.tempMin]];
    [_cellWeatherDescLabel setText:forecast.desc];
    [_cellWeatherImageView setImage:[UIImage imageNamed:forecast.weatherIcon]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
