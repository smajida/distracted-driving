//
//  SettingsViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 7/16/12.
//
//

#import <UIKit/UIKit.h>

@protocol SettingsDelegate <NSObject>
@required

@property (nonatomic, assign) BOOL limitBatteryConsumption;

- (void)settingsMenuDidClose;

@end


@interface SettingsViewController : UIViewController
{
	id <SettingsDelegate>	delegate;
	UISwitch				*energySwitch;
}

@property (nonatomic, retain) id <SettingsDelegate>	delegate;
@property (nonatomic, retain) IBOutlet UISwitch		*energySwitch;

- (IBAction)saveButtonWasTouched:(id)sender;

@end