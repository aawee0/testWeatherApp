
#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initMapView];
    
    self.navigationItem.title = @"Select location"; // screen title
}

- (void)initMapView {
    _mapView.mapType = MKMapTypeHybrid;
    _mapView.delegate = self;
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]
                                                         initWithTarget:self action:@selector(handleLongPress:)];
    longPressRecognizer.minimumPressDuration = 1.0; // time of press
    [self.mapView addGestureRecognizer:longPressRecognizer];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    NSLog(@"Coordinates selected: ( %f , %f ) ",
          touchMapCoordinate.latitude, touchMapCoordinate.longitude);
    
    [self proceedSelectionWithPoint:
     CGPointMake(touchMapCoordinate.latitude, touchMapCoordinate.longitude)];
}

- (void)proceedSelectionWithPoint:(CGPoint)point {
    [self.navigationController popViewControllerAnimated:YES];
    
    if (_completionBlock) _completionBlock(point);
}

@end
