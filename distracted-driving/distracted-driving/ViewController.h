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
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MapKit/MapKit.h>
#import "MapTag.h"
#import "GradientButton.h"

// Settings (Constants)
extern int const	kMinimumDrivingSpeed;
extern int const	kDataPointsForAverage;
extern double const kMapSpanDelta;

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>
{
	GradientButton		*startButton, *uploadButton, *tagButton;
	UILabel				*speedometer;
	sqlite3				*db;
	NSTimer				*ticker;
	NSString			*dbpath;
	NSString			*device;
	CLLocationManager	*locationManager;
	CLLocation			*oldLocation, *lastCenteredLocation;
	UIAccelerometer		*accelerometer;
	AVAudioRecorder		*recorder;
	MKMapView			*mapView;
	NSMutableArray		*speedValues;
	int					accelValuesCollected;
	float				accelX, accelY, accelZ, speed;
	BOOL				recording, trackingUser, hasAlertedUser;
}

@property (nonatomic, retain) IBOutlet GradientButton	*startButton, *uploadButton, *tagButton;
@property (nonatomic, retain) IBOutlet UILabel			*speedometer;
@property (nonatomic, retain) NSTimer					*ticker;
@property (nonatomic, retain) NSString					*dbpath;
@property (nonatomic, retain) NSString					*device;
@property (nonatomic, retain) CLLocationManager			*locationManager;
@property (nonatomic, retain) CLLocation				*oldLocation, *lastCenteredLocation;
@property (nonatomic, retain) UIAccelerometer			*accelerometer;
@property (nonatomic, retain) AVAudioRecorder			*recorder;
@property (nonatomic, retain) IBOutlet MKMapView		*mapView;
@property (nonatomic, retain) NSMutableArray			*speedValues;
@property (nonatomic, assign) int						accelValuesCollected;
@property (nonatomic, assign) float						accelX, accelY, accelZ, speed;
@property (nonatomic, assign) BOOL						recording, trackingUser, hasAlertedUser;

// Initializing functions
- (BOOL)sqlcon;

// Variable manipulation functions
- (void)calculateSpeed;
- (float)mphFromMps:(float)mps;
- (float)mpsFromMph:(float)mph;

// Data management functions
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery;
- (int)numRows;
- (void)uploadRows;
- (void)emptyTable;
- (void)updateData;

// Location functions
- (BOOL)isValidLocation:(CLLocation *)newLocation;
- (void)centerMapOnLocation:(CLLocation *)location;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation;
- (void)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation;
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation;

// Input receiving functions
- (void)longTouchHappened:(UIGestureRecognizer *)gestureRecognizer;
- (void)panHappened:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)startButtonWasTouched:(id)sender;
- (IBAction)tagButtonWasTouched:(id)sender;
- (IBAction)uploadButtonWasTouched:(id)sender;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

// Ticking functions
- (void)monitorWhileNotRecording:(id)sender;
- (void)record:(id)sender;

@end
