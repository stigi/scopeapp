//
//  XYPlotView.h
//  MacCRO X
//
//  Created by Philip Derrin on Sun Jul 14 2002.
//  Copyright (c) 2002 Philip Derrin.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/XYPlotView.h,v 1.6 2003/02/14 11:55:16 narge Exp $
//

#import <AppKit/AppKit.h>
#import "TraceView.h"

@interface XYPlotView : TraceView {
	// **** Controls ****
	// X scale
	IBOutlet NSSlider* myXScaleSlider;
	IBOutlet NSSlider* myXFineSlider;
	
	// Y scale
	IBOutlet NSSlider* myYScaleSlider;
	IBOutlet NSSlider* myYFineSlider;

	// display settings
	IBOutlet NSButton* myShowTimeCheckbox;
	IBOutlet NSButton* myShowScaleCheckbox;

@protected
	//  oscilloscope settings
	double myXScale, myYScale;
	double myGain;
	BOOL myShowScales;
}

-(IBAction) changedScale: (id) sender;

-(IBAction) changedDisplaySettings: (id) sender;

@end

// vim:syn=objc:nocin:si:
