//
//  TestSampler.m
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/TestSampler.m,v 1.9 2003/02/20 12:56:36 narge Exp $
//

#import "TestSampler.h"

#include <math.h>

// Possible values for the sampler's conditional lock
enum
{
	kTestSamplerRunning, // currently collecting data
	kTestSamplerStopped // thread should be stopped or stopping
};

// Internal interfaces
@interface TestSampler (TestSamplerInternal)

-(void) idleThread: (id) unused;

-(id) createData;

@end

@implementation TestSampler

-(id) init
{
	return [self initWithOwner: nil];
}

// init a sampler with a given owner object
-(id) initWithOwner: (id <InputHandler, NSObject>) owner
{
	self = [super init];
	
	if(self != nil)
	{
		myOwner = owner;
		if(myOwner) { [myOwner retain]; }
		
		myStateLock = [[NSConditionLock alloc]
				initWithCondition: kTestSamplerStopped];
		
		mySampleRate = 44100.0;
		myFrequency = 538.3301; // exact multiple of block size
//		myFrequency = 3000; // not exact multiple of block size
		myChannelCount = 2;
		myBlockSize = 64;
		myOffset = 0;
	}
	
	return self;
}

-(void) dealloc
{
	[self stopSampling];
	
	if(myOwner != nil) { [myOwner release]; }
	if(myStateLock != nil) { [myStateLock release]; }
	
	[super dealloc];
}

// return YES if the sampler has an input settings dialog it can show
-(BOOL) canShowInputSettings { return NO; }

// show the input settings dialog
-(id) showInputSettings { return self;}

// return YES if the sampler can show a dialog to choose between multiple
// sources
-(BOOL) canShowChooseSource { return NO; }

// show the "choose source" dialog
-(id) showChooseSource { return self; }

// start sampling sound data
-(id) startSampling
{
	if(![myStateLock tryLockWhenCondition: kTestSamplerStopped]) { return self; }
	[myStateLock unlockWithCondition: kTestSamplerRunning];
	
	[NSThread detachNewThreadSelector: @selector(idleThread:)
			toTarget: self withObject: nil];
	
	return self;
}

// stop sampling sound data
-(id) stopSampling
{
	if([myStateLock condition] == kTestSamplerStopped) { return self; }
	
	[myStateLock lock];
	[myStateLock unlockWithCondition: kTestSamplerStopped];
	
	return self;
}

// set the object which handles captured data
-(id) setOwner: (id <InputHandler, NSObject>) owner
{
	if(myOwner != nil) [myOwner release];
	myOwner = owner;
	if(myOwner != nil) [myOwner retain];
	
	return self;
}

// request a specific block size
-(id) requestBlockSize: (unsigned long)size {
	myBlockSize = size;
	return self;
}

// get the actual block size
-(unsigned long) blockSize
{
	return myBlockSize;
}

// return YES if the sampler is currently sampling data
-(BOOL) isSampling
{
	return [myStateLock condition] == kTestSamplerRunning;
}

// return the sample rate
-(float) sampleRate
{
	return mySampleRate;
}

// return the number of channels in the input data
-(char) channelCount
{
	return myChannelCount;
}

@end

// internal implementations
@implementation TestSampler (TestSamplerInternal)

// internal method which is the idler thread's main loop
-(void) idleThread: (id) unused
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while(YES)
	{
		if(![myStateLock tryLockWhenCondition: kTestSamplerRunning]) { break; }
		[self createData];
		[myStateLock unlock];
	}
	
	[pool release];
}

-(id) createData
{
	int curChannel;
	Sample* theData;
	unsigned long curSample;
//	float amplitude = (float)random() / (float)INT_MAX;
	float amplitude = 0.4;
	
//	myFrequency += 10 * ((float)random() / (float)INT_MAX - 0.5);
	
	if(myOwner == nil) return self;
	
	theData = malloc(myBlockSize * myChannelCount * sizeof(Sample));
	
	for(curSample = 0; curSample < myBlockSize; curSample++) {
		for(curChannel = 0; curChannel < myChannelCount; curChannel++) {
			theData[(curSample * myChannelCount) + curChannel] 
				= sin(myOffset) * amplitude;
		}
		myOffset += 2*M_PI*myFrequency / mySampleRate;
		if(myOffset > 2*M_PI) myOffset -= 2*M_PI;
	}
	
	[myOwner processData: theData length: myBlockSize
		channels: myChannelCount rate: mySampleRate
		fromSampler: self];

	free(theData);
	
	return self;
}

@end

// vim:syn=objc:nocin:si:
