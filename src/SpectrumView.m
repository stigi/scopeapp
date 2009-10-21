//
//  SpectrumView.m
//  MacCRO X
//
//  Created by Philip Derrin on Sun Jul 14 2002.
//  Copyright (c) 2002, 2003 Philip Derrin.
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
//  $Header: /cvsroot/scopeapp/scopeapp/src/SpectrumView.m,v 1.14 2003/02/20 02:22:58 narge Exp $
//

#import "SpectrumView.h"
#import "ScopeAppDefaults.h"

#include <math.h>

#define kResolutionMenuOffset	9

#ifdef __APPLE__
#include <vecLib/vDSP.h>
#include <vecLib/vfp.h>

void vsqrt(float* data, int count);
#endif

@interface SpectrumView (SpectrumViewInternal)

- recalculateWindowWithSize: (int) length;

@end

@implementation SpectrumView

- (void)awakeFromNib {
	myGain = 1.0;
	myDataWanted[0] = 4096;
	myDataWanted[1] = 4096;
	myXFrom[0] = 1.0;
	myYFrom[0] = 1.0;
	myXFrom[1] = 1.0;
	myYFrom[1] = 1.0;
	myXTo[0] = 0.0;
	myYTo[0] = 0.0;
	myXTo[1] = 0.0;
	myYTo[1] = 0.0;
	myXIsLog = NO;
	myYIsLog = NO;
	myWindowType = eWindowRectangular;
	myShowScales = NO;
	myAccumulatedData[0] = myAccumulatedData[1] = nil;
	myAccumulationCount[0] = myAccumulationCount[1] = -1;
	myWindowFactors = nil;
	mySavedDataLock = [[NSLock alloc] init];
	
	myFFTSetup = vDSP_create_fftsetup(12, kFFTRadix2);

	[super awakeFromNib];
}

- (void) dealloc
{
	[self stopDrawing];
	
	vDSP_destroy_fftsetup(myFFTSetup);

	[mySavedDataLock lock];
	if(myAccumulatedData[0]) { [myAccumulatedData[0] release]; }
	if(myAccumulatedData[1]) { [myAccumulatedData[1] release]; }
	if(myWindowFactors) { [myWindowFactors release]; }
	[mySavedDataLock unlock];

	[mySavedDataLock release];
	
	[super dealloc];
}

-(IBAction) changedDisplaySettings: (id) sender
{
	myShowTime = [myShowTimeCheckbox intValue];
	myShowScales = [myShowScaleCheckbox intValue];
}

-(IBAction) changedFreqScale: (id) sender
{
	if(sender == myFreqResolutionMenu) {
		int log2n, n;
		BOOL wasDrawing;

		log2n = [sender indexOfSelectedItem] + kResolutionMenuOffset;
		n = 1 << log2n;
		
		wasDrawing = [self drawing];
		if(wasDrawing) [self stopDrawing];
		
		myDataWanted[0] = n;
		myDataWanted[1] = n;
		
		vDSP_destroy_fftsetup(myFFTSetup);
		myFFTSetup = vDSP_create_fftsetup(log2n, kFFTRadix2);

		[self recalculateWindowWithSize: n];

		if(wasDrawing) [self startDrawing];
	} else {
		myXFrom[0] = [myFreqFrom floatValue];
		myXTo[0] = [myFreqTo floatValue];
		
		myXFrom[1] = myXFrom[0];
		myXTo[1] = myXTo[0];
		
		if([myFreqIsLogCheckbox state] == NSOnState) {
			myXIsLog = YES;
		} else {
			myXIsLog = NO;
		}
		
		[self updateGrid];
	}
}

-(IBAction) changedVoltScale: (id) sender
{
	float from, to;
	
	if([myAmpUnitsMenu indexOfSelectedItem] == 0) {
		// menu item 0: mV
		from = [myAmpFrom floatValue] / 1000.0;
		to = [myAmpTo floatValue] / 1000.0;
	} else {
		// menu item 1: dBFS
		from = pow(10.0, [myAmpFrom floatValue] / 10.0);
		to = pow(10.0, [myAmpTo floatValue] / 10.0);
	}
	
	myYFrom[0] = myYFrom[1] = from;
	myYTo[0] = myYTo[1] = to;
	
	if([myAmpIsLogCheckbox state] == NSOnState) {
		myYIsLog = YES;
	} else {
		myYIsLog = NO;
	}
	
	[self updateGrid];
}

-(IBAction) changedAccumulationSettings: (id) sender
{
	[mySavedDataLock lock];
	if(sender == myAccumulateReset) {
		myAccumulationCount[0] = 0;
		myAccumulationCount[1] = 0;
	} else if([myAccumulateCheckbox state] == NSOffState) {
		myAccumulationCount[0] = -1;
		myAccumulationCount[1] = -1;
	} else {
		myAccumulationCount[0] = 0;
		myAccumulationCount[1] = 0;
	}
	[mySavedDataLock unlock];
}

-(IBAction) changedWindowingSettings: (id) sender
{
	myWindowType = [myWindowTypeMenu indexOfSelectedItem];

	[mySavedDataLock lock];
	if(myWindowFactors != nil) {
		[myWindowFactors release];
		myWindowFactors = nil;
	}
	[mySavedDataLock unlock];
}

-(NSData*) doRealFFTForData: (NSData*) data
{
#if defined(__APPLE__)
	float *real, *imag;
	float *magnitudes;
	DSPSplitComplex splitdata;
	float scale;
	float temp;
	int length;
	
	length = [data length] / sizeof(float);
	
	// first allocate some temporary space
	real = malloc(sizeof(float) * length / 2);
	imag = malloc(sizeof(float) * length / 2);
	
	// do fft using Apple's vecLib routines
	splitdata.realp = real;
	splitdata.imagp = imag;
	
	// split the data into even-odd array
	vDSP_ctoz((DSPComplex*)[data bytes], 2,
		&splitdata, 1, length / 2);
	
	// run the transform
	vDSP_fft_zrip(myFFTSetup, &splitdata, 1, log2(length), FFT_FORWARD);

	// apply scaling factor
	// I'm not sure that this is correct, but it gives correct results for
	// a wave with a power of 2 number of samples per cycle and
	// approximately correct (better than rectangular window) results for
	// other frequencies.
	scale = 1.0 / myWindowArea;
	vDSP_vsmul(real, 1, &scale, real, 1, length / 2);
	vDSP_vsmul(imag, 1, &scale, imag, 1, length / 2);
	
	// imag[0] really contains real[n/2]. Set it to 0 so it doesn't get in
	// the way when calculating magnitudes.
	temp = imag[0];
	imag[0] = 0.0;
	
	// now calculate the magnitudes.
	magnitudes = malloc((length / 2 + 1) * sizeof(float));
	vDSP_vmul(real, 1, real, 1, real, 1, length / 2);
	vDSP_vmul(imag, 1, imag, 1, imag, 1, length / 2);
	vDSP_vadd(real, 1, imag, 1, magnitudes, 1, length / 2);
	vsqrt(magnitudes, length / 2);
	
	// copy real[n/2] back
	magnitudes[length/2] = temp;
	
	free(real);
	free(imag);
	
	[data release];
	
	return [[NSData alloc] initWithBytesNoCopy: magnitudes 
			length: ((length / 2) + 1) * sizeof(float)
			freeWhenDone: YES];
#else
#error FIXME FFT not implemented on this platform
#endif	
}

-(NSData*) doWindowingOnData: (NSData*) data
{
	float *newData;
	const float *oldData;
	const float *factors;
	int i, count = [data length] / sizeof(float);
	
	if(myWindowFactors == nil ||
		[data length] != [myWindowFactors length])
	{
		[self recalculateWindowWithSize: count];
	}

	if(myWindowType == eWindowRectangular) {
		// take a shortcut...
		return data;
	}

	newData = malloc([data length]);
	oldData = [data bytes];
	factors = [myWindowFactors bytes];

	[mySavedDataLock lock];

#ifdef __APPLE__
#pragma unused(i)
	vDSP_vmul(factors, 1, oldData, 1, newData, 1, count);
#else
	for(i=0; i<count; i++) {
		newData[i] = factors[i] * oldData[i];
	}
#endif
	[mySavedDataLock unlock];
	
	[data release];
	
	return [[NSData alloc] initWithBytesNoCopy: newData
			length: count * sizeof(float) freeWhenDone: YES];
}

-(NSData*) doAccumulationOnData: (NSData*) data fromTrace: (int) trace
{
	if(myAccumulationCount[trace] < 0) {
		return data;
	}

	[mySavedDataLock lock];

	if(myAccumulatedData[trace] == nil ||
		myAccumulationCount[trace] == 0 ||
		[myAccumulatedData[trace] length] != [data length])
	{
		myAccumulationCount[trace] = 1;
		if(myAccumulatedData[trace]) {
			[myAccumulatedData[trace] release];
		}
		myAccumulatedData[trace] = 
			[[NSMutableData alloc] initWithData: data];
	} else {
		float *newData;
		const float *oldData;
		float f;
		int count, i;

		newData = [myAccumulatedData[trace] mutableBytes];
		oldData = [data bytes];
		count = [data length] / sizeof(float);

#ifdef __APPLE__
#pragma unused(i)
		f = myAccumulationCount[trace];
		vDSP_vsmul(newData, 1, &f, newData, 1, count);
		vDSP_vadd(newData, 1, oldData, 1, newData, 1, count);
		f = 1.0 / (float)++myAccumulationCount[trace];
		vDSP_vsmul(newData, 1, &f, newData, 1, count);
#else
#pragma unused(f)
		for(i=0; i<count; i++)
		{
			newData[i] = (oldData[i] +
				(myAccumulationCount[trace] * newData[i]))
				/ (float)(myAccumulationCount[trace] + 1);
		}
		myAccumulationCount[trace]++;
#endif
	}

	[mySavedDataLock unlock];

	[data release];

	return (NSData*)[myAccumulatedData[trace] retain];
}

// FIXME implement this function to set the controls appropriately from
// default / saved values
- (id) updateControls
{
	int i;
	
	// Update the resolutions displayed on the resolution menu
	int oldselection = [myFreqResolutionMenu indexOfSelectedItem];
	[myFreqResolutionMenu removeAllItems];
	for(i=0; i<7; i++) {
		double res;
		int n;
		
		n = 1 << (i + kResolutionMenuOffset);
		res = mySampleRate / n;
		
		[myFreqResolutionMenu addItemWithTitle:
			[NSString stringWithFormat: @"%.2f Hz", res]];
	}
	[myFreqResolutionMenu selectItemAtIndex: oldselection];
	
	[self changedDisplaySettings: self];
	[self changedFreqScale: myFreqResolutionMenu];
	[self changedFreqScale: self];
	[self changedVoltScale: self];
	[self changedAccumulationSettings: self];
	[self changedWindowingSettings: self];
	
	return self;
}

- (id)updateDisplay: (int) inTrace
{
	float curX, curY;
	float xscale, yscale, xoffset, yoffset;
	int i, istart, count;
	NSData* data;
	const float* magnitudes;

	// FIXME implement split-screen display for two channels?
	if(inTrace) return self;

	data = [[NSData alloc] initWithBytesNoCopy: myDisplayData[inTrace]
			length: myDataStored[inTrace] * sizeof(float)
			freeWhenDone: NO];
	data = [self doWindowingOnData: data];
	data = [self doRealFFTForData: data];
	data = [self doAccumulationOnData: data fromTrace: inTrace];
	magnitudes = [data bytes];
	count = [data length] / sizeof(float);

	// calculate the values by which frequency and magnitude must be
	// scaled and offset
	xoffset = -myXFrom[inTrace] * myDataStored[inTrace] / mySampleRate;
	
	if(myXTo[inTrace] - myXFrom[inTrace] <= 0) {
		xscale = 0;
	} else if(myXIsLog) {
		xscale = 1 / log10(myXTo[inTrace] / myXFrom[inTrace]);
		xoffset = -log10(myXFrom[inTrace] * myDataStored[inTrace]
					/ mySampleRate);
	} else {
		xscale = mySampleRate /
			((myXTo[inTrace] - myXFrom[inTrace]) * myDataStored[inTrace]);
	}
	
	yoffset = -myYFrom[inTrace] / myGain;
	
	if(myYTo[inTrace] - myYFrom[inTrace] <= 0) {
		yscale = 0;
	} else if(myYIsLog) {
		yscale = 1 / log10(myYTo[inTrace] / myYFrom[inTrace]);
		yoffset = -log10(myYFrom[inTrace] / myGain);
	} else {
		yscale = myGain / (myYTo[inTrace] - myYFrom[inTrace]);
	}
	
	// calculate the first value to be plotted
	istart = floor(myXFrom[inTrace] * myDataStored[inTrace] / mySampleRate) - 1;
	if (istart < 0) istart = 0;
	
	// FIXME if X is logarithmic, the 0th point will have an x-coordinate of -inf,
	// which Quartz will silently fail to draw.

	[myDisplayLock lock];
	[myTracePaths[inTrace] removeAllPoints];
	
	for(i = istart; i < count; i++) {
		float m = magnitudes[i];
		curX = ((myXIsLog ? log10(i) : i) + xoffset) * xscale;
		curY = ((myYIsLog ? log10(m) : m) + yoffset) * yscale;
		[myTracePaths[inTrace] addPoint: NSMakePoint(curX, curY)];
		// if we've gone past the right-hand edge of the display, stop
		if(curX > 1) { break; }
	}
	
	[myDisplayLock unlock];

	[data release];
	
	return self;
}

-(id) updateGrid
{
	float x, start, finish, offset, offsetPower;
	int i;
	
	[myGridPath removeAllPoints];
	[myGridPath setLineWidth: 0.0];
	
	if(myXIsLog && (myXFrom[0] <= 0 || myXTo[0] <= myXFrom[0])) {
		// scale is invalid; do nothing
	} else if (myXIsLog) {
		start = log10(myXFrom[0]);
		finish = log10(myXTo[0]);
		
		for(offset = floor(start); offset < finish; offset++) {
			for(i = 2; i <= 10; i++) {
				offsetPower = log10(pow(10, offset) * i);
				x = (offsetPower - start) / (finish - start);
				if(x <= 0) continue;
				if(x >= 1) break;
				[myGridPath moveToPoint: NSMakePoint(x, 0)];
				[myGridPath lineToPoint: NSMakePoint(x, 1)];
			}
		}
	} else {
		for(x=0.1; x<1; x+=0.1) {
			[myGridPath moveToPoint: NSMakePoint(x, 0)];
			[myGridPath lineToPoint: NSMakePoint(x, 1)];
		}
	}
	
	if(myYIsLog && (myYFrom[0] <= 0 || myYTo[0] <= myYFrom[0])) {
		// scale is invalid; do nothing
	} else if (myYIsLog) {
		start = log10(myYFrom[0]);
		finish = log10(myYTo[0]);
		
		for(offset = floor(start); offset < finish; offset++) {
			for(i = 1; i <= 10; i++) {
				offsetPower = log10(pow(10, offset) * i);
				x = (offsetPower - start) / (finish - start);
				if(x <= 0) continue;
				if(x >= 1) break;
				[myGridPath moveToPoint: NSMakePoint(0, x)];
				[myGridPath lineToPoint: NSMakePoint(1, x)];
			}
		}
	} else {
		for(x=0.1; x<1; x+=0.1) {
			[myGridPath moveToPoint: NSMakePoint(0, x)];
			[myGridPath lineToPoint: NSMakePoint(1, x)];
		}
	}
	
	return self;
}

-(id) updateCaptions
{
	NSString* xscale;
	NSString* yscale;

	xscale = yscale = @"";

	if(myShowScales) {
		if(!myXIsLog) {
			xscale = [NSString localizedStringWithFormat:
				@"%.4gHz/div", (myXTo[0] - myXFrom[0]) / 10];
		}
		if(!myYIsLog) {
			yscale = [NSString localizedStringWithFormat:
				@"%.4gmV/div", (myYTo[0] - myYFrom[0]) * 100];
		}
	}
	
	[myXScaleCaption setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myYScaleCaption1 setTextColor: 
		[[ScopeAppDefaults sharedInstance] colourForTrace: 0]];
	[myXScaleCaption setStringValue: xscale];
	[myYScaleCaption1 setStringValue: yscale];

	[myYScaleCaption2 setStringValue: @""];
	
	return [super updateCaptions];
}

@end

#ifdef __APPLE__
void vsqrt(float* data, int count)
{
#if __VEC__
	// This code requires compilation with -faltivec
	vector float *vdata;
	while(((unsigned int)data % 16) && count)
	{
		*data = sqrt(*data);
		count--;
		data++;
	}
	vdata = (vector float*)data;
	while(count >= 4)
	{
		*vdata = vsqrtf(*vdata);
		count -= 4;
		vdata++;
	}
	while(count)
	{
		*data = sqrt(*data);
		count--;
		data++;
	}
#else
	int i;
	for(i=0; i<count; i++)
	{
		data[i] = sqrt(data[i]);
	}
#endif
}
#endif

@implementation SpectrumView (SpectrumViewInternal)

- recalculateWindowWithSize: (int) length;
{
	float* data;
	int i;

	if(myWindowFactors != nil) {
		[myWindowFactors release];
	}
	
	if(myWindowType == eWindowRectangular) {
		myWindowFactors = nil;
		myWindowArea = length;
		return self;
	}

	data = malloc(length * sizeof(float));
	myWindowArea = 0;

	switch(myWindowType)
	{
	case eWindowBartlett:
		for(i=0; i<length/2; i++) {
			data[i] = (2.0 * i) / (length - 1);
			myWindowArea += data[i];
		}
		for(i=length/2; i<length; i++) {
			data[i] = (2.0 * (length - i - 1)) / (length - 1);
			myWindowArea += data[i];
		}
		break;
	case eWindowHann:
		for(i=0; i<length; i++) {
			data[i] = 0.5 * (1 - cos(2*M_PI*((float)i / (length - 1))));
			myWindowArea += data[i];
		}
		break;
	case eWindowHamming:
		for(i=0; i<length; i++) {
			data[i] = 0.54 - (0.46*cos(2*M_PI*((float)i / (length - 1))));
			myWindowArea += data[i];
		}
		break;
	case eWindowBlackman:
		for(i=0; i<length; i++) {
			data[i] = 0.42 - (0.5*cos(2*M_PI*((float)i / (length - 1)))) +
				(0.08*cos(4*M_PI*((float)i / (length - 1))));
			myWindowArea += data[i];
		}
		break;
	case eWindowWelch:
		for(i=0; i<length; i++) {
			data[i] = 1 - pow(((float)i - (length/2))/(length/2), 2);
			myWindowArea += data[i];
		}
		break;
	default:	
		NSLog(@"-[SpectrumView recalculateWindowWithSize:]: unknown window type");
		break;
	}

	myWindowFactors = [[NSData alloc] initWithBytesNoCopy: data
		length: length * sizeof(float)
		freeWhenDone: YES];

	return self;
}

@end


// vim:syn=objc:inde=:
