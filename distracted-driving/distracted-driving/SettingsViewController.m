//
//  SettingsViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 7/16/12.
//
//

#import "SettingsViewController.h"

@implementation SettingsViewController

@synthesize delegate, energySwitch, reminderSwitch;

- (IBAction)saveButtonWasTouched:(id)sender
{
	// Save settings
	[[NSUserDefaults standardUserDefaults] setBool:energySwitch.on forKey:@"limitBatteryConsumption"];
	[[NSUserDefaults standardUserDefaults] setBool:!reminderSwitch.on forKey:@"doNotRemindUserToRecord"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if(delegate)
	{
		[delegate setLimitBatteryConsumption:energySwitch.on];
		[delegate setRemindUserToRecord:reminderSwitch.on];
		
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
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	energySwitch	= nil;
	reminderSwitch	= nil;
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
