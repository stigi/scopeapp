//
//  TraceView.m
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/TraceView.m,v 1.21 2003/11/16 04:09:20 narge Exp $
//

#import "TraceView.h"
#import "ScopeAppDefaults.h"

// possible states for the data NSConditionLock
enum
{
	kWaitingForData,
	kHaveRequiredData
};

// possible states for the drawing NSConditionLock
enum
{
	kDrawThreadRunning,
	kDrawThreadStopped
};

@interface TraceView (TraceViewInternal)

- (id)cycleBuffers;

- (void)displayThread: (id) unused;

@end

@implementation TraceView

- (void)awakeFromNib {
	myTracePaths[0] = [[TracePath alloc] init];
	myTracePaths[1] = [[TracePath alloc] init];
	
	myGridPath = [[NSBezierPath alloc] init];
	[myGridPath setCachesBezierPath: YES];
	
	myDisplayIsFrozen = NO;
	myDataLock = [[NSConditionLock alloc]
			initWithCondition: kWaitingForData];
	myDrawThreadState = [[NSConditionLock alloc]
			initWithCondition: kDrawThreadStopped];
	myDisplayLock = [[NSLock alloc] init];
	mySampler = nil;
	
	myCollectedData[0] = malloc(myDataWanted[0] * sizeof(Sample));
	myCollectedData[1] = malloc(myDataWanted[1] * sizeof(Sample));
	myDataCollected[0] = 0;
	myDataCollected[1] = 0;
	myDisplayData[0] = NULL;
	myDisplayData[1] = NULL;
	myDataStored[0] = 0;
	myDataStored[1] = 0;
	
	[self updateGrid];
}

- (void) dealloc
{
	[self stopDrawing];
	if(mySampler != nil) {
		[mySampler stopSampling];
		[mySampler setOwner:nil];
		[mySampler release];
	}
	
	[myTracePaths[0] release];
	[myTracePaths[1] release];
	[myDataLock release];
	[myDisplayLock release];
	
	free(myCollectedData[0]);
	free(myCollectedData[1]);
	if(myDisplayData[0] != NULL) free(myDisplayData[0]);
	if(myDisplayData[1] != NULL) free(myDisplayData[1]);
	
	[super dealloc];
}

- (BOOL) isOpaque { return YES; }

- (void)drawRect:(NSRect)rect {
#if 0
	NSDate* startTime;
	NSTimeInterval time;
#endif
	NSRect bounds = [self bounds];
	NSGraphicsContext* context;
	BOOL wasAntiAliased;
	
	[self updateCaptions];
	
	NSAffineTransform* scaling =
			[NSAffineTransform transform];
	NSAffineTransform* translation =
			[NSAffineTransform transform];
	
	[NSBezierPath clipRect: rect];
	
	[[[ScopeAppDefaults sharedInstance] colourForBackground] set];
	[NSBezierPath fillRect: rect];
	
	// scale to the size of the frame
	[scaling scaleXBy: bounds.size.width yBy: bounds.size.height];
	[translation translateXBy: bounds.origin.x yBy: bounds.origin.y];
	[scaling concat];
	[translation concat];
	
	// lock the display data
	[myDisplayLock lock];
#if 0
	startTime = [NSDate date];
#endif

	// turn off anti-aliasing if necessary
	context = [NSGraphicsContext currentContext];
	wasAntiAliased = [context shouldAntialias];
	[context setShouldAntialias: YES]; // FIXME put this in prefs panel

	// draw grid
	[[[ScopeAppDefaults sharedInstance] colourForGrid] set];
	[myGridPath stroke];
	
	// draw trace A
	[[[ScopeAppDefaults sharedInstance] colourForTrace: 0] set];
	[myTracePaths[0] stroke];
	
	// draw trace B
	[[[ScopeAppDefaults sharedInstance] colourForTrace: 1] set];
	[myTracePaths[1] stroke];

	// undo the scaling and translation so it doesn't affect the captions
	[translation invert];
	[translation concat];
	[scaling invert];
	[scaling concat];

	// restore antialiasing
	[context setShouldAntialias: wasAntiAliased];

#if 0
	time = -[startTime timeIntervalSinceNow];
	fprintf(stderr, "%d %lf\n", myDataWanted[0], time);
#endif
	
	// unlock the display data
	[myDisplayLock unlock];
}

-(void) mouseDown: (NSEvent*) theEvent
{
	// if the user single-left-clicks on the trace view, write it to a pdf
	if([theEvent type] == NSLeftMouseDown && [theEvent clickCount] == 1)
	{
		[self savePDFImage: self];
	}
}

