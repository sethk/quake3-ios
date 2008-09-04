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
#include "../client/client.h"

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

	[layer setDrawableProperties:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
			kColorFormat, kEAGLDrawablePropertyColorFormat,
			nil]];

	if (!(_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1]))
		return NO;

	if (![self _createSurface])
		return NO;

	_GUIMouseLocation = CGPointMake(0, 0);

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

	if (![EAGLContext setCurrentContext:_context])
		return NO;

	_size = layer.bounds.size;
	_size.width = roundf(_size.width);
	_size.height = roundf(_size.height);
	if (_size.width > _size.height)
	{
		_GUIMouseOffset.width = _GUIMouseOffset.height = 0;
		_mouseScale.x = 640 / _size.width;
		_mouseScale.y = 480 / _size.height;
	}
	else
	{
		float aspect = _size.height / _size.width;

		_GUIMouseOffset.width = -roundf((480 * aspect - 640) / 2.0);
		_GUIMouseOffset.height = 0;
		_mouseScale.x = (480 * aspect) / _size.height;
		_mouseScale.y = 480 / _size.width;
	}

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
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, kDepthFormat, _size.width, _size.height);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthBuffer);

	glBindRenderbufferOES(GL_FRAMEBUFFER_OES, oldFrameBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, oldRenderBuffer);

	return YES;
}

- (void)_destroySurface
{
	EAGLContext *oldContext = [EAGLContext currentContext];

	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];

	glDeleteRenderbuffersOES(1, &_depthBuffer);
	glDeleteRenderbuffersOES(1, &_renderBuffer);
	glDeleteFramebuffersOES(1, &_frameBuffer);

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

- (void)layoutSubviews
{
	CGSize boundsSize = self.bounds.size;

	if (roundf(boundsSize.width) != _size.width || roundf(boundsSize.height) != _size.height)
	{
		[self _destroySurface];
		[self _createSurface];
	}
}

- (void)_moveMouseWithTouch:(UITouch *)touch
{
	if (cls.state == CA_ACTIVE || cls.state == CA_DISCONNECTED)
	{
		CGPoint location = [touch locationInView:self];
		int deltaX, deltaY;

		if (cls.state == CA_ACTIVE)
		{
			CGPoint previousLocation = [touch previousLocationInView:self];
			CGSize mouseDelta;

			if (glConfig.vidRotation == 90)
			{
				mouseDelta.width = previousLocation.y - location.y;
				mouseDelta.height = location.x - previousLocation.x;
			}
			else if (glConfig.vidRotation == 0)
			{
				mouseDelta.width = location.x - previousLocation.x;
				mouseDelta.height = location.y - previousLocation.y;
			}
			else if (glConfig.vidRotation == 270)
			{
				mouseDelta.width = location.y - previousLocation.y;
				mouseDelta.height = previousLocation.x - location.x;
			}
			else
			{
				mouseDelta.width = previousLocation.x - location.x;
				mouseDelta.height = previousLocation.y - location.y;
			}

			deltaX = roundf(mouseDelta.width * _mouseScale.x);
			deltaY = roundf(mouseDelta.height * _mouseScale.y);
		}
		else if (cls.state == CA_DISCONNECTED)
		{
			CGPoint mouseLocation, GUIMouseLocation;

			if (glConfig.vidRotation == 90)
			{
				mouseLocation.x = _size.height - location.y;
				mouseLocation.y = location.x;
			}
			else if (glConfig.vidRotation == 0)
			{
				mouseLocation.x = location.x;
				mouseLocation.y = location.y;
			}
			else if (glConfig.vidRotation == 270)
			{
				mouseLocation.x = location.y;
				mouseLocation.y = _size.width - location.x;
			}
			else
			{
				mouseLocation.x = _size.width - location.x;
				mouseLocation.y = _size.height - location.y;
			}

			GUIMouseLocation.x = roundf(_GUIMouseOffset.width + mouseLocation.x * _mouseScale.x);
			GUIMouseLocation.y = roundf(_GUIMouseOffset.height + mouseLocation.y * _mouseScale.y);

			GUIMouseLocation.x = MIN(MAX(GUIMouseLocation.x, 0), 640);
			GUIMouseLocation.y = MIN(MAX(GUIMouseLocation.y, 0), 480);

			deltaX = GUIMouseLocation.x - _GUIMouseLocation.x;
			deltaY = GUIMouseLocation.y - _GUIMouseLocation.y;
			_GUIMouseLocation = GUIMouseLocation;
		}

		ri.Printf(PRINT_DEVELOPER, "%s: deltaX = %d, deltaY = %d\n", __PRETTY_FUNCTION__, deltaX, deltaY);
		if (deltaX || deltaY)
			Sys_QueEvent(0, SE_MOUSE, deltaX, deltaY, 0, NULL);
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.state == CA_DISCONNECTED)
		// Warp the pointer if in the GUI:
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

@synthesize context = _context;

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
