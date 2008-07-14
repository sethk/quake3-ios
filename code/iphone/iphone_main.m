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
	UIApplicationMain(ac, av, nil, nil);

	[pool release];
	return 0;
}
