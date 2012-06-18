//
//  TagMenuViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol TagMenuDelegate <NSObject>
@required

- (void)tagViewAsDangerous:(MKAnnotationView *)view withTraffic:(BOOL)traffic andRoadConditions:(BOOL)roadConditions;
- (void)tagMenuDidClose;

@end

@interface TagMenuViewController : UIViewController
{
	id <TagMenuDelegate>	delegate;
	MKAnnotationView		*annotationView;
	UILabel					*titleLabel;
	UISwitch				*roadSwitch;
	UISwitch				*trafficSwitch;
	NSString				*titleText;
}

@property (nonatomic, retain) id <TagMenuDelegate>	delegate;
@property (nonatomic, retain) MKAnnotationView		*annotationView;
@property (nonatomic, retain) IBOutlet UILabel		*titleLabel;
@property (nonatomic, retain) IBOutlet UISwitch		*roadSwitch, *trafficSwitch;
@property (nonatomic, retain) NSString				*titleText;

- (id)initWithTitle:(NSString *)text;
- (IBAction)closeAndTag:(id)sender;
- (IBAction)close:(id)sender;

@end