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
int const kMinimumDrivingSpeed	= 5;
int const kDataPointsForAverage	= 3;

// Pointers (i.e. UIButton *)
@synthesize startButton, uploadButton, centerButton, dbpath, device, ticker, locationManager, oldLocation, lastCenteredLocation, accelerometer, recorder, mapView, speedValues;

// Low-level types (i.e. int)
@synthesize accelValuesCollected, accelX, accelY, accelZ, speed, recording, trackingUser;

// Connect to the SQL database
- (BOOL)sqlcon
{
	NSLog(@":: Initializing SQL connection.");
	
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
		NSLog(@":: Creating database file.");
		
		// Create the file
		NSString *dbpathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"distracted-driving_v1.1.db"];
		
		// Copy it to the correct location
		[[NSFileManager defaultManager] copyItemAtPath:dbpathFromApp toPath:dbpath error:nil];
		
		// Get the UTF8String of the dbpath to use with sqlite3
		database = [dbpath UTF8String];
		
		// Create the table once the connection is made
		if(sqlite3_open(database, &db) == SQLITE_OK)
		{
			NSLog(@":: Creating table in database.");
			
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
		
		NSLog(@":: Database file already exists; connecting to database.");
		
		if(sqlite3_open(database, &db) != SQLITE_OK)
		{
			NSLog(@":: Database connection failed!");
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_close(db);
	}
	
	NSLog(@":: SQL connection succeeded.");
	
	return YES;
}

// Insert a row to local SQL
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery
{
	NSLog(@":: Inserting a row into the local SQL database.");
	
	sqlite3_stmt	*query;
	
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
	
	NSLog(@":: SQL insertion succeeeded.");
	
	return YES;
}

- (int)numRows
{
	int num = 0;
	
	sqlite3_stmt	*query;
	
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

- (IBAction)uploadRows:(id)sender
{
	NSLog(@":: Uploading local SQL rows to the server.");
	
	NSString		*_id;
	NSString		*_device;
	NSString		*date;
	NSString		*accelorometer;
	NSString		*sound;
	NSString		*gps;
	NSString		*compass;
	NSString		*battery;
	
	NSMutableURLRequest	*request;
	NSURLConnection		*connection;
	
	sqlite3_stmt	*query;
	
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
				NSLog(@":: SQL row upload successful.");
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
	
	[self emptyTable:sender];
}

- (void)connection: (NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// received remote data
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// finished loading remote connection
}

- (IBAction)emptyTable:(id)sender
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

- (BOOL)isValidLocation:(CLLocation *)newLocation
{
	if(!newLocation)
		return NO;
	
	// Make sure the new location is valid and accurate within 100 meters
	if(newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > 100)
		return NO;
	
	// If this is the first time we've checked for coordinates, set this as the old location and prevent it from being used
	if(oldLocation == nil)
	{
		oldLocation = newLocation;
		return NO;
	}
	
	// Make sure the new location is really new
	NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
	if(timeInterval < 0)
		return NO;
	
	/*
	// Make sure the speed is positive, not negative (i.e. invalid)
	speed += (float) [newLocation distanceFromLocation:oldLocation] / (float) [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
	speedValuesCollected++;
	
	// Average the speed
	if(speedValuesCollected >= kDataPointsForAverage)
	{
		speed = speed / kDataPointsForAverage;
		[spedometer setText:[NSString stringWithFormat:@"%d mph", (int) [self mphFromMps:speed]]];
		
		// Negative speed is invalid; speed over 200 mph is probably wrong too
		if(speed < 0 || [self mphFromMps:speed] > 200)
			return NO;
		
		speed = 0.0;
		speedValuesCollected = 0;
	}
	*/
	
	return YES;
}

- (float)mphFromMps:(float)mps
{
	// Convert meters per second into miles per hour
	return mps * 2.23693629;
}

- (void)centerMapOnLocation:(CLLocation *)location andZoom:(BOOL)zoom
{
	MKCoordinateRegion adjustedRegion;
	
	if(!zoom)
	{
		NSLog(@":: Centering mapView on user location");
		adjustedRegion = mapView.region;
		adjustedRegion.center = location.coordinate;
	}
	else
	{
		NSLog(@":: Centering mapView on user location and zooming in");
		adjustedRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000);
	}
	
	trackingUser			= YES;
	lastCenteredLocation	= location;
	adjustedRegion			= [mapView regionThatFits:adjustedRegion];
	
	[mapView setRegion:adjustedRegion animated:YES];
}

- (void)centerMapOnLocation:(CLLocation *)location
{
	[self centerMapOnLocation:location andZoom:NO];
}

