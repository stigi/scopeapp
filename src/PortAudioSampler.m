//
//  PortAudioSampler.m
//  MacCRO X
//
//  Created by Philip Derrin on Thu Dec 05 2002.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/PortAudioSampler.m,v 1.2 2003/04/25 07:27:32 narge Exp $
//

#import "PortAudioSampler.h"
#import "ScopeAppGlobals.h"

#import <AppKit/AppKit.h>

#include <limits.h>

PortAudioCallback PASamplerCallback;

static BOOL gPASamplerExists = NO;

// Internal interfaces
@interface PortAudioSampler (PASamplerInternal)

-(int) processData: (in float*) inInputData
		frameCount: (unsigned long) count;

-(id) initPortAudio;

@end

// public implementations
@implementation PortAudioSampler

// init a sampler with a given owner object
-(id) initWithOwner: (id <InputHandler, NSObject>) owner
	withErrorHandler: (id <InputErrorHandler, NSObject>) errorHandler
{
	if(gPASamplerExists) return nil;
	
	self = [super init];
	
	if(self != nil)
	{
		myOwner = owner;
		if(myOwner) { [myOwner retain]; }
		
		myErrorHandler = errorHandler;
		if(myErrorHandler) { [myErrorHandler retain]; }
		
		mySamplerRunning = NO;
		
		myBlockSize = 512;
		
		if([self initPortAudio] == nil)
		{
			[self release];
			return nil;
		}
	}
	
	return self;
}

-(void) dealloc
{
	if(myStream != nil) {
		Pa_CloseStream(myStream);
	}
	
	Pa_Terminate();
	
	if(myOwner != nil) { [myOwner release]; }
	if(myErrorHandler != nil) { [myErrorHandler release]; }
	
	[super dealloc];
}

// return YES if the sampler has an input settings dialog it can show
-(BOOL) canShowInputSettings { return NO; }

// show the input settings dialog
-(id) showInputSettings
{
// FIXME
	return self;
}

// return YES if the sampler can show a dialog to choose between multiple
// sources
-(BOOL) canShowChooseSource { return NO; }

// show the "choose source" dialog
-(id) showChooseSource {
// FIXME
	return self;
}

// start sampling sound data
-(id) startSampling
{
	PaError status;
	
	mySamplerRunning = YES;
	
	status = Pa_StartStream(myStream);
	
	if (status) {
		NSLog(@"Pa_StartStream: returned %d (%s)", status,
			Pa_GetErrorText(status));
		
		[myErrorHandler displayError: _(@"Couldn't start recording sound.")
			withExtraText: [NSString stringWithFormat:
				_(@"PortAudio returned error: %s"),
				Pa_GetErrorText(status)]
			withDefaultButton: _(@"OK")
			withCancelButton: nil isFatal: YES];
		
		mySamplerRunning = NO;

		return nil;
	}
	
	return self;
}

// stop sampling sound data
-(id) stopSampling
{
	PaError status;
	
	mySamplerRunning = NO;
	
	status = Pa_StopStream(myStream);
	if (status) {
		NSLog(@"Pa_StopStream: returned %d (%s)", status,
			Pa_GetErrorText(status));
		
		[myErrorHandler displayError: _(@"Couldn't stop recording sound.")
			withExtraText: [NSString stringWithFormat:
				_(@"PortAudio returned error: %s"),
				Pa_GetErrorText(status)]
			withDefaultButton: _(@"OK")
			withCancelButton: nil isFatal: NO];

		mySamplerRunning = YES;

		return nil;
	}
	
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
	// WARNING: this will only take effect when the sampler restarts
	return self;
}

// get the actual block size
-(unsigned long) blockSize
{
	return myBlockSize;
}

// return true if the sampler is currently sampling data
-(BOOL) isSampling
{
	return mySamplerRunning;
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
@implementation PortAudioSampler (PASamplerInternal)

-(int) processData: (in float*) inInputData
		frameCount: (unsigned long) count
{
	/* if the sampler should have stopped already, tell
	 * portaudio to stop */
	if(!mySamplerRunning) return 1;
	
	/* now pass the data to the owner */
	[myOwner processData: inInputData length: count
		channels: myChannelCount rate: mySampleRate
		fromSampler: self];

	return paNoError;
}

- (id) initPortAudio {
	PaError status;
	PaDeviceID inputDevice;
	const PaDeviceInfo* deviceInfo;
	
	/* Start portaudio */
	status = Pa_Initialize();
	if (status) {
		NSLog(@"Pa_Initialize: returned %d (%s)", status,
			Pa_GetErrorText(status));
			
		[myErrorHandler displayError: _(@"Couldn't open sound input device.")
			withExtraText: [NSString stringWithFormat:
				_(@"PortAudio returned error: %s"),
				Pa_GetErrorText(status)]
			withDefaultButton: _(@"OK")
			withCancelButton: nil isFatal: YES];
		
		return nil;
	}
	
	/* find the input device */
	inputDevice = Pa_GetDefaultInputDeviceID();
	if(inputDevice == paNoDevice) {
		NSLog(@"Pa_GetDefaultInputDeviceID: returned paNoDevice");
		[myErrorHandler displayError: _(@"Couldn't find sound input device.")
#if __APPLE__
			withExtraText: _(@"Select a sound input device in the Sound panel of System Preferences.")
#else
			withExtraText: _(@"Make sure your sound card is configured correctly.")
#endif
			withDefaultButton: _(@"OK")
			withCancelButton: nil isFatal: YES];
		Pa_Terminate();
		return nil;
	}
	
	/* get information about the device */
	deviceInfo = Pa_GetDeviceInfo(inputDevice);
	if(!deviceInfo) {
		NSLog(@"Pa_GetDeviceInfo: returned NULL");
		Pa_Terminate();
		return nil;
	}

	/* now choose the highest possible sample rate */
	mySampleRate = -1;
	if(deviceInfo->numSampleRates == -1) {
		/* there's a range; choose the maximum */
		mySampleRate = deviceInfo->sampleRates[1];
	} else {
		int i;
		for(i=0; i<deviceInfo->numSampleRates; i++) {
			if(deviceInfo->sampleRates[i] > mySampleRate) {
				mySampleRate = deviceInfo->sampleRates[i];
			}
		}
	}

	/* find the number of input channels (currently no more than 2) */
	myChannelCount = deviceInfo->maxInputChannels;
	if(myChannelCount > 2) myChannelCount = 2;

	/* and finally, open the stream */
	status = Pa_OpenStream(&myStream, inputDevice, myChannelCount,
				paFloat32, NULL, paNoDevice, 0, 0, NULL,
				mySampleRate, myBlockSize, 0, paNoFlag,
				PASamplerCallback, self);
	
	if (status) {
		NSLog(@"Pa_OpenStream: returned %d (%s)", status,
			Pa_GetErrorText(status));
		
		[myErrorHandler displayError: _(@"Couldn't open sound input device.")
			withExtraText: [NSString stringWithFormat:
				_(@"PortAudio returned error: %s"),
				Pa_GetErrorText(status)]
			withDefaultButton: _(@"OK")
			withCancelButton: nil isFatal: YES];

		Pa_Terminate();
		return nil;
	}

	return self;
}

@end

int PASamplerCallback(void *inputBuffer, void *outputBuffer,
			unsigned long framesPerBuffer,
			PaTimestamp outTime, void *userData)
{
	return [(PortAudioSampler*)userData processData: inputBuffer
			frameCount: framesPerBuffer];
}

// vim:syn=objc:nocin:si:
