//
//  ViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

// Settings (Constants)
int const		kMinimumDrivingSpeed		= 10;		// 10 mph
float const		kTimeIntervalForTick		= 5.0;		// 5.0 seconds
int const		kPauseInterval				= 10;		// 10 seconds
int const		kMaximumStopTime			= 300;		// 5 minutes
int const		kDrasticSpeedChange			= 50;		// 50 mps
int const		kSignificantLocationChange	= 100;		// 100 meters
int const		kDataPointsForAverage		= 5;		// 5 points
int const		kAlertExpire				= 300;		// 5 minutes
double const	kMapSpanDelta				= 0.005;	// 0.005 degrees

// Pointers (i.e. UIButton *)
@synthesize startButton, tagButton, speedometer, dbpath, device, ticker, locationManager, oldLocation, lastCenteredLocation, accelerometer, recorder, mapView, speedValues, lastAlertedUser, lastRecordedData, dateStopped, dangerTagsData, dangerTagsConnection, settings;

// Low-level types (i.e. int)
@synthesize accelValuesCollected, accelX, accelY, accelZ, speed, recording, trackingUser, bgTask, thrownAwaySpeed, didGetDangerTags, isUsingOnlySignificantChanges, limitBatteryConsumption, remindUserToRecord, hasBeenInBackground;

/**************************
 * Initializing functions *
 **************************/

// Connect to the SQL database
- (BOOL)sqlcon
{
	// Two temporary variables
	NSArray			*paths;
	const char		*database;
	
	// Get device paths
	paths		= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	// Get the path to the database
	dbpath		= [[NSString alloc] initWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"distracted-driving_v1.1.db"]];
	
	// Create the database file if it doesn't exist
	if([[NSFileManager defaultManager] fileExistsAtPath:dbpath] == NO)
	{
		// Create the file
		NSString *dbpathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"distracted-driving_v1.1.db"];
		
		// Copy it to the correct location
		[[NSFileManager defaultManager] copyItemAtPath:dbpathFromApp toPath:dbpath error:nil];
		
		// Get the UTF8String of the dbpath to use with sqlite3
		database = [dbpath UTF8String];
		
		// Create the table once the connection is made
		if(sqlite3_open(database, &db) == SQLITE_OK)
		{
			char *err;
			const char *sql = "CREATE TABLE IF NOT EXISTS collected_data (id INTEGER PRIMARY KEY AUTOINCREMENT, device_id TEXT, date DATETIME, accelorometer TEXT, sound TEXT, gps TEXT, compass TEXT, battery TEXT)";
			
			if(sqlite3_exec(db, sql, NULL, NULL, &err) != SQLITE_OK)
			{
				NSLog(@":: Table creation failed!");
				sqlite3_close(db);
				return NO;
			}
			
			sqlite3_close(db);
		}
		else
		{
			NSLog(@":: Database creation failed!");
			return NO;
		}
	}
	else
	{
		database = [dbpath UTF8String];
		
		if(sqlite3_open(database, &db) != SQLITE_OK)
		{
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_close(db);
	}
	
	NSLog(@":: Connected to SQL.");
	
	return YES;
}

- (void)loadUserSettings
{
	// Load saved settings
	settings = [NSUserDefaults standardUserDefaults];
	
	limitBatteryConsumption	= [settings boolForKey:@"limitBatteryConsumption"];
	remindUserToRecord		= ![settings boolForKey:@"doNotRemindUserToRecord"];
}

/***********************************
 * Variable manipulation functions *
 ***********************************/

// Calculates the current speed based on a number of data points
- (void)calculateSpeed
{
	// Temporary variables
	float averageSpeed = 0.0, highestSpeed = 0.0, lowestSpeed = 0.0;
	
	// Get average, lowest, and highest speeds for the data points
	for(int i = 0; i < [speedValues count]; i++)
	{
		averageSpeed += [[speedValues objectAtIndex:i] floatValue];
		
		if(i == 0)
			highestSpeed = lowestSpeed = [[speedValues objectAtIndex:i] floatValue];
		
		if(highestSpeed < [[speedValues objectAtIndex:i] floatValue])
			highestSpeed = [[speedValues objectAtIndex:i] floatValue];
		
		if(lowestSpeed > [[speedValues objectAtIndex:i] floatValue])
			lowestSpeed = [[speedValues objectAtIndex:i] floatValue];
	}
	
	// Pretend the speed is zero while gathering data, and if there are multiple zeros pretend the speed is zero
	if([speedValues count] > 0)
	{
		averageSpeed = averageSpeed / [speedValues count];
		
		// If there are enough points, we can use the average
		if([speedValues count] == kDataPointsForAverage)
		{
			if(([self mphFromMps:highestSpeed] - [self mphFromMps:lowestSpeed]) < 5)
			{
				// Peak/valley difference is low; good average
				speed = averageSpeed;
			}
		}
		else
			speed = 0.0;
	}
	else
		speed = 0.0;
	
	// Update stop time
	if(speed >= kMinimumDrivingSpeed)
		dateStopped = [NSDate date];
	
	if(recording && [[NSDate date] timeIntervalSinceDate:dateStopped] > kMaximumStopTime && [[NSDate date] timeIntervalSinceDate:lastAlertedUser] > kAlertExpire)
	{
		// Alert the user; they've been stopped for a long time
		NSString *alertString = @"Don't forget to stop recording when you're finished!";
		
		if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
		{
			[TestFlight passCheckpoint:@"Notified user in background to stop recording."];
			
			// Alert the user from the background that they need to record
			bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
				[[UIApplication sharedApplication] endBackgroundTask:bgTask];
				bgTask = UIBackgroundTaskInvalid;
			}];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				// Alert the user they need to start recording because they are driving
				UILocalNotification *notification	= [[UILocalNotification alloc] init];
				notification.fireDate				= [NSDate dateWithTimeIntervalSinceNow:0];
				notification.alertBody				= alertString;
				notification.soundName				= UILocalNotificationDefaultSoundName;
				
				[[UIApplication sharedApplication] scheduleLocalNotification:notification];
			});
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention!" message:alertString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
			[alert show];
		}
		
		lastAlertedUser = [NSDate date];
	}
	
	// Convert speed to MPH
	speed = [self mphFromMps:speed];
}

// Convert meters per second into miles per hour
- (float)mphFromMps:(float)mps
{
	return mps * 2.23693629;
}

// Convert miles per hour into meters per second
- (float)mpsFromMph:(float)mph
{
	return mph / 2.23693629;
}

/***********************
 * Animation functions *
 ***********************/

- (void)bounce1AnimationStopped
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3/2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	tagMenu.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3/2];
	tagMenu.view.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}

/*****************************
 * Data management functions *
 *****************************/

// Insert a row to local SQL
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery
{
	// Temporary variable
	sqlite3_stmt *query;
	
	if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
	{
		NSString *nsquery = [NSString stringWithFormat:@"INSERT INTO collected_data (device_id, date, accelorometer, sound, gps, compass, battery) VALUES ('%@', datetime('now'), '%@', '%@', '%@', '%@', '%@')", device, accelorometer, sound, gps, compass, battery];
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		if(sqlite3_step(query) != SQLITE_DONE)
		{
			NSLog(@":: Query failed; %s!", sqlite3_errmsg(db));
			sqlite3_finalize(query);
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
	{
		NSLog(@":: Query failed; %s!", sqlite3_errmsg(db));
		return NO;
	}
	
	NSLog(@":: Local SQL table added a row.");
	
	return YES;
}

// Get the number of rows in the local database
- (int)numRows
{
	// The number of rows
	int num = 0;
	
	// Temprary variable
	sqlite3_stmt *query;
	
	if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
	{
		NSString *nsquery = @"SELECT * FROM collected_data";
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		while(sqlite3_step(query) == SQLITE_ROW)
			num++;
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
	
	return num;
}

// Upload rows from the local database to the remote server
- (void)uploadRows
{
	if([self numRows] > 0)
	{
		NSLog(@":: Uploading data to remote server.");
		
		// Temporary variables
		NSString			*_id;
		NSString			*_device;
		NSString			*date;
		NSString			*accelorometer;
		NSString			*sound;
		NSString			*gps;
		NSString			*compass;
		NSString			*battery;
		NSMutableURLRequest	*request;
		NSURLConnection		*connection;
		sqlite3_stmt		*query;
		
		if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
		{
			NSString *nsquery = @"SELECT * FROM collected_data";
			
			const char *cquery = [nsquery UTF8String];
			
			sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
			
			while(sqlite3_step(query) == SQLITE_ROW)
			{
				_id				= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 0)];
				_device			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 1)];
				date			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 2)];
				accelorometer	= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 3)];
				sound			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 4)];
				gps				= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 5)];
				compass			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 6)];
				battery			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 7)];
				request			= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/add_data.php"]];
				
				[request setHTTPMethod:@"POST"];
				
				NSString *postString = [NSString stringWithFormat:@"device=%@&date=%@&accelorometer=%@&sound=%@&gps=%@&compass=%@&battery=%@", _device, date, accelorometer, sound, gps, compass, battery];
				
				[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
				
				[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
				
				connection		= [[NSURLConnection alloc] initWithRequest:request delegate:self];
				
				if(connection)
				{
					// NSLog(@":: SQL row upload successful.");
				}
				else
				{
					NSLog(@":: SQL row upload failed.");
				}
			}
			
			sqlite3_finalize(query);
			sqlite3_close(db);
		}
		else
			NSLog(@":: Query failed; %s!", sqlite3_errmsg(db));
		
		// Empty the table now that the rows have been uploaded
		[self emptyTable];
	}
}

