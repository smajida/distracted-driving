//
//  TagMenuViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import "TagMenuViewController.h"

@implementation TagMenuViewController

@synthesize delegate, annotationView, titleLabel, roadSwitch, trafficSwitch, tagButton, cancelButton, uploadButton, titleText, isUploadType;

- (id)initWithTitle:(NSString *)text withUpload:(BOOL)upload
{
	self = [super initWithNibName:@"TagMenuView" bundle:nil];
	
	if(self)
	{
		titleText		= text;
		isUploadType	= upload;
	}
	
	return self;
}

- (id)initWithTitle:(NSString *)text
{
	return [self initWithTitle:text withUpload:NO];
}

- (id)init
{
	return [self initWithTitle:@"Tag as Dangerous"];
}

- (IBAction)closeAndUpload:(id)sender
{
	if(delegate)
	{
		[delegate uploadRows];
		return [self closeAndTag:sender];
	}
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
	
	if(isUploadType)
	{
		tagButton.hidden	= YES;
		cancelButton.hidden	= YES;
	}
	else
		uploadButton.hidden	= YES;
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
