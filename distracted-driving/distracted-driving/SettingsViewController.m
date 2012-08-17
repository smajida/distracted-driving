//
//  SettingsViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 7/16/12.
//
//

#import "SettingsViewController.h"

@implementation SettingsViewController

@synthesize delegate, energySwitch, reminderSwitch, automaticSwitch, tagSwitch;

- (IBAction)saveButtonWasTouched:(id)sender
{
	// Save settings
	[[NSUserDefaults standardUserDefaults] setBool:energySwitch.on forKey:@"limitBatteryConsumption"];
	[[NSUserDefaults standardUserDefaults] setBool:!reminderSwitch.on forKey:@"doNotRemindUserToRecord"];
	[[NSUserDefaults standardUserDefaults] setBool:!tagSwitch.on forKey:@"doNotRemindUserToTag"];
	[[NSUserDefaults standardUserDefaults] setBool:automaticSwitch.on forKey:@"automaticallyStartAndStop"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if(delegate)
	{
		[delegate setLimitBatteryConsumption:energySwitch.on];
		[delegate setRemindUserToRecord:reminderSwitch.on];
		[delegate setRemindUserToTag:tagSwitch.on];
		[delegate setAutomaticallyStartAndStop:automaticSwitch.on];
		
		[delegate settingsMenuDidClose];
	}
	
	[self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
		
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if(delegate)
	{
		[energySwitch setOn:[delegate limitBatteryConsumption]];
		[reminderSwitch setOn:[delegate remindUserToRecord]];
		[tagSwitch setOn:[delegate remindUserToTag]];
		
		if([CLLocationManager regionMonitoringAvailable] && [CLLocationManager regionMonitoringEnabled])
			[automaticSwitch setOn:[delegate automaticallyStartAndStop]];
		else
		{
			[automaticSwitch setOn:NO];
			[automaticSwitch setEnabled:NO];
		}
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	energySwitch	= nil;
	reminderSwitch	= nil;
	automaticSwitch	= nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