// Delete all entries in the local database
- (void)emptyTable
{
	sqlite3_stmt *query;
	
	if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
	{
		NSString *nsquery = @"DELETE FROM collected_data";
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		if(sqlite3_step(query) != SQLITE_DONE)
		{
			NSLog(@":: Query failed; %s!", sqlite3_errmsg(db));
			sqlite3_finalize(query);
			sqlite3_close(db);
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@":: Query failed; %s!", sqlite3_errmsg(db));
}

/**********************
 * Location functions *
 **********************/

// Validates a given location, throwing out bad values (i.e. nil or a location with bad accuracy or old timestamp)
- (BOOL)isValidLocation:(CLLocation *)newLocation
{
	// Throw out nil
	if(!newLocation)
		return NO;
	
	// Throw out locations with invalid or imprecise accuracy values
	if(!newLocation.horizontalAccuracy || newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > 100)
		return NO;
	
	// Throw out the first location sent to this function
	if(oldLocation == nil)
	{
		oldLocation = newLocation;
		return NO;
	}
	
	// Throw out locations with timestamps older than the old location
	NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
	if(timeInterval < 0)
		return NO;
	
	// This is a valid location
	return YES;
}

// Drop a maptag at the given location
- (void)dropPinAtCoordinate:(CLLocationCoordinate2D)coordinate
{
	[mapView addAnnotation:[[MapTag alloc] initWithName:@"Mark as Dangerous" address:nil coordinate:coordinate]];
}

// Finish a location tag
- (void)tagViewAsDangerous:(MKAnnotationView *)view withTraffic:(BOOL)traffic andRoadConditions:(BOOL)roadConditions andSignal:(BOOL)signal
{
	NSMutableURLRequest	*request;
	NSURLConnection		*connection;
	NSString			*postString, *dateString;
	
	// If signal, road/traffic conditions must be ignored
	if(signal)
		roadConditions = traffic = NO;
	
	// Get the date
	NSDate				*date		= [NSDate date];
	NSDateFormatter		*formatter	= [[NSDateFormatter alloc] init];
	
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	dateString = [formatter stringFromDate:date];
	
	// Send a request to the server to mark this location as dangerous
	request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/add_tag.php"]];
	
	if(view)
	{
		// Specifically tagged location
		postString = [NSString stringWithFormat:@"device=%@&date=%@&latitude=%f&longitude=%f&traffic=%d&roadConditions=%d&signal=%d&trip=0", device, dateString, view.annotation.coordinate.latitude, view.annotation.coordinate.longitude, traffic, roadConditions, signal];
		
		NSString *title, *subtitle;
		BOOL isSafe = NO;
		
		title = @"Dangerous Zone";
		
		if(roadConditions && traffic)
			subtitle = @"Dangerous traffic and road conditions";
		else if(roadConditions)
			subtitle = @"Dangerous road conditions";
		else if(traffic)
			subtitle = @"Dangerous traffic conditions";
		else if(signal)
		{
			title		= @"Traffic Signal";
			subtitle	= nil;
		}
		else
			isSafe = YES;
		
		// Make a new annotation (DangerTag)
		if(!isSafe)
		{
			[TestFlight passCheckpoint:@"Tagged an area as dangerous."];
			[mapView addAnnotation:[[DangerTag alloc] initWithName:title address:subtitle coordinate:view.annotation.coordinate]];
		}
		
		// Remove the annotation
		[mapView removeAnnotation:view.annotation];
	}
	else
	{
		// Trip tag
		postString = [NSString stringWithFormat:@"device=%@&date=%@&latitude=%f&longitude=%f&traffic=%d&roadConditions=%d&signal=0&trip=1", device, dateString, locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, traffic, roadConditions];
	}
	
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if(connection)
		NSLog(@":: Danger tag successful!");
	else
		NSLog(@":: Danger tag failed.");
}

// Start following the user if they move far enough
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation
{
	// float ds = [newLocation distanceFromLocation:_oldLocation];
	float dt = [newLocation.timestamp timeIntervalSinceDate:_oldLocation.timestamp];
	
	// Update the speed
	if(manager.heading.trueHeading >= 0 && [self isValidLocation:newLocation])
	{
		if(dt < 30)
		{
			// Only affect speed if the updates are more frequent than 30 seconds apart
			float obj = (float) [newLocation distanceFromLocation:_oldLocation] / (float) [newLocation.timestamp timeIntervalSinceDate:_oldLocation.timestamp];
			
			// Throw away old values if the last two thrown away values are very close
			if(thrownAwaySpeed > 0 && fabs(thrownAwaySpeed - obj) < 5 && [speedValues count] == kDataPointsForAverage)
			{
				[speedValues removeAllObjects];
				NSLog(@"Throwing out old speed");
			}
			
			// Only add the point if it isn't drastically different from the average
			thrownAwaySpeed = -1.0;
			
			if(fabs([self mphFromMps:obj] - speed) < kDrasticSpeedChange || [speedValues count] < kDataPointsForAverage)
				[speedValues insertObject:[NSNumber numberWithFloat:obj] atIndex:0];
			else if(fabs([self mphFromMps:obj] - speed) >= kDrasticSpeedChange)
				thrownAwaySpeed = obj;
			
			if([speedValues count] > kDataPointsForAverage)
				[speedValues removeLastObject];
			
			[self calculateSpeed];
		}
		
		// Update location regardless of dt
		oldLocation = newLocation;
	}
	
	// This alert is for phones that can't use Geofencing
	if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground && speed > kMinimumDrivingSpeed && !recording && [[NSDate date] timeIntervalSinceDate:lastAlertedUser] > kAlertExpire && !tagMenu)
	{
		[TestFlight passCheckpoint:@"Notified user in background via significant change."];
		NSString *alertString = @"Don't forget to record when you're driving!";
		
		// Alert the user from the background that they need to record
		bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:bgTask];
			bgTask = UIBackgroundTaskInvalid;
		}];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			// Alert the user they need to start recording because they are driving
			UILocalNotification *notification	= [[UILocalNotification alloc] init];
			notification.fireDate				= [NSDate dateWithTimeIntervalSinceNow:0];
			notification.alertBody				= alertString;
			notification.soundName				= UILocalNotificationDefaultSoundName;
			
			[[UIApplication sharedApplication] scheduleLocalNotification:notification];
		});
		
		lastAlertedUser = [NSDate date];
	}
	
	// Check distance not from the last location but from the last centered location
	if(!trackingUser && [self isValidLocation:newLocation] && [newLocation distanceFromLocation:lastCenteredLocation] > 100)
	{
		trackingUser = YES;
		[mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
	}
	
	// Check for danger tags
	if(!didGetDangerTags && [self isValidLocation:newLocation])
	{
		NSLog(@":: Making a request for danger tags.");
		
		NSDate				*date		= [NSDate date];
		NSDateFormatter		*formatter	= [[NSDateFormatter alloc] init];
		
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		NSString *dateString = [formatter stringFromDate:date];
		
		NSString *postString = [NSString stringWithFormat:@"device=%@&date=%@&latitude=%f&longitude=%f", device, dateString, newLocation.coordinate.latitude, newLocation.coordinate.longitude];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/get_tags.php"]];
		[request setHTTPMethod:@"POST"];
		[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
		[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
		
		dangerTagsData			= [[NSMutableData alloc] init];
		dangerTagsConnection	= [[NSURLConnection alloc] initWithRequest:request delegate:self];
		didGetDangerTags		= YES;
	}
}

// Detect significant changes
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
	NSString *alertString = @"Don't forget to record when you're driving!";
	
	if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
	{
		[TestFlight passCheckpoint:@"Notified user in background via Geofencing."];
		
		// Alert the user from the background that they need to record
		bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:bgTask];
			bgTask = UIBackgroundTaskInvalid;
		}];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			// Alert the user they need to start recording because they are driving
			UILocalNotification *notification	= [[UILocalNotification alloc] init];
			notification.fireDate				= [NSDate dateWithTimeIntervalSinceNow:0];
			notification.alertBody				= alertString;
			notification.soundName				= UILocalNotificationDefaultSoundName;
			
			[[UIApplication sharedApplication] scheduleLocalNotification:notification];
		});
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:alertString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
		[alert show];
	}
	
	lastAlertedUser = [NSDate date];
}

// Handle callout button touches
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	[self openTagMenuWithAnnotationView:view];
}

// Handle annotations
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	NSString	*identifier = @"maptag";
	BOOL		isDangerTag = NO;
	
	// Skip user location annotation
	if([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	
	// Differentiate between MapTags and DangerTags
	if([annotation isKindOfClass:[DangerTag class]])
	{
		identifier	= @"dangertag";
		isDangerTag	= YES;
	}
	
	// Load the annotation view
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
	
	// Create a new one, if one didn't already exist
	if(annotationView == nil)
		annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
	else
		annotationView.annotation = annotation;
	
	// Allow user interaction
	annotationView.enabled			= YES;
	annotationView.canShowCallout	= YES;
	
	MapTag *tmp = (MapTag *) annotation;
	annotationView.animatesDrop = tmp.animateDrop;
	
	if(isDangerTag)
	{
		// Danger tags are red and appear instantly
		annotationView.pinColor		= MKPinAnnotationColorRed;
	}
	else
	{
		// Map tags are green and animate dropping in
		annotationView.pinColor		= MKPinAnnotationColorGreen;
		
		// Add a button to allow users to tag this pin as a dangerous zone
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[annotationView setRightCalloutAccessoryView:btn];
	}
	
	return annotationView;
}

/*****************************
 * Display (popup) functions *
 *****************************/

// Open the tag menu popup
- (void)openTagMenuWithTitle:(NSString *)title andAnnotationView:(MKAnnotationView *)view
{
	// Display the background
	tagMenuBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"behind_alert_view.png"]];
	[tagMenuBackground setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	[self.view addSubview:(UIView *)tagMenuBackground];
	
	// Set up the tag menu
	if(title && view)
		tagMenu = [[TagMenuViewController alloc] initWithTitle:title];
	else if(title)
		tagMenu = [[TagMenuViewController alloc] initWithTitle:title withUpload:YES];
	else
		tagMenu = [[TagMenuViewController alloc] init];
	
	tagMenu.delegate = self;
	
	if(view)
		tagMenu.annotationView = view;
	
	// Animate it!
	tagMenu.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	[self.view addSubview:tagMenu.view];
	tagMenu.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
	[UIView commitAnimations];
}

