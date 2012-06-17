//
//  TagMenuViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 6/16/12.
//
//

#import <UIKit/UIKit.h>

@interface TagMenuViewController : UIViewController
{
	UILabel		*titleLabel;
	UISwitch	*roadSwitch;
	UISwitch	*trafficSwitch;
	NSString	*titleText;
}

@property (nonatomic, retain) IBOutlet UILabel	*titleLabel;
@property (nonatomic, retain) IBOutlet UISwitch	*roadSwitch, *trafficSwitch;
@property (nonatomic, retain) NSString			*titleText;

- (id)initWithTitle:(NSString *)text;
- (IBAction)closeAndTag:(id)sender;
- (IBAction)close:(id)sender;

@end
