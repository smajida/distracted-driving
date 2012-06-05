//
//  MapTag.m
//  distracted-driving
//
//  Created by Luke Godfrey on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapTag.h"

@implementation MapTag

@synthesize name, address, coordinate;

- (id)initWithName:(NSString*)_name address:(NSString*)_address coordinate:(CLLocationCoordinate2D)_coordinate
{
	if(self = [super init])
	{
		name		= [_name copy];
		address		= [_address copy];
		coordinate	= _coordinate;
	}
	
	return self;
}

- (NSString *)title
{
	return name;
}

- (NSString *)subtitle
{
	return address;
}

@end

@implementation DangerTag

@synthesize name, address, coordinate;

- (id)initWithName:(NSString*)_name address:(NSString*)_address coordinate:(CLLocationCoordinate2D)_coordinate
{
	if(self = [super init])
	{
		name		= [_name copy];
		address		= [_address copy];
		coordinate	= _coordinate;
	}
	
	return self;
}

- (NSString *)title
{
	return name;
}

- (NSString *)subtitle
{
	return address;
}

@end
