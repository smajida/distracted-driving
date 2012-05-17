//
//  ViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize startButton, recordingLabel, dataLabel, dbpath, ticker, dataExists;


- (void)setDataExists:(BOOL)value
{
	dataExists = value;
	
	if(dataExists)
		[dataLabel setText:@"You have recorded data to send."];
	else
		[dataLabel setText:@"You do not have recorded data to send."];
}

// Connect to the SQL database
- (BOOL)sqlcon
{
	NSString		*database;
	NSArray			*paths;
	
	paths		= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	database	= [[NSString alloc] initWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"distracted-driving.db"]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:database] == NO)
	{
		NSString *dbpathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"distracted-driving.db"];
		[[NSFileManager defaultManager] copyItemAtPath:dbpathFromApp toPath:database error:nil];
		
		NSLog(@"that way");
		
		dbpath = [database UTF8String];
		
		if(sqlite3_open(dbpath, &db) == SQLITE_OK)
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
		dbpath = [database UTF8String];
		
		if(sqlite3_open(dbpath, &db) != SQLITE_OK)
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
	
	if(sqlite3_open(dbpath, &db) == SQLITE_OK)
	{
		NSString *nsquery = [NSString stringWithFormat:@"INSERT INTO collected_data (date, accelorometer, sound, gps, compass, battery) VALUES (datetime('now'), '%@', '%@', '%@', '%@', '%@')", accelorometer, sound, gps, compass, battery];
		
		const char *cquery = [nsquery UTF8String];
		
		sqlite3_prepare_v2(db, cquery, -1, &query, NULL);
		
		if(sqlite3_step(query) != SQLITE_DONE)
		{
			NSLog(@"Query failed (%s)!", sqlite3_errmsg(db));
			sqlite3_finalize(query);
			sqlite3_close(db);
			return NO;
		}
		
		sqlite3_finalize(query);
		sqlite3_close(db);
	}
	else
		NSLog(@"Query failed (%s)!", sqlite3_errmsg(db));
	
	return YES;
}

- (void)record:(id)sender
{
	// For each tick, add a row to SQL	
	NSString *accelorometer		= @"Unknown";
	NSString *sound				= @"Unknown";
	NSString *gps				= @"Unknown";
	NSString *compass			= @"Unknown";
	NSString *battery			= [NSString stringWithFormat:@"%f", [[UIDevice currentDevice] batteryLevel]];
	
	[self insertRowWithAccelorometer:accelorometer andSound:sound andGps:gps andCompass:compass andBattery:battery];
}

- (IBAction)toggleButton:(id)sender
{
	startButton.selected = !startButton.selected;
	
	if(startButton.selected)
	{
		// Recording
		
		// Since we're recording, data will need to be sent
		[self setDataExists:YES];
		
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
	
	// Set button labels
	[startButton setTitle:@"Start Recording"	forState:UIControlStateNormal];
	[startButton setTitle:@"Stop Recording"		forState:UIControlStateSelected];
	
	// Set initial label text
	[recordingLabel	setText:@"You are not recording."];
	[dataLabel		setText:@"You do not have recorded data to send."];
	
	// Set initial booleans
	[self setDataExists:NO];
	
	// Connect to SQL
	[self sqlcon];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self.startButton	= nil;
	self.recordingLabel	= nil;
	self.dataLabel		= nil;
	self.ticker			= nil;
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
