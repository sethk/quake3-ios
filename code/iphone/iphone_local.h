/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#ifndef IPHONE_LOCAL_H
#define IPHONE_LOCAL_H

#include <stdio.h>

#define UNIMPL()	Com_Printf("%s(): Unimplemented\n", __FUNCTION__)

#define IPHONE_XRES			320
#define IPHONE_VERT_YRES	220
#define IPHONE_HORIZ_YRES	480
#define IPHONE_BPP			16
#define IPHONE_DEPTH_BPP	16
#define IPHONE_PIXEL_FORMAT	('5' << 24 | '6' << 16 | '5' << 8 | 'L')

#ifdef IPHONE_SIMUL
#import	<Cocoa/Cocoa.h>

#define AppClass NSApplication
#define App NSApp
#define WindowClass NSWindow
#else
#import	<UIKit/UIKit.h>

#define AppClass UIApplication
#define App UIApp
#define WindowClass UIWindow
#endif // IPHONE_SIMUL

void GLimp_SetMode(void);
void GLimp_ReleaseGL(void);

#endif // IPHONE_LOCAL_H
