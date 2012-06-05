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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil]; 
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
	// Register for Push Notifications
	NSLog(@":: Registering device for push notifications.");
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	// Prevent iPhone sleeping
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	// NSString *str = [NSString stringWithFormat:@"Device Token=%@",deviceToken];
	// NSLog(str);
	
	NSCharacterSet *chars	= [NSCharacterSet characterSetWithCharactersInString:@"< >"];
	NSString *str			= [[deviceToken description] stringByTrimmingCharactersInSet:chars];
	device					= [str stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	[self.viewController setDevice:device];
	
	NSLog(@":: Device ID acquired.");
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
	// NSString *str = [NSString stringWithFormat: @"Error: %@", err];
	// NSLog(str);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	for (id key in userInfo)
	{
		NSLog(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
		NSString *message = nil;
		
		NSDictionary *aps = [NSDictionary dictionaryWithDictionary:(NSDictionary *) [userInfo objectForKey:key] ];
		message = [aps objectForKey:@"alert"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
		
		[alert show];
	}
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
	
	// Warn the user that something is happening
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
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
