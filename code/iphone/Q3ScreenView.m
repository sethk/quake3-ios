/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3ScreenView.h"
#import "iphone_local.h"
#ifndef IPHONE_SIMUL
#import	<CoreGraphics/CoreGraphics.h>
#endif // !IPHONE_SIMUL

#include "../game/q_shared.h"
#include "../qcommon/qcommon.h"
#include "../ui/keycodes.h"
#include "../renderer/tr_local.h"

@implementation Q3ScreenView

- initWithFrame:(CGRect)frame
{
#ifdef IPHONE_SIMUL
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, IPHONE_BPP,
		NSOpenGLPFADepthSize, IPHONE_DEPTH_BPP,
		0
	};

	if ((self = [super initWithFrame:NSRectFromCGRect(frame)
						 pixelFormat:[[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease]]))
	{
#else
	if ((self = [super initWithFrame:frame]))
	{
#ifdef TODO_EAGL
#if 0
		NSDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:YES], kCoreSurfaceBufferGlobal,
				@"PurpleGFXMem", kCoreSurfaceBufferMemoryRegion,
				[NSNumber numberWithInt:xres * (bpp >> 3)], kCoreSurfaceBufferPitch,
				[NSNumber numberWithInt:xres], kCoreSurfaceBufferWidth,
				[NSNumber numberWithInt:yres], kCoreSurfaceBufferHeight,
				[NSNumber numberWithInt:format], kCoreSurfaceBufferPixelFormat,
				[NSNumber numberWithInt:xres * yres * (bpp >> 3)], kCoreSurfaceBufferAllocSize,
				nil];

		coreSurface CoreSurfaceBufferCreate((CFDictionaryRef)attrs);
#else
		int xres = frame.size.width, yres = frame.size.height;
		int pitch = xres * 2, allocSize = 2 * xres * yres;
		char *pixelFormat = "565L";
		CFMutableDictionaryRef dict;

		dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal,        kCFBooleanTrue);
		CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,  CFSTR("PurpleGFXMem"));
		CFDictionarySetValue(dict, kCoreSurfaceBufferPitch,         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
		CFDictionarySetValue(dict, kCoreSurfaceBufferWidth,         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &xres));
		CFDictionarySetValue(dict, kCoreSurfaceBufferHeight,        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &yres));
		CFDictionarySetValue(dict, kCoreSurfaceBufferPixelFormat,   CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
		CFDictionarySetValue(dict, kCoreSurfaceBufferAllocSize,     CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize));

		surface = CoreSurfaceBufferCreate(dict);
#endif
		NSAssert(surface, @"Core surface creation failed");

		CoreSurfaceBufferLock(surface, 3);
		LKLayer *layer = [LKLayer new];
		[layer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		[layer setContents:surface];
		[layer setOpaque:YES];
		[[self _layer] addSublayer:layer];
		CoreSurfaceBufferUnlock(surface);
#endif // TODO_EAGL
#endif // IPHONE_SIMUL

		mousePoint = CGPointMake(0, frame.size.height);
		mouseScaleX = 640 / frame.size.width;
		mouseScaleY = 480 / frame.size.height;
	}

	return self;
}

#ifdef IPHONE_SIMUL
- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

#ifdef TODO_TOUCH
- (void)mouseDown:(NSEvent *)theEvent
{
	[self mouseMoved:theEvent];
#else
- (void)mouseDown:(GSEventRef)theEvent
{
	int startCount = GSEventGetDeltaX(theEvent), count = GSEventGetDeltaY(theEvent);

	ri.Printf(PRINT_DEVELOPER, "%s startCount = %d, count = %d\n", __PRETTY_FUNCTION__, startCount, count);
	[self mouseDragged:theEvent];
#endif // IPHONE_SIMUL
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 1, 0, NULL);
}

#ifdef IPHONE_SIMUL
- (void)mouseUp:(NSEvent *)theEvent
#else
- (void)mouseUp:(GSEventRef)theEvent
#endif // IPHONE_SIMUL
{
	ri.Printf(PRINT_DEVELOPER, "%s\n", __PRETTY_FUNCTION__);
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 0, 0, NULL);
}

#ifdef IPHONE_SIMUL
- (void)mouseMoved:(NSEvent *)theEvent
{
	CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);

	point.x = MAX(MIN(point.x, glConfig.vidWidth), 0.0);
	point.y = MAX(MIN(point.y, glConfig.vidHeight), 0.0);
#else
- (void)mouseDragged:(GSEventRef)theEvent
{
	CGPoint point = [self convertPoint:GSEventGetLocationInWindow(theEvent) fromView:nil];
#endif // IPHONE_SIMUL
	int deltaX, deltaY;

	point.x*= mouseScaleX;
	point.y*= mouseScaleY;
	deltaX = point.x - mousePoint.x;
	deltaY = point.y - mousePoint.y;

	ri.Printf(PRINT_DEVELOPER, "%s: deltaX = %d, deltaY = %d\n", __PRETTY_FUNCTION__, deltaX, deltaY);

	if (deltaX || deltaY)
	{
		Sys_QueEvent(Sys_Milliseconds(), SE_MOUSE, deltaX, deltaY, 0, NULL);
		mousePoint = point;
	}
}
#endif // TODO_TOUCH

#ifndef IPHONE_SIMUL
#ifdef TODO_EAGL
- (CoreSurfaceBufferRef)surface
{
	return surface;
}
#endif // TODO_EAGL
#endif // !IPHONE_SIMUL

- (void)drawRect:(CGRect)frame
{
}

@end
