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

#define kAccelerometerFrequency		60.0 //Hz

// the fire key is in the lower right corner
#define EVENTREGIONFIRE(location) (location.x >= 280 && location.y <=40)

// the four rectangular 40x40 areas are located like this in the lower left corner
//
//  | |
//| | | |
//
// this is a similar layout as the arrow keys on a keyboard
//
#define EVENTREGIONMOVEFORWARD(location) (location.x < 280 && location.x >= 240) && (location.y >= 400 && location.y < 440)
#define EVENTREGIONMOVEBACK(location) (location.x >= 280 && (location.y >= 400 && location.y < 440))
#define EVENTREGIONLEFT(location)(location.x >= 280 && location.y >= 440)
#define EVENTREGIONRIGHT(location)(location.x >= 280 && (location.y >= 360 && location.y < 400))

@interface Q3ScreenView ()

- (BOOL)_commonInit;
- (BOOL)_createSurface;
- (void)_destroySurface;
- (void)_queueEventWithType:(enum Q3EventType)type value1:(int)value1 value2:(int)value2;
- (void)_handleMenuDragToPoint:(CGPoint)point;
- (void)_handleTouch:(UITouch *)touch;
- (void)_handleDragFromPoint:(CGPoint)location toPoint:(CGPoint)previousLocation;

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

	[self setMultipleTouchEnabled:YES];

	_GUIMouseLocation = CGPointMake(0, 0);

	_bitMask = 0;

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

