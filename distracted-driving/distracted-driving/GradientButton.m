//
//  GradientButton.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GradientButton.h"

@implementation GradientButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self initLayers];
	
    return self;
}

- (void)initBorder
{
	CALayer *layer		= self.layer;
	layer.cornerRadius	= 8.0f;
	layer.masksToBounds	= YES;
	layer.borderWidth	= 1.0f;
	layer.borderColor	= [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
}

- (void)addShineLayer
{
	shineLayer			= [CAGradientLayer layer];
	shineLayer.frame	= self.layer.bounds;
	shineLayer.colors	=	[NSArray arrayWithObjects:
							(id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
							(id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
							(id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
							(id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
							(id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
							nil];
	
	shineLayer.locations	=	[NSArray arrayWithObjects:
								[NSNumber numberWithFloat:0.0f],
								[NSNumber numberWithFloat:0.5f],
								[NSNumber numberWithFloat:0.5f],
								[NSNumber numberWithFloat:0.8f],
								[NSNumber numberWithFloat:1.0f],
								nil];
	
	[self.layer addSublayer:shineLayer];
}

- (void)addHighlightLayer
{
	highlightLayer = [CALayer layer];
	highlightLayer.backgroundColor = [UIColor colorWithRed:0.25f
													green:0.25f
													blue:0.25f
													alpha:0.75].CGColor;
	highlightLayer.frame = self.layer.bounds;
	highlightLayer.hidden = YES;
	[self.layer insertSublayer:highlightLayer below:shineLayer];
}

- (void)setHighlighted:(BOOL)highlight
{
	highlightLayer.hidden = !highlight;
	[super setHighlighted:highlight];
}

- (void)initLayers
{
	[self initBorder];
	[self addShineLayer];
	[self addHighlightLayer];
}

- (void)awakeFromNib
{
	[self initLayers];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
