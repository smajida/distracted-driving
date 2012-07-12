//
//  ViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 Luke Godfrey

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MapKit/MapKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MapTag.h"
#import "GradientButton.h"
#import "TagMenuViewController.h"
#import "AppDelegate.h"

// Settings (Constants)
extern int const	kMinimumDrivingSpeed;
extern int const	kDrasticSpeedChange;
extern int const	kMaximumSpeedAge;
extern int const	kDataPointsForAverage;
extern int const	kAlertExpire;
extern double const kMapSpanDelta;

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, TagMenuDelegate>
{
	TagMenuViewController		*tagMenu;
	UIImageView					*tagMenuBackground;
	GradientButton				*startButton, *tagButton;
	UILabel						*speedometer;
	sqlite3						*db;
	NSTimer						*ticker;
	NSString					*dbpath;
	NSString					*device;
	CLLocationManager			*locationManager;
	CLLocation					*oldLocation, *lastCenteredLocation;
	UIAccelerometer				*accelerometer;
	AVAudioRecorder				*recorder;
	MKMapView					*mapView;
	NSMutableArray				*speedValues;
	NSDate						*lastAlertedUser;
	NSURLConnection				*dangerTagsConnection;
	NSMutableData				*dangerTagsData;
	UIBackgroundTaskIdentifier	bgTask;
	int							accelValuesCollected;
	float						accelX, accelY, accelZ, speed, thrownAwaySpeed;
	BOOL						recording, trackingUser, didGetDangerTags, isUsingOnlySignificantChanges;
}

@property (nonatomic, retain) TagMenuViewController			*tagMenu;
@property (nonatomic, retain) UIImageView					*tagMenuBackground;

@property (nonatomic, retain) IBOutlet GradientButton		*startButton, *tagButton;
@property (nonatomic, retain) IBOutlet UILabel				*speedometer;
@property (nonatomic, retain) NSTimer						*ticker;
@property (nonatomic, retain) NSString						*dbpath;
@property (nonatomic, retain) NSString						*device;
@property (nonatomic, retain) CLLocationManager				*locationManager;
@property (nonatomic, retain) CLLocation					*oldLocation, *lastCenteredLocation;
@property (nonatomic, retain) UIAccelerometer				*accelerometer;
@property (nonatomic, retain) AVAudioRecorder				*recorder;
@property (nonatomic, retain) IBOutlet MKMapView			*mapView;
@property (nonatomic, retain) NSMutableArray				*speedValues;
@property (nonatomic, retain) NSDate						*lastAlertedUser;
@property (nonatomic, retain) NSURLConnection				*dangerTagsConnection;
@property (nonatomic, retain) NSMutableData					*dangerTagsData;
@property (nonatomic, assign) UIBackgroundTaskIdentifier	bgTask;
@property (nonatomic, assign) int							accelValuesCollected;
@property (nonatomic, assign) float							accelX, accelY, accelZ, speed, thrownAwaySpeed;
@property (nonatomic, assign) BOOL							recording, trackingUser, didGetDangerTags, isUsingOnlySignificantChanges;

// Initializing functions
- (BOOL)sqlcon;

// Variable manipulation functions
- (void)calculateSpeed;
- (float)mphFromMps:(float)mps;
- (float)mpsFromMph:(float)mph;

// Animation Functions
- (void)bounce1AnimationStopped;
- (void)bounce2AnimationStopped;

// Data management functions
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery;
- (int)numRows;
- (void)uploadRows;
- (void)emptyTable;

// Server/Connection functions
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

// Location functions
- (BOOL)isValidLocation:(CLLocation *)newLocation;
- (void)dropPinAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)tagViewAsDangerous:(MKAnnotationView *)view withTraffic:(BOOL)traffic andRoadConditions:(BOOL)roadConditions andSignal:(BOOL)signal;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation;
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation;

// Display (popup) functions
- (void)openTagMenuWithTitle:(NSString *)title andAnnotationView:(MKAnnotationView *)view;
- (void)openTagMenuWithTitle:(NSString *)title;
- (void)openTagMenuWithAnnotationView:(MKAnnotationView *)view;
- (void)openTagMenu;
- (void)tagMenuDidClose;

// Input receiving functions
- (void)longTouchHappened:(UIGestureRecognizer *)gestureRecognizer;
- (void)panHappened:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)startButtonWasTouched:(id)sender;
- (IBAction)tagButtonWasTouched:(id)sender;
- (IBAction)feedbackButtonWasTouched:(id)sender;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

// Ticking functions
- (void)record:(id)sender;

@end
