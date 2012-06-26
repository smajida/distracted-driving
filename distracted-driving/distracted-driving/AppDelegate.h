//
//  AppDelegate.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/14/12.
//  Copyright (c) 2012 Luke Godfrey
//

#import <UIKit/UIKit.h>
#import "TestFlight.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
	NSString *device;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (nonatomic, retain) NSString *device;

- (void)fooWithFoo:(NSString *)foo;

@end
