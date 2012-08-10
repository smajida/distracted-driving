//
//  TagMenuViewController.m
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import "TagMenuViewController.h"

@implementation TagMenuViewController

@synthesize delegate, annotationView, titleLabel, roadSwitch, trafficSwitch, signalLabel, signalSwitch, tagButton, cancelButton, uploadButton, titleText, isUploadType, image, cameraButton;

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
		[delegate tagViewAsDangerous:annotationView withTraffic:trafficSwitch.on andRoadConditions:roadSwitch.on andSignal:signalSwitch.on andImage:image];
	else if(delegate && !annotationView)
		[delegate tagViewAsDangerous:nil withTraffic:trafficSwitch.on andRoadConditions:roadSwitch.on andSignal:signalSwitch.on andImage:image];
	
	[self close:sender];
}

- (IBAction)close:(id)sender
{
	[[self view] removeFromSuperview];
	
	if(delegate)
		[delegate tagMenuDidClose];
}

- (IBAction)cameraButtonWasTouched:(id)sender
{
	UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self presentModalViewController:imagePicker animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	[cameraButton setEnabled:NO];
	[cameraButton setBackgroundColor:[UIColor grayColor]];
	[cameraButton setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
	[cameraButton setTitle:@"Saved" forState:UIControlStateDisabled];
	
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[titleLabel setText:titleText];
	
	image = nil;
	
	if(isUploadType)
	{
		tagButton.hidden	= YES;
		cancelButton.hidden	= YES;
		signalSwitch.hidden	= YES;
		signalLabel.hidden	= YES;
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
	self.signalLabel	= nil;
	self.signalSwitch	= nil;
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
