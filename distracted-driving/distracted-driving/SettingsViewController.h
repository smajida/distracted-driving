//
//  SettingsViewController.h
//  distracted-driving
//
//  Created by Luke Godfrey on 7/16/12.
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol SettingsDelegate <NSObject>
@required

@property (nonatomic, assign) BOOL limitBatteryConsumption, remindUserToRecord, automaticallyStartAndStop, remindUserToTag;

- (void)settingsMenuDidClose;

@end


@interface SettingsViewController : UIViewController
{
	id <SettingsDelegate>	delegate;
	UISwitch				*energySwitch, *reminderSwitch, *automaticSwitch, *tagSwitch;
}

@property (nonatomic, retain) id <SettingsDelegate>	delegate;
@property (nonatomic, retain) IBOutlet UISwitch		*energySwitch, *reminderSwitch, *automaticSwitch, *tagSwitch;

- (IBAction)saveButtonWasTouched:(id)sender;

@end