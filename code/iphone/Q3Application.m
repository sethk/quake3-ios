/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3Application.h"
#import	"Q3ScreenView.h"
#include "iphone_local.h"
#include "../renderer/tr_local.h"

@implementation Q3Application

- (void)dealloc
{
	[window release];

	[super dealloc];
}

- (void)applicationDidFinishLaunching:(id)unused
{
	[self createWindow];
	[self startQuake];
}

#ifdef DEBUG_KEEPALIVE
- (void)_keepalive:(NSTimer *)timer
{
	fprintf(stderr, "Keepalive...\n");
}
#endif // DEBUG_KEEPALIVE

- (void)createWindow
{
#ifdef IPHONE_SIMUL
	NSRect screenRect = NSMakeRect(100, 100, IPHONE_XRES, IPHONE_VERT_YRES);
	unsigned styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;

	window = [[NSWindow alloc] initWithContentRect:screenRect
										 styleMask:styleMask
										   backing:NSBackingStoreRetained
											 defer:NO];
	screenView = [[[Q3ScreenView alloc] initWithFrame:screenRect] autorelease];
	[window setTitle:@"Quake 3"];
	[window setAcceptsMouseMovedEvents:YES];
#else
	CGRect screenRect = CGRectMake(0, 0, IPHONE_XRES, IPHONE_VERT_YRES);

	[UIApplication sharedApplication].statusBarHidden = YES;

	window = [[UIWindow alloc] initWithFrame:screenRect];
	screenView = [[[Q3ScreenView alloc] initWithFrame:screenRect] autorelease];
#endif // IPHONE_SIMUL
	[window addSubview:screenView];
	[window makeKeyAndVisible];
}

- (void)_runMainLoop
{
	while (1)
		Com_Frame();
}

- (void)startQuake
{
	extern void Sys_Startup(int argc, char *argv[]);
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	int ac, i;
	const char *av[32];

	ac = MIN([arguments count], sizeof(av) / sizeof(av[0]));
	for (i = 0; i < ac; ++i)
		av[i] = [[arguments objectAtIndex:i] cString];

	Sys_Startup(ac, (char **)av);

	GLimp_ReleaseGL();

#ifdef DEBUG_KEEPALIVE
	[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_keepalive:) userInfo:nil repeats:YES];
#endif // DEBUG_KEEPALIVE

	Com_Printf("Starting render thread...\n");

	[NSThread detachNewThreadSelector:@selector(_runMainLoop) toTarget:self withObject:nil];
}

- (Q3ScreenView *)screenView
{
	return screenView;
}

@end
