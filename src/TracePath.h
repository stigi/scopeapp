//
//  TracePath.h
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/TracePath.h,v 1.1 2003/01/10 10:49:27 narge Exp $
//

#import <Foundation/Foundation.h>

// TracePath is intended to replace NSBezierPath for drawing large numbers
// of connected straight line segments. It is significantly faster than
// NSBezierPath, at the expense of not using high-quality joins between
// segments or drawing overlapping lines correctly (especially when
// transparent). It does this by drawing line segments one at a time, rather
// than all in one large path.

@interface TracePath : NSObject {
	NSPoint* myPoints; // an array of NSPoints
	int myPointsAllocated; // the current size of the array
	int myPointsStored; // the number of points stored in the array
}

- init;

- removeAllPoints;

- addPoint: (NSPoint) newPoint;

- stroke;

@end

// vim:syn=objc:nocin:si:
