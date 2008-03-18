/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#ifdef IPHONE_SIMUL
#import	<Cocoa/Cocoa.h>
#else
#import	<UIKit/UIView.h>
#import	<CoreSurface/CoreSurface.h>
#endif // IPHONE_SIMUL

#ifdef IPHONE_SIMUL
@interface Q3ScreenView : NSOpenGLView
{
@protected
#else
@interface Q3ScreenView : UIView
{
@protected
	CoreSurfaceBufferRef surface;
#endif // !IPHONE_SIMUL
	CGPoint mousePoint;
	float mouseScaleX, mouseScaleY;
}

- initWithFrame:(CGRect)frame;
#ifndef IPHONE_SIMUL
- (CoreSurfaceBufferRef)surface;
#endif // !IPHONE_SIMUL

@end
