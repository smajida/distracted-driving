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
int const		kMinimumDrivingSpeed	= 5;
int const		kDataPointsForAverage	= 5;
double const	kMapSpanDelta			= 0.005;

// Pointers (i.e. UIButton *)
@synthesize startButton, uploadButton, tagButton, speedometer, dbpath, device, ticker, locationManager, oldLocation, lastCenteredLocation, accelerometer, recorder, mapView, speedValues;

// Low-level types (i.e. int)
@synthesize accelValuesCollected, accelX, accelY, accelZ, speed, recording, trackingUser, hasAlertedUser;

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

/***********************************
 * Variable manipulation functions *
 ***********************************/

// Calculates the current speed based on a number of data points
- (void)calculateSpeed
{
	// Temporary variables
	float averageSpeed = 0.0, highestSpeed = 0.0, lowestSpeed = 0.0;
	NSString *foo;
	
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
	
	averageSpeed = averageSpeed / [speedValues count];
	
	// Standard procedure with a good number of data points
	if([speedValues count] == kDataPointsForAverage)
	{
		// Convert all to MPH
		averageSpeed	= [self mphFromMps:averageSpeed];
		highestSpeed	= [self mphFromMps:highestSpeed];
		lowestSpeed		= [self mphFromMps:lowestSpeed];
		
		// Now, compare the determined values to see if the variation makes sense
		if((highestSpeed - lowestSpeed) > 5)
		{
			// Variation is greater than 5mph between the highest and lowest speeds, so check the average
			if((highestSpeed - averageSpeed) > 5 || (averageSpeed - lowestSpeed) > 5)
			{
				// Variation is very high, probably due to acceleration; average the last two points
				foo = [NSString stringWithFormat:@"High variation. (A: %d, H: %d, L: %d)", (int) averageSpeed, (int) highestSpeed, (int) lowestSpeed];\
				speed = [self mpsFromMph:([[speedValues objectAtIndex:0] floatValue] + [[speedValues objectAtIndex:1] floatValue])/2];
			}
			else
			{
				// Variation is moderate (high between peaks and valleys, but low overall); the average should be used
				foo = [NSString stringWithFormat:@"Moderate variation. (A: %d, H: %d, L: %d)", (int) averageSpeed, (int) highestSpeed, (int) lowestSpeed];
				speed = [self mpsFromMph:averageSpeed];
			}
		}
		else
		{
			// Variation is low; the last point is good enough on its own
			foo = [NSString stringWithFormat:@"Low variation. (A: %d, H: %d, L: %d)", (int) averageSpeed, (int) highestSpeed, (int) lowestSpeed];
			speed = [self mpsFromMph:[[speedValues objectAtIndex:0] floatValue]];
		}
	}
	else
	{
		// With fewer points, we'll just average them and hope for the best
		speed = averageSpeed;
		foo = @"not enough points";
	}
	
	[speedometer setText:[NSString stringWithFormat:@"%d mph\n%@", (int) [self mphFromMps:speed], foo]];
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
	
	[self updateData];
}

// Update the upload button -- blue when there is data to send, gray when there is no data to send
- (void)updateData
{
	int rows = [self numRows];
	
	if(rows > 0)
		[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.1f blue:0.6f alpha:1.0f]];
	else
		[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f]];
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
	if(newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > 100)
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

// Shortcut to the automatic centering function
- (void)centerMapOnLocation:(CLLocation *)location
{
	// Temporary variables
	MKCoordinateRegion		region;
	MKCoordinateSpan		span;
	
	// Set the span
	span.longitudeDelta = span.latitudeDelta = kMapSpanDelta;
	
	// Set up the region
	region.span		= span;
	region.center	= location.coordinate;
	
	// Set the map view
	[mapView setRegion:region animated:YES];
}

// Start following the user if they move far enough
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation
{
	// Check distance not from the last location but from the last centered location
	if(!trackingUser && [self isValidLocation:newLocation] && [newLocation distanceFromLocation:lastCenteredLocation] > 100)
		trackingUser = YES;
}

// Follow the user's location if tracking is enabled
- (void)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if(trackingUser)
		[self centerMapOnLocation:(CLLocation *)userLocation];
}

// Handle callout button touches
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	tagMenu = [[TagMenuViewController alloc] init];
	[[self view] addSubview:[tagMenu view]];
	
	return;
	
	NSMutableURLRequest	*request;
	NSURLConnection		*connection;
	NSString			*postString, *dateString;
	
	// Get the date
	NSDate				*date		= [NSDate date];
	NSDateFormatter		*formatter	= [[NSDateFormatter alloc] init];
	
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	dateString = [formatter stringFromDate:date];
	
	// Get the annotation coordinate
	CLLocationCoordinate2D coordinate = view.annotation.coordinate;
	
	// Send a request to the server to mark this location as dangerous
	request		= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/add_tag.php"]];
	postString	= [NSString stringWithFormat:@"device=%@&date=%@&latitude=%f&longitude=%f", device, dateString, coordinate.latitude, coordinate.longitude];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if(connection)
	{
		NSLog(@":: Danger tag successful.");
	}
	else
	{
		NSLog(@":: Danger tag failed.");
	}
	
	// Remove the annotation
	[mapView removeAnnotation:view.annotation];
	
	// Make a new annotation (DangerTag)
	[mapView addAnnotation:[[DangerTag alloc] initWithName:@"Dangerous Zone" address:nil coordinate:coordinate]];
}