- (void)_queueEventWithType:(enum Q3EventType)type value1:(int)value1 value2:(int)value2
{
	switch (type)
	{
		case Q3Event_RotateCamera:
			Sys_QueEvent(Sys_Milliseconds(), SE_MOUSE, value1, value2, 0, NULL);
			break;

		case Q3Event_Fire:
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, value1, value2, 0, NULL);
			break;

		case Q3Event_MovePlayerForward:
		case Q3Event_MovePlayerBack:
		case Q3Event_MovePlayerLeft:
		case Q3Event_MovePlayerRight:
			Sys_QueEvent(Sys_Milliseconds(), SE_KEY, value1, value2, 0, NULL );
			break;

		default:
			return;
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

//
// handleTouch handles all touchBegan, touchMoved and touchEnd events coming
// from the touch input
// it identifies touch events by their location
// if an event is found that is associated with a certain location on screen
// the next question is if it happened in the Began, Moved or End phase
// To prevent that any event is send twice to the Quake event system
// it is guarded with a bit from a bitmask
//
- (void)_handleTouch:(UITouch *)touch
{
	CGPoint location = [touch locationInView:self];
	CGPoint previousLocation;

	// if we are in a touchMoved phase use the previous location but then check if the current
	// location is still in there
	if (touch.phase == UITouchPhaseMoved)
		previousLocation = [touch previousLocationInView:self];
	else
		previousLocation = location;

	// works only with this orientation
	if (glConfig.vidRotation == 90) // main button is on the left side
	{
		// fire event
		// lower right corner .. box is 40 x 40
		if (EVENTREGIONFIRE(previousLocation))
		{
			if (touch.phase == UITouchPhaseBegan)
			{
				// only trigger once
				if (_bitMask ^ Q3Event_Fire)
				{
					[self _queueEventWithType:Q3Event_Fire value1:K_MOUSE1 value2:1];

					_bitMask|= Q3Event_Fire;
				}
			}
			else if (touch.phase == UITouchPhaseEnded)
			{
				if (_bitMask & Q3Event_Fire)
				{
					[self _queueEventWithType:Q3Event_Fire value1:K_MOUSE1 value2:0];

					_bitMask^= Q3Event_Fire;
				}
			}
			else if (touch.phase == UITouchPhaseMoved)
			{
				if (!(EVENTREGIONFIRE(location)))
				{
					if (_bitMask & Q3Event_Fire)
					{
						[self _queueEventWithType:Q3Event_Fire value1:K_MOUSE1 value2:0];

						_bitMask^= Q3Event_Fire;
					}
				}
			}
		}


		//
		// move player
		//
		// move forward
		if (EVENTREGIONMOVEFORWARD(previousLocation))
		{
			if (touch.phase == UITouchPhaseBegan)
			{
				// only trigger once
				if (_bitMask ^ Q3Event_MovePlayerForward)
				{
					[self _queueEventWithType:Q3Event_MovePlayerForward value1:K_UPARROW value2:1];

					_bitMask|= Q3Event_MovePlayerForward;
				}
			}
			else if (touch.phase == UITouchPhaseEnded)
			{
				if (_bitMask & Q3Event_MovePlayerForward)
				{
					[self _queueEventWithType:Q3Event_MovePlayerForward value1:K_UPARROW value2:0];

					_bitMask ^= Q3Event_MovePlayerForward;
				}
			}
			else if (touch.phase == UITouchPhaseMoved)
			{
				if (!(EVENTREGIONMOVEFORWARD(location)))
				{
					if (_bitMask & Q3Event_MovePlayerForward)
					{
						[self _queueEventWithType:Q3Event_MovePlayerForward value1:K_UPARROW value2:0];

						_bitMask^= Q3Event_MovePlayerForward;
					}
				}
			}

		}

		// move back
		if (EVENTREGIONMOVEBACK(previousLocation))
		{
			if (touch.phase == UITouchPhaseBegan)
			{
				// only trigger once
				if (_bitMask ^ Q3Event_MovePlayerBack)
				{
					[self _queueEventWithType:Q3Event_MovePlayerBack value1:K_DOWNARROW value2:1];

					_bitMask|= Q3Event_MovePlayerBack;
				}
			}
			else if (touch.phase == UITouchPhaseEnded)
			{
				if (_bitMask & Q3Event_MovePlayerBack)
				{
					[self _queueEventWithType:Q3Event_MovePlayerBack value1:K_DOWNARROW value2:0];

					_bitMask^= Q3Event_MovePlayerBack;
				}
			}
			else if (touch.phase == UITouchPhaseMoved)
			{
				if (!(EVENTREGIONMOVEBACK(location)))
				{
					if (_bitMask & Q3Event_MovePlayerBack)
					{
						[self _queueEventWithType:Q3Event_MovePlayerBack value1:K_DOWNARROW value2:0];

						_bitMask^= Q3Event_MovePlayerBack;
					}
				}
			}
		}

		// to the left
		if (EVENTREGIONLEFT(previousLocation))
		{
			if (touch.phase == UITouchPhaseBegan)
			{
				// only trigger once
				if (_bitMask ^ Q3Event_MovePlayerLeft)
				{
					[self _queueEventWithType:Q3Event_MovePlayerLeft value1:'a' value2:1];

					_bitMask |= Q3Event_MovePlayerLeft;
				}
			}
			else if (touch.phase == UITouchPhaseEnded)
			{
				if (_bitMask & Q3Event_MovePlayerLeft)
				{
					[self _queueEventWithType:Q3Event_MovePlayerLeft value1:'a' value2:0];

					_bitMask^= Q3Event_MovePlayerLeft;
				}
			}
			else if (touch.phase == UITouchPhaseMoved)
			{
				if (!(EVENTREGIONLEFT(location)))
				{
					if (_bitMask & Q3Event_MovePlayerLeft)
					{
						[self _queueEventWithType:Q3Event_MovePlayerLeft value1:'a' value2:0];

						_bitMask^= Q3Event_MovePlayerLeft;
					}
				}
			}
		}

		// to the right
		if (EVENTREGIONRIGHT(previousLocation))
		{
			if (touch.phase == UITouchPhaseBegan)
			{
				// only trigger once
				if (_bitMask ^ Q3Event_MovePlayerRight)
				{
					[self _queueEventWithType:Q3Event_MovePlayerRight value1:'d' value2:1];

					_bitMask|= Q3Event_MovePlayerRight;
				}
			}
			else if (touch.phase == UITouchPhaseEnded)
			{
				if (_bitMask & Q3Event_MovePlayerRight)
				{
					[self _queueEventWithType:Q3Event_MovePlayerRight value1:'d' value2:0];

					_bitMask^= Q3Event_MovePlayerRight;
				}
			}
			else if (touch.phase == UITouchPhaseMoved)
			{
				if (!(EVENTREGIONRIGHT(location)))
				{
					if (_bitMask & Q3Event_MovePlayerRight)
					{
						[self _queueEventWithType:Q3Event_MovePlayerRight value1:'d' value2:0];

						_bitMask^= Q3Event_MovePlayerRight;
					}
				}
			}
		}
	}
}

// handleDragFromPoint rotates the camera based on a touchedMoved event
- (void)_handleDragFromPoint:(CGPoint)location toPoint:(CGPoint)previousLocation
{
	CGSize mouseDelta;

	if (glConfig.vidRotation == 90)
	{
		mouseDelta.width = previousLocation.y - location.y;
		mouseDelta.height = location.x - previousLocation.x;

		[self _queueEventWithType:Q3Event_RotateCamera
						   value1:roundf(mouseDelta.width * _mouseScale.x)
						   value2:roundf(mouseDelta.height * _mouseScale.y)];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// only call if the game is not in the menu system
	if (cls.state == CA_ACTIVE)
	{
		NSUInteger touchCount = 0;

		// Enumerates through all touch objects
		for (UITouch *touch in touches)
		{
			[self _handleTouch:touch];
			touchCount++;
		}
	}
	// the game is in the menu system
	else if (cls.state == CA_DISCONNECTED || cls.state == CA_CINEMATIC)
	{
		UITouch *touch = [[event allTouches] anyObject];
		CGPoint location = [touch locationInView:self];

		// Warp the pointer if in the GUI:
		if (cls.state == CA_DISCONNECTED)
			[self _handleMenuDragToPoint:location];
		Sys_QueEvent(Sys_Milliseconds(), SE_KEY, K_MOUSE1, 1, 0, NULL);
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.state == CA_ACTIVE)
	{
		NSUInteger touchCount = 0;

		// Enumerates through all touch objects
		for (UITouch *touch in touches)
		{
			[self _handleTouch:touch];
			touchCount++;
		}
	}
	else if (cls.state == CA_DISCONNECTED)
	{
		UITouch *touch = [[event allTouches] anyObject];
		CGPoint location = [touch locationInView:self];

		[self _handleMenuDragToPoint:location];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (cls.state == CA_ACTIVE)
	{
		NSUInteger touchCount = 0;

		// Enumerates through all touch objects
		for (UITouch *touch in touches)
		{
			[self _handleTouch:touch];
			touchCount++;
		}
	}
	else if (cls.state == CA_DISCONNECTED || cls.state == CA_CINEMATIC)
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
