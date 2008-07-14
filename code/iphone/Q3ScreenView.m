/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3ScreenView.h"
#import "iphone_local.h"
#import	<QuartzCore/QuartzCore.h>
#import	<OpenGLES/ES1/glext.h>

#include "../game/q_shared.h"
#include "../qcommon/qcommon.h"
#include "../ui/keycodes.h"
#include "../renderer/tr_local.h"

#define kColorFormat kEAGLColorFormatRGB565
#define kDepthFormat GL_DEPTH_COMPONENT16_OES

@interface Q3ScreenView ()

- (BOOL)_commonInit;
- (BOOL)_createSurface;
- (void)_destroySurface;

@end

@implementation Q3ScreenView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (BOOL)_commonInit
{
	CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
	CGRect frame = self.frame;

	[layer setDrawableProperties:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
			kColorFormat, kEAGLDrawablePropertyColorFormat,
			nil]];

	if (!(_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1]))
		return NO;

	if (![self _createSurface])
		return NO;

	_mousePoint = CGPointMake(0, frame.size.height);
	_mouseScale.width = 640 / frame.size.width;
	_mouseScale.height = 480 / frame.size.height;

	return YES;
}

- initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder]))
	{
		if (![self _commonInit])
		{
			[self release];
			return nil;
		}
	}

	return self;
}

- initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		if (![self _commonInit])
		{
			[self release];
			return nil;
		}
	}

	return self;
}

- (void)dealloc
{
	[self _destroySurface];

	[_context release];

	[super dealloc];
}

- (BOOL)_createSurface
{
	CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
	GLint oldFrameBuffer, oldRenderBuffer;
	CGSize size;

	if (![EAGLContext setCurrentContext:_context])
		return NO;

	size = layer.bounds.size;
	size.width = roundf(size.width);
	size.height = roundf(size.height);

	qglGetIntegerv(GL_RENDERBUFFER_BINDING_OES, &oldRenderBuffer);
	qglGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFrameBuffer);

	glGenRenderbuffersOES(1, &_renderBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderBuffer);

	if (![_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer])
	{
		glDeleteRenderbuffersOES(1, &_renderBuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_BINDING_OES, oldRenderBuffer);
		return NO;
	}

	glGenFramebuffersOES(1, &_frameBuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderBuffer);
	glGenRenderbuffersOES(1, &_depthBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, kDepthFormat, size.width, size.height);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthBuffer);

	glBindRenderbufferOES(GL_FRAMEBUFFER_OES, oldFrameBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, oldRenderBuffer);

	return YES;
}

- (void)_destroySurface
{
	//EAGLContext *oldContext = [EAGLContext currentContext];
}

#ifdef IPHONE_SIMUL
- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

#ifdef TODO_TOUCH
- (void)mouseDown:(NSEvent *)theEvent
{
	[self mouseMoved:theEvent];
#else
- (void)mouseDown:(GSEventRef)theEvent
{
	int startCount = GSEventGetDeltaX(theEvent), count = GSEventGetDeltaY(theEvent);

	ri.Printf(PRINT_DEVELOPER, "%s startCount = %d, count = %d\n", __PRETTY_FUNCTION__, startCount, count);
	[self mouseDragged:theEvent];
#endif // IPHONE_SIMUL
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 1, 0, NULL);
}

#ifdef IPHONE_SIMUL
- (void)mouseUp:(NSEvent *)theEvent
#else
- (void)mouseUp:(GSEventRef)theEvent
#endif // IPHONE_SIMUL
{
	ri.Printf(PRINT_DEVELOPER, "%s\n", __PRETTY_FUNCTION__);
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 0, 0, NULL);
}

#ifdef IPHONE_SIMUL
- (void)mouseMoved:(NSEvent *)theEvent
{
	CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);

	point.x = MAX(MIN(point.x, glConfig.vidWidth), 0.0);
	point.y = MAX(MIN(point.y, glConfig.vidHeight), 0.0);
#else
- (void)mouseDragged:(GSEventRef)theEvent
{
	CGPoint point = [self convertPoint:GSEventGetLocationInWindow(theEvent) fromView:nil];
#endif // IPHONE_SIMUL
	int deltaX, deltaY;

	point.x*= mouseScaleX;
	point.y*= mouseScaleY;
	deltaX = point.x - mousePoint.x;
	deltaY = point.y - mousePoint.y;

	ri.Printf(PRINT_DEVELOPER, "%s: deltaX = %d, deltaY = %d\n", __PRETTY_FUNCTION__, deltaX, deltaY);

	if (deltaX || deltaY)
	{
		Sys_QueEvent(Sys_Milliseconds(), SE_MOUSE, deltaX, deltaY, 0, NULL);
		mousePoint = point;
	}
}
#endif // TODO_TOUCH

#ifndef IPHONE_SIMUL
#ifdef TODO_EAGL
- (CoreSurfaceBufferRef)surface
{
	return surface;
}
#endif // TODO_EAGL
#endif // !IPHONE_SIMUL

- (void)drawRect:(CGRect)frame
{
}

@end
