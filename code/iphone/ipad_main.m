/*
 *
 * Quake3Arena iPad Port by Alexander Pick
 * based on iPhone Quake 3 by Seth Kingsley
 *
 */

#import	"ipad_local.h"

#import	"Q3Application.h"

qboolean
Sys_LowPhysicalMemory(void)
{
	return qtrue;
}

void
Sys_Error(const char *error, ...)
{
	NSString *errorString;
	va_list ap;

	va_start(ap, error);
	errorString = [[[NSString alloc] initWithFormat:[NSString stringWithCString:error encoding:NSUTF8StringEncoding]
																				arguments:ap] autorelease];
	va_end(ap);
#ifdef IPHONE_USE_THREADS
	[[Q3Application sharedApplication] performSelectorOnMainThread:@selector(presentErrorMessage:)
																											withObject:errorString
																									 waitUntilDone:YES];
#else
	[(Q3Application *)[Q3Application sharedApplication] presentErrorMessage:errorString];
#endif // IPHONE_USE_THREADS
}

void
Sys_Warn( const char *warning, ...)
{
	NSString *warningString;
	va_list ap;

	va_start(ap, warning);
	warningString = [[[NSString alloc] initWithFormat:[NSString stringWithCString:warning encoding:NSUTF8StringEncoding]
																					arguments:ap] autorelease];
	va_end(ap);
#ifdef IPHONE_USE_THREADS
	[[Q3Application sharedApplication] performSelectorOnMainThread:@selector(presentWarningMessage:)
																											withObject:warningString
																									 waitUntilDone:YES];
#else
	[(Q3Application *)[Q3Application sharedApplication] presentWarningMessage:warningString];
#endif // IPHONE_USE_THREADS
}

void applicationDidFinishLaunching(id unused)
{
	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
	
}

int
main(int ac, char *av[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	[[Q3Application sharedApplication] setPriority:1.0];
	
	UIApplicationMain(ac, av, nil, nil);

	[pool release];
	return 0;
}
