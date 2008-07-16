/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3Application.h"
#import	"Q3ScreenView.h"
#include "iphone_local.h"
#include "../renderer/tr_local.h"

@interface Q3Application ()

- (void)_runMainLoop:(id)context;
- (void)_runFrame:(NSTimer *)timer;

@end

@implementation Q3Application

- (void)applicationDidFinishLaunching:(id)unused
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

#if IPHONE_USE_THREADS
	Com_Printf("Starting render thread...\n");

	[NSThread detachNewThreadSelector:@selector(_runMainLoop:) toTarget:self withObject:nil];
#else
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_runFrame:) userInfo:nil repeats:YES];
#endif // IPHONE_USE_THREADS
}

- (void)_runMainLoop:(id)context
{
	while (1)
		Com_Frame();
}

- (void)_runFrame:(NSTimer *)timer
{
	Com_Frame();
}

@synthesize screenView = _screenView;

@end
