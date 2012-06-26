//
//  MapTag.h
//  distracted-driving
//
//  Created by Luke Godfrey on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapTag : NSObject <MKAnnotation>
{
	NSString				*name, *address;
	CLLocationCoordinate2D	coordinate;
	BOOL					animateDrop;
}

@property (copy) NSString								*name, *address;
@property (nonatomic, readonly) CLLocationCoordinate2D	coordinate;
@property (nonatomic, assign) BOOL						animateDrop;

- (id)initWithName:(NSString*)_name address:(NSString*)_address coordinate:(CLLocationCoordinate2D)_coordinate;

@end

@interface DangerTag : NSObject <MKAnnotation>
{
	NSString				*name, *address;
	CLLocationCoordinate2D	coordinate;
	BOOL					animateDrop;
}

@property (copy) NSString								*name, *address;
@property (nonatomic, readonly) CLLocationCoordinate2D	coordinate;
@property (nonatomic, assign) BOOL						animateDrop;

- (id)initWithName:(NSString*)_name address:(NSString*)_address coordinate:(CLLocationCoordinate2D)_coordinate;

@end