- (IBAction)centerMap:(id)sender
{
	[self centerMapOnLocation:locationManager.location];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)_oldLocation
{
	// Check distance not from the last location but from the last centered location	
	if([self isValidLocation:newLocation])
	{
		if(trackingUser)
			[self centerMapOnLocation:newLocation];
		else if([newLocation distanceFromLocation:lastCenteredLocation] > 10)
			trackingUser = YES;
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@":: Location error: %@", error);
}

// Handle "Mark as Dangerous" button taps
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	NSLog(@":: Requesting that a location be marked as dangerous");
	
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

- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	NSString	*identifier;
	BOOL		isDangerTag;
	
	// Don't change the user location
	if([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	
	// Differentiate between MapTags and DangerTags
	if([annotation isKindOfClass:[MapTag class]])
	{
		identifier	= @"maptag";
		isDangerTag	= NO;
	}
	else
	{
		identifier	= @"dangertag";
		isDangerTag	= YES;
	}
	
	MKPinAnnotationView *annotationView	= (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
	
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
	
	return annotationView;
}

// Action received when the user taps and holds on the map
- (void)longTouch:(UIGestureRecognizer *)gestureRecognizer
{
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		[mapView addAnnotation:[[MapTag alloc] initWithName:@"Mark as Dangerous" address:nil coordinate:[mapView convertPoint:[gestureRecognizer locationInView:mapView] toCoordinateFromView:mapView]]];
	}
}

// Action received when the user drags the map
-(void)panHandler:(UIGestureRecognizer *)gestureRecognizer
{
	// If the user pans the screen, stop tracking
	trackingUser = NO;
}

- (void)updateData
{
	int rows = [self numRows];
	
	if(rows > 0)
		[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.1f blue:0.6f alpha:1.0f]];
	else
		[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f]];
}

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
		if([speedValues count] == kDataPointsForAverage)
		{
			speed = 0.0;
			for(int i = 0; i < [speedValues count]; i++)
				speed += [[speedValues objectAtIndex:i] floatValue];
			speed = speed / [speedValues count];
			
			// If we're going fast enough to be driving, alert the user
			if([self mphFromMps:speed] > kMinimumDrivingSpeed)
			{
				NSString	*str	= [NSString stringWithFormat:@"It appears that you are driving (about %d mph).  Please start recording data now.", (int) [self mphFromMps:speed]];
				UIAlertView	*alert	= [[UIAlertView alloc] initWithTitle:@"Enable Recording" message:str delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
				[alert show];
			}
		}
		
		oldLocation = locationManager.location;
	}
}

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
	if(recorder)
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
}

- (IBAction)toggleButton:(id)sender
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{   
    return YES;
}

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
	
	// Set button labels
	[startButton setTitle:@"Record"	forState:UIControlStateNormal];
	[startButton setTitle:@"Stop"	forState:UIControlStateSelected];
	
	[uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
	
	// Set button colors
	[startButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.6f blue:0.1f alpha:1.0f]];
	[uploadButton	setBackgroundColor: [UIColor colorWithRed:0.1f green:0.1f blue:0.6f alpha:1.0f]];
	
	[self updateData];
	
	// Set device ID
	device = @"Unknown";
	
	// Set other variables
	recording		= NO;
	trackingUser	= YES;
	
	// Set up speed monitor
	speedValues = [[NSMutableArray alloc] init];
	
	// Set up GPS
	locationManager					= [[CLLocationManager alloc] init];
	locationManager.delegate		= self;
	locationManager.distanceFilter	= kCLDistanceFilterNone;
	locationManager.desiredAccuracy	= kCLLocationAccuracyNearestTenMeters;
	[locationManager startUpdatingLocation];
	[locationManager startUpdatingHeading];
	
	oldLocation = nil;
	
	// Set up the map view
	UILongPressGestureRecognizer	*longPress	= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouch:)];
	UIPanGestureRecognizer			*pan		= [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
	
	[pan setDelegate:self];
	
	[mapView addGestureRecognizer:longPress];
	[mapView addGestureRecognizer:pan];
	
	[mapView setDelegate:self];
	[self centerMapOnLocation:locationManager.location andZoom:YES];
	
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
	if([[MPMusicPlayerController iPodMusicPlayer] playbackState] != MPMusicPlaybackStatePlaying)
	{
		recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
		
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

- (void)accelerometer:(UIAccelerometer *)a didAccelerate:(UIAcceleration *)acceleration
{
	accelX += acceleration.x;
	accelY += acceleration.y;
	accelZ += acceleration.z;
	accelValuesCollected++;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self.startButton			= nil;
	self.uploadButton			= nil;
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
