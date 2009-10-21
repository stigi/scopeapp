//
//  XYPlotView.m
//  MacCRO X
//
//  Created by Philip Derrin on Sun Jul 14 2002.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/XYPlotView.m,v 1.13 2003/11/16 06:59:37 narge Exp $
//

#import "XYPlotView.h"
#import "ScopeAppDefaults.h"

static double gVoltScales[7] = {0.01,0.02,0.05,0.1,0.2,0.5,1};

@implementation XYPlotView

- (void)awakeFromNib {
	myGain = 1.0;
	myDataWanted[0] = 882; // FIXME add a control for this
	myDataWanted[1] = 882; // FIXME add a control for this
	myXScale = 1;
	myYScale = 1;

	[super awakeFromNib];
}

- (void) dealloc
{
	[self stopDrawing];
	
	/* currently nothing to deallocate */
	
	[super dealloc];
}

-(IBAction) changedScale: (id) sender
{
	if(sender == myYScaleSlider)
	{
		// if the scale slider moved, zero the fine slider
		[myYFineSlider setIntValue: 0];
	}
	
	if(sender == myXScaleSlider)
	{
		[myXFineSlider setIntValue: 0];
	}
	
	myXScale = gVoltScales[[myXScaleSlider intValue]-1] *
			pow(2.0, [myXFineSlider doubleValue]);

	myYScale = gVoltScales[[myYScaleSlider intValue]-1] *
			pow(2.0, [myYFineSlider doubleValue]);
}

-(IBAction) changedDisplaySettings: (id) sender
{
	myShowTime = [myShowTimeCheckbox intValue];
	myShowScales = [myShowScaleCheckbox intValue];
}

-(id) updateControls
{
	[self changedScale: self];
	[self changedDisplaySettings: self];
	return self; 
} 

- (id)updateDisplay: (int) inTrace
{
	double theScaleFactor[2];
	float curX, curY;
	unsigned long curSample;
	
	// channel B trace is empty for X/Y plot
	if(inTrace == 1)
	{
		[myDisplayLock lock];
		[myTracePaths[1] removeAllPoints];
		[myDisplayLock unlock];
		return self;
	}
	
	theScaleFactor[0] = myGain * 1 / myXScale;
	theScaleFactor[1] = myGain * 1 / myYScale;
	
	[myDisplayLock lock];
	[myTracePaths[0] removeAllPoints];
	
	curX = 0.5 + (myDisplayData[0][0] * theScaleFactor[0]);
	curY = 0.5 + (myDisplayData[1][0] * theScaleFactor[1]);
	[myTracePaths[0] addPoint: NSMakePoint(curX, curY)];
	
	for(curSample = 0;
		(curSample < myDataStored[0]) && (curSample < myDataStored[1]);
		curSample++)
	{
		curX = 0.5 + (myDisplayData[0][curSample] * theScaleFactor[0]);
		curY = 0.5 + (myDisplayData[1][curSample] * theScaleFactor[1]);
		[myTracePaths[0] addPoint: NSMakePoint(curX, curY)];
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
	NSString* yscale;

	if(myShowScales) {
		xscale = [NSString localizedStringWithFormat:
				@"%.4gmV/div", myXScale * 100];
		yscale = [NSString localizedStringWithFormat:
				@"%.4gmV/div", myYScale * 100];
	} else {
		xscale = yscale = @"";
	}
	
	[myXScaleCaption setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myYScaleCaption1 setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myXScaleCaption setStringValue: xscale];
	[myYScaleCaption1 setStringValue: yscale];

	[myYScaleCaption2 setStringValue: @""];
	
	return [super updateCaptions];
}

@end

// vim:syn=objc:inde=:
