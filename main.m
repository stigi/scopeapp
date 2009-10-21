//
//  main.m
//  MacCRO X
//
//  Copyright (c) 2002 Philip Derrin and Rafal Kolanski.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/main.m,v 1.4 2002/10/19 06:39:31 narge Exp $
//

#import <AppKit/AppKit.h>
#import "ScopeAppDelegate.h"

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSApplication sharedApplication];
	
	[NSApp setDelegate: [ScopeAppDelegate new]];
	[NSBundle loadNibNamed:@"MainMenu" owner: NSApp];
	[NSApp run];
	
	[pool release];
	
	return 0;
}

// vim:syn=objc:nocin:si:
