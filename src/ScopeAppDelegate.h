//
//  ScopeAppDelegate.h
//  MacCRO X
//
//  Created by narge on Wed Nov 28 2001.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/ScopeAppDelegate.h,v 1.12 2003/02/05 12:56:14 narge Exp $
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ScopeController.h"

@interface ScopeAppDelegate : NSObject {
	IBOutlet NSWindow* myLicenseWindow;
	IBOutlet NSTextView* myLicenseText;
}

// - (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

// - (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;

- (void) applicationDidFinishLaunching: (NSNotification *)not;

- (IBAction) orderFrontPreferencesPanel: (id) sender;

- (IBAction) orderFrontLicensePanel: (id) sender;

@end

// vim:syn=objc:nocin:si:
