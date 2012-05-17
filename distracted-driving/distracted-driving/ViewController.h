//
//  ViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface ViewController : UIViewController
{
	UIButton	*startButton;
	UILabel		*recordingLabel;
	UILabel		*dataLabel;
	sqlite3		*db;
	NSTimer		*ticker;
	BOOL		dataExists;
	const char	*dbpath;
}

@property (nonatomic, retain) IBOutlet UIButton	*startButton;
@property (nonatomic, retain) IBOutlet UILabel	*recordingLabel;
@property (nonatomic, retain) IBOutlet UILabel	*dataLabel;
@property (nonatomic, retain) NSTimer			*ticker;
@property (nonatomic, assign) const char		*dbpath;
@property (nonatomic, assign) BOOL				dataExists;

- (void)setDataExists:(BOOL)value;
- (BOOL)sqlcon;
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery;
- (void)record:(id) sender;
- (IBAction)toggleButton:(id) sender;

@end
