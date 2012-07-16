//
//  SettingsViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 7/16/12.
//
//

#import "SettingsViewController.h"

@implementation SettingsViewController

@synthesize delegate, energySwitch;

- (IBAction)saveButtonWasTouched:(id)sender
{
	// Save settings
	[[NSUserDefaults standardUserDefaults] setBool:energySwitch.on forKey:@"limitBatteryConsumption"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if(delegate)
		[delegate setLimitBatteryConsumption:energySwitch.on];
	
	// Close settings panel
	if(delegate)
		[delegate settingsMenuDidClose];
	
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
		[energySwitch setOn:[delegate limitBatteryConsumption]];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	energySwitch	= nil;
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
