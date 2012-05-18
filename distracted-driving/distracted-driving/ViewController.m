//
//  ViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize startButton, recordingLabel, dataLabel, dbpath, ticker, locationManager, accelerometer, recorder, accelValuesCollected, accelX, accelY, accelZ;

// Connect to the SQL database
- (BOOL)sqlcon
{
	NSArray			*paths;
	const char		*database;
	
	paths		= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dbpath		= [[NSString alloc] initWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"distracted-driving.db"]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:dbpath] == NO)
	{
		NSString *dbpathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"distracted-driving.db"];
		[[NSFileManager defaultManager] copyItemAtPath:dbpathFromApp toPath:dbpath error:nil];
		
		NSLog(@"Database file will be created.");
		
		database = [dbpath UTF8String];
		
		if(sqlite3_open(database, &db) == SQLITE_OK)
		{
			char *err;
			const char *sql = "CREATE TABLE IF NOT EXISTS collected_data (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATETIME, accelorometer TEXT, sound TEXT, gps TEXT, compass TEXT, battery TEXT)";
			
			if(sqlite3_exec(db, sql, NULL, NULL, &err) != SQLITE_OK)
			{
				NSLog(@"Table creation failed!");
				sqlite3_close(db);
				return NO;
			}
			
			sqlite3_close(db);
		}
		else
		{
			NSLog(@"Database connection failed!");
			return NO;
		}
	}
	else
	{
		database = [dbpath UTF8String];
		
		NSLog(@"Database file was found.");
		
		if(sqlite3_open(database, &db) != SQLITE_OK)
		{
			NSLog(@"Database connection failed!");
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_close(db);
	}
	
	return YES;
}

// Insert a row to SQL
- (BOOL)insertRowWithAccelorometer:(NSString *)accelorometer andSound:(NSString *)sound andGps:(NSString *)gps andCompass:(NSString *)compass andBattery:(NSString *)battery
{
	sqlite3_stmt	*query;
	
	if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
	{
		NSString *nsquery = [NSString stringWithFormat:@"INSERT INTO collected_data (date, accelorometer, sound, gps, compass, battery) VALUES (datetime('now'), '%@', '%@', '%@', '%@', '%@')", accelorometer, sound, gps, compass, battery];
		
		// NSLog(@"Executing query.");
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		if(sqlite3_step(query) != SQLITE_DONE)
		{
			NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
			sqlite3_finalize(query);
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
	
	return YES;
}

- (int)numRows
{
	int num = 0;
	
	sqlite3_stmt	*query;
	
	// NSLog(@"Counting rows.");
	
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
	NSString		*_id;
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
			date			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 1)];
			accelorometer	= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 2)];
			sound			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 3)];
			gps				= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 4)];
			compass			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 5)];
			battery			= [NSString stringWithUTF8String:(const char *) sqlite3_column_text(query, 6)];
			
			request			= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/add_data.php"]];
			
			[request setHTTPMethod:@"POST"];
			
			NSString *postString = [NSString stringWithFormat:@"date=%@&accelorometer=%@&sound=%@&gps=%@&compass=%@&battery=%@", date, accelorometer, sound, gps, compass, battery];
			
			[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
			
			[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
			
			connection		= [[NSURLConnection alloc] initWithRequest:request delegate:self];
			
			if(connection)
			{
				// NSLog(@"Connection successful.");
			}
			else
			{
				NSLog(@"Connection failed.");
			}
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
	
	[self emptyTable:sender];
}

- (void)connection: (NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// NSLog(@"Received data %@", data);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Finished!");
}

- (IBAction)emptyTable:(id)sender
{
	sqlite3_stmt *query;
	
	if(sqlite3_open([dbpath UTF8String], &db) == SQLITE_OK)
	{
		NSString *nsquery = @"DELETE FROM collected_data";
		
		// NSLog(@"Executing query.");
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		if(sqlite3_step(query) != SQLITE_DONE)
		{
			NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
			sqlite3_finalize(query);
			sqlite3_close(db);
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@"Query failed; %s!", sqlite3_errmsg(db));
	
	[self updateDataLabel];
}

- (void)updateDataLabel
{
	int rows = [self numRows];
	
	if(rows > 0)
		[dataLabel setText:[NSString stringWithFormat:@"You have %i %@ of data to send.", rows, (rows == 1 ? @"row" : @"rows")]];
	else
		[dataLabel setText:@"You do not have any recorded data."];
}

- (void)record:(id)sender
{
	NSLog(@"Tick.");
	
	NSString *accel, *sound, *gps, *compass, *battery;
	
	// Accelorometer
	accel = [NSString stringWithFormat:@"x: %f, y: %f, z: %f", accelX / accelValuesCollected, accelY / accelValuesCollected, accelZ / accelValuesCollected];
	
	accelX = accelY = accelZ = 0.0;
	accelValuesCollected = 0;
	
	// Sound
	[recorder updateMeters];
	sound = [NSString stringWithFormat:@"%f", [recorder averagePowerForChannel:0]];
	
	// Compass
	compass = [NSString stringWithFormat:@"%f", locationManager.heading.magneticHeading];
	
	// GPS
	gps = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f, Heading: %f, Speed: %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, locationManager.heading.trueHeading, locationManager.location.speed];
	
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
	
	battery = [NSString stringWithFormat:@"%f; %@", [[UIDevice currentDevice] batteryLevel], state];
	
	[self insertRowWithAccelorometer:accel andSound:sound andGps:gps andCompass:compass andBattery:battery];
	[self updateDataLabel];
}

- (IBAction)toggleButton:(id)sender
{
	startButton.selected = !startButton.selected;
	
	if(startButton.selected)
	{
		// Recording
		
		// Since we started recording, tell the user we're recording
		[recordingLabel setText:@"You are recording."];
		
		// Start recording
		ticker = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(record:) userInfo:nil repeats:YES];
	}
	else
	{
		// Done recording
		
		// Tell the user we've stopped recording
		[recordingLabel setText:@"You are not recording."];
		
		// Update numRows
		[self updateDataLabel];
		
		// Stop recording
		[ticker invalidate];
		ticker = nil;
	}
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
	[startButton setTitle:@"Start Recording"	forState:UIControlStateNormal];
	[startButton setTitle:@"Stop Recording"		forState:UIControlStateSelected];
	
	// Set initial label text
	[recordingLabel setText:@"You are not recording."];
	[self updateDataLabel];
	
	// Set up GPS
	locationManager					= [[CLLocationManager alloc] init];
	locationManager.distanceFilter	= kCLDistanceFilterNone;
	locationManager.desiredAccuracy	= kCLLocationAccuracyHundredMeters;
	[locationManager startUpdatingLocation];
	[locationManager startUpdatingHeading];
	
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
	
	recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
	
	if(recorder)
	{
		[recorder prepareToRecord];
		recorder.meteringEnabled = YES;
		[recorder record];
	}
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
    
	self.startButton		= nil;
	self.recordingLabel		= nil;
	self.dataLabel			= nil;
	self.dbpath				= nil;
	self.ticker				= nil;
	self.locationManager	= nil;
	self.accelerometer		= nil;
	self.recorder			= nil;
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
