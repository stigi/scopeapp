//
//  TracePath.m
//  MacCRO X
//
//  Created by Philip Derrin on Fri Jan 10 2003.
//  Copyright (c) 2003 Philip Derrin.
//
//  This file is part of MacCRO X.
//
//  MacCRO X is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  MacCRO X is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with MacCRO X; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//  $Header: /cvsroot/scopeapp/scopeapp/src/TracePath.m,v 1.1 2003/01/10 10:49:27 narge Exp $
//

#import <AppKit/AppKit.h>

#import "TracePath.h"

@implementation TracePath

- init
{
	self = [super init];
	if(self != nil) {
		myPointsStored = 0;
		myPointsAllocated = 4;
		myPoints = malloc(sizeof(NSPoint) * myPointsAllocated);
	}
	return self;
}

-(void) dealloc
{
	free(myPoints);
}

- removeAllPoints
{
	// don't bother to reallocate array; chances are it'll just fill up
	// to the same size next time it's used
	myPointsStored = 0;
	
	return self;
}

- addPoint: (NSPoint) newPoint
{
	if(myPointsStored == myPointsAllocated)
	{
		myPointsAllocated *= 2;
		myPoints = realloc(myPoints, sizeof(NSPoint) * myPointsAllocated);
	}
	myPoints[myPointsStored] = newPoint;
	myPointsStored++;
	
	return self;
}

- stroke
{
	int i;
	NSBezierPath* path = [[NSBezierPath alloc] init];
	
	// FIXME: I tried using CoreGraphics directly to do this, but
	// it took "line width = 0" literally and drew nothing, rather
	// than drawing the thinnest possible line as Cocoa does.
	[path setLineWidth: 0.0];
	[path setLineCapStyle: NSButtLineCapStyle]; 
	
	for(i=0; i<myPointsStored-1; i++) {
		[path removeAllPoints];
		[path moveToPoint: myPoints[i]];
		[path lineToPoint: myPoints[i+1]];
		[path stroke];
	}
	
	[path release];
	
	return self;
}

@end

// vim:syn=objc:nocin:si:
