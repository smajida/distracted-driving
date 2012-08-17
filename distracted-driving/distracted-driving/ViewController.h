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
#import "SettingsViewController.h"
#import "AppDelegate.h"

// Settings (Constants)
extern int const	kMinimumDrivingSpeed;
extern float const	kTimeIntervalForTick;
extern int const	kPauseInterval;
extern int const	kMaximumStopTime;
extern int const	kAutomaticallyStopTime;
extern int const	kRemindUserToTagTime;
extern int const	kDrasticSpeedChange;
extern int const	kSignificantLocationChange;
extern int const	kMaximumSpeedAge;
extern int const	kDataPointsForAverage;
extern int const	kAlertExpire;
extern int const	kAlertViewDangerTag;
extern double const kMapSpanDelta;

@interface ViewController : UIViewController <UIAlertViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, TagMenuDelegate, SettingsDelegate>
{
	TagMenuViewController		*tagMenu;
	UIImageView					*tagMenuBackground;
	GradientButton				*startButton, *tagButton;
	UILabel						*speedometer;
	sqlite3						*db;
	NSTimer						*ticker;
	NSString					*dbpath;
	NSString					*device;
	NSUserDefaults				*settings;
	CLLocationManager			*locationManager;
	CLLocation					*oldLocation, *lastCenteredLocation;
	CLRegion					*currentBoundary;
	UIAccelerometer				*accelerometer;
	AVAudioRecorder				*recorder;
	MKMapView					*mapView;
	MKAnnotationView			*selectedAnnotation;
	NSMutableArray				*speedValues;
	NSDate						*lastAlertedUser, *lastRecordedData, *dateStopped;
	NSURLConnection				*dangerTagsConnection;
	NSMutableData				*dangerTagsData;
	UIBackgroundTaskIdentifier	bgTask;
	int							accelValuesCollected;
	float						accelX, accelY, accelZ, speed, thrownAwaySpeed;
	BOOL						recording, trackingUser, didGetDangerTags, isUsingOnlySignificantChanges, limitBatteryConsumption, remindUserToRecord, hasBeenInBackground, automaticallyStartAndStop, hasRemindedUserToTag, remindUserToTag;
}

@property (nonatomic, retain) TagMenuViewController			*tagMenu;
@property (nonatomic, retain) UIImageView					*tagMenuBackground;
@property (nonatomic, retain) IBOutlet GradientButton		*startButton, *tagButton;
@property (nonatomic, retain) IBOutlet UILabel				*speedometer;
@property (nonatomic, retain) NSTimer						*ticker;
@property (nonatomic, retain) NSString						*dbpath;
@property (nonatomic, retain) NSString						*device;
@property (nonatomic, retain) NSUserDefaults				*settings;
@property (nonatomic, retain) CLLocationManager				*locationManager;
@property (nonatomic, retain) CLLocation					*oldLocation, *lastCenteredLocation;
@property (nonatomic, retain) CLRegion						*currentBoundary;
@property (nonatomic, retain) UIAccelerometer				*accelerometer;
@property (nonatomic, retain) AVAudioRecorder				*recorder;
@property (nonatomic, retain) IBOutlet MKMapView			*mapView;
@property (nonatomic, retain) MKAnnotationView				*selectedAnnotation;
@property (nonatomic, retain) NSMutableArray				*speedValues;
@property (nonatomic, retain) NSDate						*lastAlertedUser, *lastRecordedData, *dateStopped;
@property (nonatomic, retain) NSURLConnection				*dangerTagsConnection;
@property (nonatomic, retain) NSMutableData					*dangerTagsData;
@property (nonatomic, assign) UIBackgroundTaskIdentifier	bgTask;
@property (nonatomic, assign) int							accelValuesCollected;
@property (nonatomic, assign) float							accelX, accelY, accelZ, speed, thrownAwaySpeed;
@property (nonatomic, assign) BOOL							recording, trackingUser, didGetDangerTags, isUsingOnlySignificantChanges, limitBatteryConsumption, remindUserToRecord, hasBeenInBackground, automaticallyStartAndStop, hasRemindedUserToTag, remindUserToTag;

// Initializing functions
- (BOOL)sqlcon;
- (void)loadUserSettings;

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
- (void)dropTagAtCoordinate:(CLLocationCoordinate2D)coordinate withRoadConditions:(BOOL)roadConditions andTraffic:(BOOL)traffic andSignal:(BOOL)signal;
- (void)tagViewAsDangerous:(MKAnnotationView *)view withTraffic:(BOOL)traffic andRoadConditions:(BOOL)roadConditions andSignal:(BOOL)signal andImage:(UIImage *)image;
- (void)createAndMonitorRegion;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation;
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation;

// Display (popup) functions
- (void)openTagMenuWithTitle:(NSString *)title andAnnotationView:(MKAnnotationView *)view;
- (void)openTagMenuWithTitle:(NSString *)title;
- (void)openTagMenuWithAnnotationView:(MKAnnotationView *)view;
- (void)openTagMenu;
- (void)tagMenuDidClose;
- (void)settingsMenuDidClose;
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

// Input receiving functions
- (void)longTouchHappened:(UIGestureRecognizer *)gestureRecognizer;
- (void)panHappened:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)startButtonWasTouched:(id)sender;
- (IBAction)tagButtonWasTouched:(id)sender;
- (IBAction)feedbackButtonWasTouched:(id)sender;
- (IBAction)settingsButtonWasTouched:(id)sender;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

// Enabling/Disabling functions
- (void)enableLocationServicesInBackground:(BOOL)inBackground;
- (void)enableLocationServices;
- (void)disableLocationServices;
- (void)enableAccelerometer;
- (void)disableAccelerometer;
- (void)enableMicrophone;
- (void)disableMicrophone;

// Ticking functions
- (void)record:(id)sender;

@end
