//
//  ScopeAppDefaults.h
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeAppDefaults.h,v 1.1 2003/02/05 12:50:19 narge Exp $
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// This class is a wrapper around NSUserDefaults. It exists for two reasons:
// to provide convenient methods for getting current settings and showing the
// prefs panel; and to provide thread-safety, which NSUserDefaults does not have.

@interface ScopeAppDefaults : NSObject {
	NSColor* myTraceColours[2];
	NSColor* myBackColour;
	NSColor* myGridColour;
	
	IBOutlet NSPanel* myPrefsPanel;
	
	IBOutlet NSColorWell* myTraceAColourWell;
	IBOutlet NSColorWell* myTraceBColourWell;
	IBOutlet NSColorWell* myBackColourWell;
	IBOutlet NSColorWell* myGridColourWell;
}

+ sharedInstance;

- (void) showPreferencesPanel;

- (NSColor*) colourForTrace: (int) inTrace;

- (NSColor*) colourForBackground;

- (NSColor*) colourForGrid;

- (IBAction) changedSetting: (id) sender;

@end
