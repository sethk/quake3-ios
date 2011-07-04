/*
 * Quake3 -- iOS Port
 *
 * Seth Kingsley, January 2008.
 */

#import	<UIKit/UIApplication.h>
#import	<UIKit/UINibDeclarations.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIProgressView.h>
#import <UIKit/UIAccelerometer.h>

@class Q3ScreenView;
@class Q3Downloader;

@interface Q3Application : UIApplication <UIAccelerometerDelegate>
{
@protected
	IBOutlet Q3ScreenView *_screenView;
	IBOutlet UIView *_loadingView;
	IBOutlet UILabel *_loadingLabel;
	IBOutlet UIActivityIndicatorView *_loadingActivity;
	IBOutlet UILabel *_downloadStatusLabel;
	IBOutlet UIProgressView *_downloadProgress;
	Q3Downloader *_demoDownloader;
	UIAccelerationValue _accelerationX, _accelerationY, _accelerationZ;
	int _accelPitch, _accelRoll, _accelYaw;
#if IOS_USE_THREADS
	NSThread *_frameThread;
#else
	NSTimer *_frameTimer;
#endif // IOS_USE_THREADS
}

@property (assign, readonly, nonatomic) Q3ScreenView *screenView;
@property (assign, readonly, nonatomic) float deviceRotation;
- (void)presentErrorMessage:(NSString *)errorMessage;
- (void)presentWarningMessage:(NSString *)warningMessage;

@end
