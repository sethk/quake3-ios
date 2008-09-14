/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	<UIKit/UIApplication.h>
#import	<UIKit/UINibDeclarations.h>

@class Q3ScreenView;

@interface Q3Application : UIApplication
{
@protected
	IBOutlet Q3ScreenView *_screenView;
	IBOutlet UIView *_loadingView;
}

@property (assign, readonly, nonatomic) Q3ScreenView *screenView;

@end
