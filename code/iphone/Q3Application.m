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
	[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(_keepAlive:) userInfo:nil repeats:YES];
#else
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_runFrame:) userInfo:nil repeats:YES];
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
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

	if (UIDeviceOrientationIsValidInterfaceOrientation(orientation))
	{
		Q3ScreenView *screenView = self.screenView;
		UIView *superview = screenView.superview;
		CGRect superviewBounds = superview.bounds, frame;

		if (UIDeviceOrientationIsPortrait(orientation))
		{
			frame.size.width = superviewBounds.size.width;
			frame.size.height = frame.size.width * (3 / 4.0);
			frame.origin.x = superviewBounds.origin.x;
			frame.origin.y = (superviewBounds.size.height - frame.size.height) / 2;
		}
		else
			frame = superviewBounds;

		screenView.frame = frame;

		GLimp_SetMode();

		if (cls.uiStarted)
		{
			cls.glconfig = glConfig;
			VM_Call(uivm, UI_UPDATE_GLCONFIG);
		}
		
		if (cls.state == CA_ACTIVE)
		{
			cls.glconfig = glConfig;
			VM_Call(cgvm, CG_UPDATE_GLCONFIG);
		}
	}
}

#ifdef IPHONE_USE_THREADS
- (void)_runMainLoop:(id)context
{
	while (1)
		Com_Frame();
}

- (void)_keepAlive:(NSTimer *)timer
{
	NSLog(@"keepAlive:");
}

#else

- (void)_runFrame:(NSTimer *)timer
{
	Com_Frame();
}
#endif // IPHONE_USE_THREADS

@synthesize screenView = _screenView;

@end
