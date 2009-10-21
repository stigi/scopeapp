//
//  ScopeController.h
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeController.h,v 1.10 2003/04/25 07:31:09 narge Exp $
//

#import <AppKit/AppKit.h>
#import "InputSampler.h"
#import "ScopeView.h"
#import "SpectrumView.h"
#import "XYPlotView.h"
//#import "WaterfallView.h"

@interface ScopeController : NSWindowController <InputErrorHandler> {
	IBOutlet ScopeView* myScopeView;
	IBOutlet SpectrumView* mySpectrumView;
	IBOutlet XYPlotView* myXYPlotView;
//	IBOutlet WaterfallView* myWaterfallView;

	IBOutlet NSPanel* myControlPanel;
	IBOutlet NSTabView* myModeTabs;
	
@private	
	id <InputSampler, NSObject> mySampler;
	Class mySamplerClass;
}

-(id) initWithSamplerClass: (Class) samplerClass;

-(void) windowBecameMain: (id) notification;

-(void) windowResignedMain: (id) notification;

// tab view delegate methods

-(void) tabView: (NSTabView*) tabView
	didSelectTabViewItem: (NSTabViewItem*) tabViewItem;

-(IBAction) orderFrontControlWindow: (id) sender;

@end

// vim:syn=objc:nocin:si:
