/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"Q3Application.h"
#import	"Q3ScreenView.h"
#import <UIKit/UIAlert.h>
#include "iphone_local.h"
#include "../renderer/tr_local.h"
#include "../client/client.h"

@interface Q3Application ()

- (void)_startRunning;
- (void)_stopRunning;
- (void)_quakeMain;
- (void)_deviceOrientationChanged:(NSNotification *)notification;
#ifdef IPHONE_USE_THREADS
- (void)_runMainLoop:(id)context;
- (void)keepAlive:(NSTimer *)timer;
#else
- (void)_runFrame:(NSTimer *)timer;
#endif // !IPHONE_USE_THREADS

@end

enum
{
	Q3App_ErrorTag,
	Q3App_WarningTag
};

extern cvar_t *com_maxfps;

static cvar_t *in_accelFilter;
static cvar_t *in_accelPitchBias;

@implementation Q3Application

- (void)_startRunning
{
#if IPHONE_USE_THREADS
	Com_Printf("Starting render thread...\n");

	GLimp_ReleaseGL();

	_frameThread = [NSThread detachNewThreadSelector:@selector(_runMainLoop:) toTarget:self withObject:nil];
#else
	_frameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / com_maxfps->integer
												   target:self
												 selector:@selector(_runFrame:)
												 userInfo:nil
												  repeats:YES];
#endif // IPHONE_USE_THREADS
}

- (void)_stopRunning
{
#if IPHONE_USE_THREADS
	Com_Printf("Stopping the render thread...\n")
	[_frameThread cancel];
#else
	[_frameTimer invalidate];
#endif // IPHONE_USE_THREADS
}

- (void)_quakeMain
{
	extern void Sys_Startup(int argc, char *argv[]);
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	int ac, i;
	const char *av[32];
	UIDevice *device = [UIDevice currentDevice];
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];

	ac = MIN([arguments count], sizeof(av) / sizeof(av[0]));
	for (i = 0; i < ac; ++i)
		av[i] = [[arguments objectAtIndex:i] cString];

	Sys_Startup(ac, (char **)av);

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_deviceOrientationChanged:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:device];
	[device beginGeneratingDeviceOrientationNotifications];

	in_accelFilter = Cvar_Get("in_accelFilter", "0.05", CVAR_ARCHIVE);
	in_accelPitchBias = Cvar_Get("in_accelPitchBias", "-125", CVAR_ARCHIVE);

	accelerometer.delegate = self;
	accelerometer.updateInterval = 1.0 / com_maxfps->integer;

	[_loadingView removeFromSuperview];
	_screenView.isHidden = NO;

	[self _startRunning];
}

- (void)applicationDidFinishLaunching:(id)unused
{
	[self performSelector:@selector(_quakeMain) withObject:nil afterDelay:0.0];
}

- (void)_deviceOrientationChanged:(NSNotification *)notification
{
	// Keep the orientation locked into landscape while in-game:
	if (cls.state == CA_DISCONNECTED)
	{
		UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

		if (UIDeviceOrientationIsValidInterfaceOrientation(orientation))
			GLimp_SetMode(self.deviceRotation);
	}
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if (cls.state == CA_ACTIVE)
	{
		int pitch, roll, yaw;
		float oneMinusFilter = 1.0 - in_accelFilter->value;

		_accelerationX = acceleration.x * in_accelFilter->value + _accelerationX * oneMinusFilter;
		_accelerationY = acceleration.y * in_accelFilter->value + _accelerationY * oneMinusFilter;
		_accelerationZ = acceleration.z * in_accelFilter->value + _accelerationZ * oneMinusFilter;

		pitch = RAD2DEG(atan2(_accelerationX, _accelerationZ)) + in_accelPitchBias->integer;
		if (in_accelPitchBias < 0 && pitch < -180)
			pitch = 360 + pitch;
		else if (in_accelPitchBias > 0 && pitch > 180)
			pitch = -360 + pitch;

		roll = RAD2DEG(atan2(_accelerationY, _accelerationX));
		yaw = RAD2DEG(atan2(_accelerationZ, _accelerationY));
		if (pitch != _accelPitch || roll != _accelRoll || yaw != _accelYaw)
		{
			Com_DPrintf("accel: pitch = %d, roll = %d, yaw = %d\n", pitch, roll, yaw);
			Sys_QueEventEx(Sys_Milliseconds(), SE_ACCEL, pitch, roll, yaw, 0, NULL);
			_accelPitch = pitch;
			_accelRoll = roll;
			_accelYaw = yaw;
		}
	}
}

#ifdef IPHONE_USE_THREADS
- (void)_runMainLoop:(id)context
{
	NSThread *thread = [NSThread currentThread];

	while (!thread.isCancelled)
		Com_Frame();
}
#else
- (void)_runFrame:(NSTimer *)timer
{
	Com_Frame();
}
#endif // IPHONE_USE_THREADS

@synthesize screenView = _screenView;

@dynamic deviceRotation;

- (float)deviceRotation
{
 	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

	if (!UIDeviceOrientationIsValidInterfaceOrientation(orientation))
		orientation = UIDeviceOrientationPortrait;

 	switch (orientation)
 	{
 		case UIDeviceOrientationPortrait: return 0.0;
 		case UIDeviceOrientationLandscapeRight: return 90.0;
 		case UIDeviceOrientationPortraitUpsideDown: return 180.0;
 		case UIDeviceOrientationLandscapeLeft: return 270.0;
		default: NSAssert(NO, @"Grievous errors have been made..."); return 0;
 	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	extern void Sys_Exit(int ex);

	switch (alertView.tag)
	{
		case Q3App_ErrorTag:
			Sys_Exit(1);

		case Q3App_WarningTag:
			[self _startRunning];
	}
}

- (void)presentErrorMessage:(NSString *)errorMessage
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
													 message:errorMessage
													delegate:self
										   cancelButtonTitle:@"Exit"
										   otherButtonTitles:nil] autorelease];

	alert.tag = Q3App_ErrorTag;
	[self _stopRunning];
	[alert show];
	[[NSRunLoop currentRunLoop] run];
}

- (void)presentWarningMessage:(NSString *)warningMessage
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Warning"
													 message:warningMessage
													delegate:self
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil] autorelease];

	alert.tag = Q3App_WarningTag;
	[self _stopRunning];
	[alert show];
	[[NSRunLoop currentRunLoop] run];
}

@end
