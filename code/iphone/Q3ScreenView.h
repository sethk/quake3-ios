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
	CGSize _mouseScale;
}

- initWithFrame:(CGRect)frame;
@property (assign, readonly, nonatomic) NSUInteger numColorBits;
@property (assign, readonly, nonatomic) NSUInteger numDepthBits;
- (void)swapBuffers;

@end