// Handle annotations
- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	NSString	*identifier;
	BOOL		isDangerTag = NO, isUserLocation = NO;
	
	// Differentiate between user location, MapTags and DangerTags
	if([annotation isKindOfClass:[MKUserLocation class]])
	{
		identifier		= @"userlocation";
		isUserLocation	= YES;
	}
	else if([annotation isKindOfClass:[MapTag class]])
	{
		identifier	= @"maptag";
	}
	else
	{
		identifier	= @"dangertag";
		isDangerTag	= YES;
	}
	
	MKPinAnnotationView *annotationView;
	
	if(!isUserLocation)
	{
		annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
		
		if(annotationView == nil)
			annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
		else
			annotationView.annotation = annotation;
		
		annotationView.enabled			= YES;
		annotationView.canShowCallout	= YES;
		
		if(isDangerTag)
		{
			annotationView.pinColor		= MKPinAnnotationColorRed;
			annotationView.animatesDrop	= NO;
		}
		else
		{
			annotationView.pinColor		= MKPinAnnotationColorGreen;
			annotationView.animatesDrop	= YES;
			
			// Add a button to allow users to tag this pin as a dangerous zone
			UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			[annotationView setRightCalloutAccessoryView:btn];
		}
	}
	else
	{
		// User location
		annotationView = (MKPinAnnotationView *) [mapView viewForAnnotation:annotation];
		annotationView.annotation = annotation;
		
		// Add a button to allow users to tag this pin as a dangerous zone
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[annotationView setRightCalloutAccessoryView:btn];
	}
	
	return annotationView;
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
		[mapView addAnnotation:[[MapTag alloc] initWithName:@"Mark as Dangerous" address:nil coordinate:[mapView convertPoint:[gestureRecognizer locationInView:mapView] toCoordinateFromView:mapView]]];
	}
}

// Action received when the user drags the map
-(void)panHappened:(UIGestureRecognizer *)gestureRecognizer
{
	// If the user pans the screen, stop tracking
	trackingUser = NO;
}

// Action received when the start/stop button is touched
- (IBAction)startButtonWasTouched:(id)sender
{
	startButton.selected = !startButton.selected;
	
	if(startButton.selected)
	{
		// Recording
		recording = YES;
		
		// Update button color to red
		[startButton setBackgroundColor: [UIColor colorWithRed:0.6f green:0.1f blue:0.1f alpha:1.0f]];
		
		// End the non-recording ticker
		[ticker invalidate];
		ticker = nil;
		
		// Start recording
		ticker = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(record:) userInfo:nil repeats:YES];
	}
	else
	{
		// Done recording
		recording = NO;
		
		// Update button color to green
		[startButton setBackgroundColor: [UIColor colorWithRed:0.1f green:0.6f blue:0.1f alpha:1.0f]];
		
		// Update numRows
		[self updateData];
		
		// Stop recording
		[ticker invalidate];
		ticker = nil;
		
		// Start non-recording ticker
		ticker = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(monitorWhileNotRecording:) userInfo:nil repeats:YES];
	}
}

// Action received when the tag button is touched
- (IBAction)tagButtonWasTouched:(id)sender
{
	// Center the map first
	[self centerMapOnLocation:locationManager.location];
	
	// Make a callout
	
}

// Action received when the upload button is touched
- (IBAction)uploadButtonWasTouched:(id)sender
{
	// Upload rows, if there are rows to upload
	if([self numRows] > 0)
		[self uploadRows];
}

// Enable gesture recognition
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{   
    return YES;
}

/*********************
 * Ticking functions *
 *********************/

// The tick when not recording data
- (void)monitorWhileNotRecording:(id)sender
{
	// Detect driving and alert the user to enable recording if not recording
	if(((int) locationManager.heading.trueHeading) != 0 && [self isValidLocation:locationManager.location])
	{
		float obj = (float) [locationManager.location distanceFromLocation:oldLocation] / (float) [locationManager.location.timestamp timeIntervalSinceDate:oldLocation.timestamp];
		
		if([speedValues count] < kDataPointsForAverage)
			[speedValues addObject:[NSNumber numberWithFloat:obj]];
		else
		{
			[speedValues insertObject:[NSNumber numberWithFloat:obj] atIndex:0];
			[speedValues removeLastObject];
		}
		
		// Average the speed
		[self calculateSpeed];
		
		oldLocation = locationManager.location;
	}
}

// The tick when recording data
- (void)record:(id)sender
{
	NSString *accel, *sound, *gps, *compass, *battery;
	
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
	if(((int) locationManager.heading.magneticHeading) != 0)
		compass = [NSString stringWithFormat:@"%f", locationManager.heading.magneticHeading];
	else
		compass = @"Unknown";
	
	// GPS
	if(((int) locationManager.heading.trueHeading) != 0 && [self isValidLocation:locationManager.location])
		gps = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f, Heading: %f, Speed: %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, locationManager.heading.trueHeading, locationManager.location.speed];
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
	[self updateData];
	
	// Speed
	if(((int) locationManager.heading.trueHeading) != 0 && [self isValidLocation:locationManager.location])
	{
		float obj = (float) [locationManager.location distanceFromLocation:oldLocation] / (float) [locationManager.location.timestamp timeIntervalSinceDate:oldLocation.timestamp];
		
		if([speedValues count] < kDataPointsForAverage)
			[speedValues addObject:[NSNumber numberWithFloat:obj]];
		else
		{
			[speedValues insertObject:[NSNumber numberWithFloat:obj] atIndex:0];
			[speedValues removeLastObject];
		}
		
		// Average the speed
		[self calculateSpeed];
		
		oldLocation = locationManager.location;
	}
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
	
	// Enable battery monitoring
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	
	// Connect to SQL
	[self sqlcon];
	
	// Set up label
	[speedometer setNumberOfLines:0];
	
	// Set button labels
	[startButton	setTitle:@"Record"		forState:UIControlStateNormal];
	[startButton	setTitle:@"Stop"		forState:UIControlStateSelected];
	[uploadButton	setTitle:@"Upload"		forState:UIControlStateNormal];
	
	// Set button colors
	[startButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.6f blue:0.1f alpha:1.0f]];
	[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.1f blue:0.6f alpha:1.0f]];
	
	[self updateData];
	
	// Set device ID
	device = @"Unknown";
	
	// Set other variables
	recording		= NO;
	trackingUser	= YES;
	hasAlertedUser	= NO;
	speed			= 0.0;
	
	// Set up speed monitor
	speedValues = [[NSMutableArray alloc] init];
	
	// Set up GPS
	locationManager					= [[CLLocationManager alloc] init];
	locationManager.delegate		= self;
	locationManager.distanceFilter	= kCLDistanceFilterNone;
	locationManager.desiredAccuracy	= kCLLocationAccuracyHundredMeters;
	[locationManager startUpdatingLocation];
	[locationManager startUpdatingHeading];
	
	oldLocation = nil;
	
	// Set up the map view
	UILongPressGestureRecognizer	*longPress	= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouchHappened:)];
	UIPanGestureRecognizer			*pan		= [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHappened:)];
	
	[pan setDelegate:self];
	
	[mapView addGestureRecognizer:longPress];
	[mapView addGestureRecognizer:pan];
	[mapView setDelegate:self];
	
	[self centerMapOnLocation:locationManager.location];
	
	// Set up accelorometer
	accelerometer					= [UIAccelerometer sharedAccelerometer];
	accelerometer.delegate			= (id) self;
	accelerometer.updateInterval	= 0.1;
	accelX = accelY = accelZ		= 0.0;
	accelValuesCollected			= 0;
	
	// Set up microphone
	NSURL			*url		= [NSURL fileURLWithPath:@"/dev/null"];
	NSDictionary	*settings	= [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:44100.0],					AVSampleRateKey,
		[NSNumber numberWithInt:kAudioFormatAppleLossless],	AVFormatIDKey,
		[NSNumber numberWithInt:1],							AVNumberOfChannelsKey,
		[NSNumber numberWithInt:AVAudioQualityMax],			AVEncoderAudioQualityKey,
	nil];
	
	NSError *error;
	
	// Don't use the mic if the user is already playing music or listening to something
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error];
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	
	UInt32 otherAudio;
	UInt32 size = sizeof(otherAudio);
	AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &otherAudio);
	
	recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
	
	if(!otherAudio)
	{
		if(recorder)
		{
			[recorder prepareToRecord];
			recorder.meteringEnabled = YES;
			[recorder record];
		}
	}
	
	// Start monitoring ticker
	ticker = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(monitorWhileNotRecording:) userInfo:nil repeats:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self.startButton			= nil;
	self.uploadButton			= nil;
	self.tagButton				= nil;
	self.speedometer			= nil;
	self.dbpath					= nil;
	self.device					= nil;
	self.ticker					= nil;
	self.locationManager		= nil;
	self.oldLocation			= nil;
	self.lastCenteredLocation	= nil;
	self.accelerometer			= nil;
	self.recorder				= nil;
	self.mapView				= nil;
	self.speedValues			= nil;
	self.tagMenu				= nil;
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
