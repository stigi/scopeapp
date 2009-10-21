//
//  ScopeAppDelegate.m
//  MacCRO X
//
//  Created by narge on Wed Nov 28 2001.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeAppDelegate.m,v 1.20 2003/04/25 07:31:18 narge Exp $
//

#import "ScopeAppGlobals.h"
#import "ScopeAppDelegate.h"
#import "ScopeAppDefaults.h"
#import "ScopeController.h"
#import "InputSampler.h"
#import "PortAudioSampler.h"

@implementation ScopeAppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *)not
{
	ScopeController* controller;
	Class samplerClass;

	// FIXME choose an appropriate InputSampler
	samplerClass = [PortAudioSampler class];
	
	// FIXME eventually this program will be (sort of) document-based,
	// with an NSDocumentController keeping track of all the existing
	// ScopeControllers and their associated windows. For now, just
	// create a ScopeController and let it take care of itself
	controller = [[ScopeController alloc]
		initWithSamplerClass: samplerClass];
	//[controller autorelease];
	
	myLicenseWindow = nil;
}

// FIXME is this required?
// - (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

// FIXME implement this
// - (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES; // FIXME change after adding support for reading from files ?
}

- (IBAction) orderFrontPreferencesPanel: (id) sender
{
	[[ScopeAppDefaults sharedInstance] showPreferencesPanel];
}

- (IBAction) orderFrontLicensePanel: (id) sender
{
	if(myLicenseWindow == nil)
	{
		[NSBundle loadNibNamed:@"LicenseWindow" owner: self];
		[myLicenseText readRTFDFromFile: 
			[[NSBundle mainBundle]
				pathForResource: @"License"
				ofType: @"rtf"]];
	}
	
	[myLicenseWindow makeKeyAndOrderFront: self];
}

- (void) dealloc
{
	if(myLicenseWindow != nil)
	{
		[myLicenseWindow release];
	}
}

@end

// vim:syn=objc:nocin:si:
