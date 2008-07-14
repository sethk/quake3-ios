/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"iphone_local.h"
#import "../game/q_shared.h"
#import "../qcommon/qcommon.h"

#import	"Q3Application.h"

qboolean
Sys_LowPhysicalMemory(void)
{
	return qtrue;
}

int
main(int ac, char *av[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
#ifdef IPHONE_SIMUL
	[[Q3Application sharedApplication] setDelegate:NSApp];
	NSApplicationMain(ac, av);
#else
	UIApplicationMain(ac, av, nil, nil);
#endif // IPHONE_SIMUL

	[pool release];
	return 0;
}
