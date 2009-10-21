//
//  ScopeController.m
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeController.m,v 1.15 2003/04/25 07:31:16 narge Exp $
//

#import "ScopeAppGlobals.h"

#import "ScopeController.h"

enum {
	eOscilloscopeTab = 0,
	eXYPlotTab,
	eSpectrumTab
};

@implementation ScopeController

-(id) initWithSamplerClass: (Class) samplerClass
{
	self = [super initWithWindowNibName: @"ScopeWindow"];
	
	if(self != nil)
	{
		NSNotificationCenter *nCenter;
		
		mySamplerClass = samplerClass;
		
		nCenter = [NSNotificationCenter defaultCenter];
		[nCenter addObserver: self selector: @selector(windowBecameMain:)
				name: @"NSWindowDidBecomeMain" object: [self window]];
		[nCenter addObserver: self selector: @selector(windowResignedMain:)
				name: @"NSWindowDidResignMain" object: [self window]];
	}
	
	return self;
}

-(void) windowDidLoad
{
	[myScopeView retain];
	[myXYPlotView retain];
	[mySpectrumView retain];
	[myControlPanel retain];

	[[self window] orderFront: self];

	[myControlPanel orderWindow: NSWindowAbove
			relativeTo: [[self window] windowNumber]];
	
	mySampler = [[mySamplerClass alloc]
		initWithOwner: nil
		withErrorHandler: self];
	
	// make sure the oscilloscope tab is selected, then
	// display the oscilloscope; don't set the delegate until
	// afterwards because I'm not sure whether
	// selectTabViewItemAtIndex: will ever call
	// tabView:didSelectTabViewItem:
	[myModeTabs selectTabViewItemAtIndex: eOscilloscopeTab];
	[self tabView: myModeTabs didSelectTabViewItem:
		[myModeTabs tabViewItemAtIndex: eOscilloscopeTab]];
	[myModeTabs setDelegate: self];
}

-(void) dealloc
{
	[mySampler release];
	
	[myScopeView release];
	[myXYPlotView release];
	[mySpectrumView release];
	[myControlPanel release];
	
	[super dealloc];
}

-(void) windowBecameMain: (id) notification
{
	[myControlPanel orderWindow: NSWindowAbove
			relativeTo: [[self window] windowNumber]];
}

-(void) windowResignedMain: (id) notification
{
	[myControlPanel orderWindow: NSWindowOut
			relativeTo: [[self window] windowNumber]];
}

-(void) tabViewDidChangeNumberOfTabViewItems: (NSTabView*) tabView { }

-(void) tabView: (NSTabView *) tabView
	didSelectTabViewItem: (NSTabViewItem *) tabViewItem;
{
	int newTab = [tabView indexOfTabViewItem: tabViewItem];
	TraceView* newView = nil;
	
	// assert that the tab view that has been switched is the mode tabs
	if(tabView != myModeTabs) { return; }
	
	// stop the view which is currently drawing
	[myScopeView stopDrawing];
	[myXYPlotView stopDrawing];
	[mySpectrumView stopDrawing];
	
	// hide all the views
	[myScopeView removeFromSuperview];
	[myXYPlotView removeFromSuperview];
	[mySpectrumView removeFromSuperview];
	
	// show and start drawing in the new active view
	switch(newTab)
	{
	case eOscilloscopeTab:
		newView = myScopeView;
		break;
	case eXYPlotTab:
		newView = myXYPlotView;
		break;
	case eSpectrumTab:
		newView = mySpectrumView;
		break;
	}
	
	[newView setFrameSize: [[[self window] contentView] bounds].size];
	[[[self window] contentView] addSubview: newView
		positioned: NSWindowBelow relativeTo: nil];
	[newView startDrawingWithSampler: mySampler];
}


-(BOOL) tabView: (NSTabView*) tabView
	shouldSelectTabViewItem: (NSTabViewItem*) tabViewItem
{
	return YES;
}
  
-(void) tabView: (NSTabView*) tabView
	willSelectTabViewItem: (NSTabViewItem*) tabViewItem { }

-(IBAction) orderFrontControlWindow: (id) sender
{
	[myControlPanel orderWindow: NSWindowAbove
			relativeTo: [[self window] windowNumber]];
}

-(int) displayError: (NSString*) title
	withExtraText: (NSString*) subtitle
	withDefaultButton: (NSString*) defaultButton
	withCancelButton: (NSString*) cancelButton
	isFatal: (BOOL) fatal;
{
	SEL sheetClosedHandler = fatal ? @selector(handleFatalError) : nil;
	
	NSLog(@"Displaying error message...");
	NSBeginAlertSheet(title, defaultButton, cancelButton, nil,
		[self window], self, nil, sheetClosedHandler, NULL, subtitle);

	return 0;
}

- (void) handleFatalError
{
	// send a close action to the window; this will call all the appropriate	// methods to deallocate everything.
	[[self window] close];
}

@end

// vim:syn=objc:nocin:si:
