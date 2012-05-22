/*
 * Quake3 -- iOS Port
 *
 * Seth Kingsley, January 2008.
 */

#import	<UIKit/UIView.h>
#import	<OpenGLES/EAGL.h>
#import	<OpenGLES/EAGLDrawable.h>
#import	<OpenGLES/ES1/gl.h>

@class UIImageView;

@interface Q3ScreenView : UIView
{
	IBOutlet UIImageView *joypadCap;
	IBOutlet UIView *_newControlView;

@protected
	EAGLContext *_context;
	GLuint _frameBuffer;
	GLuint _renderBuffer;
	GLuint _depthBuffer;
	CGSize _size;
	CGPoint _GUIMouseLocation;
	CGSize _GUIMouseOffset;
	CGPoint _mouseScale;
	NSUInteger _numTouches;
#ifdef TODO
	unsigned int _bitMask;
#endif // TODO
	NSTimer *_gameTimer;
	BOOL _isJoypadMoving;
	CGRect _joypadArea;
	uint joypadCenterx, joypadCentery, joypadMaxRadius, joypadWidth, joypadHeight;
	int joypadTouchHash;
	CGPoint _joypadCapLocation;
	CGPoint _oldLocation;
	CGRect _shootButtonArea;
	BOOL _isShooting;
	BOOL _isLooking;
	float _touchAngle;
	float _distanceFromCenter;
}

- initWithFrame:(CGRect)frame;
@property (assign, readonly, nonatomic) NSUInteger numColorBits;
@property (assign, readonly, nonatomic) NSUInteger numDepthBits;
@property (assign, readonly, nonatomic) EAGLContext *context;
- (void)swapBuffers;

@end
