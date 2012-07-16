//
//  AppDelegate.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize device;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
	[TestFlight takeOff:@"6ab119d7ecfdf82ed74673d4b42400ec_MTAxNDI3MjAxMi0wNi0yMiAyMjowMDo1NS4wMjczNjI"];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil]; 
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
	// Register for Push Notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	// Prevent iPhone sleeping
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	// Check if the app has been woken up from the background
	if([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey])
		[TestFlight passCheckpoint:@"Launched from Geofence Boundary"];
	
    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSCharacterSet *chars	= [NSCharacterSet characterSetWithCharactersInString:@"< >"];
	NSString *str			= [[deviceToken description] stringByTrimmingCharactersInSet:chars];
	device					= [str stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	[self.viewController setDevice:device];
	
	NSLog(@":: Device ID acquired for push notifications.");
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
	// NSString *str = [NSString stringWithFormat: @"Error: %@", err];
	// NSLog(str);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	/*
	for (id key in userInfo)
	{
		NSLog(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
		NSString *message = nil;
		
		NSDictionary *aps = [NSDictionary dictionaryWithDictionary:(NSDictionary *) [userInfo objectForKey:key] ];
		message = [aps objectForKey:@"alert"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
		
		[alert show];
	}
	*/
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
	
	/*
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mpss.csce.uark.edu/~lgodfrey/push.php"]];
	[request setHTTPMethod:@"POST"];
	
	NSString *postString = [NSString stringWithFormat:@"password=driving123~&device=%@", device];
	[request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if(connection)
	{
		NSLog(@":: Requested a push notification from the server.");
	}
	else
	{
		NSLog(@":: Connection to remote server failed.");
	}
	*/
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
	 
	 // Only monitor significant changes – unless recording
	 if(!self.viewController.recording)
	 {
		 // Flag that lets us know we're monitoring the region
		 self.viewController.isUsingOnlySignificantChanges = YES;
		 
		 // Stop using full location services
		 [self.viewController disableLocationServices];
		 
		 if([CLLocationManager regionMonitoringAvailable] && [CLLocationManager regionMonitoringEnabled])
		 {
			 // Create a boundary -- a circle around the current location
			 self.viewController.currentBoundary = [[CLRegion alloc] initCircularRegionWithCenter:self.viewController.locationManager.location.coordinate radius:kSignificantLocationChange identifier:@"Current Location Boundary"];
			 
			 // Monitor the boundary
			 [self.viewController.locationManager startMonitoringForRegion:self.viewController.currentBoundary];
		 }
		 else
		 {
			 // Use significant change, because the device doesn't support Geofencing
			 [self.viewController.locationManager startMonitoringSignificantLocationChanges];
			 [TestFlight passCheckpoint:@"Used significant change instead of geofencing."];
		 }
	 }
	 
	 // Disable other services
	 [self.viewController disableAccelerometer];
	 [self.viewController disableMicrophone];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
	
	// When the app is open, always use full location services
	self.viewController.isUsingOnlySignificantChanges = NO;
	
	// Stop monitoring the region
	if(self.viewController.currentBoundary)
	{
		[self.viewController.locationManager stopMonitoringForRegion:self.viewController.currentBoundary];
		self.viewController.currentBoundary = nil;
	}
	
	// Stop significant changes, if we were using them
	[self.viewController.locationManager stopMonitoringSignificantLocationChanges];
	
	// Start full location services again
	[self.viewController enableLocationServices];
	
	// Enable other serices
	[self.viewController enableAccelerometer];
	[self.viewController enableMicrophone];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end
