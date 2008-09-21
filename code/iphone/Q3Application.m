/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3Application.h"
#import	"Q3ScreenView.h"
#include "iphone_local.h"
#include "../renderer/tr_local.h"
#include "../client/client.h"

@interface Q3Application ()

- (void)_quakeMain;
- (void)_deviceOrientationChanged:(NSNotification *)notification;
#ifdef IPHONE_USE_THREADS
- (void)_runMainLoop:(id)context;
- (void)keepAlive:(NSTimer *)timer;
#else
- (void)_runFrame:(NSTimer *)timer;
#endif // !IPHONE_USE_THREADS

@end

@implementation Q3Application

- (void)_quakeMain
{
	extern void Sys_Startup(int argc, char *argv[]);
	extern cvar_t *com_maxfps;
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	int ac, i;
	const char *av[32];

	ac = MIN([arguments count], sizeof(av) / sizeof(av[0]));
	for (i = 0; i < ac; ++i)
		av[i] = [[arguments objectAtIndex:i] cString];

	Sys_Startup(ac, (char **)av);

	[_loadingView removeFromSuperview];
	_screenView.isHidden = NO;

#if IPHONE_USE_THREADS
	Com_Printf("Starting render thread...\n");

	GLimp_ReleaseGL();

	[NSThread detachNewThreadSelector:@selector(_runMainLoop:) toTarget:self withObject:nil];
#else
	[NSTimer scheduledTimerWithTimeInterval:1.0 / com_maxfps->integer
									 target:self
								   selector:@selector(_runFrame:)
								   userInfo:nil
									repeats:YES];
#endif // IPHONE_USE_THREADS
}

- (void)applicationDidFinishLaunching:(id)unused
{
	UIDevice *device = [UIDevice currentDevice];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_deviceOrientationChanged:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:device];
	[device beginGeneratingDeviceOrientationNotifications];

	[self performSelector:@selector(_quakeMain) withObject:nil afterDelay:0.0];
}

- (void)_deviceOrientationChanged:(NSNotification *)notification
{
	// Keep the orientation locked into landscape while in-game:
	if (cls.state == CA_DISCONNECTED)
	{
		UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

		if (UIDeviceOrientationIsValidInterfaceOrientation(orientation))
			GLimp_SetMode(self.deviceRotation);
	}
}

#ifdef IPHONE_USE_THREADS
- (void)_runMainLoop:(id)context
{
	while (1)
		Com_Frame();
}
#else
- (void)_runFrame:(NSTimer *)timer
{
	Com_Frame();
}
#endif // IPHONE_USE_THREADS

@synthesize screenView = _screenView;

@dynamic deviceRotation;

- (float)deviceRotation
{
 	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

	if (!UIDeviceOrientationIsValidInterfaceOrientation(orientation))
		orientation = UIDeviceOrientationPortrait;

 	switch (orientation)
 	{
 		case UIDeviceOrientationPortrait: return 0.0;
 		case UIDeviceOrientationLandscapeRight: return 90.0;
 		case UIDeviceOrientationPortraitUpsideDown: return 180.0;
 		case UIDeviceOrientationLandscapeLeft: return 270.0;
		default: NSAssert(NO, @"Grievous errors have been made..."); return 0;
 	}
}

@end