- (void)openTagMenuWithTitle:(NSString *)title
{
	return [self openTagMenuWithTitle:title andAnnotationView:nil];
}

- (void)openTagMenuWithAnnotationView:(MKAnnotationView *)view
{
	return [self openTagMenuWithTitle:nil andAnnotationView:view];
}

- (void)openTagMenu
{
	return [self openTagMenuWithTitle:nil andAnnotationView:nil];
}

// Receive this action when the popup is closed
- (void)tagMenuDidClose
{
	// Remove the image overlay
	[tagMenuBackground removeFromSuperview];
	tagMenuBackground = nil;
	
	// Free data from the menu itself
	tagMenu = nil;
}

- (void)settingsMenuDidClose
{
	// Check changed settings and make appropriate changes
	if(limitBatteryConsumption)
	{
		// Don't use the magnetometer
		[locationManager stopUpdatingHeading];
		
		// Don't use the microphone
		if([recorder isRecording])
			[self disableMicrophone];
	}
	else
	{
		// Use the magnetometer
		[locationManager startUpdatingHeading];
		
		// Use the microphone
		if(![recorder isRecording])
			[self enableMicrophone];
	}
}

/*******************************
 * Server/Connection functions *
 *******************************/

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(connection == dangerTagsConnection)
	{
		[dangerTagsData setLength:0];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(connection == dangerTagsConnection)
	{
		[dangerTagsData appendData:data];
	}
	else
	{
		NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(connection == dangerTagsConnection)
	{
		NSLog(@":: Danger tags received from server.");
		
		NSArray *dangerTags = [[NSJSONSerialization JSONObjectWithData:dangerTagsData options:kNilOptions error:nil] objectForKey:@"danger_tags"];
		
		for(int i = 0; i < [dangerTags count]; i++)
		{
			NSDictionary *item = [dangerTags objectAtIndex:i];
			CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[item objectForKey:@"latitude"] floatValue], [[item objectForKey:@"longitude"] floatValue]);
			NSString *title, *subtitle;
			
			BOOL roadConditions	= [[item objectForKey:@"roadConditions"] intValue];
			BOOL traffic		= [[item objectForKey:@"traffic"] intValue];
			BOOL signal			= [[item objectForKey:@"signal"] intValue];
			BOOL isSafe			= NO;
			
			title = @"Dangerous Zone";
			
			if(roadConditions && traffic)
				subtitle = @"Dangerous traffic and road conditions";
			else if(roadConditions)
				subtitle = @"Dangerous road conditions";
			else if(traffic)
				subtitle = @"Dangerous traffic conditions";
			else if(signal)
			{
				title		= @"Traffic Signal";
				subtitle	= nil;
			}
			else
				isSafe = YES;
			
			if(!isSafe)
			{
				DangerTag *tag = [[DangerTag alloc] initWithName:title address:subtitle coordinate:coordinate];
				tag.animateDrop = YES;
				[mapView addAnnotation:tag];
			}
		}
		
		
		// Get rid of the old data
		dangerTagsConnection	= nil;
		dangerTagsData			= nil;
	}
}

/*****************************
 * Input receiving functions *
 *****************************/

// Action received when the user taps and holds on the map
- (void)longTouchHappened:(UIGestureRecognizer *)gestureRecognizer
{
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		// Drop a pin at that location
		[self dropPinAtCoordinate:[mapView convertPoint:[gestureRecognizer locationInView:mapView] toCoordinateFromView:mapView]];
	}
}

// Action received when the user drags the map
-(void)panHappened:(UIGestureRecognizer *)gestureRecognizer
{
	// If the user pans the screen, stop tracking
	trackingUser = NO;
	lastCenteredLocation = [mapView userLocation].location;
	[mapView setUserTrackingMode:MKUserTrackingModeNone];
}

// Action received when the start/stop button is touched
- (IBAction)startButtonWasTouched:(id)sender
{
	[TestFlight passCheckpoint:@"Started recording data."];
	
	startButton.selected = !startButton.selected;
	
	if(startButton.selected)
	{
		// Recording
		recording = YES;
		
		// Update button color to red
		[startButton setBackgroundColor: [UIColor colorWithRed:0.6f green:0.1f blue:0.1f alpha:1.0f]];
		
		// Start recording
		ticker = [NSTimer scheduledTimerWithTimeInterval:kTimeIntervalForTick target:self selector:@selector(record:) userInfo:nil repeats:YES];
	}
	else
	{
		// Done recording
		recording = NO;
		
		// Update button color to green
		[startButton setBackgroundColor: [UIColor colorWithRed:0.1f green:0.6f blue:0.1f alpha:1.0f]];
		
		// Stop recording
		[ticker invalidate];
		ticker = nil;
		
		// Reset the alert
		lastAlertedUser = [NSDate dateWithTimeIntervalSinceNow:kPauseInterval];
		
		// Display the popup
		[self openTagMenuWithTitle:@"This Trip Had Dangerous..."];
	}
}

// Action received when the tag button is touched
- (IBAction)tagButtonWasTouched:(id)sender
{
	// Center the map first
	[mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
	
	// Drop a pin at the current location
	[self dropPinAtCoordinate:locationManager.location.coordinate];
	
	// Get the annotation view for that pin
	for(id<MKAnnotation> annotation in [mapView annotations])
	{
		if(locationManager.location.coordinate.latitude == annotation.coordinate.latitude && locationManager.location.coordinate.longitude == annotation.coordinate.longitude)
		{
			// Open the tag menu and pass in the view for this pin
			[self openTagMenuWithAnnotationView:[mapView viewForAnnotation:annotation]];
			
			// Stop searching, since we found the pin already
			break;
		}
	}
}

- (IBAction)feedbackButtonWasTouched:(id)sender
{
	[TestFlight openFeedbackView];
}

- (IBAction)settingsButtonWasTouched:(id)sender
{
	SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	settingsViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	settingsViewController.delegate = self;
	[self presentModalViewController:settingsViewController animated:YES];
}

// Enable gesture recognition
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{   
    return YES;
}

/********************************
 * Enabling/Disabling functions *
 ********************************/

- (void)enableLocationServices
{
	BOOL inBackground = [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground;
	
	// This flag will only be true when app is running in the background
	isUsingOnlySignificantChanges = NO;
	
	// Create the location manager
	if(!locationManager)
	{
		locationManager					= [[CLLocationManager alloc] init];
		locationManager.delegate		= self;
		locationManager.distanceFilter	= kCLDistanceFilterNone;
		locationManager.desiredAccuracy	= kCLLocationAccuracyHundredMeters;
		
		// Include some mapView settings here for first-time initializations
		UILongPressGestureRecognizer	*longPress	= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouchHappened:)];
		UIPanGestureRecognizer			*pan		= [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHappened:)];
		[pan setDelegate:self];
		[mapView addGestureRecognizer:longPress];
		[mapView addGestureRecognizer:pan];
		[mapView setDelegate:self];
		
		// Temporary variables
		MKCoordinateRegion		region;
		MKCoordinateSpan		span;
		
		// Set the span
		span.longitudeDelta = span.latitudeDelta = kMapSpanDelta;
		
		// Set up the region
		region.span		= span;
		region.center	= locationManager.location.coordinate;
		
		// Set mapView region
		[mapView setRegion:region animated:YES];
	}
	
	// Stop background monitoring (may be lingering from old versions, killed app, etc.)
	[locationManager stopMonitoringSignificantLocationChanges];
	
	// Stop background monitoring (regions)
	for(int i = 0; i < [[[locationManager monitoredRegions] allObjects] count]; i++)
		[locationManager stopMonitoringForRegion:[[[locationManager monitoredRegions] allObjects] objectAtIndex:i]];
	
	// If we're in the background, this is all that is required, so stop here
	if(inBackground)
		return;
	
	// Start magnetometer
	if(!limitBatteryConsumption)
		[locationManager startUpdatingHeading];
	
	// Start location services
	[locationManager startUpdatingLocation];
	
	oldLocation = nil;
	
	[mapView setShowsUserLocation:YES];
	[mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)disableLocationServices
{
	// Stop all location services
	[locationManager stopUpdatingHeading];
	[locationManager stopUpdatingLocation];
	[locationManager stopMonitoringSignificantLocationChanges];
	
	// Stop background monitoring (regions)
	for(int i = 0; i < [[[locationManager monitoredRegions] allObjects] count]; i++)
		[locationManager stopMonitoringForRegion:[[[locationManager monitoredRegions] allObjects] objectAtIndex:i]];
	
	// Stop the map view from updating
	[mapView setUserTrackingMode:MKUserTrackingModeNone];
	[mapView setShowsUserLocation:NO];
}

- (void)enableAccelerometer
{
	if(!accelerometer)
		accelerometer = [UIAccelerometer sharedAccelerometer];
	
	accelerometer.delegate			= (id) self;
	accelerometer.updateInterval	= 0.1;
	accelX = accelY = accelZ		= 0.0;
	accelValuesCollected			= 0;
}

- (void)disableAccelerometer
{
	accelerometer.delegate = nil;
}

- (void)enableMicrophone
{
	if(!recorder)
	{
		NSURL			*url		= [NSURL fileURLWithPath:@"/dev/null"];
		NSDictionary	*setting	= [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat:44100.0],					AVSampleRateKey,
									   [NSNumber numberWithInt:kAudioFormatAppleLossless],	AVFormatIDKey,
									   [NSNumber numberWithInt:1],							AVNumberOfChannelsKey,
									   [NSNumber numberWithInt:AVAudioQualityMax],			AVEncoderAudioQualityKey,
									   nil];
		
		UInt32 override	= YES;
		UInt32 speaker	= kAudioSessionOverrideAudioRoute_Speaker;
		
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
		
		AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(override), &override);
		AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(speaker), &speaker);
		
		[[AVAudioSession sharedInstance] setActive:YES error:nil];
		
		UInt32 otherAudio;
		UInt32 size = sizeof(otherAudio);
		
		AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &otherAudio);
		
		recorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:nil];
	}
	
	if(!limitBatteryConsumption)
	{
		if(recorder)
		{
			recorder.meteringEnabled = YES;
			[recorder record];
		}
	}
}

- (void)disableMicrophone
{
	if(recorder)
		[recorder stop];
}

/*********************
 * Ticking functions *
 *********************/

