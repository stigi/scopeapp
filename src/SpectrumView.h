//
//  SpectrumView.h
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/SpectrumView.h,v 1.9 2003/02/20 02:22:58 narge Exp $
//

#import <AppKit/AppKit.h>

#ifdef __APPLE__
#import <vecLib/vecLib.h>
#else
#include <rfftw.h>
#endif

#import "TraceView.h"

typedef enum WindowType {
	eWindowRectangular = 0,
	eWindowBartlett,
	eWindowHann,
	eWindowHamming,
	eWindowBlackman,
	eWindowWelch,
} WindowType;

@interface SpectrumView : TraceView {
	// **** Controls ****
	// Frequency scale
	IBOutlet NSFormCell* myFreqFrom;
	IBOutlet NSFormCell* myFreqTo;
	IBOutlet NSButton* myFreqIsLogCheckbox;
	IBOutlet NSPopUpButton* myFreqResolutionMenu;
	
	// Amplitude scale
	IBOutlet NSFormCell* myAmpFrom;
	IBOutlet NSFormCell* myAmpTo;
	IBOutlet NSButton* myAmpIsLogCheckbox;
	IBOutlet NSPopUpButton* myAmpUnitsMenu;
	
	// Accumulation settings
	IBOutlet NSButton* myAccumulateCheckbox;
	IBOutlet NSButton* myAccumulateReset;

	// Windowing settings
	IBOutlet NSPopUpButton* myWindowTypeMenu;
	
	// display settings
	IBOutlet NSButton* myShowTimeCheckbox;
	IBOutlet NSButton* myShowScaleCheckbox;

@protected
	// spectrum analyser settings
	double myXFrom[2], myYFrom[2];
	double myXTo[2], myYTo[2];
	BOOL myXIsLog, myYIsLog;
	double myGain;
	
	BOOL myShowScales;

	// FFT stuff
#ifdef __APPLE__
	FFTSetup myFFTSetup;
#endif

	// Data for accumulation and windowing
	NSMutableData* myAccumulatedData[2];
	int myAccumulationCount[2]; // -1 if disabled
	NSData* myWindowFactors;
	WindowType myWindowType;
	float myWindowArea;
	NSLock* mySavedDataLock;
}

-(IBAction) changedFreqScale: (id) sender;

-(IBAction) changedVoltScale: (id) sender;

-(IBAction) changedAccumulationSettings: (id) sender;

-(IBAction) changedWindowingSettings: (id) sender;

-(IBAction) changedDisplaySettings: (id) sender;

-(NSData*) doRealFFTForData: (NSData*) data;

-(NSData*) doWindowingOnData: (NSData*) data;

-(NSData*) doAccumulationOnData: (NSData*) data fromTrace: (int) trace;

@end

// vim:syn=objc:inde=:
