//
//  TraceView.h
//  MacCRO X
//
//  Created by Philip Derrin on Sat Jun 29 2002.
//  Copyright (c) 2002, 2003 Philip Derrin.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/TraceView.h,v 1.11 2003/02/20 12:51:32 narge Exp $
//

#import <AppKit/AppKit.h>
#import "InputSampler.h"
#import "TracePath.h"

@interface TraceView : NSView <InputHandler> {
	IBOutlet NSPanel* myControlPanel;
	
	IBOutlet NSButton* myFreezeCheckbox;
	
@protected
	id <InputSampler, NSObject> mySampler;
	
	// sound input data
	NSConditionLock* myDataLock;
	Sample* myDisplayData[2]; // data currently being displayed
	int myDataStored[2]; // size of myDisplayData (in frames)
	
	Sample* myCollectedData[2]; // data being collected for display
	int myDataWanted[2]; // required size of myCollectedData
	int myDataCollected[2]; // current size of myCollectedData
	
	float mySampleRate;
	int myChannelCount;
	
	// drawing thread stuff
	NSLock* myDisplayLock; // lock for access to the Bezier Paths
	TracePath* myTracePaths[2];
	NSBezierPath* myGridPath;
	NSConditionLock* myDrawThreadState; // semaphore to start & stop the drawing thread
	BOOL myDisplayIsFrozen;
	BOOL myDrawThreadShouldRun;
	BOOL myShowTime;

	// Captions
	IBOutlet NSTextField* myTimeCaption;
	IBOutlet NSTextField* myYScaleCaption1;
	IBOutlet NSTextField* myYScaleCaption2;
	IBOutlet NSTextField* myXScaleCaption;
}

-(id) startDrawingWithSampler: (id <InputSampler, NSObject>) sampler;

-(id) startDrawing;

-(id) stopDrawing;

-(BOOL) drawing;

-(id) freezeDrawing: (BOOL) freeze;

-(IBAction) changedFreezeSetting: (id) sender;

-(id) updateDisplay: (int) trace;

-(id) updateControls;

-(id) updateGrid;

-(id) updateCaptions;

-(IBAction) savePDFImage: (id) sender;

- (id)doTriggerOnData: (Sample*) inData
		frameCount: (unsigned long) inFrameCount
		atPosition: (unsigned long[2]) outTriggerPos
		didTrigger: (BOOL[2]) outTriggered;

- (id) clearData;

@end

// vim:syn=objc:inde=:
