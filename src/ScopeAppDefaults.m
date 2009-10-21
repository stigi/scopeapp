//
//  ScopeAppDefaults.m
//  MacCRO X
//
//  Created by Philip Derrin on Wed Feb 05 2003.
//  Copyright (c) 2003 Philip Derrin. All rights reserved.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeAppDefaults.m,v 1.1 2003/02/05 12:50:19 narge Exp $
//

#import "ScopeAppDefaults.h"

#define	SATraceColour0	@"Colour for trace A"
#define	SATraceColour1	@"Colour for trace B"
#define	SABackColour	@"Background colour"
#define	SAGridColour	@"Grid colour"

NSLock* gDefaultsLock = nil;

@interface ScopeAppDefaults (SADefaultsPrivate)

- sharedInit;

- loadDefaults;

- saveDefaults;

@end

@implementation ScopeAppDefaults

+ sharedInstance
{
	static ScopeAppDefaults* shared = nil;
	
	if(shared == nil) {
		shared = [[ScopeAppDefaults alloc] sharedInit];
	}
	
	return shared;
}

- (void) showPreferencesPanel
{
	if(myPrefsPanel == nil)
	{
		[NSBundle loadNibNamed:@"PrefsPanel" owner: self];
		
		[myTraceAColourWell setColor: myTraceColours[0]];
		[myTraceBColourWell setColor: myTraceColours[1]];
		[myBackColourWell setColor: myBackColour];
		[myGridColourWell setColor: myGridColour];
	}
	
	[myPrefsPanel makeKeyAndOrderFront: self];
}

- (NSColor*) colourForTrace: (int) inTrace
{
	return myTraceColours[inTrace];
}

- (NSColor*) colourForBackground
{
	return myBackColour;
}


- (NSColor*) colourForGrid
{
	return myGridColour;
}

- (IBAction) changedSetting: (id) sender
{
	[myTraceColours[0] autorelease];
	myTraceColours[0] = [[myTraceAColourWell color] retain];
	[myTraceColours[1] autorelease];
	myTraceColours[1] = [[myTraceBColourWell color] retain];
	[myBackColour autorelease];
	myBackColour = [[myBackColourWell color] retain];
	[myGridColour autorelease];
	myGridColour = [[myGridColourWell color] retain];
	[self saveDefaults];
}

@end

@implementation ScopeAppDefaults (SADefaultsPrivate)

- sharedInit
{
	self = [super init];
	
	if(self != nil)
	{
		if(gDefaultsLock == nil) gDefaultsLock = [[NSLock alloc] init];
		
		[self loadDefaults];
		
		myPrefsPanel = nil;
	}
	
	return self;
}

- loadDefaults
{
	NSUserDefaults* defaults;
	NSData* data;

	[gDefaultsLock lock];
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	data = [defaults objectForKey: SATraceColour0];
	if(data == nil) {
		myTraceColours[0] = [NSColor greenColor];
	} else {
		myTraceColours[0] = [NSUnarchiver unarchiveObjectWithData: data];
	}
	[myTraceColours[0] retain];
	
	data = [defaults objectForKey: SATraceColour1];
	if(data == nil) {
		myTraceColours[1] = [NSColor cyanColor];
	} else {
		myTraceColours[1] = [NSUnarchiver unarchiveObjectWithData: data];
	}
	[myTraceColours[1] retain];
	
	data = [defaults objectForKey: SABackColour];
	if(data == nil) {
		myBackColour = [NSColor blackColor];
	} else {
		myBackColour = [NSUnarchiver unarchiveObjectWithData: data];
	}
	[myBackColour retain];
	
	data = [defaults objectForKey: SAGridColour];
	if(data == nil) {
		myGridColour = [NSColor grayColor];
	} else {
		myGridColour = [NSUnarchiver unarchiveObjectWithData: data];
	}
	[myGridColour retain];
	
	[gDefaultsLock unlock];
	
	return self;
}

- saveDefaults
{
	NSUserDefaults* defaults;

	[gDefaultsLock lock];
	
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults
		setObject: [NSArchiver archivedDataWithRootObject: myTraceColours[0]]
		forKey: SATraceColour0];
	[defaults
		setObject: [NSArchiver archivedDataWithRootObject: myTraceColours[1]]
		forKey: SATraceColour1];
	[defaults
		setObject: [NSArchiver archivedDataWithRootObject: myBackColour]
		forKey: SABackColour];
	[defaults
		setObject: [NSArchiver archivedDataWithRootObject: myGridColour]
		forKey: SAGridColour];

	[gDefaultsLock unlock];
	
	return self;
}


@end
