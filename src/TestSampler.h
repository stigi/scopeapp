//
//  TestSampler.h
//  MacCRO X
//
//  Created by narge on Thu Nov 29 2001.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/TestSampler.h,v 1.8 2003/02/20 12:56:36 narge Exp $
//

#import <Foundation/Foundation.h>

#import "InputSampler.h"

@interface TestSampler : NSObject <InputSampler> {
	// InputSampler data
	id <InputHandler, NSObject> myOwner;
	int myBlockSize;
	float mySampleRate;
	unsigned short myChannelCount;
	
	float myFrequency;
	float myOffset;
	
	NSConditionLock* myStateLock;
}

-(id) init;

// init a sampler with a given owner object
-(id) initWithOwner: (id <InputHandler>) owner;

-(void) dealloc;

// return YES if the sampler has an input settings dialog it can show
-(BOOL) canShowInputSettings;

// show the input settings dialog
-(id) showInputSettings;

// return YES if the sampler can show a dialog to choose between multiple
// sources
-(BOOL) canShowChooseSource;

// show the "choose source" dialog
-(id) showChooseSource;

// start sampling sound data
-(id) startSampling;

// stop sampling sound data
-(id) stopSampling;

// set the object which handles captured data
-(id) setOwner: (id <InputHandler>) owner;

// request a specific block size
-(id) requestBlockSize: (unsigned long)size;

// get the actual block size
-(unsigned long) blockSize;

// return YES if the sampler is currently sampling data
-(BOOL) isSampling;

// return the sample rate
-(float) sampleRate;

// return the number of channels in the input data
-(char) channelCount;

@end

// vim:syn=objc:nocin:si:
