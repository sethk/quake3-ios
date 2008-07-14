/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#include	"iphone_local.h"

@class Q3ScreenView;

@interface Q3Application : AppClass
{
@protected
	WindowClass *_window;
	Q3ScreenView *_screenView;
}

@end
