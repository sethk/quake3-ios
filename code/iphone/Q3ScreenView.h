/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	<UIKit/UIView.h>
#import	<OpenGLES/EAGL.h>
#import	<OpenGLES/EAGLDrawable.h>
#import	<OpenGLES/ES1/gl.h>

@interface Q3ScreenView : UIView
{
@protected
	EAGLContext *_context;
	GLuint _frameBuffer;
	GLuint _renderBuffer;
	GLuint _depthBuffer;
	CGPoint _mousePoint;
	NSSize _mouseScale;
}

- initWithFrame:(CGRect)frame;
#ifdef EAGL_TODO
- (CoreSurfaceBufferRef)surface;
#endif // EAGL_TODO

@end
