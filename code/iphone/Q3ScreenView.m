/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3ScreenView.h"
#import "iphone_local.h"
#import	<QuartzCore/QuartzCore.h>
#import	<OpenGLES/ES1/glext.h>
#import	<UIKit/UITouch.h>

#include "../ui/keycodes.h"
#include "../renderer/tr_local.h"

#define kColorFormat  kEAGLColorFormatRGB565
#define kNumColorBits 16
#define kDepthFormat  GL_DEPTH_COMPONENT16_OES
#define kNumDepthBits 16

@interface Q3ScreenView ()

- (BOOL)_commonInit;
- (BOOL)_createSurface;
- (void)_destroySurface;
- (void)_moveMouseWithTouch:(UITouch *)touch;

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

	_mousePoint = CGPointMake(20, frame.size.height - 20);
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

- (void)_moveMouseWithTouch:(UITouch *)touch
{
	CGPoint point = [touch locationInView:self];
	CGRect bounds = self.bounds;
	int deltaX, deltaY;

	point.x = MIN(MAX(point.x, bounds.origin.x), bounds.origin.x + bounds.size.width);
	point.y = MIN(MAX(point.y, bounds.origin.y), bounds.origin.y + bounds.size.height);

	point.x = roundf(point.x * _mouseScale.width);
	point.y = roundf(point.y * _mouseScale.height);

	deltaX = point.x - _mousePoint.x;
	deltaY = point.y - _mousePoint.y;

	ri.Printf(PRINT_DEVELOPER, "%s: deltaX = %d, deltaY = %d\n", __PRETTY_FUNCTION__, deltaX, deltaY);

	if (deltaX || deltaY)
	{
		Sys_QueEvent(0, SE_MOUSE, deltaX, deltaY, 0, NULL);
		_mousePoint = point;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _moveMouseWithTouch:[touches anyObject]];
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 1, 0, NULL);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _moveMouseWithTouch:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _moveMouseWithTouch:[touches anyObject]];
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 0, 0, NULL);
}

@dynamic numColorBits;
	
- (NSUInteger)numColorBits
{
	return kNumColorBits;
}

- (NSUInteger)numDepthBits
{
	return kNumDepthBits;
}

- (void)swapBuffers
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	GLuint oldRenderBuffer;

	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];

	qglGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *)&oldRenderBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderBuffer);

	if (![_context presentRenderbuffer:GL_RENDERBUFFER_OES])
		NSLog(@"Failed to swap renderbuffer");

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

@end
