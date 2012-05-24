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

@interface ViewController : UIViewController
{
	UIButton			*startButton;
	UILabel				*recordingLabel;
	UILabel				*dataLabel;
	sqlite3				*db;
	NSTimer				*ticker;
	NSString			*dbpath;
	NSString			*device;
	CLLocationManager	*locationManager;
	UIAccelerometer		*accelerometer;
	AVAudioRecorder		*recorder;
	int					accelValuesCollected;
	float				accelX, accelY, accelZ;
}

@property (nonatomic, retain) IBOutlet UIButton		*startButton;
@property (nonatomic, retain) IBOutlet UILabel		*recordingLabel;
@property (nonatomic, retain) IBOutlet UILabel		*dataLabel;
@property (nonatomic, retain) NSTimer				*ticker;
@property (nonatomic, retain) NSString				*dbpath;
@property (nonatomic, retain) NSString				*device;
@property (nonatomic, retain) CLLocationManager		*locationManager;
@property (nonatomic, retain) UIAccelerometer		*accelerometer;
@property (nonatomic, retain) AVAudioRecorder		*recorder;
@property (nonatomic, assign) int					accelValuesCollected;
@property (nonatomic, assign) float					accelX, accelY, accelZ;

- (void)setDevice:(NSString *)_device;
- (void)warn;
- (BOOL)sqlcon;
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery;
- (int)numRows;
- (IBAction)uploadRows:(id)sender;
- (IBAction)emptyTable:(id)sender;
- (void)updateDataLabel;
- (void)record:(id)sender;
- (IBAction)toggleButton:(id)sender;

@end
