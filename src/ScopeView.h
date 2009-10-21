//
//  ScopeView.h
//  MacCRO X
//
//  Created by narge on Tue Nov 27 2001.
//  Copyright (c) 2001, 2002 Philip Derrin.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeView.h,v 1.12 2003/02/14 11:55:16 narge Exp $
//

#import <AppKit/AppKit.h>
#import "TraceView.h"

@interface ScopeView : TraceView {
	// **** Controls ****
	// X scale
	IBOutlet NSSlider* myXScaleSlider;
	IBOutlet NSSlider* myXFineSlider;
	
	// y scale (trace A)
	IBOutlet NSSlider* myYAScaleSlider;
	IBOutlet NSSlider* myYAFineSlider;
	IBOutlet NSPopUpButton* myYATraceMenu;
	IBOutlet NSSlider* myYAOffsetSlider;
	
	// y scale (trace B)
	IBOutlet NSSlider* myYBScaleSlider;
	IBOutlet NSSlider* myYBFineSlider;
	IBOutlet NSPopUpButton* myYBTraceMenu;
	IBOutlet NSSlider* myYBOffsetSlider;
	
	// trigger settings
	IBOutlet NSMatrix* myTriggerChRadio;
	IBOutlet NSMatrix* myTriggerEdgeRadio;
	IBOutlet NSSlider* myThresholdSlider;
	
	// display settings
	IBOutlet NSPopUpButton* myOffsetMenu;
	IBOutlet NSButton* myShowTimeCheckbox;
	IBOutlet NSButton* myShowScaleCheckbox;

@protected
	//  oscilloscope settings
	double myXScales[2], myYScales[2];
	double myYOffsets[2];
	double myTriggerLevel;
	double myGain;
	
	int myTriggerChannel, myTriggerEdge;
	BOOL myShowScales;
}

-(IBAction) changedXScale: (id) sender;

-(IBAction) changedYAScale: (id) sender;

-(IBAction) changedYBScale: (id) sender;

-(IBAction) changedTriggerSettings: (id) sender;

-(IBAction) changedDisplaySettings: (id) sender;

- (id)doTriggerOnData: (Sample*) inData
		frameCount: (unsigned long) inFrameCount
		atPosition: (unsigned long[2]) outTriggerPos
		didTrigger: (BOOL[2]) outTriggered;

@end

// vim:syn=objc:inde=:
