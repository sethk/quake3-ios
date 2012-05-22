/*
 * Quake3 -- iOS Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3ScreenView.h"
#import "ios_local.h"
#import	<QuartzCore/QuartzCore.h>
#import	<OpenGLES/ES1/glext.h>
#import	<UIKit/UITouch.h>
#import <UIKit/UIImageView.h>

#include "../ui/keycodes.h"
#include "../renderer/tr_local.h"
#include "../client/client.h"

#define kColorFormat  kEAGLColorFormatRGB565
#define kNumColorBits 16
#define kDepthFormat  GL_DEPTH_COMPONENT16_OES
#define kNumDepthBits 16

@implementation Q3ScreenView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}


- (void)_mainGameLoop
{
	CGPoint newLocation = CGPointMake(_oldLocation.x - _distanceFromCenter/4 * cosf(_touchAngle),
			_oldLocation.y - _distanceFromCenter/4 * sinf(_touchAngle));
	CGSize mouseDelta;
	mouseDelta.width = roundf((_oldLocation.y - newLocation.y) * _mouseScale.x);
	mouseDelta.height = roundf((newLocation.x - _oldLocation.x) * _mouseScale.y);

	//Sys_QueEvent(Sys_Milliseconds(), SE_MOUSE, mouseDelta.width, mouseDelta.height, 0, NULL);
	//_oldLocation = newLocation;
	//Com_Printf("%f\n", mouseDelta.width);

	if (_distanceFromCenter > 30)
	{
		if (mouseDelta.height < -10)
		{
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_UPARROW, 1, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_DOWNARROW, 0, 0, NULL);
			//Com_Printf("%f\n", mouseDelta.height);
		}
		else if (mouseDelta.height > 10)
		{
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_UPARROW, 0, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_DOWNARROW, 1, 0, NULL);
			//Com_Printf("Back: %f\n", mouseDelta.height);
		}
		else
		{
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_UPARROW, 0, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_DOWNARROW, 0, 0, NULL);
		}

		if (mouseDelta.width < -25)
		{
			//Com_Printf("Left: %f\n", mouseDelta.width);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'a', 1, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'd', 0, 0, NULL);
		}
		else if (mouseDelta.width > 25)
		{
			//Com_Printf("Right: %f\n", mouseDelta.width);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'a', 0, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'd', 1, 0, NULL);
		}
		else
		{
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'a', 0, 0, NULL);
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'd', 0, 0, NULL);
		}
	}
	else
	{
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_UPARROW, 0, 0, NULL);
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_DOWNARROW, 0, 0, NULL);
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'a', 0, 0, NULL);
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, 'd', 0, 0, NULL);
	}
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

	[self setMultipleTouchEnabled:YES];

	_GUIMouseLocation = CGPointMake(0, 0);

	_gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60
												  target:self
												selector:@selector(_mainGameLoop)
												userInfo:nil
												 repeats:YES];

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

- (void)awakeFromNib
{
	CGRect newControlFrame = [_newControlView frame];
	_shootButtonArea = CGRectMake(CGRectGetMinX(newControlFrame) + 4, CGRectGetMinY(newControlFrame) + 40, 68, 68);

	CGRect joypadCapFrame = [joypadCap frame];
	_joypadArea = CGRectMake(CGRectGetMinX(joypadCapFrame), CGRectGetMinY(joypadCapFrame), 250, 250);
	joypadCenterx = CGRectGetMidX(joypadCapFrame);
	joypadCentery = CGRectGetMidY(joypadCapFrame);
	joypadMaxRadius = 60;
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

- (void)_handleMenuDragToPoint:(CGPoint)point
{
	CGPoint mouseLocation, GUIMouseLocation;
	int deltaX, deltaY;

	if (glConfig.vidRotation == 90)
	{
		mouseLocation.x = _size.height - point.y;
		mouseLocation.y = point.x;
	}
	else if (glConfig.vidRotation == 0)
	{
		mouseLocation.x = point.x;
		mouseLocation.y = point.y;
	}
	else if (glConfig.vidRotation == 270)
	{
		mouseLocation.x = point.y;
		mouseLocation.y = _size.width - point.x;
	}
	else
	{
		mouseLocation.x = _size.width - point.x;
		mouseLocation.y = _size.height - point.y;
	}

	GUIMouseLocation.x = roundf(_GUIMouseOffset.width + mouseLocation.x * _mouseScale.x);
	GUIMouseLocation.y = roundf(_GUIMouseOffset.height + mouseLocation.y * _mouseScale.y);

	GUIMouseLocation.x = MIN(MAX(GUIMouseLocation.x, 0), 640);
	GUIMouseLocation.y = MIN(MAX(GUIMouseLocation.y, 0), 480);

	deltaX = GUIMouseLocation.x - _GUIMouseLocation.x;
	deltaY = GUIMouseLocation.y - _GUIMouseLocation.y;
	_GUIMouseLocation = GUIMouseLocation;

	ri.Printf(PRINT_DEVELOPER, "%s: deltaX = %d, deltaY = %d\n", __PRETTY_FUNCTION__, deltaX, deltaY);
	if (deltaX || deltaY)
		Sys_QueEvent(0, SE_MOUSE, deltaX, deltaY, 0, NULL);
}

- (void)_reCenter {
	
	if(!_isLooking) {
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_END, 1, 0, NULL);
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_END, 0, 0, NULL);
	}
}

// handleDragFromPoint rotates the camera based on a touchedMoved event
- (void)_handleDragFromPoint:(CGPoint)location toPoint:(CGPoint)previousLocation
{
	if (glConfig.vidRotation == 90)
	{
		CGSize mouseDelta;

		mouseDelta.width = roundf((previousLocation.y - location.y) * _mouseScale.x);
		mouseDelta.height = roundf((location.x - previousLocation.x) * _mouseScale.y);

		Sys_QueEvent(Sys_Milliseconds(), SE_MOUSE, mouseDelta.width, mouseDelta.height, 0, NULL);
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.keyCatchers == 0)
	{
		for (UITouch *touch in touches)
		{
			CGPoint touchLocation = [touch locationInView:self];

			if (CGRectContainsPoint(_joypadArea, touchLocation) && !_isJoypadMoving)
			{
				_isJoypadMoving = YES;
				joypadTouchHash = [touch hash];
			}
			else if (CGRectContainsPoint(_shootButtonArea, touchLocation) && !_isShooting)
			{
				_isShooting = YES;
				_isLooking = YES;
				Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 1, 0, NULL);
				[self _handleMenuDragToPoint:[touch locationInView:self]];
			}
			else
			{
				_isLooking = YES;
				[self _handleMenuDragToPoint:[touch locationInView:self]];
			}
		}
	}
	else
	{
		for (UITouch *touch in touches)
		{
			if (_numTouches == 0)
				[self _handleMenuDragToPoint:[touch locationInView:self]];

			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1 + _numTouches++, 1, 0, NULL);
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.keyCatchers == 0)
	{
		for (UITouch *touch in touches)
		{
			if ([touch hash] == joypadTouchHash && _isJoypadMoving)
			{
				CGPoint touchLocation = [touch locationInView:self];
				float dx = (float)joypadCenterx - (float)touchLocation.x;
				float dy = (float)joypadCentery - (float)touchLocation.y;

				_distanceFromCenter = sqrtf((joypadCenterx - touchLocation.x) * (joypadCenterx - touchLocation.x) + 
						(joypadCentery - touchLocation.y) * (joypadCentery - touchLocation.y));
				_touchAngle = atan2(dy, dx);

				if (_distanceFromCenter > joypadMaxRadius)
					joypadCap.center = CGPointMake(joypadCenterx - cosf(_touchAngle) * joypadMaxRadius, 
												   joypadCentery - sinf(_touchAngle) * joypadMaxRadius);

				else
					joypadCap.center = touchLocation;
			}
			else
				[self _handleDragFromPoint:[touch previousLocationInView:self]
								   toPoint:[touch locationInView:self]];
		}
	}
	else
		// TODO: Find the touch that started first.
		[self _handleMenuDragToPoint:[[touches anyObject] locationInView:self]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.keyCatchers == 0)
	{
		for (UITouch *touch in touches)
		{
			if ([touch hash] == joypadTouchHash)
			{
				_isJoypadMoving = NO;
				joypadTouchHash = 0;
				_distanceFromCenter = 0;
				_touchAngle = 0;
				joypadCap.center = CGPointMake(joypadCenterx, joypadCentery);
			}
			else
			{
				_isShooting = NO;
				Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 0, 0, NULL);
				_isLooking = NO;
				[NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(_reCenter) userInfo:nil repeats:NO];
			}
		}
	}
	else
		for (UITouch *touch in touches)
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1 + _numTouches--, 0, 0, NULL);
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

- (IBAction)startJumping:(id)sender
{
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_SPACE, 1, 0, NULL);
}

- (IBAction)stopJumping:(id)sender
{
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_SPACE, 0, 0, NULL);
}

- (IBAction)changeWeapon:(id)sender
{
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, '/', 1, 0, NULL);
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, '/', 0, 0, NULL);
}

- (IBAction)escape:(id)sender
{
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_ESCAPE, 1, 0, NULL);
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_ESCAPE, 0, 0, NULL);
}

- (IBAction)enter:(id)sender
{
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_ENTER, 1, 0, NULL);
	Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_ENTER, 0, 0, NULL);
}

@end
