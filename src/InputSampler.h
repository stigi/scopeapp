//
//  InputSampler.h
//  MacCRO X
//
//  Created by narge on Mon Nov 26 2001.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/InputSampler.h,v 1.7 2003/04/25 07:23:50 narge Exp $
//

#import <Foundation/Foundation.h>

typedef float Sample;

// **********
// Protocol for an object which handles sampled sound data
// **********
@protocol InputHandler

// Process the given blocks of data from the given input sampler.
// inData points to an interleaved array of Samples.
// Warning: this function must be thread-safe, as it may be called from
// the sampler's thread.
-(id) processData: (Sample*) inData
		length: (unsigned long) frameCount
		channels: (int) channelCount
		rate: (float) sampleRate
		fromSampler: (id) sampler;

@end

@protocol InputErrorHandler

// Display an alert when the InputSampler has encountered an error.
// If fatal, the InputHandler should destroy the InputSampler and exit
// when the error has finished displaying.
-(int) displayError: (NSString*) title
	withExtraText: (NSString*) subtitle
	withDefaultButton: (NSString*) defaultButton
	withCancelButton: (NSString*) cancelButton
	isFatal: (BOOL) fatal;

@end

// **********
// Protocol for an object which samples sound data
// **********
@protocol InputSampler

// init a sampler with a given owner object, and an object which handles errors
-(id) initWithOwner: (id <InputHandler, NSObject>) owner
	withErrorHandler: (id <InputErrorHandler, NSObject>) errorHandler;

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
-(id) setOwner: (id <InputHandler, NSObject>) owner;

// request a specific block size
-(id) requestBlockSize: (unsigned long)size;

// get the actual block size
-(unsigned long) blockSize;

// return true if the sampler is currently sampling data
-(BOOL) isSampling;

// return the sample rate
-(float) sampleRate;

// return the number of channels in the input data
-(char) channelCount;

@end

// Create a new input sampler with the best available source
id <InputSampler, NSObject> NewSamplerWithBestSource();

// vim:syn=objc:nocin:si:
