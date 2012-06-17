//
//  TagMenuViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import "TagMenuViewController.h"

@implementation TagMenuViewController

@synthesize titleLabel, roadSwitch, trafficSwitch, titleText;

- (id)initWithTitle:(NSString *)text
{
	self = [super initWithNibName:@"TagMenuView" bundle:nil];
	
	if(self)
	{
		titleText = text;
	}
	
	return self;
}

- (id)init
{
	return [self initWithTitle:@"Tag as Dangerous"];
}

- (IBAction)closeAndTag:(id)sender
{
	// Tag here
	NSLog(@"Should tag as dangerous, with road (%d) and traffic (%d).", roadSwitch.on, trafficSwitch.on);
	
	[self close:sender];
}

- (IBAction)close:(id)sender
{
	[[self view] removeFromSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[titleLabel setText:titleText];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.titleLabel		= nil;
	self.roadSwitch		= nil;
	self.trafficSwitch	= nil;
	self.titleText		= nil;
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
