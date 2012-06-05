//
//  ViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MapKit/MapKit.h>
#import "MapTag.h"

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>
{
	UIButton			*startButton, *uploadButton;
	sqlite3				*db;
	NSTimer				*ticker;
	NSString			*dbpath;
	NSString			*device;
	CLLocationManager	*locationManager;
	CLLocation			*oldLocation, *lastCenteredLocation;
	UIAccelerometer		*accelerometer;
	AVAudioRecorder		*recorder;
	MKMapView			*mapView;
	int					accelValuesCollected;
	float				accelX, accelY, accelZ;
	BOOL				recording, trackingUser;
}

@property (nonatomic, retain) IBOutlet UIButton		*startButton, *uploadButton;
@property (nonatomic, retain) NSTimer				*ticker;
@property (nonatomic, retain) NSString				*dbpath;
@property (nonatomic, retain) NSString				*device;
@property (nonatomic, retain) CLLocationManager		*locationManager;
@property (nonatomic, retain) CLLocation			*oldLocation, *lastCenteredLocation;
@property (nonatomic, retain) UIAccelerometer		*accelerometer;
@property (nonatomic, retain) AVAudioRecorder		*recorder;
@property (nonatomic, retain) IBOutlet MKMapView	*mapView;
@property (nonatomic, assign) int					accelValuesCollected;
@property (nonatomic, assign) float					accelX, accelY, accelZ;
@property (nonatomic, assign) BOOL					recording, trackingUser;

- (void)setDevice:(NSString *)_device;
- (BOOL)sqlcon;

- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery;
- (int)numRows;
- (IBAction)uploadRows:(id)sender;
- (IBAction)emptyTable:(id)sender;

- (BOOL)isValidLocation:(CLLocation *)newLocation;
- (float)mphFromMps:(float)mps;

- (void)centerMapOnLocation:(CLLocation *)location andZoom:(BOOL)zoom;
- (void)centerMapOnLocation:(CLLocation *)location;
- (IBAction)centerMap:(id)sender;

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation;

- (void)longTouch:(UIGestureRecognizer *)gestureRecognizer;
- (void)panHandler:(UIGestureRecognizer *)gestureRecognizer;

- (void)updateData;
- (void)monitorWhileNotRecording:(id)sender;
- (void)record:(id)sender;

- (IBAction)toggleButton:(id)sender;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
