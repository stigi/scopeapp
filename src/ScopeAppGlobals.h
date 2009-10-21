/*
 *  ScopeAppGlobals.h
 *  MacCRO X
 *
 *  Created by Philip Derrin on Fri Jul 19 2002.
 *  Copyright (c) 2002 Philip Derrin. All rights reserved.
 *
 */

// Macro to use on strings which can be localised
// Based on similar macro from GNUMail
// Strings labelled this way are easy to find using
// a perl script, to auto-generate  Localizable.strings
#define _(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:key table:nil]

// vim:syn=objc:nocin:si:
