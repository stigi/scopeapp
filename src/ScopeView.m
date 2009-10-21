//
//  ScopeView.m
//  MacCRO X
//
//  Created by narge on Tue Nov 27 2001.
//  Copyright (c) 2001, 2002, 2003 Philip Derrin.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeView.m,v 1.20 2003/02/14 11:57:33 narge Exp $
//

#import "ScopeView.h"
#import "ScopeAppGlobals.h"
#import "ScopeAppDefaults.h"

static double gTimeScales[] = {0.001,0.002,0.005,0.01,0.02,0.05,0.1};
static double gVoltScales[] = {0.01,0.02,0.05,0.1,0.2,0.5,1};

// trigger channel settings
enum
{
	eTriggerOff = 0,
	eTriggerTraceA,
	eTriggerTraceB,
	eTriggerSeparate
};

// trigger edge settings
enum
{
	eTriggerRising = 0,
	eTriggerFalling
};

// offset menu settings
enum
{
	eOffsetCentered = 0,
	eOffsetSplit,
	eOffsetCustom
};

// trace menus
enum
{
	eTraceChannel1 = 0,
	eTraceChannel2,
	eTraceAdd,
	eTraceSubtract,
	eTraceBNone
};

@implementation ScopeView

- (void)awakeFromNib {
	myGain = 1.0;
	myDataWanted[0] = 441;
	myDataWanted[1] = 441;
	myXScales[0] = 0.01;
	myYScales[0] = 1;
	myYScales[1] = 1;
	myYOffsets[0] = 0;
	myYOffsets[1] = 0;

	[super awakeFromNib];
}

- (void) dealloc
{
	[self stopDrawing];
	
	/* currently nothing to deallocate */
	
	[super dealloc];
}


-(IBAction) changedXScale: (id) sender
{
	BOOL wasDrawing;

	if(sender == myXScaleSlider)
	{
		// if the scale slider moved, zero the fine slider
		[myXFineSlider setIntValue: 0];
	}
	
	wasDrawing = [self drawing];
	if(wasDrawing) [self stopDrawing];

	myXScales[0] = gTimeScales[[myXScaleSlider intValue]-1] *
			pow(2.0, [myXFineSlider doubleValue]);
	myXScales[1] = myXScales[0];
	
	myDataWanted[0] = myXScales[0] * mySampleRate + 1;
	myDataWanted[1] = myXScales[1] * mySampleRate + 1;
	
	free(myCollectedData[0]);
	free(myCollectedData[1]);
	myCollectedData[0] = malloc(myDataWanted[0] * sizeof(Sample));
	myCollectedData[1] = malloc(myDataWanted[1] * sizeof(Sample));
	
	myDataCollected[0] = 0;
	myDataCollected[1] = 0;
	
	if(wasDrawing) [self startDrawing];
}

-(IBAction) changedYAScale: (id) sender
{
	if(sender == myYAScaleSlider)
	{
		// if the scale slider moved, zero the fine slider
		[myYAFineSlider setIntValue: 0];
	}
	
	myYScales[0] = gVoltScales[[myYAScaleSlider intValue]-1] *
			pow(2.0, [myYAFineSlider doubleValue]);
	
	if(myTriggerChannel != eTriggerTraceB)
	{
		[self changedTriggerSettings: self];
	}
}

-(IBAction) changedYBScale: (id) sender
{
	if(sender == myYBScaleSlider)
	{
		// if the scale slider moved, zero the fine slider
		[myYBFineSlider setIntValue: 0];
	}
	
	myYScales[1] = gVoltScales[[myYBScaleSlider intValue]-1] *
			pow(2.0, [myYBFineSlider doubleValue]);
	
	if(myTriggerChannel == eTriggerTraceB)
	{
		[self changedTriggerSettings: self];
	}
}

-(IBAction) changedTriggerSettings: (id) sender
{
	BOOL wasDrawing = [self drawing];

	if(wasDrawing) [self stopDrawing];

	myTriggerChannel = [myTriggerChRadio selectedRow];
	myTriggerEdge = [myTriggerEdgeRadio selectedRow];
	
	if(myTriggerChannel != eTriggerOff)
	{
		[myThresholdSlider setEnabled: YES];
		
		// disable triggering on trace B and separate traces if they don't apply
		if([myYBTraceMenu indexOfSelectedItem] == eTraceBNone)
		{
			[[myTriggerChRadio cellAtRow: eTriggerTraceB column: 1] setEnabled: NO];
			[[myTriggerChRadio cellAtRow: eTriggerSeparate column: 1] setEnabled: NO];
			
			// if we're currently set to use one of these, change the selection
			// and try again
			if(myTriggerChannel == eTriggerTraceB ||
				myTriggerChannel == eTriggerSeparate)
			{
				[myTriggerChRadio selectCellAtRow: eTriggerOff column: 1];
				if(wasDrawing) [self startDrawing];
				return;
			}
		}
		else // otherwise enable them
		{
			[[myTriggerChRadio cellAtRow: eTriggerTraceB column: 1] setEnabled: YES];
			[[myTriggerChRadio cellAtRow: eTriggerSeparate column: 1] setEnabled: YES];
		}
	}
	else {
		[myThresholdSlider setEnabled: NO];
	}
	
	myTriggerLevel = [myThresholdSlider doubleValue];
		
	if(myTriggerChannel == eTriggerTraceB) {
		myTriggerLevel *= gVoltScales[[myYBScaleSlider intValue]] *
			pow(2.0, [myYBFineSlider doubleValue]);
	}
	else {
		myTriggerLevel *= gVoltScales[[myYAScaleSlider intValue]] *
			pow(2.0, [myYAFineSlider doubleValue]);
	}
	
	if(wasDrawing) [self startDrawing];
}

-(IBAction) changedDisplaySettings: (id) sender
{
	if(sender == myOffsetMenu)
	{
		int item = [myOffsetMenu indexOfSelectedItem];
		if(item == eOffsetCentered)
		{
			[myYAOffsetSlider setDoubleValue: 0.0];
			[myYBOffsetSlider setDoubleValue: 0.0];
		}
		else if(item == eOffsetSplit)
		{
			[myYAOffsetSlider setDoubleValue: 0.25];
			[myYBOffsetSlider setDoubleValue: -0.25];
		}
	}
	
	if(sender == myYAOffsetSlider || sender == myYBOffsetSlider)
	{
		[myOffsetMenu selectItemAtIndex: eOffsetCustom];
	}
	
	myYOffsets[0] = [myYAOffsetSlider doubleValue];
	myYOffsets[1] = [myYBOffsetSlider doubleValue];
	
	myShowTime = [myShowTimeCheckbox intValue];
	myShowScales = [myShowScaleCheckbox intValue];
}

-(id) updateControls
{
	[self changedXScale: self];
	[self changedYAScale: self];
	[self changedYBScale: self];
	[self changedTriggerSettings: self];
	[self changedDisplaySettings: self];
	return self;
}

- (id)updateDisplay: (int) inTrace
{
	double theScaleFactor;
	double curValue;
	float curX, curY;
	int traceMode;
	unsigned long curSample;
	
	theScaleFactor = myGain * 1 / myYScales[inTrace];
	
	if(inTrace == 1 && [myYBTraceMenu indexOfSelectedItem] == eTraceBNone)
	{
		[myDisplayLock lock];
		[myTracePaths[1] removeAllPoints];
		[myDisplayLock unlock];
		return self;
	}
	
	if(inTrace == 0)
	{
		traceMode = [myYATraceMenu indexOfSelectedItem];
	}
	else
	{
		traceMode = [myYBTraceMenu indexOfSelectedItem];
	}
	
	switch(traceMode) {
		case eTraceChannel1:
			if(myDisplayData[0] == NULL) { return self; }
			curValue = myDisplayData[0][0];
			break;
		case eTraceChannel2:
			if(myDisplayData[1] == NULL) { return self; }
			curValue = myDisplayData[1][0];
			break;
		case eTraceAdd:
			if(myDisplayData[0] == NULL) { return self; }
			if(myDisplayData[1] == NULL) { return self; }
			curValue = (myDisplayData[0][0] + myDisplayData[1][0]);
			break;
		case eTraceSubtract:
			if(myDisplayData[0] == NULL) { return self; }
			if(myDisplayData[1] == NULL) { return self; }
			curValue = (myDisplayData[0][0] - myDisplayData[1][0]);
			break;
		default:
			NSLog(@"[ScopeView updateDisplays]: Invalid trace type\n");
			return self;
	}
	
	[myDisplayLock lock];
	[myTracePaths[inTrace] removeAllPoints];
	
	curX = 0;
	curY = 0.5 + (curValue * theScaleFactor) + myYOffsets[inTrace];
	[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
	
	switch(traceMode) {
		case eTraceChannel1:
			for(curSample = 0; curSample < myDataStored[0]; curSample++) {
				curX = (float)curSample / (mySampleRate * myXScales[0]);
				curValue = myDisplayData[0][curSample];
				curY = 0.5 + (curValue * theScaleFactor) + myYOffsets[inTrace];
				[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
			}
			break;
		case eTraceChannel2:
			for(curSample = 0; curSample < myDataStored[1]; curSample++) {
				curX = (float)curSample / (mySampleRate * myXScales[0]);
				curValue = myDisplayData[1][curSample];
				curY = 0.5 + (curValue * theScaleFactor) + myYOffsets[inTrace];
				[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
			}
			break;
		case eTraceAdd:
			for(curSample = 0; curSample < myDataStored[0]; curSample++) {
				curX = (float)curSample / (mySampleRate * myXScales[0]);
				curValue = (myDisplayData[0][curSample] +
					myDisplayData[1][curSample]);
				curY = 0.5 + (curValue * theScaleFactor) + myYOffsets[inTrace];
				[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
			}
			break;
		case eTraceSubtract:
			for(curSample = 0; curSample < myDataStored[0]; curSample++) {
				curX = (float)curSample / (mySampleRate * myXScales[0]);
				curValue = (myDisplayData[0][curSample] -
					myDisplayData[1][curSample]);
				curY = 0.5 + (curValue * theScaleFactor) + myYOffsets[inTrace];
				[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
			}
			break;
		default:
			NSLog(@"[ScopeView updateDisplays]: Invalid trace type\n");
			break;
	}
	
	[myDisplayLock unlock];
	
	return self;
}

-(id) updateGrid
{
	float x;
	
	[myGridPath removeAllPoints];
	[myGridPath setLineWidth: 0.0];
	
	for(x=0.1; x<1; x+=0.1) {
		[myGridPath moveToPoint: NSMakePoint(x, 0)];
		[myGridPath lineToPoint: NSMakePoint(x, 1)];
		[myGridPath moveToPoint: NSMakePoint(0, x)];
		[myGridPath lineToPoint: NSMakePoint(1, x)];
	}
	
	return self;
}

-(id) updateCaptions
{
	NSString* xscale;
	NSString* yscale1;
	NSString* yscale2;

	if(myShowScales) {
		xscale = [NSString localizedStringWithFormat:
				@"%.4gms/div", myXScales[0] * 100];
		yscale1 = [NSString localizedStringWithFormat:
				@"%.4gmV/div", myYScales[0] * 100];
		yscale2 = [NSString localizedStringWithFormat:
				@"%.4gmV/div", myYScales[1] * 100];
	} else {
		xscale = yscale1 = yscale2 = @"";
	}
	
	[myXScaleCaption setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myYScaleCaption1 setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myYScaleCaption2 setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 1]];
	[myXScaleCaption setStringValue: xscale];
	[myYScaleCaption1 setStringValue: yscale1];
	[myYScaleCaption2 setStringValue: yscale2];
	
	return [super updateCaptions];
}

- (id)doTriggerOnData: (Sample*) inData
		frameCount: (unsigned long) inFrameCount
		atPosition: (unsigned long[2]) outTriggerPos
		didTrigger: (BOOL[2]) outTriggered
{
// FIXME implement this
	return self;
}

@end

// vim:syn=objc:inde=:
