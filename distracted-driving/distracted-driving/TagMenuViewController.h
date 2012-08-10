//
//  TagMenuViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TestFlight.h"

@protocol TagMenuDelegate <NSObject>
@required

- (void)tagViewAsDangerous:(MKAnnotationView *)view withTraffic:(BOOL)traffic andRoadConditions:(BOOL)roadConditions andSignal:(BOOL)signal andImage:(UIImage *)image;
- (void)tagMenuDidClose;
- (void)uploadRows;

@end

@interface TagMenuViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
	id <TagMenuDelegate>	delegate;
	MKAnnotationView		*annotationView;
	UILabel					*titleLabel, *signalLabel;
	UISwitch				*roadSwitch, *trafficSwitch, *signalSwitch;
	UIButton				*tagButton, *cancelButton, *uploadButton, *cameraButton;
	NSString				*titleText;
	BOOL					isUploadType;
}

@property (nonatomic, retain) id <TagMenuDelegate>	delegate;
@property (nonatomic, retain) MKAnnotationView		*annotationView;
@property (nonatomic, retain) IBOutlet UILabel		*titleLabel, *signalLabel;
@property (nonatomic, retain) IBOutlet UISwitch		*roadSwitch, *trafficSwitch, *signalSwitch;
@property (nonatomic, retain) IBOutlet UIButton		*tagButton, *cancelButton, *uploadButton, *cameraButton;
@property (nonatomic, retain) UIImage				*image;
@property (nonatomic, retain) NSString				*titleText;
@property (nonatomic, assign) BOOL					isUploadType;

- (id)initWithTitle:(NSString *)text withUpload:(BOOL)upload;
- (id)initWithTitle:(NSString *)text;
- (IBAction)closeAndUpload:(id)sender;
- (IBAction)closeAndTag:(id)sender;
- (IBAction)close:(id)sender;
- (IBAction)cameraButtonWasTouched:(id)sender;

@end