// The tick when recording data
- (void)record:(id)sender
{
	NSString *accel, *sound, *gps, *compass, *battery;
	
	// Average the speed
	[self calculateSpeed];
	
	// Accelorometer
	if(accelValuesCollected > 0)
		accel = [NSString stringWithFormat:@"x: %f, y: %f, z: %f", accelX / accelValuesCollected, accelY / accelValuesCollected, accelZ / accelValuesCollected];
	else
		accel = @"Unknown";
	
	accelX = accelY = accelZ = 0.0;
	accelValuesCollected = 0;
	
	// Sound
	if(recorder && [recorder isRecording])
	{
		[recorder updateMeters];
		sound = [NSString stringWithFormat:@"%f", [recorder averagePowerForChannel:0]];
	}
	else
		sound = @"Unknown";
	
	// Compass
	if(locationManager.heading.magneticHeading >= 0)
		compass = [NSString stringWithFormat:@"%f", locationManager.heading.magneticHeading];
	else
		compass = @"Unknown";
	
	// GPS
	if(locationManager.heading.trueHeading >= 0 && [self isValidLocation:locationManager.location])
		gps = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f, Heading: %f, Speed: %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, locationManager.heading.trueHeading, speed];
	else if([self isValidLocation:locationManager.location])
		gps = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f, Heading: Unknown, Speed: %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, speed];
	else
		gps = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f, Heading: Unknown, Speed: Unknown", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude];
	
	// Battery
	NSString *state;
	
	if([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnknown)
		state = @"Unknown";
	
	if([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged)
		state = @"Unplugged";
	
	if([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging)
		state = @"Charging";
	
	if([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateFull)
		state = @"Full";
	
	if(((int) [[UIDevice currentDevice] batteryLevel]) != -1)
		battery = [NSString stringWithFormat:@"%f; %@", [[UIDevice currentDevice] batteryLevel], state];
	else
		battery = @"Unknown";
	
	[self insertRowWithAccelorometer:accel andSound:sound andGps:gps andCompass:compass andBattery:battery];
	
	lastRecordedData = [NSDate date];
}

/********************
 * Sensor functions *
 ********************/

// Collect accelorometer data
- (void)accelerometer:(UIAccelerometer *)a didAccelerate:(UIAcceleration *)acceleration
{
	accelX += acceleration.x;
	accelY += acceleration.y;
	accelZ += acceleration.z;
	accelValuesCollected++;
}

/**************************
 * Device event functions *
 **************************/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Clear old notifications
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	
	// Enable battery monitoring
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	
	// Connect to SQL
	[self sqlcon];
	
	// Set up label
	[speedometer setNumberOfLines:0];
	
	// Set button labels
	[startButton	setTitle:@"Record"		forState:UIControlStateNormal];
	[startButton	setTitle:@"Stop"		forState:UIControlStateSelected];
	
	// Set button colors
	[startButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.6f blue:0.1f alpha:1.0f]];
	
	// Set device ID
	device = @"Unknown";
	
	// Set other variables
	recording				= NO;
	trackingUser			= YES;
	hasBeenInBackground		= NO;
	lastAlertedUser			= [NSDate dateWithTimeIntervalSinceNow:kPauseInterval];
	lastRecordedData		= [NSDate dateWithTimeIntervalSinceNow:kPauseInterval];
	dateStopped				= [NSDate dateWithTimeIntervalSinceNow:kPauseInterval];
	speed					= 0.0;
	thrownAwaySpeed			= -1.0;
	
	// Load user settings
	[self loadUserSettings];
	
	// Set up speed monitor
	speedValues = [[NSMutableArray alloc] init];
	
	// Enable data collection
	[self enableLocationServices];
	[self enableAccelerometer];
	[self enableMicrophone];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self.startButton			= nil;
	self.tagButton				= nil;
	self.speedometer			= nil;
	self.dbpath					= nil;
	self.device					= nil;
	self.ticker					= nil;
	self.locationManager		= nil;
	self.oldLocation			= nil;
	self.lastCenteredLocation	= nil;
	self.currentBoundary		= nil;
	self.accelerometer			= nil;
	self.recorder				= nil;
	self.mapView				= nil;
	self.speedValues			= nil;
	self.lastAlertedUser		= nil;
	self.lastRecordedData		= nil;
	self.dateStopped			= nil;
	self.tagMenu				= nil;
	self.tagMenuBackground		= nil;
	self.dangerTagsConnection	= nil;
	self.dangerTagsData			= nil;
	self.settings				= nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
