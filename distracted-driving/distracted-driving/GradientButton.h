//
//  GradientButton.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface GradientButton : UIButton
{
	CAGradientLayer *shineLayer;
	CALayer			*highlightLayer;
}

@end
