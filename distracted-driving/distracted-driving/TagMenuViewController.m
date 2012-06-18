//
//  TagMenuViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import "TagMenuViewController.h"

@implementation TagMenuViewController

@synthesize delegate, annotationView, titleLabel, roadSwitch, trafficSwitch, titleText;

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
	if(delegate && annotationView)
		[delegate tagViewAsDangerous:annotationView withTraffic:trafficSwitch.on andRoadConditions:roadSwitch.on];
	else if(delegate && !annotationView)
		[delegate tagViewAsDangerous:nil withTraffic:trafficSwitch.on andRoadConditions:roadSwitch.on];
	
	[self close:sender];
}

- (IBAction)close:(id)sender
{
	[[self view] removeFromSuperview];
	
	if(delegate)
		[delegate tagMenuDidClose];
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