-(BOOL) acceptsFirstMouse: (NSEvent*) theEvent
{
	return YES;
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}

-(IBAction) savePDFImage: (id) sender;
{
	// we draw the contents of the entire window, not just the
	// current view, so the captions are included.
	NSView* view = [[self window] contentView];
	NSData* pdfdata =
		[[view dataWithPDFInsideRect: [view bounds]] retain];
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"pdf"];
#ifndef __APPLE__
	// runModalForDirectory:file:relativeToWindow: works on OS X,
	// but prints a warning that it is "obsolete and will be
	// removed". Sheets are not available in GNUstep, however.
	if([panel runModalForDirectory: nil file: nil
		relativeToWindow: [self window]] ==
		NSFileHandlingPanelOKButton)
	{
		[pdfdata writeToFile: [panel filename] atomically: NO];
	}
	[pdfdata release];
#else
	[panel beginSheetForDirectory: nil file:nil
		modalForWindow: [self window] modalDelegate: self
		didEndSelector: @selector(savePanelDidEnd:returnCode:
		contextInfo:) contextInfo: pdfdata];
#endif
}

#ifdef __APPLE__
// This method is called by the NSSavePanel created by -savePDFImage:.
// contextInfo will be an NSData* containing the data to write to the
// chosen file.
-(void) savePanelDidEnd: (NSSavePanel*) panel
	returnCode: (int) returnCode
	contextInfo: (void*) contextInfo
{
	NSData* data = (NSData*) contextInfo;
	if(returnCode == NSOKButton)
	{
		[data writeToFile: [panel filename] atomically: NO];
	}
	[data release];
}
#endif

-(id) startDrawingWithSampler: (id <InputSampler, NSObject>) sampler
{
	if(mySampler != nil) {
		[mySampler setOwner: nil];
		[mySampler release];
	}
	mySampler = sampler;
	[mySampler retain];
	[mySampler setOwner: self];
	
	mySampleRate = [mySampler sampleRate];
	myChannelCount = [mySampler channelCount];
	
	[self updateControls];

	return [self startDrawing];
}

-(id) startDrawing
{
	// be certain the draw thread is not running
	if(myDrawThreadShouldRun) return self;
	[myDrawThreadState lockWhenCondition: kDrawThreadStopped];
	
	// get the buffers ready
	[self clearData];
	
	// allow the thread to run
	myDrawThreadShouldRun = YES;
	[myDrawThreadState unlockWithCondition: kDrawThreadRunning];

	// start the thread
	[NSThread detachNewThreadSelector: @selector(displayThread:)
			toTarget: self withObject: nil];

        // start the sampler
	[mySampler startSampling];
	
	return self;
}

-(id) stopDrawing
{
	if([myDrawThreadState condition] == kDrawThreadStopped) { return self; }
	
	// tell the thread to stop
	myDrawThreadShouldRun = NO;
	
	// wait for it to really stop
	[myDrawThreadState lock];
	[myDrawThreadState unlockWithCondition: kDrawThreadStopped];

        // stop the sampler
	[mySampler stopSampling];
	
	return self;
}

-(BOOL) drawing
{
	return myDrawThreadShouldRun;
}

-(id) freezeDrawing: (BOOL) freeze
{
	myDisplayIsFrozen = freeze;
	
	if(!freeze) {
		[self clearData];
	}
	
	return self;
}

-(IBAction) changedFreezeSetting: (id) sender
{
	[self freezeDrawing: [myFreezeCheckbox intValue]];
}

-(id) updateDisplay: (int) trace
{
#ifdef __APPLE__
	[self doesNotRecognizeSelector:_cmd];
#else
	[self subclassResponsibility:_cmd];
#endif
    	return nil;
}

-(id) updateControls
{
#ifdef __APPLE__
	[self doesNotRecognizeSelector:_cmd];
#else
	[self subclassResponsibility:_cmd];
#endif
	return nil;
}

-(id) updateGrid
{
#ifdef __APPLE__
	[self doesNotRecognizeSelector:_cmd];
#else
	[self subclassResponsibility:_cmd];
#endif
	return nil;
}

-(id) updateCaptions
{
	NSDate* now;
	NSString* currentTime;


	if(myShowTime) {
		now = [NSDate date];
		currentTime = [now descriptionWithCalendarFormat: @"%X" 
				timeZone: nil locale: nil];
	} else {
		currentTime = @"";
	}
	
	[myTimeCaption setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myTimeCaption setStringValue: currentTime];
	
	return self;
}

-(id) processData: (Sample*) inData
		length: (unsigned long) frameCount
		channels: (int) channelCount
		rate: (float) sampleRate
		fromSampler: (id <InputSampler, NSObject>) sampler
{
	BOOL updateRequired = NO;
	BOOL hasTriggered[2] = {YES, YES};
	unsigned long theTriggerPoint[2] = { 0, 0 };
	int curChannel;

	if(myDisplayIsFrozen || [myDrawThreadState condition] == kDrawThreadStopped) {
		return self;
	}

	if(channelCount != myChannelCount || sampleRate != mySampleRate)
	{
		[self clearData];
		myChannelCount = channelCount;
		mySampleRate = sampleRate;
	}
	
	[myDataLock lock];
		
	[self doTriggerOnData: inData
			frameCount: frameCount
			atPosition: theTriggerPoint
			didTrigger: hasTriggered];
	
	for(curChannel = 0; curChannel < channelCount; curChannel++)
	{
		unsigned long newCollectedSize;
		unsigned long i;
		Sample* source;
		Sample* dest;
		
		if(!hasTriggered[curChannel])
			{ continue; }
		if(myDataCollected[curChannel] == myDataWanted[curChannel])
		{
			updateRequired = YES;
			continue; 
		}
		
		newCollectedSize = (myDataCollected[curChannel] + frameCount)
					- theTriggerPoint[curChannel];
		
		if(newCollectedSize > myDataWanted[curChannel])
			{ newCollectedSize = myDataWanted[curChannel]; }
		
		source = inData + curChannel;
		dest = myCollectedData[curChannel] +
			myDataCollected[curChannel];
		for(i=myDataCollected[curChannel]; i < newCollectedSize; i++)
		{
			*(dest++) = *source;
			source += channelCount;
		}
		
		myDataCollected[curChannel] = newCollectedSize;
		if(myDataWanted[0] == myDataCollected[0])
		{
			updateRequired = YES;
		}
	}
	
	[myDataLock unlockWithCondition: updateRequired ?
				kHaveRequiredData : kWaitingForData];
	
	return self;
}

- (id)doTriggerOnData: (Sample*) inData
		frameCount: (unsigned long) inFrameCount
		atPosition: (unsigned long[2]) outTriggerPos
		didTrigger: (BOOL[2]) outTriggered
{
	// no triggering in a basic TraceView
	return self;
}

- (id)clearData
{
	[myDataLock lock];
	
	myDataCollected[0] = 0;
	myDataCollected[1] = 0;
	
	free(myCollectedData[0]);
	free(myCollectedData[1]);

	myCollectedData[0] = malloc(sizeof(Sample) * myDataWanted[0]);
	myCollectedData[1] = malloc(sizeof(Sample) * myDataWanted[1]);
	
	[myDataLock unlockWithCondition: kWaitingForData];
	
	return self;
}

@end

@implementation TraceView (TraceViewInternal)

- (id)cycleBuffers
{
	if(myDataCollected[0] == myDataWanted[0])
	{
		free(myDisplayData[0]);
		myDisplayData[0] = myCollectedData[0];
		myDataStored[0] = myDataCollected[0];
		myDataCollected[0] = 0;
		myCollectedData[0] = malloc(sizeof(Sample) * myDataWanted[0]);
	}
	
	if(myDataCollected[1] == myDataWanted[1])
	{
		free(myDisplayData[1]);
		myDisplayData[1] = myCollectedData[1];
		myDataStored[1] = myDataCollected[1];
		myDataCollected[1] = 0;
		myCollectedData[1] = malloc(sizeof(Sample) * myDataWanted[1]);
	}
	
	return self;
}

- (void)displayThread: (id) unused
{
	NSAutoreleasePool *pool;
	
	[myDrawThreadState lockWhenCondition: kDrawThreadRunning];
	
	while(myDrawThreadShouldRun)
	{
		pool = [[NSAutoreleasePool alloc] init];
		
		[myDataLock lockWhenCondition: kHaveRequiredData];
		[self cycleBuffers];
		[myDataLock unlockWithCondition: kWaitingForData];
		[self updateDisplay: 0];
		[self updateDisplay: 1];
		
		[self display];
		
		[pool release];
	}

	[myDrawThreadState unlock];
}

@end

// vim:syn=objc:inde=:
